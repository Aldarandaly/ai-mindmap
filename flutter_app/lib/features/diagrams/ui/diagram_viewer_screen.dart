import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/core/network/api_client.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/diagram_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import 'dart:ui' as ui;

class DiagramViewerScreen extends StatefulWidget {
  final Diagram diagram;
  const DiagramViewerScreen({super.key, required this.diagram});

  @override
  State<DiagramViewerScreen> createState() => _DiagramViewerScreenState();
}

class _DiagramViewerScreenState extends State<DiagramViewerScreen>
    with TickerProviderStateMixin {
  bool _showCode = false;
  bool _showBanner = true;
  bool _isExporting = false;
  bool _webViewLoading = true;
  bool _copied = false;

  String _currentDiagramCode = '';
  final List<Map<String, String>> _chatHistory = [];
  final TextEditingController _chatController = TextEditingController();
  bool _isChatLoading = false;

  WebViewController? _webController;
  final _screenshotController = ScreenshotController();
  Uint8List? _capturedImage;

  late final AnimationController _bannerCtrl;
  late final Animation<Offset> _bannerSlide;
  late final AnimationController _viewCtrl;
  late final Animation<double> _viewFade;
  late final AnimationController _copyCtrl;
  late final Animation<double> _copyScale;

  @override
  void initState() {
    super.initState();
    _currentDiagramCode = widget.diagram.diagramCode ?? '';
    _setupAnimations();
    _initWebView();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _dismissBanner();
    });
  }

  void _setupAnimations() {
    _bannerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _bannerSlide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _bannerCtrl, curve: Curves.easeOutCubic));
    _viewCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..forward();
    _viewFade = CurvedAnimation(parent: _viewCtrl, curve: Curves.easeOut);
    _copyCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _copyScale = Tween<double>(
      begin: 1.0,
      end: 1.18,
    ).animate(CurvedAnimation(parent: _copyCtrl, curve: Curves.easeInOut));
  }

  void _initWebView() {
    try {
      _webController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(AppColors.background)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (_) async {
              setState(() => _webViewLoading = false);
              await Future.delayed(const Duration(seconds: 4));
              await _captureWebView();
            },
          ),
        )
        ..loadHtmlString(_buildHtml(_currentDiagramCode));
    } catch (_) {
      _webController = null;
    }
  }

  Future<void> _captureWebView() async {
    try {
      await _webController?.runJavaScript("window.scrollTo(0, 0)");
      await Future.delayed(const Duration(milliseconds: 300));

      final img = await _screenshotController.capture(pixelRatio: 3.0);
      if (mounted && img != null) setState(() => _capturedImage = img);
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
    await Clipboard.setData(ClipboardData(text: _currentDiagramCode));
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
    _chatController.dispose();
    super.dispose();
  }

  void _showChatSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: _ChatSheet(
            chatHistory: _chatHistory,
            controller: _chatController,
            isLoading: _isChatLoading,
            onSend: (msg) async {
              await _sendEditMessage(msg, setSheetState);
            },
          ),
        ),
      ),
    );
  }

  Future<void> _sendEditMessage(
    String message,
    StateSetter setSheetState,
  ) async {
    if (message.trim().isEmpty) return;
    setSheetState(() {
      _chatHistory.add({'role': 'user', 'content': message});
      _isChatLoading = true;
    });
    _chatController.clear();

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.pythonUrl}/api/edit'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'current_code': _currentDiagramCode,
          'message': message,
          'type': widget.diagram.type,
          'history': _chatHistory
              .map((m) => {'role': m['role'], 'content': m['content']})
              .toList(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newCode = data['diagram_code'] as String;
        final reply = data['reply'] as String;
        setSheetState(() {
          _chatHistory.add({'role': 'assistant', 'content': reply});
          _isChatLoading = false;
        });
        setState(() => _currentDiagramCode = newCode);
        _webController?.loadHtmlString(_buildHtml(newCode));
        try {
          await ApiClient().put(
            '/diagrams/${widget.diagram.id}',
            data: {'diagram_code': newCode},
          );
        } catch (_) {}
      } else {
        setSheetState(() {
          _chatHistory.add({
            'role': 'assistant',
            'content': 'Something went wrong. Please try again.',
          });
          _isChatLoading = false;
        });
      }
    } catch (e) {
      setSheetState(() {
        _chatHistory.add({
          'role': 'assistant',
          'content': 'Connection error. Check your network.',
        });
        _isChatLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    AppSizes.init(context);
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
              if (_showBanner) _buildBanner(),
              _buildAppBar(),
              _buildToggle(),
              Expanded(
                child: FadeTransition(
                  opacity: _viewFade,
                  child:
                      widget.diagram.diagramCode == null ||
                          widget.diagram.diagramCode!.isEmpty
                      ? _buildNoCode()
                      : _showCode
                      ? _buildCodeView()
                      : _buildPreview(),
                ),
              ),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBanner() {
    final isDone = widget.diagram.isDone;
    final color = isDone ? AppColors.success : AppColors.warning;
    return SlideTransition(
      position: _bannerSlide,
      child: GestureDetector(
        onTap: _dismissBanner,
        child: Container(
          margin: EdgeInsets.fromLTRB(AppSizes.md, AppSizes.sm, AppSizes.md, 0),
          padding: EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 11),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: Icon(
                  isDone ? Icons.check_rounded : Icons.hourglass_top_rounded,
                  size: 15,
                  color: color,
                ),
              ),
              SizedBox(width: AppSizes.sm),
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
              Icon(
                Icons.close_rounded,
                size: 15,
                color: color.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSizes.md, AppSizes.sm, AppSizes.md, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: AppSizes.iconSm,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          SizedBox(width: AppSizes.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.diagram.name.isNotEmpty
                      ? widget.diagram.name
                      : 'Untitled',
                  style: TextStyle(
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
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: AppSizes.fontXs,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle() {
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSizes.md, AppSizes.md, AppSizes.md, 0),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppSizes.radiusRound),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
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

  Widget _buildPreview() {
    if (_webController == null) return _buildFallback();
    return Container(
      margin: EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
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
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ),
                      SizedBox(height: AppSizes.md),
                      Text(
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
        padding: EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppSizes.radiusXl),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 36,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: AppSizes.lg),
            Text(
              'Diagram Ready',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: AppSizes.fontXl,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: AppSizes.sm),
            Text(
              'Tap "Mermaid Code" to view the source',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: AppSizes.fontSm,
              ),
            ),
            SizedBox(height: AppSizes.xl),
            GestureDetector(
              onTap: () => _switchView(true),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.radiusRound),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.code_rounded, size: 16, color: Colors.white),
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

  Widget _buildCodeView() {
    return Container(
      margin: EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSizes.md,
              AppSizes.sm,
              AppSizes.sm,
              AppSizes.sm,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppSizes.radiusRound),
                  ),
                  child: Text(
                    'Mermaid',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: AppSizes.fontXs,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                ScaleTransition(
                  scale: _copyScale,
                  child: GestureDetector(
                    onTap: _copyCode,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: _copied
                            ? AppColors.success.withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(
                          AppSizes.radiusRound,
                        ),
                        border: Border.all(
                          color: _copied
                              ? AppColors.success.withValues(alpha: 0.4)
                              : Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _copied ? Icons.check_rounded : Icons.copy_rounded,
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
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.07)),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(AppSizes.md),
              child: SelectableText(
                _currentDiagramCode,
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
              borderRadius: BorderRadius.circular(AppSizes.radiusXl),
            ),
            child: const Icon(
              Icons.hourglass_empty_rounded,
              size: 34,
              color: AppColors.textTertiary,
            ),
          ),
          SizedBox(height: AppSizes.lg),
          Text(
            'No diagram yet',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: AppSizes.fontXl,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: AppSizes.xs),
          Text(
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

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSizes.md,
        AppSizes.sm,
        AppSizes.md,
        AppSizes.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.9),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _isExporting ? null : _showExportSheet,
              child: Container(
                height: AppSizes.buttonHeight,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isExporting
                        ? [
                            AppColors.primary.withValues(alpha: 0.5),
                            AppColors.accent.withValues(alpha: 0.5),
                          ]
                        : [AppColors.primary, AppColors.accent],
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.radiusRound),
                  boxShadow: _isExporting
                      ? []
                      : [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
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
                        : const Icon(
                            Icons.download_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                    SizedBox(width: AppSizes.sm),
                    Text(
                      _isExporting ? 'Exporting...' : 'Export',
                      style: TextStyle(
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
          SizedBox(width: AppSizes.sm),
          GestureDetector(
            onTap: _showChatSheet,
            child: Container(
              width: AppSizes.buttonHeight,
              height: AppSizes.buttonHeight,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF9B59B6)],
                ),
                borderRadius: BorderRadius.circular(AppSizes.radiusRound),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: AppSizes.iconMd,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(width: AppSizes.sm),
          GestureDetector(
            onTap: () => _switchView(!_showCode),
            child: Container(
              width: AppSizes.buttonHeight,
              height: AppSizes.buttonHeight,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(AppSizes.radiusRound),
                border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
              ),
              child: Icon(
                _showCode ? Icons.visibility_rounded : Icons.code_rounded,
                size: AppSizes.iconMd,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showExportSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        margin: EdgeInsets.all(AppSizes.md),
        padding: EdgeInsets.all(AppSizes.lg),
        decoration: BoxDecoration(
          color: const Color(0xFF131B2E),
          borderRadius: BorderRadius.circular(AppSizes.radiusXl + 4),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            SizedBox(height: AppSizes.lg),
            Text(
              'Export Diagram',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: AppSizes.fontLg,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Choose export format',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: AppSizes.fontSm,
              ),
            ),
            SizedBox(height: AppSizes.lg),
            _ExportOption(
              icon: Icons.image_rounded,
              label: 'PNG Image',
              subtitle: 'Full diagram, high quality',
              color1: AppColors.primary,
              color2: AppColors.accent,
              onTap: () {
                Navigator.pop(context);
                _exportPNG();
              },
            ),
            SizedBox(height: AppSizes.sm),
            _ExportOption(
              icon: Icons.picture_as_pdf_rounded,
              label: 'PDF Document',
              subtitle: 'Full diagram, print quality',
              color1: const Color(0xFF9B59B6),
              color2: AppColors.primary,
              onTap: () {
                Navigator.pop(context);
                _exportPDF();
              },
            ),
            SizedBox(height: AppSizes.sm),
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
            SizedBox(height: AppSizes.md),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(AppSizes.radiusRound),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
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
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

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
  <meta name="viewport" content="width=device-width, initial-scale=1.0, minimum-scale=0.1, maximum-scale=10.0, user-scalable=yes">
  <script src="https://cdn.jsdelivr.net/npm/mermaid@10.6.1/dist/mermaid.min.js"></script>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    html, body { background: #0D1B2A; width: 100vw; height: 100vh; display: flex; align-items: center; justify-content: center; overflow: hidden; }
    #container { display: flex; align-items: center; justify-content: center; transform-origin: center center; }
    #diagram svg { display: block; max-width: none !important; }
  </style>
</head>
<body>
  <div id="container">
    <div id="diagram" class="mermaid"></div>
  </div>
  <script>
    window.currentScale = 1;
    
    mermaid.initialize({ startOnLoad: false, securityLevel: 'loose', theme: 'dark', themeVariables: { background: '#0D1B2A', primaryColor: '#6C63FF', primaryTextColor: '#ffffff', lineColor: '#00D4FF', secondaryColor: '#1A1828', tertiaryColor: '#1A1828' } });
    
    async function renderDiagram() {
      try {
        document.getElementById('diagram').textContent = \`$cleanCode\`;
        await mermaid.run();
        autoZoom();
      } catch(e) {}
    }
    
    function autoZoom() {
      const svg = document.querySelector('#diagram svg');
      if (!svg) return;
      const svgWidth = svg.getBoundingClientRect().width;
      const svgHeight = svg.getBoundingClientRect().height;
      const scaleX = (window.innerWidth - 40) / svgWidth;
      const scaleY = (window.innerHeight - 40) / svgHeight;
      const scale = Math.min(scaleX, scaleY, 1);
      window.currentScale = scale;
      document.getElementById('container').style.transform = 'scale(' + scale + ')';
    }
    
    renderDiagram();
  </script>
</body>
</html>
''';
  }

  Future<Uint8List?> _captureFullDiagram() async {
    try {
      final img = await _screenshotController.capture(pixelRatio: 6.0);
      return img ?? _capturedImage;
    } catch (e) {
      return _capturedImage;
    }
  }

  Future<void> _exportPNG() async {
    setState(() => _isExporting = true);
    try {
      final img = await _captureFullDiagram();
      if (img == null) throw Exception('Could not capture diagram');
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${widget.diagram.name}.png');
      await file.writeAsBytes(img);
      await Share.shareXFiles([XFile(file.path)], text: widget.diagram.name);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportPDF() async {
    setState(() => _isExporting = true);
    try {
      final img = await _captureFullDiagram();
      if (img == null) throw Exception('Could not capture diagram');
      final pdf = pw.Document();
      final pdfImage = pw.MemoryImage(img);
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(20),
          build: (ctx) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                widget.diagram.name,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Expanded(
                child: pw.Center(
                  child: pw.Image(pdfImage, fit: pw.BoxFit.contain),
                ),
              ),
            ],
          ),
        ),
      );
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: '${widget.diagram.name}.pdf',
      );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _exportCode() {
    Share.share(_currentDiagramCode, subject: widget.diagram.name);
  }
}

// ─── Chat Sheet ───────────────────────────────────────────────

class _ChatSheet extends StatefulWidget {
  final List<Map<String, String>> chatHistory;
  final TextEditingController controller;
  final bool isLoading;
  final Future<void> Function(String) onSend;
  const _ChatSheet({
    required this.chatHistory,
    required this.controller,
    required this.isLoading,
    required this.onSend,
  });

  @override
  State<_ChatSheet> createState() => _ChatSheetState();
}

class _ChatSheetState extends State<_ChatSheet> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend() async {
    final msg = widget.controller.text.trim();
    if (msg.isEmpty || widget.isLoading) return;
    await widget.onSend(msg);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    AppSizes.init(context);
    _scrollToBottom();
    return Container(
      height: MediaQuery.of(context).size.height * 0.80,
      margin: EdgeInsets.fromLTRB(AppSizes.sm, 0, AppSizes.sm, AppSizes.sm),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1628),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl + 4),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSizes.md,
              AppSizes.md,
              AppSizes.md,
              0,
            ),
            child: Column(
              children: [
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
                SizedBox(height: AppSizes.md),
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: AppSizes.sm),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Diagram Editor',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: AppSizes.fontMd,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Ask me to modify your diagram',
                          style: TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: AppSizes.fontXs,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: AppSizes.md),
                Divider(height: 1, color: Colors.white.withValues(alpha: 0.07)),
              ],
            ),
          ),
          Expanded(
            child: widget.chatHistory.isEmpty
                ? _buildEmptyChat()
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(AppSizes.md),
                    itemCount:
                        widget.chatHistory.length + (widget.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == widget.chatHistory.length)
                        return _buildTypingIndicator();
                      final msg = widget.chatHistory[index];
                      return _ChatBubble(
                        message: msg['content'] ?? '',
                        isUser: msg['role'] == 'user',
                      );
                    },
                  ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
              AppSizes.md,
              AppSizes.sm,
              AppSizes.md,
              AppSizes.md,
            ),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusRound,
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        child: TextField(
                          controller: widget.controller,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: AppSizes.fontSm,
                          ),
                          decoration: InputDecoration(
                            hintText: 'e.g. Add a Payment class...',
                            hintStyle: TextStyle(
                              color: AppColors.textTertiary.withValues(
                                alpha: 0.7,
                              ),
                              fontSize: AppSizes.fontSm,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: AppSizes.md,
                              vertical: AppSizes.sm + 2,
                            ),
                          ),
                          onSubmitted: (_) => _handleSend(),
                          enabled: !widget.isLoading,
                          maxLines: 3,
                          minLines: 1,
                        ),
                      ),
                    ),
                    SizedBox(width: AppSizes.sm),
                    GestureDetector(
                      onTap: widget.isLoading ? null : _handleSend,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: widget.isLoading
                              ? LinearGradient(
                                  colors: [
                                    AppColors.primary.withValues(alpha: 0.4),
                                    AppColors.accent.withValues(alpha: 0.4),
                                  ],
                                )
                              : const LinearGradient(
                                  colors: [AppColors.primary, AppColors.accent],
                                ),
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusRound,
                          ),
                        ),
                        child: widget.isLoading
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.send_rounded,
                                size: 18,
                                color: Colors.white,
                              ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.15),
                  AppColors.accent.withValues(alpha: 0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 28,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: AppSizes.md),
          Text(
            'Edit with AI',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: AppSizes.fontMd,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: AppSizes.xs),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Describe what you want to change and the diagram will update live',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: AppSizes.fontXs + 1,
                height: 1.5,
              ),
            ),
          ),
          SizedBox(height: AppSizes.lg),
          Wrap(
            spacing: AppSizes.sm,
            runSpacing: AppSizes.sm,
            alignment: WrapAlignment.center,
            children: const [
              _SuggestionChip(label: '➕ Add a class'),
              _SuggestionChip(label: '🔗 Add relationship'),
              _SuggestionChip(label: '✏️ Rename entity'),
              _SuggestionChip(label: '🗑️ Remove element'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSizes.sm),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 14,
              color: Colors.white,
            ),
          ),
          SizedBox(width: AppSizes.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DotPulse(delay: 0),
                const SizedBox(width: 4),
                _DotPulse(delay: 200),
                const SizedBox(width: 4),
                _DotPulse(delay: 400),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  const _ChatBubble({required this.message, required this.isUser});

  @override
  Widget build(BuildContext context) {
    AppSizes.init(context);
    return Padding(
      padding: EdgeInsets.only(bottom: AppSizes.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 14,
                color: Colors.white,
              ),
            ),
            SizedBox(width: AppSizes.sm),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: isUser
                    ? const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF9B59B6)],
                      )
                    : null,
                color: isUser ? null : Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isUser ? 16 : 4),
                  topRight: Radius.circular(isUser ? 4 : 16),
                  bottomLeft: const Radius.circular(16),
                  bottomRight: const Radius.circular(16),
                ),
                border: isUser
                    ? null
                    : Border.all(color: Colors.white.withValues(alpha: 0.08)),
                boxShadow: isUser
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [],
              ),
              child: Text(
                message,
                style: TextStyle(
                  color: isUser ? Colors.white : AppColors.textSecondary,
                  fontSize: AppSizes.fontSm,
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            SizedBox(width: AppSizes.sm),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.25),
                ),
              ),
              child: const Icon(
                Icons.person_rounded,
                size: 16,
                color: AppColors.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  const _SuggestionChip({required this.label});

  @override
  Widget build(BuildContext context) {
    AppSizes.init(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSizes.radiusRound),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.20)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: AppSizes.fontXs + 1,
        ),
      ),
    );
  }
}

class _DotPulse extends StatefulWidget {
  final int delay;
  const _DotPulse({required this.delay});

  @override
  State<_DotPulse> createState() => _DotPulseState();
}

class _DotPulseState extends State<_DotPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _anim = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: AppColors.textTertiary,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}

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
          borderRadius: BorderRadius.circular(AppSizes.radiusRound),
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
              color: isSelected ? Colors.white : AppColors.textTertiary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textTertiary,
                fontSize: AppSizes.fontSm,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

  @override
  Widget build(BuildContext context) {
    AppSizes.init(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Container(
          padding: EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [color1, color2]),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  boxShadow: [
                    BoxShadow(
                      color: color1.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: AppSizes.iconMd),
              ),
              SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: AppSizes.fontMd,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: AppSizes.fontXs + 1,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
