import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/network/api_client.dart';
import '../data/plan_model.dart';
import '../../../features/main/ui/main.screen.dart';

class PaymentScreen extends StatefulWidget {
  final PlanModel plan;
  final bool isAnnual;

  const PaymentScreen({super.key, required this.plan, required this.isAnnual});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  WebViewController? _webController;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  bool _paymentHandled = false;

  @override
  void initState() {
    super.initState();
    _initiatePayment();
  }

  Future<void> _initiatePayment() async {
    try {
      print('🚀 Starting payment initiation...');
      final response = await ApiClient().post(
        '/payment/initiate',
        data: {
          'plan': widget.plan.id,
          'billing_cycle': widget.isAnnual ? 'annual' : 'monthly',
        },
      );
      print('✅ Response: $response');

      final paymentUrl = response['payment_url'];
      print('💳 Payment URL: $paymentUrl');

      _webController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setUserAgent(
          'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
        )
        ..setBackgroundColor(Colors.white)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (url) {
              print('🔗 URL: $url');

              if (_paymentHandled) return;

              if (url.contains('success=true') ||
                  url.contains('txn_response_code=APPROVED') ||
                  url.contains('merchant_order_id')) {
                _paymentHandled = true;
                _onPaymentSuccess();
              } else if (url.contains('success=false') ||
                  url.contains('txn_response_code=DECLINED')) {
                _paymentHandled = true;
                _onPaymentFailed();
              }
            },
            onPageFinished: (url) {
              print('✅ PAGE FINISHED: $url');
              setState(() => _isLoading = false);
            },
            onWebResourceError: (error) {
              print('❌ ERROR: ${error.description}');
            },
          ),
        )
        ..loadRequest(Uri.parse(paymentUrl));

      setState(() {});
    } catch (e) {
      print('❌ Error: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  void _onPaymentSuccess() async {
    try {
      await ApiClient().post(
        '/payment/confirm-success',
        data: {
          'plan': widget.plan.id,
          'billing_cycle': widget.isAnnual ? 'annual' : 'monthly',
        },
      );
      print('✅ Plan activated successfully');
    } catch (e) {
      print('❌ Confirm error: $e');
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentResultScreen(success: true, plan: widget.plan),
        ),
      );
    }
  }

  void _onPaymentFailed() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              PaymentResultScreen(success: false, plan: widget.plan),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    AppSizes.init(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, size: 22),
          color: AppColors.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Secure Payment',
              style: TextStyle(
                fontSize: AppSizes.fontMd,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '${widget.plan.name} Plan',
              style: TextStyle(
                fontSize: AppSizes.fontXs,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: AppSizes.md),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.lock_rounded, size: 12, color: AppColors.success),
                const SizedBox(width: 4),
                Text(
                  'Secured',
                  style: TextStyle(
                    fontSize: AppSizes.fontXs,
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_hasError)
            _buildError()
          else if (_webController != null)
            WebViewWidget(controller: _webController!),

          if (_isLoading)
            Container(
              color: AppColors.background,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: AppSizes.md),
                    Text(
                      'Preparing payment...',
                      style: TextStyle(
                        fontSize: AppSizes.fontSm,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: AppColors.error,
            ),
            SizedBox(height: AppSizes.md),
            Text(
              'Payment initialization failed',
              style: TextStyle(
                fontSize: AppSizes.fontLg,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: AppSizes.xs),
            Text(
              _errorMessage ?? 'Please try again',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppSizes.fontSm,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: AppSizes.xl),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _hasError = false;
                  _paymentHandled = false;
                });
                _initiatePayment();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Payment Result Screen ──────────────────────────────────────────────────

class PaymentResultScreen extends StatelessWidget {
  final bool success;
  final PlanModel plan;

  const PaymentResultScreen({
    super.key,
    required this.success,
    required this.plan,
  });

  @override
  Widget build(BuildContext context) {
    AppSizes.init(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSizes.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: (success ? AppColors.success : AppColors.error)
                      .withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  success ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  size: 56,
                  color: success ? AppColors.success : AppColors.error,
                ),
              ),
              SizedBox(height: AppSizes.xl),

              Text(
                success ? '🎉 Payment Successful!' : 'Payment Failed',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: AppSizes.sm),

              Text(
                success
                    ? 'Welcome to ${plan.name}! Your subscription is now active. Enjoy unlimited access to all features.'
                    : 'Your payment was not completed. Please try again or contact support.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppSizes.fontSm,
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),

              if (success) ...[
                SizedBox(height: AppSizes.lg),
                Container(
                  padding: EdgeInsets.all(AppSizes.md),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(AppSizes.cardRadius),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildFeatureRow(
                        '✅ ${plan.diagramsPerMonth == -1 ? 'Unlimited' : plan.diagramsPerMonth} diagrams/month',
                      ),
                      _buildFeatureRow('✅ All diagram types unlocked'),
                      _buildFeatureRow('✅ Premium export formats'),
                    ],
                  ),
                ),
              ],

              SizedBox(height: AppSizes.xl),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (success) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const MainScreen()),
                        (_) => false,
                      );
                    } else {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: success
                        ? AppColors.success
                        : AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                  ),
                  child: Text(
                    success ? 'Start Using Premium 🚀' : 'Try Again',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: AppSizes.fontMd,
                    ),
                  ),
                ),
              ),

              if (!success) ...[
                SizedBox(height: AppSizes.sm),
                TextButton(
                  onPressed: () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
                  child: const Text(
                    'Back to Home',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: AppSizes.fontSm,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
