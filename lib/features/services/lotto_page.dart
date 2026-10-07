import 'dart:math';

import 'package:flutter/material.dart';

class LottoPage extends StatefulWidget {
  const LottoPage({super.key});

  @override
  State<LottoPage> createState() => _LottoPageState();
}

class _LottoPageState extends State<LottoPage> {
  final Set<int> _selectedNumbers = {};

  List<int> _generatedNumbers = [];

  final List<List<int>> _history = [];

  void _toggleNumber(int number) {
    setState(() {
      if (_selectedNumbers.contains(number)) {
        _selectedNumbers.remove(number);
        return;
      }

      if (_selectedNumbers.length >= 6) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('최대 6개까지 선택할 수 있습니다.')));

        return;
      }

      _selectedNumbers.add(number);
    });
  }

  void _generateAuto() {
    final random = Random();

    final numbers = <int>{};

    while (numbers.length < 6) {
      numbers.add(random.nextInt(45) + 1);
    }

    final result = numbers.toList()..sort();

    setState(() {
      _generatedNumbers = result;

      _history.insert(0, List<int>.from(result));
    });
  }

  void _generateSemiAuto() {
    if (_selectedNumbers.length >= 6) {
      _saveSelectedNumbers();

      return;
    }

    final random = Random();

    final numbers = Set<int>.from(_selectedNumbers);

    while (numbers.length < 6) {
      numbers.add(random.nextInt(45) + 1);
    }

    final result = numbers.toList()..sort();

    setState(() {
      _generatedNumbers = result;

      _history.insert(0, List<int>.from(result));
    });
  }

  void _saveSelectedNumbers() {
    if (_selectedNumbers.length != 6) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('수동 선택은 번호 6개를 선택해주세요.')));

      return;
    }

    final result = _selectedNumbers.toList()..sort();

    setState(() {
      _generatedNumbers = result;

      _history.insert(0, List<int>.from(result));
    });
  }

  void _clear() {
    setState(() {
      _selectedNumbers.clear();

      _generatedNumbers = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('로또 6/45 DEMO')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    '포트폴리오용 번호 생성 시뮬레이터',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '실제 복권 구매 또는 발행 기능은 제공하지 않습니다.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            '번호 선택',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemCount: 45,
            itemBuilder: (context, index) {
              final number = index + 1;

              final selected = _selectedNumbers.contains(number);

              return InkWell(
                onTap: () {
                  _toggleNumber(number);
                },
                borderRadius: BorderRadius.circular(100),
                child: CircleAvatar(
                  child: Text(
                    '$number',
                    style: TextStyle(
                      fontWeight: selected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          Text('선택한 번호: ${_selectedNumbers.length}/6'),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _clear,
                  child: const Text('초기화'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: _saveSelectedNumbers,
                  child: const Text('수동'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: FilledButton.tonal(
                  onPressed: _generateSemiAuto,
                  child: const Text('반자동'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: _generateAuto,
                  child: const Text('자동'),
                ),
              ),
            ],
          ),

          if (_generatedNumbers.isNotEmpty) ...[
            const SizedBox(height: 32),

            const Text(
              '생성 결과',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _generatedNumbers.map((number) {
                return CircleAvatar(
                  radius: 24,
                  child: Text(
                    '$number',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              }).toList(),
            ),
          ],

          if (_history.isNotEmpty) ...[
            const SizedBox(height: 32),

            const Text(
              '최근 생성 기록',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            ..._history.take(5).map((numbers) {
              return ListTile(
                leading: const Icon(Icons.casino_outlined),
                title: Text(numbers.join(' · ')),
              );
            }),
          ],
        ],
      ),
    );
  }
}
