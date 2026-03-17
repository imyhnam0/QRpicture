import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class UploadResult {
  final String uuid;
  final String downloadUrl;
  final String qrUrl;

  UploadResult({
    required this.uuid,
    required this.downloadUrl,
    required this.qrUrl,
  });
}

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Firebase Hosting에 배포된 웹 플레이어 URL
  static const String _webBaseUrl = 'https://qrpicture-80247.web.app/play';

  /// 음성 파일을 Firebase Storage에 업로드하고
  /// Firestore에 메타데이터를 저장한 뒤 QR URL을 반환합니다.
  Future<UploadResult> uploadAudio(
    String filePath, {
    void Function(double progress)? onProgress,
  }) async {
    final uuid = const Uuid().v4();
    final storageRef = _storage.ref().child('voices/$uuid.m4a');
    final file = File(filePath);

    final uploadTask = storageRef.putFile(
      file,
      SettableMetadata(contentType: 'audio/mp4'),
    );

    // 업로드 진행률 콜백
    if (onProgress != null) {
      uploadTask.snapshotEvents.listen((snapshot) {
        final progress =
            snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress(progress);
      });
    }

    final snapshot = await uploadTask;
    final downloadUrl = await snapshot.ref.getDownloadURL();

    // Firestore에 오디오 문서 저장
    await _firestore.collection('audios').doc(uuid).set({
      'url': downloadUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final qrUrl = '$_webBaseUrl?id=$uuid';
    return UploadResult(
      uuid: uuid,
      downloadUrl: downloadUrl,
      qrUrl: qrUrl,
    );
  }
}
