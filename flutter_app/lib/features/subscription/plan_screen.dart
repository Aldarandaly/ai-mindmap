import 'package:flutter/material.dart';
import '../../core/services/payment_service.dart';
import '../subscription/payment_screen.dart';

class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key});

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  final PaymentService _service = PaymentService();

  bool _isAnnual = false;
  bool _loading = true;

  String currentPlan = "free";

  @override
  void initState() {
    super.initState();

    // ✅ SAFE CALL (prevents freeze)
    Future.microtask(() => loadPlan());
  }

  Future<void> loadPlan() async {
    try {
      final data = await _service.getCurrentPlan()
          .timeout(const Duration(seconds: 4));

      if (!mounted) return;

      setState(() {
        currentPlan = data['plan'] ?? "free";
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      // ✅ IMPORTANT: NEVER BLOCK UI
      setState(() {
        currentPlan = "free";
        _loading = false;
      });

      debugPrint("getCurrentPlan error: $e");
    }
  }

  int get _proPrice => _isAnnual ? (799 / 12).round() : 99;
  int get _entPrice => _isAnnual ? (2499 / 12).round() : 299;

  Future<void> startPayment(String plan) async {
    try {
      final method = await showModalBottomSheet<String>(
        context: context,
        builder: (_) => _paymentSheet(),
      );

      if (method == null) return;

      final res = await _service.initiatePayment(
        plan: plan,
        billingCycle: _isAnnual ? 'annual' : 'monthly',
        paymentMethod: method,
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentScreen(data: res),
        ),
      );
    } catch (e) {
      debugPrint("Payment error: $e");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Payment failed")),
        );
      }
    }
  }

  Widget _paymentSheet() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text("InstaPay"),
            onTap: () => Navigator.pop(context, "instapay"),
          ),
          ListTile(
            title: const Text("Vodafone Cash"),
            onTap: () => Navigator.pop(context, "vodafone"),
          ),
          ListTile(
            title: const Text("Card"),
            onTap: () => Navigator.pop(context, "card"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Plans")),

      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text("Current Plan: $currentPlan"),

                const SizedBox(height: 20),

                planCard(
                  title: "Free",
                  price: "0",
                  onTap: () {},
                ),

                const SizedBox(height: 16),

                planCard(
                  title: "Pro",
                  price: "$_proPrice EGP",
                  onTap: () => startPayment("pro"),
                ),

                const SizedBox(height: 16),

                planCard(
                  title: "Enterprise",
                  price: "$_entPrice EGP",
                  onTap: () => startPayment("enterprise"),
                ),
              ],
            ),
    );
  }

  Widget planCard({
    required String title,
    required String price,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(price),
        trailing: ElevatedButton(
          onPressed: onTap,
          child: const Text("Select"),
        ),
      ),
    );
  }
}