import 'dart:ui';
import 'package:flutter/material.dart';

Locale _resolveDeviceLocale() {
  final deviceLocale = PlatformDispatcher.instance.locale;
  return deviceLocale.languageCode.toLowerCase().startsWith('ko')
      ? const Locale('ko')
      : const Locale('en');
}

final ValueNotifier<Locale> appLocale = ValueNotifier(_resolveDeviceLocale());

class S {
  static String get _lang => appLocale.value.languageCode;
  static bool get isKo => _lang == 'ko';

  // ─── Common ───────────────────────────────────────────────────
  static String get appTitle => 'QR Picture';

  // ─── Home ─────────────────────────────────────────────────────
  static String get homeSubtitle => isKo
      ? '사진에 목소리를 담아보세요\nQR 코드로 언제 어디서나 재생'
      : 'Capture your voice in photos\nPlay anytime, anywhere with QR codes';
  static String get homeHeadline => isKo
      ? '흑백의 여백 위에\n사진과 목소리를 남기세요'
      : 'Leave your photo and voice\non a black-and-white canvas';
  static String get homeDescription => isKo
      ? '사진, 음성, QR을 한 장의 장면으로 묶어\n누구나 바로 열어 들을 수 있게 만듭니다.'
      : 'Bind photos, voice, and QR into a single frame\nthat anyone can open and hear instantly.';
  static String get createNew => isKo ? '새로 만들기' : 'Create New';
  static String get scanQr => isKo ? 'QR 스캔하기' : 'Scan QR';
  static String get contactUs => isKo ? '문의하기' : 'Contact Us';
  static String get featureVoice => isKo ? '음성 메시지' : 'Voice Message';
  static String get featureQr => isKo ? 'QR 연결' : 'QR Connected';
  static String get featureBw => isKo ? '블랙 앤 화이트' : 'Black & White';
  static String get heroCardTitle =>
      isKo ? 'Print the moment' : 'Print the moment';
  static String get heroCardBody => isKo
      ? '사진 한 장이 끝이 아니라,\n그 순간의 목소리까지 함께 남깁니다.'
      : 'A photo is no longer the end of the moment.\nKeep the voice with it.';

  // ─── Layout Selector ──────────────────────────────────────────
  static String get selectLayout => isKo ? '레이아웃 선택' : 'Select Layout';
  static String get selectLayoutDesc =>
      isKo ? '원하는 사진 레이아웃을 선택해 주세요' : 'Choose your preferred photo layout';

  static String layoutName(String key) => switch (key) {
    'single' => isKo ? '1장' : '1 Photo',
    'strip4' => isKo ? '1x4 그리드' : '1×4 Grid',
    'grid2x2' => isKo ? '2×2 그리드' : '2×2 Grid',
    _ => key,
  };

  static String layoutDesc(String key) => switch (key) {
    'single' => isKo ? '사진 1장 폴라로이드 스타일' : 'Single photo polaroid style',
    'strip4' => isKo ? '1열 4행 세로 스트립' : '1 column, 4 rows vertical strip',
    'grid2x2' => isKo ? '2열 2행 정사각형 그리드' : '2×2 square grid',
    _ => key,
  };

