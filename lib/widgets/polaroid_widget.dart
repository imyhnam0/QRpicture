import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class PolaroidWidget extends StatelessWidget {
  final Uint8List? photoBytes;
  final String? qrData;
  final String dateText;
  final double width;

  const PolaroidWidget({
    super.key,
    this.photoBytes,
    this.qrData,
    required this.dateText,
    this.width = 280,
  });

  @override
  Widget build(BuildContext context) {
    final borderH = width * 0.055; // 좌우·상단 흰 테두리
    final photoSize = width - borderH * 2;
    final bottomHeight = width * 0.40; // 하단 여백 (QR + 날짜)

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
          // 상단 테두리
          SizedBox(height: borderH),
          // 사진 영역 (정사각형)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: borderH),
            child: SizedBox(
              width: photoSize,
              height: photoSize,
              child: _buildPhoto(),
            ),
          ),
          // 하단 흰 여백 (QR + 날짜)
          SizedBox(
            height: bottomHeight,
            child: _buildBottom(bottomHeight),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoto() {
    if (photoBytes != null) {
      return Image.memory(
        photoBytes!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }
    return Container(
      color: const Color(0xFFEDE8DC),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_outlined,
              size: 40,
              color: Color(0xFFB0A080),
            ),
            SizedBox(height: 8),
            Text(
              '사진을 선택해 주세요',
              style: TextStyle(
                color: Color(0xFFB0A080),
                fontSize: 11,
              ),
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
        if (qrData != null) ...[
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
          ),
        ] else ...[
          Icon(
            Icons.qr_code_outlined,
            size: height * 0.38,
            color: const Color(0xFFD0C8B0),
          ),
        ],
        const SizedBox(height: 4),
        Text(
          dateText,
          style: TextStyle(
            fontSize: height * 0.095,
            color: const Color(0xFF9B8C6C),
            letterSpacing: 0.8,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
