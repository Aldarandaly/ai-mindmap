import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/network/api_client.dart';
import '../data/plan_model.dart';
import 'payment_screen.dart';

class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key});

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  bool _isAnnual = false;
  String _currentPlan = 'free';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentPlan();
  }

  Future<void> _loadCurrentPlan() async {
    try {
      final response = await ApiClient().get('/plan/current');
      setState(() {
        _currentPlan = response['plan'] ?? 'free';
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppColors.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Upgrade Plan',
          style: TextStyle(
            fontSize: AppSizes.fontXl,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(AppSizes.screenPadding),
              child: Column(
                children: [
                  // ── Header ──
                  _buildHeader(),
                  SizedBox(height: AppSizes.lg),

                  // ── Billing Toggle ──
                  _buildBillingToggle(),
                  SizedBox(height: AppSizes.lg),

                  // ── Plans ──
                  ...kPlans.map((plan) => _buildPlanCard(plan)),
                  SizedBox(height: AppSizes.lg),

                  // ── Payment Methods ──
                  _buildPaymentMethods(),
                  SizedBox(height: AppSizes.xl),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, Color(0xFF7C3AED)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.workspace_premium_rounded,
            color: Colors.white,
            size: 32,
          ),
        ),
        SizedBox(height: AppSizes.md),
        const Text(
          'Choose Your Plan',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: AppSizes.xs),
        Text(
          'Unlock unlimited diagrams and premium features',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: AppSizes.fontSm,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildBillingToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusRound),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleOption('Monthly', !_isAnnual),
          _buildToggleOption('Annual  (-30%)', _isAnnual, badge: true),
        ],
      ),
    );
  }

  Widget _buildToggleOption(
    String label,
    bool isSelected, {
    bool badge = false,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _isAnnual = label.contains('Annual')),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.radiusRound),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: AppSizes.fontSm,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard(PlanModel plan) {
    final isCurrentPlan = _currentPlan == plan.id;
    final isFree = plan.id == 'free';
    final price = _isAnnual ? plan.annualPrice : plan.monthlyPrice;
    final period = _isAnnual ? '/year' : '/month';

    final gradients = {
      'free': [const Color(0xFF6B7280), const Color(0xFF4B5563)],
      'pro': [AppColors.primary, const Color(0xFF7C3AED)],
      'enterprise': [const Color(0xFF0D9488), const Color(0xFF0891B2)],
    };

    final gradient = gradients[plan.id]!;

    return Container(
      margin: EdgeInsets.only(bottom: AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(
          color: plan.isPopular ? AppColors.primary : AppColors.border,
          width: plan.isPopular ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          // ── Plan Header ──
          Container(
            padding: EdgeInsets.all(AppSizes.lg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSizes.cardRadius - 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (plan.isPopular)
                        Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '⭐ Most Popular',
                            style: TextStyle(
                              fontSize: AppSizes.fontXs,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      Text(
                        plan.name,
                        style: TextStyle(
                          fontSize: AppSizes.fontXl,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        plan.diagramsPerMonth == -1
                            ? 'Unlimited diagrams'
                            : '${plan.diagramsPerMonth} diagrams/month',
                        style: TextStyle(
                          fontSize: AppSizes.fontSm,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isFree ? 'Free' : '${price} EGP',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    if (!isFree)
                      Text(
                        period,
                        style: TextStyle(
                          fontSize: AppSizes.fontXs,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // ── Features ──
          Padding(
            padding: EdgeInsets.all(AppSizes.md),
            child: Column(
              children: [
                ...plan.features.map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: gradient[0],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          f,
                          style: TextStyle(
                            fontSize: AppSizes.fontSm,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: AppSizes.sm),

                // ── CTA Button ──
                if (isCurrentPlan)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                    child: Center(
                      child: Text(
                        'Current Plan',
                        style: TextStyle(
                          fontSize: AppSizes.fontSm,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                else if (!isFree)
                  GestureDetector(
                    onTap: () => _goToPayment(plan),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: gradient),
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        boxShadow: [
                          BoxShadow(
                            color: gradient[0].withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Upgrade to ${plan.name}',
                          style: TextStyle(
                            fontSize: AppSizes.fontSm,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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

  Widget _buildPaymentMethods() {
    return Container(
      padding: EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            'Accepted Payment Methods',
            style: TextStyle(
              fontSize: AppSizes.fontSm,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: AppSizes.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPaymentBadge('💳 Card'),
              SizedBox(width: AppSizes.sm),
              _buildPaymentBadge('📱 InstaPay'),
              SizedBox(width: AppSizes.sm),
              _buildPaymentBadge('📞 Vodafone'),
            ],
          ),
          SizedBox(height: AppSizes.sm),
          Text(
            'All prices in Egyptian Pounds (EGP)\nAnnual plans save up to 30%',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppSizes.fontXs,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: AppSizes.fontXs,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _goToPayment(PlanModel plan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(plan: plan, isAnnual: _isAnnual),
      ),
    );
  }
}
