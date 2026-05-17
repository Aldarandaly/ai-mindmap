import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:io';
import '../data/diagram_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

class DiagramViewerScreen extends StatefulWidget {
  final Diagram diagram;
  const DiagramViewerScreen({super.key, required this.diagram});

  @override
  State<DiagramViewerScreen> createState() =>
      _DiagramViewerScreenState();
}

class _DiagramViewerScreenState extends State<DiagramViewerScreen>
    with TickerProviderStateMixin {
  bool _showCode = false;
  bool _showBanner = true;
  bool _isExporting = false;
  bool _webViewLoading = true;
  bool _copied = false;

  WebViewController? _webController;
  final _screenshotController = ScreenshotController();
  Uint8List? _capturedImage;

  // ── Animations ──────────────────────────────────────────────────────────────
  late final AnimationController _bannerCtrl;
  late final Animation<Offset> _bannerSlide;

  late final AnimationController _viewCtrl;
  late final Animation<double> _viewFade;

  late final AnimationController _copyCtrl;
  late final Animation<double> _copyScale;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initWebView();

    // Auto-dismiss banner
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _dismissBanner();
    });
  }

  void _setupAnimations() {
    // Banner slide in
    _bannerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _bannerSlide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _bannerCtrl, curve: Curves.easeOutCubic));

    // View fade
    _viewCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..forward();
    _viewFade =
        CurvedAnimation(parent: _viewCtrl, curve: Curves.easeOut);

    // Copy bounce
    _copyCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _copyScale = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _copyCtrl, curve: Curves.easeInOut),
    );
  }

  void _initWebView() {
    try {
      _webController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(AppColors.background)
        ..setNavigationDelegate(NavigationDelegate(
          onPageFinished: (_) async {
            setState(() => _webViewLoading = false);
            await Future.delayed(const Duration(seconds: 2));
            await _captureWebView();
          },
        ))
        ..loadHtmlString(
            _buildHtml(widget.diagram.diagramCode ?? ''));
    } catch (_) {
      _webController = null;
    }
  }

  Future<void> _captureWebView() async {
    try {
      final img =
          await _screenshotController.capture(pixelRatio: 2.0);
      if (mounted) setState(() => _capturedImage = img);
    } catch (_) {}
  }

  void _dismissBanner() async {
    await _bannerCtrl.reverse();
    if (mounted) setState(() => _showBanner = false);
  }

  void _switchView(bool showCode) {
    if (_showCode == showCode) return;
    _viewCtrl.reset();
    setState(() => _showCode = showCode);
    _viewCtrl.forward();
  }

  Future<void> _copyCode() async {
    final code = widget.diagram.diagramCode ?? '';
    await Clipboard.setData(ClipboardData(text: code));
    HapticFeedback.lightImpact();
    _copyCtrl.forward().then((_) => _copyCtrl.reverse());
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  void dispose() {
    _bannerCtrl.dispose();
    _viewCtrl.dispose();
    _copyCtrl.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.background, Color(0xFF1A0535)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Banner ────────────────────────────────────────────────
              if (_showBanner) _buildBanner(),
              // ── AppBar ────────────────────────────────────────────────
              _buildAppBar(),
              // ── Toggle ────────────────────────────────────────────────
              _buildToggle(),
              // ── Content ───────────────────────────────────────────────
              Expanded(
                child: FadeTransition(
                  opacity: _viewFade,
                  child: widget.diagram.diagramCode == null ||
                          widget.diagram.diagramCode!.isEmpty
                      ? _buildNoCode()
                      : _showCode
                          ? _buildCodeView()
                          : _buildPreview(),
                ),
              ),
              // ── Bottom Bar ────────────────────────────────────────────
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Status Banner ──────────────────────────────────────────────────────────
  Widget _buildBanner() {
    final isDone = widget.diagram.isDone;
    final color = isDone ? AppColors.success : AppColors.warning;

    return SlideTransition(
      position: _bannerSlide,
      child: GestureDetector(
        onTap: _dismissBanner,
        child: Container(
          margin: const EdgeInsets.fromLTRB(
              AppSizes.md, AppSizes.sm, AppSizes.md, 0),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md, vertical: 11),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius:
                BorderRadius.circular(AppSizes.radiusMd),
            border: Border.all(
                color: color.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius:
                      BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: Icon(
                  isDone
                      ? Icons.check_rounded
                      : Icons.hourglass_top_rounded,
                  size: 15,
                  color: color,
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Text(
                  isDone
                      ? 'Diagram generated successfully! ✦'
                      : 'Status: ${widget.diagram.status}',
                  style: TextStyle(
                    color: color,
                    fontSize: AppSizes.fontSm,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(Icons.close_rounded,
                  size: 15, color: color.withValues(alpha: 0.7)),
            ],
          ),
        ),
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSizes.md, AppSizes.sm, AppSizes.md, 0),
      child: Row(
        children: [
          // ← glass back button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                borderRadius:
                    BorderRadius.circular(AppSizes.radiusMd),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10)),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: AppSizes.iconSm,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.diagram.name.isNotEmpty
                      ? widget.diagram.name
                      : 'Untitled',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: AppSizes.fontLg,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.diagram.type.isNotEmpty)
                  Text(
                    widget.diagram.type.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: AppSizes.fontXs,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
              ],
            ),
          ),
          // Export action
          GestureDetector(
            onTap: _showExportSheet,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                borderRadius:
                    BorderRadius.circular(AppSizes.radiusMd),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10)),
              ),
              child: const Icon(
                Icons.more_horiz_rounded,
                size: AppSizes.iconMd,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Segmented Toggle ───────────────────────────────────────────────────────
  Widget _buildToggle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSizes.md, AppSizes.md, AppSizes.md, 0),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius:
              BorderRadius.circular(AppSizes.radiusRound),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Expanded(
              child: _ToggleChip(
                label: 'Preview',
                icon: Icons.visibility_rounded,
                isSelected: !_showCode,
                onTap: () => _switchView(false),
              ),
            ),
            Expanded(
              child: _ToggleChip(
                label: 'Mermaid Code',
                icon: Icons.code_rounded,
                isSelected: _showCode,
                onTap: () => _switchView(true),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── WebView Preview ────────────────────────────────────────────────────────
  Widget _buildPreview() {
    if (_webController == null) return _buildFallback();

    return Container(
      margin: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.08)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Screenshot(
        controller: _screenshotController,
        child: Stack(
          children: [
            WebViewWidget(controller: _webController!),
            if (_webViewLoading)
              Container(
                color: AppColors.background,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 36,
                        height: 36,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(
                                  AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: AppSizes.md),
                      const Text(
                        'Rendering diagram...',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: AppSizes.fontSm,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallback() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                borderRadius:
                    BorderRadius.circular(AppSizes.radiusXl),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: AppSizes.lg),
            const Text(
              'Diagram Ready',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: AppSizes.fontXl,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            const Text(
              'Tap "Mermaid Code" to view the source',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: AppSizes.fontSm,
              ),
            ),
            const SizedBox(height: AppSizes.xl),
            GestureDetector(
              onTap: () => _switchView(true),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 13),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                  ),
                  borderRadius: BorderRadius.circular(
                      AppSizes.radiusRound),
                  boxShadow: [
                    BoxShadow(
                      color:
                          AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.code_rounded,
                        size: 16, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'View Code',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Code View ──────────────────────────────────────────────────────────────
  Widget _buildCodeView() {
    return Container(
      margin: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSizes.md, AppSizes.sm, AppSizes.sm, AppSizes.sm),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        AppColors.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(
                        AppSizes.radiusRound),
                  ),
                  child: const Text(
                    'Mermaid',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: AppSizes.fontXs,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                // ← animated copy button
                ScaleTransition(
                  scale: _copyScale,
                  child: GestureDetector(
                    onTap: _copyCode,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: _copied
                            ? AppColors.success
                                .withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(
                            AppSizes.radiusRound),
                        border: Border.all(
                          color: _copied
                              ? AppColors.success
                                  .withValues(alpha: 0.4)
                              : Colors.white
                                  .withValues(alpha: 0.12),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _copied
                                ? Icons.check_rounded
                                : Icons.copy_rounded,
                            size: 13,
                            color: _copied
                                ? AppColors.success
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _copied ? 'Copied!' : 'Copy',
                            style: TextStyle(
                              color: _copied
                                  ? AppColors.success
                                  : AppColors.textSecondary,
                              fontSize: AppSizes.fontXs + 1,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
              height: 1,
              color: Colors.white.withValues(alpha: 0.07)),
          // Code content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.md),
              child: SelectableText(
                widget.diagram.diagramCode ?? '',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontFamily: 'monospace',
                  fontSize: 13,
                  height: 1.65,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── No Code ────────────────────────────────────────────────────────────────
  Widget _buildNoCode() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius:
                  BorderRadius.circular(AppSizes.radiusXl),
            ),
            child: const Icon(Icons.hourglass_empty_rounded,
                size: 34, color: AppColors.textTertiary),
          ),
          const SizedBox(height: AppSizes.lg),
          const Text(
            'No diagram yet',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: AppSizes.fontXl,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSizes.xs),
          const Text(
            'The diagram is still being generated.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: AppSizes.fontMd,
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Bar ─────────────────────────────────────────────────────────────
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSizes.md, AppSizes.sm, AppSizes.md, AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.9),
        border: Border(
          top: BorderSide(
              color: Colors.white.withValues(alpha: 0.07)),
        ),
      ),
      child: Row(
        children: [
          // ← gradient Export button
          Expanded(
            child: GestureDetector(
              onTap: _isExporting ? null : _showExportSheet,
              child: Container(
                height: AppSizes.buttonHeight,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isExporting
                        ? [
                            AppColors.primary
                                .withValues(alpha: 0.5),
                            AppColors.accent.withValues(alpha: 0.5),
                          ]
                        : [AppColors.primary, AppColors.accent],
                  ),
                  borderRadius: BorderRadius.circular(
                      AppSizes.radiusRound),
                  boxShadow: _isExporting
                      ? []
                      : [
                          BoxShadow(
                            color: AppColors.primary
                                .withValues(alpha: 0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 5),
                          ),
                        ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _isExporting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.download_rounded,
                            size: 18, color: Colors.white),
                    const SizedBox(width: AppSizes.sm),
                    Text(
                      _isExporting ? 'Exporting...' : 'Export',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: AppSizes.fontMd,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          // ← glass toggle button
          GestureDetector(
            onTap: () => _switchView(!_showCode),
            child: Container(
              width: AppSizes.buttonHeight,
              height: AppSizes.buttonHeight,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(
                    AppSizes.radiusRound),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10)),
              ),
              child: Icon(
                _showCode
                    ? Icons.visibility_rounded
                    : Icons.code_rounded,
                size: AppSizes.iconMd,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Export Sheet ───────────────────────────────────────────────────────────
  void _showExportSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        margin: const EdgeInsets.all(AppSizes.md),
        padding: const EdgeInsets.all(AppSizes.lg),
        decoration: BoxDecoration(
          color: const Color(0xFF131B2E),
          borderRadius:
              BorderRadius.circular(AppSizes.radiusXl + 4),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            const Text(
              'Export Diagram',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: AppSizes.fontLg,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Choose export format',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: AppSizes.fontSm,
              ),
            ),
            const SizedBox(height: AppSizes.lg),

            _ExportOption(
              icon: Icons.image_rounded,
              label: 'PNG Image',
              subtitle: 'High quality raster image',
              color1: AppColors.primary,
              color2: AppColors.accent,
              onTap: () {
                Navigator.pop(context);
                _exportPNG();
              },
            ),
            const SizedBox(height: AppSizes.sm),
            _ExportOption(
              icon: Icons.picture_as_pdf_rounded,
              label: 'PDF Document',
              subtitle: 'Vector quality for print',
              color1: const Color(0xFF9B59B6),
              color2: AppColors.primary,
              onTap: () {
                Navigator.pop(context);
                _exportPDF();
              },
            ),
            const SizedBox(height: AppSizes.sm),
            _ExportOption(
              icon: Icons.code_rounded,
              label: 'Mermaid Code',
              subtitle: 'Share source code',
              color1: AppColors.accent,
              color2: const Color(0xFF9B59B6),
              onTap: () {
                Navigator.pop(context);
                _exportCode();
              },
            ),
            const SizedBox(height: AppSizes.md),

            // Cancel
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(
                      AppSizes.radiusRound),
                  border: Border.all(
                      color:
                          Colors.white.withValues(alpha: 0.10)),
                ),
                child: const Text(
                  'Cancel',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            SizedBox(
                height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  // ── HTML builder — unchanged ───────────────────────────────────────────────
  String _buildHtml(String mermaidCode) {
    final cleanCode = mermaidCode
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '')
        .trim();

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=yes">
  <script src="https://cdn.jsdelivr.net/npm/mermaid@10.6.1/dist/mermaid.min.js"></script>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    html, body { background: #0D1B2A; min-height: 100vh; display: flex; align-items: center; justify-content: center; padding: 16px; }
    .mermaid { max-width: 100%; overflow: auto; }
    .mermaid svg { max-width: 100%; height: auto; }
  </style>
</head>
<body>
  <div class="mermaid" id="diagram"></div>
  <script>
    mermaid.initialize({
      startOnLoad: false,
      securityLevel: 'loose',
      theme: 'dark',
      themeVariables: {
        background: '#0D1B2A',
        primaryColor: '#6C63FF',
        primaryTextColor: '#ffffff',
        lineColor: '#00D4FF',
        secondaryColor: '#1A1828',
        tertiaryColor: '#1A1828',
      },
    });
    const code = `$cleanCode`;

    const code = \`$cleanCode\`;

    async function renderDiagram() {
      try {
        const el = document.getElementById('diagram');
        el.textContent = code;
        await mermaid.run();
      } catch(e) {}
    }
    renderDiagram();
  </script>
</body>
</html>
''';
  }

  // ── Export functions — unchanged logic ─────────────────────────────────────
  Future<void> _exportPNG() async {
    setState(() => _isExporting = true);
    try {
      Uint8List? image = _capturedImage ??
          await _screenshotController.capture(pixelRatio: 2.0);
      if (image == null) throw Exception('Could not capture');
  void _copyCode() {
    final code = widget.diagram.diagramCode ?? '';
    Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Code copied to clipboard', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showExportSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            const Text('Export as', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.image_rounded, color: AppColors.primary),
              title: const Text('PNG Image', style: TextStyle(color: AppColors.textPrimary)),
              subtitle: const Text('Save as image', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              onTap: () { Navigator.pop(context); _exportPNG(); },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary),
              title: const Text('PDF Document', style: TextStyle(color: AppColors.textPrimary)),
              subtitle: const Text('Save as PDF', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              onTap: () { Navigator.pop(context); _exportPDF(); },
            ),
            ListTile(
              leading: const Icon(Icons.code_rounded, color: AppColors.primary),
              title: const Text('Mermaid Code', style: TextStyle(color: AppColors.textPrimary)),
              subtitle: const Text('Share code', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              onTap: () { Navigator.pop(context); _exportCode(); },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportPNG() async {
    setState(() => _isExporting = true);
    try {
      Uint8List? image = _capturedImage;
      image ??= await _screenshotController.capture(pixelRatio: 2.0);
      if (image == null) throw Exception('Could not capture diagram');
      final dir = await getTemporaryDirectory();
      final file =
          File('${dir.path}/${widget.diagram.name}.png');
      await file.writeAsBytes(image);
      await Share.shareXFiles(
          [XFile(file.path)], text: widget.diagram.name);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportPDF() async {
    setState(() => _isExporting = true);
    try {
      Uint8List? image = _capturedImage ??
          await _screenshotController.capture(pixelRatio: 2.0);
      if (image == null) throw Exception('Could not capture');
      Uint8List? image = _capturedImage;
      image ??= await _screenshotController.capture(pixelRatio: 2.0);
      if (image == null) throw Exception('Could not capture diagram');
      final pdf = pw.Document();
      final pdfImage = pw.MemoryImage(image);
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (ctx) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(widget.diagram.name,
                  style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold)),
              pw.Text(widget.diagram.name, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Center(child: pw.Image(pdfImage)),
            ],
          ),
        ),
      );
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: '${widget.diagram.name}.pdf',
      );
      await Printing.sharePdf(bytes: await pdf.save(), filename: '${widget.diagram.name}.pdf');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _exportCode() {
    Share.share(widget.diagram.diagramCode ?? '',
        subject: widget.diagram.name);
    Share.share(widget.diagram.diagramCode ?? '', subject: widget.diagram.name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // ← غيّرناه
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent, // ← غيّرناه
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        color: AppColors.textPrimary,
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        widget.diagram.name.isNotEmpty ? widget.diagram.name : 'Untitled',
        style: AppTextStyles.h3,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// ── Toggle Chip ───────────────────────────────────────────────────────────────
class _ToggleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [AppColors.primary, AppColors.accent],
                )
              : null,
          borderRadius:
              BorderRadius.circular(AppSizes.radiusRound),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? Colors.white
                  : AppColors.textTertiary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : AppColors.textTertiary,
                fontSize: AppSizes.fontSm,
                fontWeight: isSelected
                    ? FontWeight.w700
                    : FontWeight.w400,
              ),
  Widget _buildBody() {
    if (widget.diagram.diagramCode == null || widget.diagram.diagramCode!.isEmpty) {
      return _buildNoCode();
    }
    return Column(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 500),
          child: AnimatedOpacity(
            opacity: _showBanner ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 500),
            child: _showBanner
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: _buildStatusBanner(),
                  )
                : const SizedBox.shrink(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSizes.radiusRound),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(child: _buildToggleChip('Preview', !_showCode)),
                Expanded(child: _buildToggleChip('Mermaid code', _showCode)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(child: _showCode ? _buildCodeView() : _buildPreview()),
      ],
    );
  }

  Widget _buildPreview() {
    if (_webController != null) {
      return Screenshot(
        controller: _screenshotController,
        child: Stack(
          children: [
            WebViewWidget(controller: _webController!),
            if (_webViewLoading)
              Container(
                color: AppColors.background,
                child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              ),
          ],
        ),
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
              child: const Icon(Icons.auto_awesome_rounded, size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text('Diagram Ready', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            const Text('Visual preview is available on mobile.\nTap "Mermaid code" to view the code.', textAlign: TextAlign.center, style: TextStyle(fontSize: AppSizes.fontSm, color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => setState(() => _showCode = true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd))),
              icon: const Icon(Icons.code_rounded, size: 18),
              label: const Text('View Mermaid Code'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Export Option ─────────────────────────────────────────────────────────────
class _ExportOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color1;
  final Color color2;
  final VoidCallback onTap;

  const _ExportOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color1,
    required this.color2,
    required this.onTap,
  });
  Widget _buildCodeView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppSizes.radiusLg), border: Border.all(color: AppColors.border)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Mermaid Code', style: TextStyle(fontSize: AppSizes.fontSm, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                GestureDetector(
                  onTap: _copyCode,
                  child: const Row(children: [
                    Icon(Icons.copy_rounded, size: 14, color: AppColors.primary),
                    SizedBox(width: 4),
                    Text('Copy', style: TextStyle(fontSize: AppSizes.fontSm, color: AppColors.primary, fontWeight: FontWeight.w500)),
                  ]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(color: AppColors.border),
            const SizedBox(height: 8),
            SelectableText(
              widget.diagram.diagramCode ?? '',
              style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'monospace', fontSize: 13, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(AppSizes.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius:
                BorderRadius.circular(AppSizes.radiusLg),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [color1, color2]),
                  borderRadius: BorderRadius.circular(
                      AppSizes.radiusMd),
                  boxShadow: [
                    BoxShadow(
                      color: color1.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon,
                    color: Colors.white,
                    size: AppSizes.iconMd),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: AppSizes.fontMd,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: AppSizes.fontXs + 1,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  size: 18, color: AppColors.textTertiary),
            ],
          const SizedBox(height: AppSizes.lg),
          Text('No diagram yet', style: AppTextStyles.h3),
          const SizedBox(height: AppSizes.xs),
          const Text('The diagram is still being generated.', style: TextStyle(fontSize: AppSizes.fontMd, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildToggleChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _showCode = label == 'Mermaid code'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.radiusRound),
        ),
        child: Center(child: Text(label, style: TextStyle(fontSize: AppSizes.fontSm, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : AppColors.textSecondary))),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _isExporting ? null : _showExportSheet,
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.textPrimary, side: const BorderSide(color: AppColors.border), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd))),
              icon: _isExporting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                  : const Icon(Icons.download_rounded, size: 18),
              label: Text(_isExporting ? 'Exporting...' : 'Export', style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => setState(() => _showCode = !_showCode),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd))),
              icon: Icon(_showCode ? Icons.visibility_rounded : Icons.code_rounded, size: 18),
              label: Text(_showCode ? 'Preview' : 'Code', style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ),
    );
  }
}