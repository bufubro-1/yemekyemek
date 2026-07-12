import 'package:flutter/material.dart';

/// "Google ile bağlan" gibi ekranda görsel olarak beklenen ama şu an
/// gerçekten işlev göstermeyen butonlar için kullanılır. `onPressed: null`
/// bırakıldığı için tıklanamaz; sağ üstte küçük bir "Yakında" etiketi ile
/// bunun bilinçli bir tasarım kararı olduğu belirtilir.
class DisabledSocialButton extends StatelessWidget {
  final String label;
  final IconData icon;

  const DisabledSocialButton({
    super.key,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        SizedBox(
          height: 50,
          width: double.infinity,
          child: OutlinedButton.icon(
            // Bilinçli olarak null: buton tıklanamaz durumda.
            onPressed: null,
            icon: Icon(icon, size: 20),
            label: Text(label),
            style: OutlinedButton.styleFrom(
              disabledForegroundColor: Colors.black87,
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        Positioned(
          top: -8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.shade700,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Yakında',
              style: TextStyle(color: Colors.white, fontSize: 10),
            ),
          ),
        ),
      ],
    );
  }
}
