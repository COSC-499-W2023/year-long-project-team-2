import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:FoodHood/Models/PostDetailViewModel.dart';
import 'package:FoodHood/Screens/donor_rating.dart';
import 'package:FoodHood/Screens/posting_detail.dart';

class DoneePath extends StatefulWidget {
  final String postId;

  DoneePath({required this.postId});

  @override
  _DoneePathState createState() => _DoneePathState();
}

class _DoneePathState extends State<DoneePath> {
  late PostDetailViewModel viewModel;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    viewModel = PostDetailViewModel(widget.postId);
    viewModel.fetchData(widget.postId).then((_) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    });
  }

  void _navigateToRatingPage() {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => DonorRatingPage(postId: widget.postId),
      ),
    );
  }

  String _confirmationStatus() {
    if (viewModel.isReserved == "yes") {
      return 'Order Confirmed';
    } else if (viewModel.isReserved == "pending") {
      return 'Pending Confirmation';
    } else {
      return 'Reservation Status Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: Colors.white,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: Colors.white,
        leading: CupertinoNavigationBarBackButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          color: Colors.black,
        ),
        trailing: isLoading
            ? Container()
            : CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {},
                child: Text('Message ${viewModel.firstName}'),
              ),
        border: null,
        middle: Text('Reservation'),
      ),
      child: SafeArea(
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 80),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'You have reserved the ${viewModel.title} from ${viewModel.firstName}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Image.network(
                      viewModel.imageUrl,
                      fit: BoxFit.cover,
                      height: 200,
                      width: double.infinity,
                      errorBuilder: (BuildContext context, Object exception,
                          StackTrace? stackTrace) {
                        return const Icon(Icons.error);
                      },
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Made by ${viewModel.firstName} ${viewModel.lastName}   Posted ${viewModel.timeAgoSinceDate(viewModel.postTimestamp)}   ',
                          style: TextStyle(
                            color: CupertinoColors.label
                                .resolveFrom(context)
                                .withOpacity(0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.48,
                          ),
                        ),
                        Text(""),
                        RatingText(),
                      ],
                    ),
                    SizedBox(height: 50),
                    Text(
                      _confirmationStatus(),
                      style: TextStyle(
                        color: viewModel.isReserved == "yes"
                            ? CupertinoColors.activeGreen
                            : CupertinoColors.systemGrey,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 40),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 36.0,
                        vertical: 16.0,
                      ),
                      child: CupertinoButton.filled(
                        onPressed: _navigateToRatingPage,
                        child: Text('Leave a Review'),
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18.0),
                      ),
                    ),
                    SizedBox(height: 20),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 36.0,
                        vertical: 16.0,
                      ),
                      child: CupertinoButton(
                        onPressed: () {
                          // Action to cancel reservation
                        },
                        color: CupertinoColors.destructiveRed,
                        child: Text('Cancel Reservation'),
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18.0),
                      ),
                    ),
                    SizedBox(height: 50),
                  ],
                ),
              ),
      ),
    );
  }
}
