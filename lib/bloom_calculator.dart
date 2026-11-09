
import 'package:flutter/material.dart';

class BloomCalculator extends StatefulWidget {
  const BloomCalculator({
    super.key,
    required this.initialValue,
  });

  final String initialValue;

  @override
  State<BloomCalculator> createState() => _BloomCalculatorState();
}

class _BloomCalculatorState extends State<BloomCalculator> {
  late String expression;
  
  void calculate() {
    final input = expression.replaceAll('−', '-').replaceAll(' ', '');

    final validPattern = RegExp(
      r'^\d+(\.\d+)?([+-]\d+(\.\d+)?)*$',
    );

    if (!validPattern.hasMatch(input)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('請輸入正確的計算式 ♡'),
        ),
      );
      return;
    }

    final numbers = RegExp(
      r'[+-]?\d+(\.\d+)?',
    ).allMatches(input);

    double total = 0;

    for (final match in numbers) {
      total += double.parse(match.group(0)!);
    }

    if (!total.isFinite || total < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('計算結果不能是負數 ♡'),
        ),
      );
      return;
    }

    setState(() {
      expression = total.toStringAsFixed(2);
      if (expression.endsWith('.00')) {
        expression = expression.substring(0, expression.length - 3);
      } else if (expression.endsWith('0')) {
        expression = expression.substring(0, expression.length - 1);
      }
    });
  }


  @override
  void initState() {
    super.initState();
    expression = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Daily Bloom Calculator ♡',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF856D97),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              
              child: Text(
                expression.isEmpty ? '0' : expression,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 28,
                  color: Color(0xFF514653),
                ),
              ),
            ),

            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.4,
              children: [
                for (final key in [
                  '7', '8', '9', '+',
                  '4', '5', '6', '−',
                  '1', '2', '3', '=',
                  'C', '0', '.', '⌫',
                ])
                  Material(
                    color: key == '='
                        ? const Color(0xFFB399C7)
                        : (key == '+' || key == '−')
                            ? const Color(0xFFEADFF2)
                            : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        setState(() {
                          if (key == 'C') {
                            expression = '';
                          } else if (key == '⌫') {
                            if (expression.isNotEmpty) {
                              expression = expression.substring(
                                0,
                                expression.length - 1,
                              );
                            }
                          } else if (key == '=') {
  calculate();
} else {
  expression += key == '−' ? '-' : key;
}
                        });
                      },
                      child: Center(
                        child: Text(
                          key,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                            color: key == '='
                                ? Colors.white
                                : const Color(0xFF66586D),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),
            SizedBox(
  width: double.infinity,
  child: ElevatedButton(
    onPressed: () {
      final result = double.tryParse(expression);
      if (result != null && result.isFinite && result >= 0) {
        Navigator.pop(context, result.toString());
      }
    },
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFB399C7),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    ),
    child: const Text('套用結果 ♡'),
  ),
),

 
          ],
        ),
      ),
    );
  }
}
