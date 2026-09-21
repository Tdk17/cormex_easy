import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.compact = false,
    this.onDark = false,
  });

  final bool compact;
  final bool onDark;

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
              color: onDark ? Colors.white : AppColors.wine,
              borderRadius: BorderRadius.circular(12),
              boxShadow: onDark
                  ? const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 14,
                        offset: Offset(0, 5),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              'Cx',
              style: TextStyle(
                color: onDark ? AppColors.wineDark : Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ),
          if (!compact) ...[
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'CormeX',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 19,
                    height: 1,
                    color: onDark ? Colors.white : AppColors.ink,
                  ),
                ),
                Text(
                  'EASY',
                  style: TextStyle(
                    letterSpacing: 2.2,
                    fontWeight: FontWeight.w700,
                    fontSize: 9,
                    color: onDark ? AppColors.wineSoft : AppColors.wine,
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
