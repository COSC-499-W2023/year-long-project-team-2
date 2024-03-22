import 'package:FoodHood/Screens/message_list.dart';
import 'package:FoodHood/Screens/settings_screen.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:FoodHood/Components/profile_card.dart';
import 'package:FoodHood/Components/order_card.dart';
import 'package:FoodHood/Components/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:FoodHood/text_scale_provider.dart';
import 'package:provider/provider.dart';


const double _defaultTextFontSize = 16.0;
const double _defaultTabTextFontSize = 14.0;

class AccountScreen extends StatefulWidget {
  @override
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  int segmentedControlGroupValue = 0;
  List<Widget> activeDonatedOrders = [];
  List<OrderCard> pastDonatedOrders = [];
  List<Widget> activeReservedOrders = [];
  List<OrderCard> pastReservedOrders = [];
  late double _textScaleFactor;
  late double adjustedTextFontSize;
  late double adjustedTabTextFontSize;

  @override
  void initState() {
    super.initState();
    setUpPostStreamListener();
    _textScaleFactor =
        Provider.of<TextScaleProvider>(context, listen: false).textScaleFactor;
    _updateAdjustedFontSize();
  }

  void setUpPostStreamListener() {
    final String currentUserUID = FirebaseAuth.instance.currentUser?.uid ?? '';

    FirebaseFirestore.instance
        .collection('post_details')
        .orderBy('post_timestamp', descending: true)
        .where('user_id', isEqualTo: currentUserUID)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        var activeDonatedDocs = snapshot.docs
            .where((doc) => doc['post_status'] != 'completed')
            .toList();
        var pastDonatedDocs = snapshot.docs
            .where((doc) => doc['post_status'] == 'completed')
            .toList();
        if (mounted) {
          updateDonatedActiveOrders(activeDonatedDocs);
          updateDonatedPastOrders(pastDonatedDocs);
        }
      }
    });

    FirebaseFirestore.instance
        .collection('post_details')
        .orderBy('post_timestamp', descending: true)
        .where('reserved_by', isEqualTo: currentUserUID)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        var activeReservedDocs = snapshot.docs
            .where((doc) => doc['post_status'] != 'completed')
            .toList();
        var pastReservedDocs = snapshot.docs
            .where((doc) => doc['post_status'] == 'completed')
            .toList();
        if (mounted) {
          updateReservedActiveOrders(activeReservedDocs);
          updateReservedPastOrders(pastReservedDocs);
        }
      }
    });
  }

  void updateDonatedActiveOrders(List<QueryDocumentSnapshot> documents) {
    setState(() {
      activeDonatedOrders = documents.map((doc) {
        return createOrderCard(
            doc.data() as Map<String, dynamic>, doc.id, true);
      }).toList();
    });
  }

  void updateDonatedPastOrders(List<QueryDocumentSnapshot> documents) {
    setState(() {
      pastDonatedOrders = documents
          .map((doc) =>
              createOrderCard(doc.data() as Map<String, dynamic>, doc.id, true))
          .toList();
    });
  }

  void updateReservedActiveOrders(List<QueryDocumentSnapshot> documents) {
    setState(() {
      activeReservedOrders = documents.map((doc) {
        return createOrderCard(
            doc.data() as Map<String, dynamic>, doc.id, false);
      }).toList();
    });
  }

  void updateReservedPastOrders(List<QueryDocumentSnapshot> documents) {
    setState(() {
      pastReservedOrders = documents
          .map((doc) => createOrderCard(
              doc.data() as Map<String, dynamic>, doc.id, false))
          .toList();
    });
  }

  void _updateAdjustedFontSize() {
    adjustedTextFontSize = _defaultTextFontSize * _textScaleFactor;
    adjustedTabTextFontSize = _defaultTabTextFontSize * _textScaleFactor;
  }

  void _onOrderCardTap(String postId) {
    setState(() {
      postId = postId;
    });
    print(postId + 'accountscreen');
  }

  OrderCard createOrderCard(
      Map<String, dynamic> documentData, String postId, bool isDonation) {
    String title = documentData['title'] ?? 'No Title';
    List<String> tags = documentData['categories'].split(',');
    DateTime createdAt = (documentData['post_timestamp'] as Timestamp).toDate();

    List<Map<String, String>> imagesWithAltText = [];
    if (documentData.containsKey('images') && documentData['images'] is List) {
      imagesWithAltText = List<Map<String, String>>.from(
        (documentData['images'] as List).map((image) {
          return {
            'url': image['url'] as String? ?? '',
            'alt_text': image['alt_text'] as String? ?? '',
          };
        }),
      );
    }

    return OrderCard(
      title: title,
      tags: tags,
      orderInfo: 'Posted on ${DateFormat('MMMM dd, yyyy').format(createdAt)}',
      postId: postId,
      onTap: _onOrderCardTap,
      imagesWithAltText: imagesWithAltText,
      orderState: OrderState.confirmed,
      isDonation: isDonation,
    );
  }

  String getCurrentUserUID() {
    return FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  @override
  Widget build(BuildContext context) {
    _textScaleFactor = Provider.of<TextScaleProvider>(context).textScaleFactor;
    _updateAdjustedFontSize();

    final Map<int, Widget> tabs = <int, Widget>{
      0: Text(
        'Donations',
        style: TextStyle(
          fontSize: adjustedTabTextFontSize,
          fontWeight: FontWeight.w500,
        ),
      ),
      1: Text(
        'Reservations',
        style: TextStyle(
            fontSize: adjustedTabTextFontSize, fontWeight: FontWeight.w500),
      ),
    };

    return CupertinoPageScaffold(
      backgroundColor: groupedBackgroundColor,
      child: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: <Widget>[
            _buildNavigationBar(context),
            SliverToBoxAdapter(child: ProfileCard()),
            _buildSegmentControl(tabs),
            _buildOrdersContent(segmentedControlGroupValue),
          ],
        ),
      ),
    );
  }

  CupertinoSliverNavigationBar _buildNavigationBar(BuildContext context) {
    return CupertinoSliverNavigationBar(
      transitionBetweenRoutes: false,
      backgroundColor:
          CupertinoDynamicColor.resolve(groupedBackgroundColor, context)
              .withOpacity(0.8),
      largeTitle: Text('Account'),
      leading: CupertinoButton(
        padding: EdgeInsets.zero,
        child: Text('Messages',
            style: TextStyle(fontWeight: FontWeight.w500, color: accentColor)),
        onPressed:  () => Navigator.of(context).push(CupertinoPageRoute(builder: (context) => MessageListPage())),
      ),
      trailing: CupertinoButton(
        padding: EdgeInsets.zero,
        child: Text('Settings',
            style: TextStyle(fontWeight: FontWeight.w500, color: accentColor)),
        onPressed: () => _navigateToSettings(context),
      ),
      border: Border(bottom: BorderSide.none),
      stretch: true, // Enable stretch behavior
    );
  }

  void _navigateToSettings(BuildContext context) {
    Navigator.of(context)
        .push(CupertinoPageRoute(builder: (context) => SettingsScreen()));
  }

  SliverToBoxAdapter _buildSegmentControl(Map<int, Widget> myTabs) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: CupertinoSlidingSegmentedControl<int>(
          children: myTabs,
          onValueChanged: (int? newValue) {
            if (newValue != null) {
              setState(() => segmentedControlGroupValue = newValue);
            }
          },
          groupValue: segmentedControlGroupValue,
        ),
      ),
    );
  }

  Widget _buildOrdersContent(int segmentedValue) {
    List<dynamic> orders =
        segmentedValue == 1 ? activeReservedOrders : activeDonatedOrders;
    List<dynamic> pastOrders =
        segmentedValue == 1 ? pastReservedOrders : pastDonatedOrders;
    String activeTitle = "In Progress";
    String completedTitle = "Completed";

    int totalWidgets = 0;
    if (orders.isNotEmpty) {
      totalWidgets +=
          1 + (2 * orders.length); // For title and each order with a SizedBox
    }
    if (pastOrders.isNotEmpty) {
      totalWidgets += 1 + (2 * pastOrders.length); // Same as above
    }

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            List<Widget> combinedList = [];
            if (orders.isNotEmpty) {
              combinedList.add(buildTitleSection(context, activeTitle));
              combinedList.addAll(
                  orders.expand((order) => [order, SizedBox(height: 16.0)]));
            }
            if (pastOrders.isNotEmpty) {
              combinedList.add(buildTitleSection(context, completedTitle));
              combinedList.addAll(pastOrders
                  .expand((order) => [order, SizedBox(height: 16.0)]));
            }
            if (combinedList.isEmpty) {
              combinedList.add(_buildSectionPlaceholderText(
                  segmentedValue == 1
                      ? "No Reserved Orders"
                      : "No Donated Orders"));
            }
            return combinedList[index];
          },
          childCount:
              totalWidgets, // Updated to use the calculated totalWidgets
        ),
      ),
    );
  }

  Widget buildTitleSection(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, left: 10.0),
      child: Text(
        title,
        style: TextStyle(
          overflow: TextOverflow.ellipsis,
          color: CupertinoDynamicColor.resolve(CupertinoColors.label, context)
              .withOpacity(0.8),
          fontSize: 18,
          letterSpacing: -0.8,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSectionPlaceholderText(String message) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            FeatherIcons.shoppingBag,
            size: 22,
            color: CupertinoColors.systemGrey,
          ),
          SizedBox(width: 8.0,),
          Text(
            message,
            style: TextStyle(
              fontSize: adjustedTextFontSize,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      )
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
