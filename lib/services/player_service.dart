import 'package:cloud_firestore/cloud_firestore.dart';

class AudioInfo {
  final String url;
  final DateTime? createdAt;
  final String? previewImageUrl;

  AudioInfo({required this.url, this.createdAt, this.previewImageUrl});
}

class PlayerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _expectedHost = 'qrpicture-80247.web.app';

  /// QR 값에서 UUID 추출.
  /// 유효한 QR Picture URL이 아니면 null 반환.
  String? extractUuid(String qrValue) {
    try {
      final uri = Uri.parse(qrValue);
      if (uri.host != _expectedHost) return null;
      return uri.queryParameters['id'];
    } catch (_) {
      return null;
    }
  }

  /// Firestore에서 오디오 정보 조회
  Future<AudioInfo?> fetchAudioInfo(String uuid) async {
    final doc = await _firestore.collection('audios').doc(uuid).get();
    if (!doc.exists) return null;

    final data = doc.data()!;
    final url = data['url'] as String?;
    if (url == null) return null;

    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final previewImageUrl = data['previewImageUrl'] as String?;
    return AudioInfo(
      url: url,
      createdAt: createdAt,
      previewImageUrl: previewImageUrl,
    );
  }
}