  // ─── Create Screen ────────────────────────────────────────────
  static String createTitle(String layout) =>
      isKo ? '새로 만들기 · $layout' : 'Create · $layout';
  static String get selectPhoto => isKo ? '사진을 선택해 주세요' : 'Select a photo';
  static String selectPhotos(int n) =>
      isKo ? '사진 $n장을 선택해 주세요' : 'Select $n photos';
  static String photoProgress(int filled, int total) => isKo
      ? '$filled/$total장 선택됨  ·  각 사진을 탭해서 변경할 수 있어요'
      : '$filled/$total selected · Tap each photo to change';
  static String get selectFromGallery =>
      isKo ? '갤러리에서 선택' : 'Select from Gallery';
  static String get nextRecord => isKo ? '다음: 음성 녹음' : 'Next: Record Voice';
  static String get recordYourVoice =>
      isKo ? '목소리를 녹음해 주세요' : 'Record your voice';
  static String get recording => isKo ? '녹음 중...' : 'Recording...';
  static String recordingDone(String time) =>
      isKo ? '녹음 완료  $time' : 'Recording done  $time';
  static String get pressToRecord =>
      isKo ? '버튼을 눌러 녹음을 시작하세요' : 'Press the button to start recording';
  static String get createQrPhoto => isKo ? 'QR 사진 만들기' : 'Create QR Photo';
  static String get uploading => isKo
      ? '음성을 업로드하고\nQR 코드를 생성하는 중입니다...'
      : 'Uploading voice and\ngenerating QR code...';
  static String get stepPhoto => isKo ? '사진' : 'Photo';
  static String get stepRecord => isKo ? '녹음' : 'Record';
  static String get stepDone => isKo ? '완성' : 'Done';
  static String get pause => isKo ? '일시정지' : 'Pause';
  static String get preview => isKo ? '미리 듣기' : 'Preview';
  static String get reRecord => isKo ? '다시 녹음' : 'Re-record';
  static String get cropPhoto => isKo ? '사진 자르기' : 'Crop Photo';
  static String photoSlot(int n) => isKo ? '사진 $n' : 'Photo $n';

  // Create Screen Errors
  static String get errLoadPhoto =>
      isKo ? '사진을 불러오는 중 오류가 발생했습니다.' : 'Failed to load the photo.';
  static String get errMicPermission => isKo
      ? '마이크 접근 권한이 필요합니다. 설정에서 허용해 주세요.'
      : 'Microphone permission is required. Please allow it in settings.';
  static String get errStartRecording =>
      isKo ? '녹음을 시작할 수 없습니다.' : 'Unable to start recording.';
  static String get errSaveRecording =>
      isKo ? '녹음 저장 중 오류가 발생했습니다.' : 'Error saving the recording.';
  static String get errPlayback =>
      isKo ? '재생 중 오류가 발생했습니다.' : 'Playback error occurred.';
  static String get errUpload => isKo
      ? '업로드에 실패했습니다. 네트워크를 확인하고 다시 시도해 주세요.'
      : 'Upload failed. Please check your network and try again.';

  // ─── Scan Screen ──────────────────────────────────────────────
  static String get scanTitle => isKo ? 'QR 스캔' : 'QR Scan';
  static String get scanNotQrPicture => isKo
      ? '이 QR 코드는 QR Picture 앱에서 만들어진 것이 아닙니다.'
      : 'This QR code was not created by QR Picture.';
  static String get scanNoQr => isKo
      ? 'QR 코드를 찾을 수 없습니다. 다른 사진을 선택해 보세요.'
      : 'No QR code found. Try selecting another photo.';
  static String get scanCannotRead =>
      isKo ? 'QR 코드 값을 읽을 수 없습니다.' : 'Unable to read the QR code value.';
  static String scanAnalyzeError(String e) =>
      isKo ? '이미지 분석 중 오류가 발생했습니다.\n($e)' : 'Error analyzing the image.\n($e)';
  static String get scanHint =>
      isKo ? 'QR 코드를 프레임 안에 위치시켜 주세요' : 'Place the QR code inside the frame';
  static String get analyzing => isKo ? '분석 중...' : 'Analyzing...';
  static String get selectQrFromGallery =>
      isKo ? '갤러리에서 QR 사진 선택' : 'Select QR photo from gallery';

