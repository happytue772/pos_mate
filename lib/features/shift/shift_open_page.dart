import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/shift_provider.dart';

class ShiftOpenPage extends StatefulWidget {
  const ShiftOpenPage({super.key});

  @override
  State<ShiftOpenPage> createState() => _ShiftOpenPageState();
}

class _ShiftOpenPageState extends State<ShiftOpenPage> {
  final TextEditingController _openingCashController = TextEditingController(
    text: '100000',
  );

  @override
  void dispose() {
    _openingCashController.dispose();
    super.dispose();
  }

  void _startShift() {
    final openingCash = int.tryParse(_openingCashController.text);

    if (openingCash == null || openingCash < 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('시재금을 올바르게 입력해주세요.')));
      return;
    }

    final user = context.read<AuthProvider>().currentUser;

    if (user == null) {
      return;
    }

    final success = context.read<ShiftProvider>().startShift(
      user: user,
      openingCash: openingCash,
    );

    if (!success) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('이미 진행 중인 근무가 있습니다.')));
      return;
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('근무 시작')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('근무 시작 전 금고의 시재금을 입력해주세요.'),
          const SizedBox(height: 20),
          TextField(
            controller: _openingCashController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '시재금',
              suffixText: '원',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: _startShift, child: const Text('근무 시작')),
        ],
      ),
    );
  }
}
