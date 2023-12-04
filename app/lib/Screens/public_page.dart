// public_page.dart
import 'package:flutter/cupertino.dart';
import '../firestore_service.dart'; // Adjust the path based on your project structure

class PublicPage extends StatefulWidget {
  @override
  _PublicPageState createState() => _PublicPageState();
}

class _PublicPageState extends State<PublicPage> {
  late String firstName;
  late String lastName;
  late String city;
  late String province;
  double rating = 5.0;
  int itemsSold = 0;
  List<String> reviews = [];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    Map<String, dynamic>? documentData = await readDocument(
      collectionName: 'user',
      docName: 'afkwlDWxekVhdgV1YPZFK7E34UH3',
    );

    if (documentData != null) {
      setState(() {
        firstName = documentData['firstName'];
        lastName = documentData['lastName'];
        city = documentData['city'];
        province = documentData['province'];
        rating = 5.0;
        reviews = documentData['reviews'] ?? [];
        itemsSold = reviews.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Public Page'),
      ),
      child: CustomScrollView(
        slivers: <Widget>[
          SliverFillRemaining(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                SizedBox(height: 16),
                Text(
                  '$firstName $lastName',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'City: $city',
                  style: TextStyle(
                    fontSize: 18,
                    color: CupertinoColors.systemGreen,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Province: $province',
                  style: TextStyle(
                    fontSize: 18,
                    color: CupertinoColors.systemGreen,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Rating: $rating',
                  style: TextStyle(
                    fontSize: 18,
                    color: CupertinoColors.systemGreen,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Items Sold: $itemsSold',
                  style: TextStyle(
                    fontSize: 18,
                    color: CupertinoColors.systemGreen,
                  ),
                ),
                SizedBox(height: 16),
                CupertinoButton(
                  child: Text('Block'),
                  color: CupertinoColors.systemRed,
                  onPressed: () {
                    // Implement block functionality here
                  },
                ),
                SizedBox(height: 16),
                Text(
                  'Reviews:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                reviews.isEmpty
                    ? Text('No reviews')
                    : Column(
                        children: reviews.reversed
                            .take(3)
                            .map((review) => Text(review))
                            .toList(),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
