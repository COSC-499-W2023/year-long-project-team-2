import 'dart:async';

import 'package:FoodHood/Components/colors.dart';
import 'package:FoodHood/Components/filter_sheet.dart';
import 'package:FoodHood/Components/post_card.dart';
import 'package:FoodHood/Screens/create_post.dart';
import 'package:FoodHood/Services/FirebaseService.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

import '../Components/components.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isSearching = false;
  final TextEditingController textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<Widget> postCards = [];
  Map<String, Color> tagColors = {};
  StreamSubscription<QuerySnapshot>? postsSubscription;
  bool isLoading = true;
  Map<String, dynamic> currentFilterCriteria = {};
  List<String> categories = [];
  Map<String, Color> categoryColors = {};

  double _scale = 1.0;

  void applyFilters(Map<String, dynamic> filterCriteria) async {
    String collectionDay = filterCriteria['collectionDay'] ?? 'All';
    List<String> selectedFoodTypes =
        List<String>.from(filterCriteria['selectedFoodTypes'] ?? []);
    List<String> selectedDietPreferences =
        List<String>.from(filterCriteria['selectedDietPreferences'] ?? []);
    RangeValues selectedTimeRange =
        filterCriteria['collectionTime'] as RangeValues;

    DateTime now = DateTime.now();
    DateTime targetDate;
    if (collectionDay == "Today") {
      targetDate = DateTime(now.year, now.month, now.day);
    } else if (collectionDay == "Tomorrow") {
      DateTime tomorrow = now.add(const Duration(days: 1));
      targetDate = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
    } else {
      targetDate = now;
    }

    var snapshot = await FirebaseFirestore.instance
        .collection('post_details')
        .orderBy('post_timestamp', descending: true)
        .get();

    List<Widget> filteredPosts = [];

    for (var doc in snapshot.docs) {
      var data = doc.data();
      Timestamp? pickupTimestamp = data['pickup_time'] as Timestamp?;
      DateTime? pickupDateTime = pickupTimestamp?.toDate();

      bool isDayMatch = collectionDay == "All" ||
          (pickupDateTime != null &&
              pickupDateTime.year == targetDate.year &&
              pickupDateTime.month == targetDate.month &&
              pickupDateTime.day == targetDate.day);

      bool isTimeMatch = collectionDay == "All" ||
          (pickupDateTime != null &&
              pickupDateTime.hour + pickupDateTime.minute / 60.0 >=
                  selectedTimeRange.start &&
              pickupDateTime.hour + pickupDateTime.minute / 60.0 <=
                  selectedTimeRange.end);

      List<String> categories = List<String>.from(
          (data['categories'] ?? '').split(',').map((s) => s.trim()));
      List<String> allergens = List<String>.from(
          (data['allergens'] ?? '').split(',').map((s) => s.trim()));
      List<String> combinedTags = [...categories, ...allergens];

      bool hasMatchingTags = selectedFoodTypes
              .every((tag) => combinedTags.contains(tag)) &&
          selectedDietPreferences.every((tag) => combinedTags.contains(tag));

      if (isDayMatch &&
          isTimeMatch &&
          hasMatchingTags &&
          !data.containsKey('reserved_by')) {
        var postWidget = await _buildPostCard(doc);
        filteredPosts.add(postWidget);
      }
    }

    if (mounted) {
      setState(() {
        postCards = filteredPosts;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: groupedBackgroundColor,
      child: Stack(
        children: [
          CustomScrollView(slivers: <Widget>[
            buildMainNavigationBar(context, 'Home'),
            SliverToBoxAdapter(
                child: Column(children: <Widget>[
              _buildSearchBar(context),
              const SizedBox(height: 16),
              _buildCategoryButtons(),
              const SizedBox(height: 8)
            ])),
            isLoading ? _buildLoadingSliver(context) : _buildPostListSliver(),
          ]),
          _buildAddButton(context),
        ],
      ),
    );
  }

  @override
  void dispose() {
    textController.removeListener(_onSearchTextChanged);
    textController.dispose();
    _focusNode.dispose();
    postsSubscription?.cancel();
    super.dispose();
  }

  Future<List<String>> fetchCategories() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      DocumentSnapshot snapshot =
          await firestore.collection('Data').doc('Categories').get();

      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data() as Map<String, dynamic>;

        final categories = List<String>.from(data['categories'] ?? []);
        return categories;
      } else {
        return [];
      }
    } catch (e) {
      print("Error fetching categories: $e");
      return [];
    }
  }

  Future<List<QueryDocumentSnapshot>> fetchDocuments() async {
    var snapshot =
        await FirebaseFirestore.instance.collection('post_details').get();
    return snapshot.docs;
  }

  Future<List<Widget>> fetchFilteredPosts(
      List<String> selectedCategories) async {
    Query query = FirebaseFirestore.instance.collection('post_details');

    if (selectedCategories.isNotEmpty) {
      query = query.where('categories', whereIn: selectedCategories);
    }

    var querySnapshot = await query.get();
    var futures = querySnapshot.docs.map((doc) => _buildPostCard(doc)).toList();
    return await Future.wait(futures);
  }

  Future<List<Widget>> fetchPosts(String searchString) async {
    var querySnapshot = await FirebaseFirestore.instance
        .collection('post_details')
        .orderBy('post_timestamp', descending: true)
        .get();

    var futures = querySnapshot.docs
        .where((doc) => _matchesSearchString(doc, searchString))
        .where((doc) {
          var data = doc.data();

          return !data.containsKey('reserved_by');
        })
        .map((doc) => _buildPostCard(doc))
        .toList();

    return await Future.wait(futures);
  }

  List<QueryDocumentSnapshot> filterDocuments(
      List<QueryDocumentSnapshot> docs, List<String> selectedFilters) {
    return docs.where((doc) {
      var docCategoriesAndAllergens =
          ((doc.data() as Map<String, dynamic>)['categories'] as String)
              .split(',')
              .map((s) => s.trim())
              .toList();
      if (((doc.data() as Map<String, dynamic>)['allergens'] as String?)
              ?.isNotEmpty ??
          false) {
        docCategoriesAndAllergens.addAll(
            ((doc.data() as Map<String, dynamic>)['allergens'] as String)
                .split(',')
                .map((s) => s.trim()));
      }

      return selectedFilters
          .every((filter) => docCategoriesAndAllergens.contains(filter));
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _initListeners();
    _loadInitialPosts();
    fetchCategories().then((fetchedCategories) {
      final Color allCategoryColor = accentColor;

      List<Color> cycleColors = [yellow, orange, blue, babyPink, Cyan];

      setState(() {
        categories = ['All'] +
            fetchedCategories.map((category) {
              return category == 'Unknown' ? 'Others' : category;
            }).toList();

        int cycleIndex = 0;

        categories.forEach((category) {
          if (category == 'All') {
            categoryColors[category] = allCategoryColor;
          } else {
            if (category == 'Others') {
              categoryColors[category] =
                  cycleColors[cycleIndex % cycleColors.length];
              cycleIndex++;
            } else {
              categoryColors[category] =
                  cycleColors[cycleIndex % cycleColors.length];
              cycleIndex++;
            }
          }
        });
      });
    });
  }

  String timeAgoSinceDate(DateTime dateTime) {
    final duration = DateTime.now().difference(dateTime);
    if (duration.inDays > 7) {
      return DateFormat('MMMM dd, yyyy').format(dateTime);
    }
    if (duration.inDays >= 1) {
      return '${duration.inDays} day${duration.inDays > 1 ? "s" : ""} ago';
    }
    if (duration.inHours >= 1) {
      return '${duration.inHours} hour${duration.inHours > 1 ? "s" : ""} ago';
    }
    if (duration.inMinutes >= 1) {
      return '${duration.inMinutes} minute${duration.inMinutes > 1 ? "s" : ""} ago';
    }
    return 'Just now';
  }

  Widget _buildAddButton(BuildContext context) {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 16.0,
      right: 16.0,
      child: GestureDetector(
        onTap: () => {
          HapticFeedback.selectionClick(),
          _openCreatePostScreen(context),
        },
        onTapDown: (_) {
          setState(() => _scale = 0.85);
          HapticFeedback.selectionClick();
        },
        onTapUp: (_) {
          setState(() => _scale = 1.0);
          HapticFeedback.selectionClick();
          _openCreatePostScreen(context);
        },
        onTapCancel: () {
          setState(() => _scale = 1.0);
          HapticFeedback.selectionClick();
        },
        child: Transform.scale(
          scale: _scale,
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: Color(0x19000000),
                    blurRadius: 20,
                    offset: Offset(0, 0)),
              ],
            ),
            child: CupertinoButton(
              onPressed: () => _openCreatePostScreen(context),
              padding: const EdgeInsets.all(16.0),
              color: accentColor,
              borderRadius: BorderRadius.circular(40.0),
              child: const Icon(CupertinoIcons.add,
                  color: CupertinoColors.white, size: 30),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryButton(String title) {
    Color color = categoryColors[title] ?? Colors.grey;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 60, maxHeight: 40),
      child: CupertinoButton(
        color: color,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        borderRadius: BorderRadius.circular(100),
        onPressed: () => _filterPostsByCategory(title),
        child: Text(title,
            style: TextStyle(
                color: color.computeLuminance() > 0.5
                    ? Colors.black
                    : Colors.white,
                fontSize: 16,
                letterSpacing: -0.6,
                fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildCategoryButtons() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Wrap(
          spacing: 8.0,
          children: categories
              .map((category) => _buildCategoryButton(category))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildFilterButton() {
    return Container(
      height: 37,
      width: 37,
      decoration: BoxDecoration(
        color: CupertinoColors.tertiarySystemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: _showFilterSheet,
        child: Icon(FeatherIcons.filter,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
            size: 20),
      ),
    );
  }

  Widget _buildLoadingSliver(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
            const CupertinoActivityIndicator(),
            const SizedBox(height: 10),
            Text('Loading',
                style: TextStyle(
                    color: CupertinoColors.secondaryLabel.resolveFrom(context)))
          ])),
    );
  }

  Widget _buildNoPostsWidget() {
    return Column(
      children: [
        const SizedBox(height: 200),
        Icon(
          FeatherIcons.meh,
          size: 40,
          color: CupertinoColors.secondaryLabel.resolveFrom(context),
        ),
        const SizedBox(height: 16),
        Text(
          'No posts available',
          style: TextStyle(
            fontSize: 16,
            letterSpacing: -0.6,
            fontWeight: FontWeight.w500,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
      ],
    );
  }

  Future<Widget> _buildPostCard(QueryDocumentSnapshot document) async {
    var data = document.data() as Map<String, dynamic>?;
    if (data == null) {
      return const SizedBox.shrink();
    }

    List<String> tags = (data['categories'] as String?)
            ?.split(',')
            .map((tag) => tag.trim())
            .toList() ??
        [];
    List<Color> assignedColors() {
      return [yellow, orange, blue, babyPink, Cyan];
    }

    var userData = await readDocument(
        collectionName: 'user', docName: data['user_id'] ?? 'Unknown');
    var createdAt =
        (data['post_timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();

    List<Map<String, String>> imagesWithAltText = [];
    if (data.containsKey('images') && data['images'] is List) {
      imagesWithAltText = List<Map<String, String>>.from(
        (data['images'] as List).map((image) {
          return {
            'url': image['url'] as String? ?? '',
            'alt_text': image['alt_text'] as String? ?? '',
          };
        }),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: PostCard(
        imagesWithAltText: imagesWithAltText,
        title: data['title'] ?? 'No Title',
        tags: tags,
        tagColors: assignedColors(),
        firstName: userData?['firstName'] ?? 'Unknown',
        lastName: userData?['lastName'] ?? 'Unknown',
        timeAgo: timeAgoSinceDate(createdAt),
        onTap: (postId) => setState(() => {}),
        postId: document.id,
        profileURL: userData?['profileImagePath'] ?? '',
      ),
    );
  }

  Widget _buildPostListSliver() {
    if (postCards.isEmpty && !isSearching) {
      return SliverFillRemaining(
        child: Center(child: _buildNoPostsWidget()),
      );
    } else if (postCards.isEmpty && isSearching) {
      return SliverFillRemaining(
        child: Column(
          children: [
            const SizedBox(height: 200),
            Icon(
              FeatherIcons.search,
              size: 40,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: TextStyle(
                fontSize: 16,
                letterSpacing: -0.6,
                fontWeight: FontWeight.w500,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
          ],
        ),
      );
    } else {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => postCards[index],
          childCount: postCards.length,
        ),
      );
    }
  }

  Widget _buildSearchBar(BuildContext context) {
    bool isFocused = _focusNode.hasFocus;

    void clearSearch() {
      textController.clear();

      if (_focusNode.hasFocus) {
        _focusNode.unfocus();
      }

      setState(() {
        isSearching = false;
        _loadInitialPosts();
      });
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: CupertinoSearchTextField(
                    controller: textController,
                    focusNode: _focusNode,
                    prefixIcon: Container(
                      margin: const EdgeInsets.only(left: 6.0, top: 2.0),
                      child: const Icon(
                        FeatherIcons.search,
                        size: 18.0,
                      ),
                    ),
                    backgroundColor: CupertinoColors.tertiarySystemBackground,
                    placeholderStyle: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w400,
                      color:
                          CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                    style: const TextStyle(
                      color: CupertinoColors.black,
                    ),
                    placeholder: 'Search',
                    suffixIcon: Icon(
                      FeatherIcons.x,
                      color:
                          CupertinoColors.secondaryLabel.resolveFrom(context),
                      size: 20,
                    ),
                    onSuffixTap: clearSearch,
                  ),
                ),
                const SizedBox(width: 8),
                if (isFocused)
                  GestureDetector(
                    onTap: clearSearch,
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (!isFocused)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _buildFilterButton(),
            ),
        ],
      ),
    );
  }

  CupertinoSearchTextField _buildSearchTextField(BuildContext context) {
    return CupertinoSearchTextField(
      prefixIcon: Container(
        margin: const EdgeInsets.only(left: 6.0, top: 2.0),
        child: const Icon(
          FeatherIcons.search,
          size: 18.0,
        ),
      ),
      placeholderStyle: TextStyle(
        fontSize: 16.0,
        fontWeight: FontWeight.w400,
        color: CupertinoColors.secondaryLabel.resolveFrom(context),
      ),
      suffixIcon: Icon(
        FeatherIcons.x,
        color: CupertinoColors.secondaryLabel.resolveFrom(context),
        size: 20,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      style: TextStyle(
        fontSize: 18,
        color: CupertinoColors.label.resolveFrom(context),
      ),
      backgroundColor: CupertinoColors.tertiarySystemBackground,
      controller: textController,
      placeholder: 'Search',
      onChanged: (value) => _onSearchTextChanged(),
    );
  }

  void _filterPostsByCategory(String categoryName) async {
    setState(() => isLoading = true);

    var snapshot = await FirebaseFirestore.instance
        .collection('post_details')
        .orderBy('post_timestamp', descending: true)
        .get();

    List<Widget> filteredPosts = [];

    for (var doc in snapshot.docs) {
      var data = doc.data();
      var categories =
          List.from(data['categories'].split(',').map((c) => c.trim()));
      var allergens = data['allergens'] != null
          ? List.from(data['allergens'].split(',').map((a) => a.trim()))
          : [];

      if (categoryName == 'All' ||
          categories.contains(categoryName) ||
          allergens.contains(categoryName)) {
        var postWidget = await _buildPostCard(doc);
        filteredPosts.add(postWidget);
      }
    }

    if (mounted) {
      setState(() {
        postCards = filteredPosts;
        isLoading = false;
      });
    }
  }

  void _initListeners() {
    textController.addListener(_onSearchTextChanged);
    _focusNode.addListener(_onFocusChange);
  }

  void _loadInitialPosts() {
    setState(() => isLoading = true);
    postsSubscription = FirebaseFirestore.instance
        .collection('post_details')
        .orderBy('post_timestamp', descending: true)
        .snapshots()
        .listen((snapshot) async {
      if (mounted) {
        postCards = await _processSnapshot(snapshot);
        setState(() => isLoading = false);
      }
    });
  }

  bool _matchesSearchString(QueryDocumentSnapshot doc, String searchString) {
    var data = doc.data() as Map<String, dynamic>;
    var title = data['title']?.toLowerCase() ?? '';
    var tags = List<String>.from(
        data['categories'].split(',').map((tag) => tag.toLowerCase()));
    return title.contains(searchString) ||
        tags.any((tag) => tag.contains(searchString));
  }

  void _onFocusChange() {
    setState(() {});
  }

  void _onSearchTextChanged() {
    var searchString = textController.text.toLowerCase();
    if (searchString.isNotEmpty) {
      setState(() {
        isSearching = true;
      });
      fetchPosts(searchString).then((posts) {
        if (mounted) {
          setState(() {
            postCards = posts;
          });
        }
      });
    } else {
      setState(() {
        isSearching = false;
        _loadInitialPosts();
      });
    }
  }

  void _openCreatePostScreen(BuildContext context) {
    Navigator.of(context).push(
      CupertinoModalPopupRoute(
        builder: (context) => const CreatePostScreen(),
      ),
    );
  }

  Future<List<Widget>> _processSnapshot(QuerySnapshot snapshot) async {
    List<Widget> cards = [];
    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>?;
      if (data != null && !data.containsKey('reserved_by')) {
        cards.add(await _buildPostCard(doc));
      }
    }
    if (cards.isEmpty) {
      cards.add(_buildNoPostsWidget());
    } else {
      cards.add(const SizedBox(height: 100));
    }
    return cards;
  }

  void _showFilterSheet() {
    showCupertinoModalBottomSheet(
      context: context,
      backgroundColor:
          CupertinoDynamicColor.resolve(groupedBackgroundColor, context),
      builder: (context) => SafeArea(
        child: FilterSheet(
          initialCriteria: currentFilterCriteria,
          onApplyFilters: (filterCriteria) {
            setState(() {
              currentFilterCriteria = filterCriteria;
            });
            applyFilters(filterCriteria);
          },
        ),
      ),
    );
  }
}
