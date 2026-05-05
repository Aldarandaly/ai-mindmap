import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../data/diagram_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_sizes.dart';

class DiagramViewerScreen extends StatefulWidget {
  final DiagramModel diagram;

  const DiagramViewerScreen({super.key, required this.diagram});

  @override
  State<DiagramViewerScreen> createState() => _DiagramViewerScreenState();
}

class _DiagramViewerScreenState extends State<DiagramViewerScreen> {
  late final WebViewController _webController;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.background)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) => setState(() => _isLoading = false),
        onWebResourceError: (_) => setState(() {
          _isLoading = false;
          _hasError = true;
        }),
      ))
      ..loadHtmlString(_buildHtml(widget.diagram.diagramCode ?? ''));
  }

  String _buildHtml(String mermaidCode) {
    // Escape backticks and backslashes عشان متكسرش الـ JS template literal
    final escaped = mermaidCode
        .replaceAll(r'\', r'\\')
        .replaceAll('`', r'\`')
        .replaceAll('\$', r'\$');

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=yes">
  <script src="https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"></script>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    html, body {
      background: #0F0E17;
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 16px;
    }
    .mermaid {
      max-width: 100%;
      overflow: auto;
    }
    .mermaid svg {
      max-width: 100%;
      height: auto;
    }
    #error {
      display: none;
      color: #ef4444;
      font-family: sans-serif;
      font-size: 14px;
      text-align: center;
      padding: 24px;
    }
  </style>
</head>
<body>
  <div class="mermaid" id="diagram">${mermaidCode.replaceAll('<', '&lt;').replaceAll('>', '&gt;')}</div>
  <div id="error">فشل عرض الـ diagram. الكود قد يكون غير صحيح.</div>

  <script>
    mermaid.initialize({
      startOnLoad: false,
      theme: 'dark',
      themeVariables: {
        background: '#0F0E17',
        primaryColor: '#4F46E5',
        primaryTextColor: '#ffffff',
        primaryBorderColor: '#2D2B3D',
        lineColor: '#6366f1',
        secondaryColor: '#1A1828',
        tertiaryColor: '#1A1828',
        edgeLabelBackground: '#1A1828',
        clusterBkg: '#1A1828',
        titleColor: '#ffffff',
        nodeTextColor: '#ffffff',
        attributeBackgroundColorOdd: '#1A1828',
        attributeBackgroundColorEven: '#0F0E17',
      },
      flowchart: { curve: 'basis', htmlLabels: true },
      er: { diagramPadding: 20 },
      mindmap: { padding: 16 },
    });

    async function renderDiagram() {
      try {
        const el = document.getElementById('diagram');
        const code = el.innerText.trim();
        const { svg } = await mermaid.render('mermaid-svg', code);
        el.innerHTML = svg;
      } catch (e) {
        document.getElementById('diagram').style.display = 'none';
        document.getElementById('error').style.display = 'block';
        console.error('Mermaid error:', e);
      }
    }

    renderDiagram();
  </script>
</body>
</html>
''';
  }

  void _copyCode() {
    final code = widget.diagram.diagramCode ?? '';
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('تم نسخ الكود'),
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _reload() {
    setState(() { _isLoading = true; _hasError = false; });
    _webController.loadHtmlString(_buildHtml(widget.diagram.diagramCode ?? ''));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          // ── WebView ──
          if (!_hasError)
            WebViewWidget(controller: _webController),

          // ── Error State ──
          if (_hasError) _buildErrorState(),

          // ── Loading Overlay ──
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        color: AppColors.textPrimary,
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.diagram.name,
            style: AppTextStyles.h3,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            _typeLabel(widget.diagram.type),
            style: AppTextStyles.labelSmall,
          ),
        ],
      ),
      actions: [
        // Copy Code Button
        IconButton(
          icon: const Icon(Icons.copy_rounded, size: 20),
          color: AppColors.textSecondary,
          tooltip: 'نسخ الكود',
          onPressed: widget.diagram.diagramCode != null ? _copyCode : null,
        ),
        // Reload Button
        IconButton(
          icon: const Icon(Icons.refresh_rounded, size: 20),
          color: AppColors.textSecondary,
          tooltip: 'إعادة تحميل',
          onPressed: _reload,
        ),
        const SizedBox(width: AppSizes.xs),
      ],
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: AppColors.background,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2.5,
              ),
            ),
            const SizedBox(height: AppSizes.md),
            Text('جاري تحميل الـ diagram...', style: AppTextStyles.labelSmall),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.screenPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSizes.radiusXl),
              ),
              child: const Icon(Icons.broken_image_rounded, size: 36, color: AppColors.textTertiary),
            ),
            const SizedBox(height: AppSizes.lg),
            Text('فشل تحميل الـ diagram', style: AppTextStyles.h3),
            const SizedBox(height: AppSizes.xs),
            Text(
              'في مشكلة في عرض الـ diagram.\nحاول تعمل reload.',
              textAlign: TextAlign.center,
              style: AppTextStyles.labelSmall.copyWith(height: 1.6),
            ),
            const SizedBox(height: AppSizes.xl),
            ElevatedButton.icon(
              onPressed: _reload,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg, vertical: AppSizes.md),
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reload'),
            ),
          ],
        ),
      ),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'class': return 'Class Diagram';
      case 'erd': return 'Entity Relationship Diagram';
      case 'mindmap': return 'Mind Map';
      case 'auto': return 'Auto Generated';
      default: return type;
    }
  }
}