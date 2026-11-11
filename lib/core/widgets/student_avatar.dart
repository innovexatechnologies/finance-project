import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/core/services/supabase_helper.dart';

class StudentAvatar extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final String? avatarBase64;
  final double size;
  final double borderWidth;
  final List<BoxShadow>? shadows;

  const StudentAvatar({
    super.key,
    required this.name,
    this.avatarUrl,
    this.avatarBase64,
    this.size = 48,
    this.borderWidth = 0,
    this.shadows,
  });

  Widget _buildInitials() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
      ),
      child: Center(
        child: Text(
          SupabaseHelper.initialsFor(name, fallback: 'ST'),
          style: GoogleFonts.poppins(
            fontSize: size * 0.32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final b64 = avatarBase64?.trim() ?? '';
    if (b64.isNotEmpty) {
      try {
        final Uint8List bytes = base64Decode(b64);
        if (bytes.isNotEmpty) {
          return Image.memory(
            bytes,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => _buildInitials(),
          );
        }
      } catch (_) {}
    }

    final url = avatarUrl?.trim() ?? '';
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildInitials(),
      );
    }

    return _buildInitials();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: borderWidth > 0
            ? Border.all(color: Colors.white, width: borderWidth)
            : null,
        boxShadow: shadows,
      ),
      child: ClipOval(child: _buildContent()),
    );
  }
}
