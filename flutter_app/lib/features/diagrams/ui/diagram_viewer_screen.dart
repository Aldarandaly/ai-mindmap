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
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_sizes.dart';

class DiagramViewerScreen extends StatefulWidget {
  final Diagram diagram;
  const DiagramViewerScreen({super.key, required this.diagram});

  @override
  State<DiagramViewerScreen> createState() => _DiagramViewerScreenState();
}

class _DiagramViewerScreenState extends State<DiagramViewerScreen> {
  bool _showCode = false;
  bool _showBanner = true;
  bool _isExporting = false;
  WebViewController? _webController;
  bool _webViewLoading = true;
  final _screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showBanner = false);
    });
    _initWebView();
  }

  void _initWebView() {
    try {
      _webController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(AppColors.background)
        ..setNavigationDelegate(NavigationDelegate(
          onPageFinished: (_) => setState(() => _webViewLoading = false),
        ))
        ..loadHtmlString(_buildHtml(widget.diagram.diagramCode ?? ''));
    } catch (e) {
      _webController = null;
    }
  }

  String _buildHtml(String mermaidCode) {
    final cleanCode = mermaidCode
        .split('\n')
        .map((line) => line.trimLeft())
        .join('\n')
        .trim();

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=yes">
  <script src="https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"></script>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    html, body { background: #0F0E17; min-height: 100vh; display: flex; align-items: center; justify-content: center; padding: 16px; }
    .mermaid { max-width: 100%; overflow: auto; }
    .mermaid svg { max-width: 100%; height: auto; }
    #error { display: none; color: #ef4444; font-family: sans-serif; font-size: 14px; text-align: center; padding: 24px; }
  </style>
</head>
<body>
  <div class="mermaid" id="diagram"></div>
  <div id="error">Failed to render diagram.</div>
  <script>
    mermaid.initialize({
      startOnLoad: false,
      theme: 'dark',
      themeVariables: {
        background: '#0F0E17',
        primaryColor: '#4F46E5',
        primaryTextColor: '#ffffff',
        lineColor: '#6366f1',
        secondaryColor: '#1A1828',
        tertiaryColor: '#1A1828',
      },
    });

    const code = `$cleanCode`;

    async function renderDiagram() {
      try {
        const el = document.getElementById('diagram');
        const { svg } = await mermaid.render('mermaid-svg', code);
        el.innerHTML = svg;
      } catch (e) {
        document.getElementById('diagram').style.display = 'none';
        document.getElementById('error').style.display = 'block';
        document.getElementById('error').innerText = 'Error: ' + e.message;
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
      backgroundColor: AppColors.surface,
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
              subtitle: const Text('Copy or share code', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              onTap: () { Navigator.pop(context); _exportCode(); },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportPNG() async {
    if (_webController == null) { _copyCode(); return; }
    setState(() => _isExporting = true);
    try {
      final image = await _screenshotController.capture();
      if (image == null) return;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${widget.diagram.name}.png');
      await file.writeAsBytes(image);
      await Share.shareXFiles([XFile(file.path)], text: widget.diagram.name);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportPDF() async {
    if (_webController == null) { _copyCode(); return; }
    setState(() => _isExporting = true);
    try {
      final image = await _screenshotController.capture();
      if (image == null) return;
      final pdf = pw.Document();
      final pdfImage = pw.MemoryImage(image);
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) => pw.Center(child: pw.Image(pdfImage)),
        ),
      );
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: '${widget.diagram.name}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _exportCode() {
    Share.share(widget.diagram.diagramCode ?? '', subject: widget.diagram.name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
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
      title: Text(
        widget.diagram.name.isNotEmpty ? widget.diagram.name : 'Untitled',
        style: AppTextStyles.h3,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildBody() {
    if (widget.diagram.diagramCode == null || widget.diagram.diagramCode!.isEmpty) {
      return _buildNoCode();
    }

    return Column(
      children: [
        // ── Status Banner ──
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
        // ── Toggle ──
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
        // ── Content ──
        Expanded(
          child: _showCode ? _buildCodeView() : _buildPreview(),
        ),
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
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
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
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              ),
              child: const Icon(Icons.auto_awesome_rounded, size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text('Diagram Ready', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            const Text(
              'Visual preview is available on mobile.\nTap "Mermaid code" to view the code.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: AppSizes.fontSm, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => setState(() => _showCode = true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
              ),
              icon: const Icon(Icons.code_rounded, size: 18),
              label: const Text('View Mermaid Code'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner() {
    final isDone = widget.diagram.isDone;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDone ? AppColors.success.withValues(alpha: 0.1) : AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: isDone ? AppColors.success.withValues(alpha: 0.3) : AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(isDone ? Icons.check_circle_rounded : Icons.hourglass_top_rounded, size: 16, color: isDone ? AppColors.success : AppColors.warning),
          const SizedBox(width: 8),
          Text(
            isDone ? 'Diagram generated successfully' : 'Status: ${widget.diagram.status}',
            style: TextStyle(fontSize: AppSizes.fontSm, color: isDone ? AppColors.success : AppColors.warning, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Mermaid Code', style: TextStyle(fontSize: AppSizes.fontSm, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                GestureDetector(
                  onTap: _copyCode,
                  child: const Row(
                    children: [
                      Icon(Icons.copy_rounded, size: 14, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text('Copy', style: TextStyle(fontSize: AppSizes.fontSm, color: AppColors.primary, fontWeight: FontWeight.w500)),
                    ],
                  ),
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

  Widget _buildNoCode() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppSizes.radiusXl)),
            child: const Icon(Icons.hourglass_empty_rounded, size: 36, color: AppColors.textTertiary),
          ),
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
        child: Center(
          child: Text(label, style: TextStyle(fontSize: AppSizes.fontSm, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : AppColors.textSecondary)),
        ),
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
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
              ),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
              ),
              icon: Icon(_showCode ? Icons.visibility_rounded : Icons.code_rounded, size: 18),
              label: Text(_showCode ? 'Preview' : 'Code', style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}