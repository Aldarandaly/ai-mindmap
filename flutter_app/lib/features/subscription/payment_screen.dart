import 'package:flutter/material.dart';
import '../../core/services/payment_service.dart';

class PaymentScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const PaymentScreen({super.key, required this.data});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final PaymentService _service = PaymentService();

  final TextEditingController _txController = TextEditingController();

  bool loading = false;

  Future<void> confirm() async {
    setState(() => loading = true);

    await _service.confirmPayment(
      subscriptionId: widget.data['subscription_id'],
      transactionId: _txController.text,
    );

    setState(() => loading = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Payment submitted")),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;

    return Scaffold(
      appBar: AppBar(title: const Text("Payment")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text("Amount: ${data['amount']} EGP"),
            Text("Note: SUB-${data['subscription_id']}"),

            const SizedBox(height: 20),

            TextField(
              controller: _txController,
              decoration: const InputDecoration(
                labelText: "Transaction ID",
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: loading ? null : confirm,
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text("Confirm Payment"),
            ),
          ],
        ),
      ),
    );
  }
}