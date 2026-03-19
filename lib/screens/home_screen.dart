import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../models/layout_type.dart';
import 'create_screen.dart';
import 'inquiry_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showLanguageSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDDDDDD),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            _buildLangOption(sheetContext, '한국어', '한국어', const Locale('ko')),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            _buildLangOption(
              sheetContext,
              'English',
              'English',
              const Locale('en'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLangOption(
    BuildContext context,
    String label,
    String sublabel,
    Locale locale,
  ) {
    final isSelected = appLocale.value.languageCode == locale.languageCode;
    return InkWell(
      onTap: () {
        appLocale.value = locale;
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  color: Colors.black,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check, size: 20, color: Colors.black),
          ],
        ),
      ),
    );
  }

  void _showLayoutSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          20,
          24,
          MediaQuery.of(sheetContext).viewInsets.bottom + 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDDDDD),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              S.selectLayout,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              S.selectLayoutDesc,
              style: const TextStyle(fontSize: 13, color: Color(0xFF888888)),
            ),
            const SizedBox(height: 16),
            for (final layout in LayoutType.values) ...[
              _buildLayoutOption(context, sheetContext, layout),
              if (layout != LayoutType.values.last)
                const Divider(height: 1, color: Color(0xFFEEEEEE)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLayoutOption(
    BuildContext context,
    BuildContext sheetContext,
    LayoutType layout,
  ) {
    return InkWell(
      onTap: () {
        Navigator.pop(sheetContext);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CreateScreen(layoutType: layout)),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        child: Row(
          children: [
            _buildLayoutPreviewIcon(layout),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    layout.displayName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    layout.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF888888),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFAAAAAA), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLayoutPreviewIcon(LayoutType layout) {
    const color = Colors.black;
    switch (layout) {
      case LayoutType.single:
        return Container(
          width: 48,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.05),
            border: Border.all(color: color, width: 1.5),
            borderRadius: BorderRadius.circular(3),
          ),
          child: const Icon(Icons.photo_outlined, size: 22, color: color),
        );
      case LayoutType.strip4:
        return SizedBox(
          width: 36,
          height: 60,
          child: Column(
            children: List.generate(
              4,
              (i) => Expanded(
                child: Container(
                  margin: EdgeInsets.only(top: i == 0 ? 0 : 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.05),
                    border: Border.all(color: color, width: 1.2),
                  ),
                ),
              ),
            ),
          ),
        );
      case LayoutType.grid2x2:
        return SizedBox(
          width: 52,
          height: 52,
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(right: 1.5, bottom: 1.5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.05),
                          border: Border.all(color: color, width: 1.2),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(left: 1.5, bottom: 1.5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.05),
                          border: Border.all(color: color, width: 1.2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(right: 1.5, top: 1.5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.05),
                          border: Border.all(color: color, width: 1.2),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(left: 1.5, top: 1.5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.05),
                          border: Border.all(color: color, width: 1.2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: appLocale,
      builder: (context, _, __) => Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: () => _showLanguageSelector(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.language,
                              size: 16,
                              color: Colors.black,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              S.isKo ? '한국어' : 'English',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/mainicon.png',
                      width: 110,
                      height: 110,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'QR Picture',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    S.homeSubtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF888888),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 52),
                  ElevatedButton.icon(
                    onPressed: () => _showLayoutSelector(context),
                    icon: const Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 22,
                    ),
                    label: Text(
                      S.createNew,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const InquiryScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: Text(
                      S.contactUs,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF888888),
                      minimumSize: const Size.fromHeight(44),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
