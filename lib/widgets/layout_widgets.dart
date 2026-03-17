import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../l10n/app_strings.dart';

/// 인생네컷 스타일 (1열 4행)
class Strip4Widget extends StatelessWidget {
  final List<Uint8List?> photos; // length == 4
  final String? qrData;
  final String dateText;
  final double width;
  final void Function(int index)? onTapPhoto;

  const Strip4Widget({
    super.key,
    required this.photos,
    this.qrData,
    required this.dateText,
    this.width = 200,
    this.onTapPhoto,
  });

  @override
  Widget build(BuildContext context) {
    final pad = width * 0.055;
    final photoW = width - pad * 2;
    final photoH = photoW * 0.60;
    final gap = width * 0.025;
    final bottomH = width * 0.40;

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: pad),
          for (int i = 0; i < 4; i++) ...[
            if (i > 0) SizedBox(height: gap),
            GestureDetector(
              onTap: onTapPhoto != null ? () => onTapPhoto!(i) : null,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: pad),
                child: SizedBox(
                  width: photoW,
                  height: photoH,
                  child: _buildPhotoSlot(photos[i], i),
                ),
              ),
            ),
          ],
          SizedBox(
            height: bottomH,
            child: _buildBottom(bottomH),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSlot(Uint8List? bytes, int index) {
    if (bytes != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(bytes, fit: BoxFit.cover),
          if (onTapPhoto != null)
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit, color: Colors.white, size: 12),
              ),
            ),
        ],
      );
    }
    return Container(
      color: const Color(0xFFEEEEEE),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_photo_alternate_outlined,
              size: 24,
              color: Color(0xFFBDBDBD),
            ),
            const SizedBox(height: 4),
            Text(
              S.photoSlot(index + 1),
              style: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottom(double height) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (qrData != null)
          QrImageView(
            data: qrData!,
            size: height * 0.58,
            backgroundColor: Colors.white,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: Colors.black,
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: Colors.black,
            ),
          )
        else
          Icon(
            Icons.qr_code_outlined,
            size: height * 0.38,
            color: const Color(0xFFBDBDBD),
          ),
        const SizedBox(height: 4),
        Text(
          dateText,
          style: TextStyle(
            fontSize: height * 0.095,
            color: const Color(0xFFAAAAAA),
            letterSpacing: 0.8,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

/// 2×2 그리드
class Grid2x2Widget extends StatelessWidget {
  final List<Uint8List?> photos; // length == 4
  final String? qrData;
  final String dateText;
  final double width;
  final void Function(int index)? onTapPhoto;

  const Grid2x2Widget({
    super.key,
    required this.photos,
    this.qrData,
    required this.dateText,
    this.width = 280,
    this.onTapPhoto,
  });

  @override
  Widget build(BuildContext context) {
    final pad = width * 0.05;
    final gap = width * 0.025;
    final photoSize = (width - pad * 2 - gap) / 2;
    final bottomH = width * 0.32;

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: pad),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: pad),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildRow(0, 1, photoSize, gap),
                SizedBox(height: gap),
                _buildRow(2, 3, photoSize, gap),
              ],
            ),
          ),
          SizedBox(height: bottomH, child: _buildBottom(bottomH)),
        ],
      ),
    );
  }

  Widget _buildRow(int idx1, int idx2, double size, double gap) {
    return Row(
      children: [
        GestureDetector(
          onTap: onTapPhoto != null ? () => onTapPhoto!(idx1) : null,
          child: SizedBox(
            width: size,
            height: size,
            child: _buildPhotoSlot(photos[idx1], idx1),
          ),
        ),
        SizedBox(width: gap),
        GestureDetector(
          onTap: onTapPhoto != null ? () => onTapPhoto!(idx2) : null,
          child: SizedBox(
            width: size,
            height: size,
            child: _buildPhotoSlot(photos[idx2], idx2),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoSlot(Uint8List? bytes, int index) {
    if (bytes != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(bytes, fit: BoxFit.cover),
          if (onTapPhoto != null)
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit, color: Colors.white, size: 12),
              ),
            ),
        ],
      );
    }
    return Container(
      color: const Color(0xFFEEEEEE),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_photo_alternate_outlined,
              size: 24,
              color: Color(0xFFBDBDBD),
            ),
            const SizedBox(height: 4),
            Text(
              S.photoSlot(index + 1),
              style: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottom(double height) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (qrData != null)
          QrImageView(
            data: qrData!,
            size: height * 0.58,
            backgroundColor: Colors.white,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: Colors.black,
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: Colors.black,
            ),
          )
        else
          Icon(
            Icons.qr_code_outlined,
            size: height * 0.38,
            color: const Color(0xFFBDBDBD),
          ),
        const SizedBox(height: 4),
        Text(
          dateText,
          style: TextStyle(
            fontSize: height * 0.095,
            color: const Color(0xFFAAAAAA),
            letterSpacing: 0.8,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
