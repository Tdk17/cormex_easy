import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'CormeX Easy',
      header: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.wine,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Cx',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ),
          if (!compact) ...[
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'CormeX',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 19,
                    height: 1,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  'EASY',
                  style: TextStyle(
                    letterSpacing: 2.2,
                    fontWeight: FontWeight.w700,
                    fontSize: 9,
                    color: AppColors.wine,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

