import 'package:FoodHood/Components/pickup_info_card.dart';
import 'package:FoodHood/Components/reserve_button.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:FoodHood/Components/colors.dart';
import 'package:FoodHood/Components/detail_appbar.dart';
import 'package:FoodHood/Models/PostDetailViewModel.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:intl/intl.dart';
import 'package:FoodHood/Components/toaster.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:FoodHood/Screens/profile_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:FoodHood/Components/components.dart';

class PostDetailView extends StatefulWidget {
  final String postId;
  PostDetailView({Key? key, required this.postId}) : super(key: key);

  @override
  _PostDetailViewState createState() => _PostDetailViewState();
}

class _PostDetailViewState extends State<PostDetailView>
    with TickerProviderStateMixin {
  late PostDetailViewModel viewModel;
  late String userID;
  final GlobalKey _pickupInfoKey = GlobalKey();
  final GlobalKey _allergensSectionKey = GlobalKey();
  AnimationController? _animationController;
  bool isLoading = true;
  bool isReserved = false;
  bool _isTagSectionExpanded = false;
  BitmapDescriptor? defaultIcon;

  void initializeUserId() {
    final user = FirebaseAuth.instance.currentUser;
    userID = user!.uid;
  }

  @override
  void initState() {
    super.initState();
    initializeUserId();
    viewModel = PostDetailViewModel(widget.postId);
    viewModel.fetchData(widget.postId).then((_) {
      setState(() {
        isLoading = false;
        isReserved = viewModel.isReserved;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          CupertinoDynamicColor.resolve(detailsBackgroundColor, context),
      body: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    return AnimatedBuilder(
      animation: viewModel,
      builder: (context, _) {
        return Column(
          children: [
            Expanded(
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  DetailAppBar(
                    postId: widget.postId,
                    isFavorite: viewModel.isFavorite,
                    onFavoritePressed: () => _handleFavoritePressed(context),
                    imagesWithAltText: viewModel
                        .imagesWithAltText, // Pass the images with alt text
                  ),
                  SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 24),
                            _buildTitleDescription(),
                            const SizedBox(height: 16),
                            _buildInfoCards(),
                            _buildPickupInformation(),
                            const SizedBox(height: 16),
                            _buildAllergensSection(),
                            const SizedBox(height: 16),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              child: Row(
                children: [
                  Expanded(
                    child: ReserveButton(
                      isReserved: isReserved,
                      postId: widget.postId,
                      userId: userID,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleFavoritePressed(BuildContext context) async {
    setState(() {
      viewModel.isFavorite = !viewModel.isFavorite;
    });
    HapticFeedback.lightImpact();

    if (viewModel.isFavorite) {
      await viewModel.savePost(widget.postId);
      Toaster.show(context, 'Saved ${viewModel.title} to bookmarks');
    } else {
      await viewModel.unsavePost(widget.postId);
      Toaster.show(context, 'Removed ${viewModel.title} from bookmarks');
    }
  }

  void _reverseAnimation() {
    _animationController?.reverse();
  }

  Widget _buildPostTitleSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            viewModel.title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: CupertinoColors.label.resolveFrom(context),
              letterSpacing: -1.45,
              fontSize: 28,
            ),
          ),
        ),
        AvailabilityIndicator(isReserved: isReserved),
      ],
    );
  }

  Color _generateTagColor(int index) {
    List<Color> availableColors = [yellow, orange, blue, babyPink, Cyan];
    return availableColors[index % availableColors.length];
  }

  Widget _buildTitleDescription() {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPostTitleSection(),
            const SizedBox(height: 12),
            Text(
              viewModel.description,
              style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                    color: CupertinoColors.label
                        .resolveFrom(context)
                        .withOpacity(0.6),
                    letterSpacing: -0.62,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 12),
            buildTagSection(context),
            const SizedBox(height: 12),
            InfoRow(
              firstName: viewModel.firstName,
              lastName: viewModel.lastName,
              postTimestamp: viewModel.postTimestamp,
              viewModel: viewModel,
            ),
          ],
        ));
  }

  List<Widget> buildVisibleTags(BuildContext context) {
    // Ensure that we don't try to display more tags than we have
    final int visibleCount = _isTagSectionExpanded
        ? viewModel.tags.length
        : (viewModel.tags.length < 4 ? viewModel.tags.length : 4);

    final List<Widget> visibleTags = List<Widget>.generate(
      visibleCount,
      (i) => Padding(
        padding: EdgeInsets.only(right: i < visibleCount - 1 ? 7.0 : 0),
        child: Tag(
          text: viewModel.tags[i],
          color:
              _generateTagColor(i), // Assume this method is defined elsewhere
        ),
      ),
    );
    return visibleTags;
  }

  Widget buildTagSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () =>
              setState(() => _isTagSectionExpanded = !_isTagSectionExpanded),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.fastOutSlowIn,
                  height: _isTagSectionExpanded ? null : 22,
                  child: Wrap(
                    spacing: 2.0,
                    runSpacing: 6.0,
                    alignment: WrapAlignment.start,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: buildVisibleTags(context),
                  ),
                ),
              ),
              Visibility(
                visible: viewModel.tags.length > 4,
                child: Icon(
                  _isTagSectionExpanded
                      ? FeatherIcons.chevronUp
                      : FeatherIcons.chevronDown,
                  size: 20,
                  color: CupertinoColors.systemGrey.resolveFrom(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCards() {
    return InfoCardsRow(
      expirationDate: viewModel.expirationDate,
      pickupTime: viewModel.pickupTime,
      allergens: viewModel.allergens,
      onTapPickupTime: () => _scrollToKey(_pickupInfoKey),
      onTapAllergens: () => _scrollToKey(_allergensSectionKey),
    );
  }

  void _scrollToKey(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(context,
          duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    }
  }

  Widget _buildPickupInformation() {
    return PickupInformation(
      pickupTime:
          DateFormat('EEE, MMM d, ' 'h:mm a').format(viewModel.pickupTime),
      pickupLocation: viewModel.pickupLocation,
      meetingPoint: '330, 1130 Trello Way\nKelowna, BC\nV1V 5E0',
      additionalInfo: viewModel.pickupInstructions,
      locationCoordinates: viewModel.pickupLatLng,
      viewModel: viewModel,
    );
  }

  Widget _buildAllergensSection() {
    List<String> allergenList = viewModel.allergens.split(', ');
    return Container(
        key: _allergensSectionKey,
        child: AllergensSection(allergens: allergenList));
  }
}

class AvailabilityIndicator extends StatelessWidget {
  final bool isReserved;

  const AvailabilityIndicator({Key? key, required this.isReserved})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color indicatorColor = isReserved
        ? CupertinoColors.systemRed.withOpacity(0.15)
        : CupertinoColors.activeGreen.withOpacity(0.15);

    Color circleColor =
        isReserved ? CupertinoColors.systemRed : CupertinoColors.activeGreen;
    String statusText = isReserved ? 'Reserved' : 'Available';

    return Container(
      decoration: BoxDecoration(
        color: indicatorColor,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: circleColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            statusText,
            style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                  color: CupertinoColors.label.resolveFrom(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final String firstName;
  final String lastName;
  final DateTime postTimestamp;
  final PostDetailViewModel viewModel;

  const InfoRow({
    Key? key,
    required this.firstName,
    required this.lastName,
    required this.postTimestamp,
    required this.viewModel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: GestureDetector(
          onTap: () => Navigator.push(
                context,
                CupertinoPageRoute(
                    builder: (context) =>
                        ProfileScreen(userId: viewModel.userid)),
              ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                child: ClipOval(
                  child: viewModel.profileURL.isNotEmpty &&
                          viewModel.profileURL.startsWith('http')
                      ? CachedNetworkImage(
                          imageUrl: viewModel.profileURL,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              const CupertinoActivityIndicator(),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.error),
                        )
                      : Image.asset('assets/images/sampleProfile.png',
                          fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Posted by $firstName $lastName',
                      style: TextStyle(
                        color: CupertinoColors.label
                            .resolveFrom(context)
                            .withOpacity(0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.48,
                      ),
                    ),
                    Icon(
                      FeatherIcons.chevronRight,
                      size: 14,
                      color: CupertinoColors.label
                          .resolveFrom(context)
                          .withOpacity(0.6),
                    ),
                    Text(
                      ' ${viewModel.timeAgoSinceDate(postTimestamp)}',
                      style: TextStyle(
                        color: CupertinoColors.label
                            .resolveFrom(context)
                            .withOpacity(0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.48,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(Icons.star, color: secondaryColor, size: 14),
                    Text(
                      ' ${viewModel.rating} Rating',
                      style: TextStyle(
                        overflow: TextOverflow.fade,
                        color: CupertinoColors.label
                            .resolveFrom(context)
                            .withOpacity(0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.48,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )),
    );
  }
}

class InfoCardsRow extends StatelessWidget {
  final DateTime expirationDate;
  final DateTime pickupTime;
  final String allergens;
  final VoidCallback? onTapPickupTime;
  final VoidCallback? onTapAllergens;

  const InfoCardsRow({
    Key? key,
    required this.expirationDate,
    required this.pickupTime,
    required this.allergens,
    this.onTapPickupTime,
    this.onTapAllergens,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String formattedExp = DateFormat('d MMM yyyy').format(expirationDate);
    String formattedPick = DateFormat('h:mm a').format(pickupTime);
    int allergenCount = allergens.isEmpty ? 0 : allergens.split(',').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          buildInfoCard(
            icon: FeatherIcons.meh,
            title: 'Expiration Date',
            subtitle: formattedExp,
            context: context,
            color: CupertinoColors.systemRed,
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: onTapPickupTime, // Use the callback here
            child: buildInfoCard(
              icon: FeatherIcons.shoppingBag,
              title: 'Pickup Time',
              subtitle: formattedPick,
              context: context,
              color: blue,
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: onTapAllergens, // Use the callback here
            child: buildInfoCard(
              icon: FeatherIcons.alertCircle,
              title: 'Allergens',
              subtitle: allergenCount == 0 ? 'None' : '$allergenCount Total',
              context: context,
              color: yellow,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required BuildContext context,
    required Color color,
  }) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: CupertinoColors.tertiarySystemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          const BoxShadow(
            color: Color(0x19000000),
            blurRadius: 10,
            offset: Offset(0, 0),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: CupertinoColors.label.resolveFrom(context),
                letterSpacing: -0.55,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: CupertinoColors.systemGrey.resolveFrom(context),
                letterSpacing: -0.55,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class IconPlaceholder extends StatelessWidget {
  final String imageUrl;
  IconPlaceholder({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      child: ClipOval(
        child: imageUrl.isNotEmpty && imageUrl.startsWith('http')
            ? CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
              )
            : Image.asset(
                'assets/images/sampleProfile.png',
                fit: BoxFit.cover,
              ),
      ),
    );
  }
}

class CombinedTexts extends StatelessWidget {
  final String firstName;
  final String lastName;
  final DateTime postTimestamp;
  final PostDetailViewModel viewModel;

  const CombinedTexts({
    Key? key,
    required this.firstName,
    required this.lastName,
    required this.postTimestamp,
    required this.viewModel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Posted by $firstName $lastName  ${viewModel.timeAgoSinceDate(postTimestamp)}',
          style: TextStyle(
            color: CupertinoColors.label.resolveFrom(context).withOpacity(0.8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.48,
          ),
        ),
        const Text("  "),
        RatingText(viewModel: viewModel),
      ],
    );
  }
}

class InfoText extends StatelessWidget {
  final String firstName;
  final String lastName;
  final DateTime postTimestamp;
  final PostDetailViewModel viewModel;

  const InfoText({
    Key? key,
    required this.firstName,
    required this.lastName,
    required this.postTimestamp,
    required this.viewModel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RichText(
      overflow: TextOverflow.fade,
      text: TextSpan(
        style: TextStyle(
          color: CupertinoColors.label.resolveFrom(context).withOpacity(0.8),
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.48,
        ),
        children: <TextSpan>[
          TextSpan(text: 'Prepared by $firstName $lastName'),
          const TextSpan(text: '   '),
          TextSpan(
            text: 'Posted ${viewModel.timeAgoSinceDate(postTimestamp)}',
            style: const TextStyle(letterSpacing: -0.48),
          ),
        ],
      ),
    );
  }
}

class RatingText extends StatelessWidget {
  final PostDetailViewModel viewModel;

  const RatingText({Key? key, required this.viewModel}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.star,
          color: secondaryColor,
          size: 14,
        ),
        const SizedBox(width: 3),
        Text(
          '${viewModel.rating} Rating',
          style: TextStyle(
            overflow: TextOverflow.fade,
            color: CupertinoColors.label.resolveFrom(context).withOpacity(0.8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.48,
          ),
        ),
      ],
    );
  }
}

class CustomInfoTile extends StatelessWidget {
  final String title;
  final String subtitle;

  const CustomInfoTile({
    Key? key,
    required this.title,
    required this.subtitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: CupertinoColors.label.resolveFrom(context),
                fontWeight: FontWeight.w600,
                letterSpacing: -0.55,
              ),
            ),
          ),
          Expanded(
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color:
                    CupertinoColors.label.resolveFrom(context).withOpacity(0.6),
                fontWeight: FontWeight.w500,
                letterSpacing: -0.55,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MessageBox extends StatelessWidget {
  final BuildContext context;
  final String text;

  const MessageBox({Key? key, required this.context, required this.text})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: CupertinoColors.quaternarySystemFill.resolveFrom(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        textAlign: TextAlign.start,
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
        style: TextStyle(
          color: CupertinoColors.label.resolveFrom(context),
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.48,
        ),
      ),
    );
  }
}

class InfoButton extends StatelessWidget {
  final BuildContext context;
  final String text;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onPressed;

  const InfoButton({
    Key? key,
    required this.context,
    required this.text,
    required this.icon,
    required this.iconColor,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: CupertinoColors.quaternarySystemFill.resolveFrom(context),
      borderRadius: BorderRadius.circular(100),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            style: TextStyle(
              color: CupertinoColors.label.resolveFrom(context),
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.48,
            ),
          ),
        ],
      ),
    );
  }
}

class AllergensSection extends StatelessWidget {
  final List<String> allergens;

  const AllergensSection({Key? key, required this.allergens}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Allergens',
            style: TextStyle(
              fontSize: 20,
              color: CupertinoColors.label.resolveFrom(context),
              letterSpacing: -0.70,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color:
                  CupertinoColors.tertiarySystemBackground.resolveFrom(context),
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                const BoxShadow(
                  color: Color(0x19000000),
                  blurRadius: 20,
                  offset: Offset(0, 0),
                ),
              ],
            ),
            child: Wrap(
              alignment: WrapAlignment.start,
              spacing: 8.0, // Space between the allergens
              runSpacing: 8.0, // Space between the lines
              children: allergens
                  .map((allergen) => _buildAllergenRow(allergen, context))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAllergenRow(String allergen, BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('• ',
            style: TextStyle(
                color: CupertinoColors.label.resolveFrom(context),
                fontSize: 14,
                fontWeight: FontWeight.w600)),
        Expanded(
            child: Text(
          allergen,
          style: TextStyle(
            fontSize: 14,
            color: CupertinoColors.label.resolveFrom(context),
            letterSpacing: -0.55,
            fontWeight: FontWeight.w500,
          ),
        )),
      ],
    );
  }
}
