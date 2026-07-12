import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';

/// Wireframe'deki rozet ikonu. Basılınca yalnızca rozet etiketini
/// (örn. "Yeni Üye") gösteren küçük bir baloncuk açılır; baloncuğun
/// dışına tıklandığında otomatik kapanır (showDialog varsayılan olarak
/// barrier'a tıklamayla kapanır, bu yüzden ekstra bir "Tamam" butonuna
/// gerek yoktur).
class RatingBadge extends StatelessWidget {
  final String badgeLabel;

  const RatingBadge({
    super.key,
    required this.badgeLabel,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: () {
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (_) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 18),
              child: Text(
                badgeLabel,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: AppColors.primaryLight,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.military_tech_outlined,
          color: AppColors.primary,
          size: 26,
        ),
      ),
    );
  }
}
