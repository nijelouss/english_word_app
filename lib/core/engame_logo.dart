import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Kullanım örnekleri:
//   EngameLogo(size: 120)                        // Login ekranı — sadece ikon
//   EngameLogo(size: 80, showText: true)         // Splash / hero alanlar
//   EngameLogo(size: 32)                         // AppBar mini versiyon

class EngameLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const EngameLogo({
    super.key,
    this.size = 100,
    this.showText = false,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    if (showText) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIcon(context),
          SizedBox(width: size * 0.15),
          Text(
            'engame',
            style: GoogleFonts.poppins(
              fontSize: size * 0.5,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
              letterSpacing: -1.5,
            ),
          ),
        ],
      );
    }
    return _buildIcon(context);
  }

  Widget _buildIcon(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = backgroundColor;
    final fg = foregroundColor ?? cs.onPrimary;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size * 0.25),
              gradient: bg != null
                  ? null
                  : LinearGradient(
                      colors: [cs.primary, cs.tertiary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              color: bg,
            ),
            alignment: Alignment.center,
            child: Text(
              'E',
              style: GoogleFonts.poppins(
                fontSize: size * 0.6,
                fontWeight: FontWeight.w800,
                color: fg,
                letterSpacing: -1,
              ),
            ),
          ),
          Positioned(
            right: size * 0.08,
            bottom: size * 0.08,
            child: Container(
              width: size * 0.3,
              height: size * 0.3,
              decoration: const BoxDecoration(
                color: Color(0xFFFFB300),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Icon(
                Icons.bolt,
                color: Colors.white,
                size: size * 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
