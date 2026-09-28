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
          CormexMark(onDark: onDark),
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
                    color: onDark ? AppColors.gold : AppColors.wine,
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

class CormexMark extends StatelessWidget {
  const CormexMark({super.key, this.size = 40, this.onDark = false});

  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.wineSoft, AppColors.wine, AppColors.wineDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(size * .28),
          border: Border.all(
            color: onDark
                ? AppColors.gold.withValues(alpha: .78)
                : AppColors.wineDark.withValues(alpha: .12),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.wine.withValues(alpha: onDark ? .48 : .24),
              blurRadius: size * .34,
              offset: Offset(0, size * .12),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.location_on_rounded,
              color: Colors.white,
              size: size * .72,
            ),
            Positioned(
              top: size * .22,
              child: Container(
                width: size * .29,
                height: size * .29,
                decoration: BoxDecoration(
                  color: AppColors.wineDark,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.gold,
                    width: size * .025,
                  ),
                ),
                child: Icon(
                  Icons.home_repair_service_rounded,
                  color: AppColors.gold,
                  size: size * .17,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