  // ─── Preview Screen ───────────────────────────────────────────
  static String get complete => isKo ? '완성!' : 'Complete!';
  static String get goHome => isKo ? '홈으로' : 'Home';
  static String get qrPhotoReady =>
      isKo ? 'QR 사진이 완성되었습니다!' : 'Your QR photo is ready!';
  static String get scanToListen =>
      isKo ? 'QR 코드를 스캔하면 목소리를 들을 수 있어요' : 'Scan the QR code to hear the voice';
  static String get savedToGallery =>
      isKo ? '갤러리에 저장되었습니다!' : 'Saved to gallery!';
  static String saveFailed(String e) => isKo ? '저장 실패: $e' : 'Save failed: $e';
  static String get saved => isKo ? '저장 완료!' : 'Saved!';
  static String get saveToGallery => isKo ? '갤러리에 저장' : 'Save to Gallery';
  static String get scanQrInfo => isKo
      ? 'QR 코드를 스캔하면 웹 브라우저에서\n녹음한 음성이 바로 재생됩니다.'
      : 'Scan the QR code and the recorded\nvoice will play in your web browser.';
  static String get errCapture =>
      isKo ? '이미지 캡처에 실패했습니다.' : 'Failed to capture the image.';

  // ─── Player Screen ────────────────────────────────────────────
  static String get voiceMessage => isKo ? '목소리 메시지' : 'Voice Message';
  static String get photoPreview => isKo ? '사진 미리보기' : 'Photo Preview';
  static String get audioNotFound => isKo
      ? '음성 데이터를 찾을 수 없습니다.\nQR 코드가 올바른지 확인해 주세요.'
      : 'Audio data not found.\nPlease check if the QR code is correct.';
  static String get loadingAudio => isKo ? '음성을 불러오는 중...' : 'Loading audio...';
  static String get errLoadAudio => isKo
      ? '음성을 불러오지 못했습니다.\n네트워크 연결을 확인해 주세요.'
      : 'Failed to load audio.\nPlease check your network connection.';
  static String get goBack => isKo ? '돌아가기' : 'Go Back';
  static String dateFormat(DateTime dt) => isKo
      ? '${dt.year}년 ${dt.month}월 ${dt.day}일'
      : '${_monthName(dt.month)} ${dt.day}, ${dt.year}';

  static String _monthName(int m) => const [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][m];

  // ─── Inquiry Screen ───────────────────────────────────────────
  static String get inquiryTitle => isKo ? '문의하기' : 'Contact Us';
  static String get inquirySubmitted =>
      isKo ? '문의가 접수되었습니다!' : 'Inquiry submitted!';
  static String get inquiryThanks => isKo
      ? '소중한 의견 감사합니다.\n개발자가 7일 안에 확인하고 반영하겠습니다.'
      : 'Thank you for your feedback.\nWe\'ll review and respond within 7 days.';
  static String get returnHome => isKo ? '홈으로 돌아가기' : 'Return to Home';
  static String get inquiryBanner => isKo
      ? '추가됐으면 하는 기능이나 불편한 점을 알려주시면 개발자가 7일 안에 확인하고 수정해드리겠습니다.'
      : 'Let us know about features you\'d like or issues you\'ve found. We\'ll review and address them within 7 days.';
  static String get inquiryContent => isKo ? '문의 내용' : 'Inquiry Content';
  static String get inquiryHint => isKo
      ? '불편한 점, 개선 사항, 추가됐으면 하는 기능 등을\n자유롭게 작성해 주세요.'
      : 'Feel free to describe any issues, improvements,\nor features you\'d like to see.';
  static String get inquiryRequired =>
      isKo ? '문의 내용을 입력해 주세요.' : 'Please enter your inquiry.';
  static String get inquiryMinLength =>
      isKo ? '5자 이상 입력해 주세요.' : 'Please enter at least 5 characters.';
  static String get emailOptional => isKo ? '이메일 (선택)' : 'Email (optional)';
  static String get emailHint => isKo
      ? '답변을 받고 싶으시면 이메일을 입력해 주세요.'
      : 'Enter your email if you\'d like a reply.';
  static String get emailInvalid =>
      isKo ? '올바른 이메일 형식이 아닙니다.' : 'Invalid email format.';
  static String get sendInquiry => isKo ? '문의 보내기' : 'Send Inquiry';
  static String get errSendInquiry => isKo
      ? '전송에 실패했습니다. 네트워크를 확인하고 다시 시도해 주세요.'
      : 'Failed to send. Please check your network and try again.';
}
