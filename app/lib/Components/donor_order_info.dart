// donor_order_info.dart
// This file builds the order info section on the donor screen

import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:FoodHood/Components/colors.dart';

class OrderInfoSection extends StatelessWidget {
  final String? reservedByName;
  final String? reservedByLastName;
  final double adjustedOrderInfoFontSize;
  final double rating;
  final String photo;

  const OrderInfoSection({
    Key? key,
    required this.reservedByName,
    required this.reservedByLastName,
    required this.adjustedOrderInfoFontSize,
    required this.rating,
    required this.photo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        // Wrap the Container in an Expanded widget to take up remaining space
        child: Expanded(  
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              photo.isNotEmpty
                  ? CircleAvatar(
                      radius: 10,
                      backgroundImage: CachedNetworkImageProvider(photo),
                      onBackgroundImageError: (_, __) {
                        // Handle image load error
                      },
                      backgroundColor: Colors.transparent,
                    )
                  : CircleAvatar(
                      radius: 10,
                      backgroundImage:
                          AssetImage('assets/images/sampleProfile.png'),
                    ),
              SizedBox(width: 8),
              Text(
                'Reserved by $reservedByName $reservedByLastName',
                style: TextStyle(
                  color: CupertinoColors.label
                      .resolveFrom(context)
                      .withOpacity(0.8),
                  fontSize: adjustedOrderInfoFontSize,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(
                width: 12,
              ),
              Icon(
                Icons.star,
                color: secondaryColor,
                size: 14,
              ),
              const SizedBox(width: 3),
              Text(
                '${rating} Rating',
                style: TextStyle(
                  overflow: TextOverflow.fade,
                  color: CupertinoColors.label
                      .resolveFrom(context)
                      .withOpacity(0.8),
                  fontSize: adjustedOrderInfoFontSize,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.48,
                ),
              ),
            ],
          ),
        ));
  }
}
