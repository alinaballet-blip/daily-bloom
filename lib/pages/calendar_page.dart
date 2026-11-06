
import 'package:flutter/material.dart';
import '../services/nutrition_storage.dart';


class CalendarPage extends StatefulWidget {
  const CalendarPage({
    super.key,
    this.onEditDate,
  });

  final Future<void> Function(DateTime date)? onEditDate;

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}


class _CalendarPageState extends State<CalendarPage> {
  late DateTime selectedMonth;
  
  Map<String, dynamic> allRecords = {};
  bool isLoading = true;

  Future<void> loadRecords() async {
    try {
      final saved = await NutritionStorage.load();

      if (!mounted) return;

      setState(() {
        allRecords = saved;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('讀取月曆資料失敗：$error')),
      );
    }
  }

  String dateKey(int day) {
    final year = selectedMonth.year.toString().padLeft(4, '0');
    final month = selectedMonth.month.toString().padLeft(2, '0');
    final date = day.toString().padLeft(2, '0');

    return '$year-$month-$date';
  }

  double? caloriesForDay(int day) {
    final dayRecords = allRecords[dateKey(day)];

    if (dayRecords is! Map || dayRecords.isEmpty) {
      return null;
    }

    double total = 0;

    for (final meal in dayRecords.values) {
      if (meal is Map && meal['calories'] is num) {
        total += (meal['calories'] as num).toDouble();
      }
    }

    return total;
  }
  
int get recordedDaysInMonth {
  final daysInMonth = DateTime(
    selectedMonth.year,
    selectedMonth.month + 1,
    0,
  ).day;

  int count = 0;

  for (int day = 1; day <= daysInMonth; day++) {
    if (caloriesForDay(day) != null) {
      count++;
    }
  }

  return count;
}

double get averageCaloriesInMonth {
  final daysInMonth = DateTime(
    selectedMonth.year,
    selectedMonth.month + 1,
    0,
  ).day;

  double totalCalories = 0;
  int recordedDays = 0;

  for (int day = 1; day <= daysInMonth; day++) {
    final calories = caloriesForDay(day);

    if (calories != null) {
      totalCalories += calories;
      recordedDays++;
    }
  }

  if (recordedDays == 0) {
    return 0;
  }

  return totalCalories / recordedDays;
}
double averageMacroInMonth(String nutrient) {
  final daysInMonth = DateTime(
    selectedMonth.year,
    selectedMonth.month + 1,
    0,
  ).day;

  double total = 0;

  for (int day = 1; day <= daysInMonth; day++) {
    final dayRecords = allRecords[dateKey(day)];

    if (dayRecords is! Map) continue;

    for (final meal in dayRecords.values) {
      if (meal is Map && meal[nutrient] is num) {
        total += (meal[nutrient] as num).toDouble();
      }
    }
  }

  if (recordedDaysInMonth == 0) {
    return 0;
  }

  return total / recordedDaysInMonth;
}



void showDayDetails(int day) {
  final records = allRecords[dateKey(day)];

  double calories = 0;
  double protein = 0;
  double fat = 0;
  double carbs = 0;

  final mealNames = {
    'breakfast': '早餐',
    'lunch': '午餐',
    'dinner': '晚餐',
    'snacks': '加餐',
  };

  final mealWidgets = <Widget>[];

  if (records is Map) {
    for (final entry in mealNames.entries) {
      final meal = records[entry.key];

      if (meal is! Map) continue;

      final mealCalories = (meal['calories'] as num?)?.toDouble() ?? 0;
      final mealProtein = (meal['protein'] as num?)?.toDouble() ?? 0;
      final mealFat = (meal['fat'] as num?)?.toDouble() ?? 0;
      final mealCarbs = (meal['carbs'] as num?)?.toDouble() ?? 0;

      calories += mealCalories;
      protein += mealProtein;
      fat += mealFat;
      carbs += mealCarbs;

      mealWidgets.add(
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(entry.value),
          trailing: Text(
            '${mealCalories.toStringAsFixed(0)} kcal',
          ),
        ),
      );
    }
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${selectedMonth.month} 月 $day 日・營養紀錄',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Column(
                    children: [
                      const Text('當日總熱量'),
                      const SizedBox(height: 6),
                      Text(
                        '${calories.toStringAsFixed(0)} kcal',
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB77F98),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text('蛋白質\n${protein.toStringAsFixed(1)} g',
                        textAlign: TextAlign.center),
                    Text('脂肪\n${fat.toStringAsFixed(1)} g',
                        textAlign: TextAlign.center),
                    Text('碳水\n${carbs.toStringAsFixed(1)} g',
                        textAlign: TextAlign.center),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                if (mealWidgets.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text('這一天還沒有營養紀錄 🌱'),
                    ),
                  )
                else
                  ...mealWidgets,
                  
const SizedBox(height: 20),
SizedBox(
  width: double.infinity,
  child: FilledButton.icon(
    onPressed: widget.onEditDate == null
        ? null
              : () async {
            final date = DateTime(
              selectedMonth.year,
              selectedMonth.month,
              day,
            );

            

Navigator.pop(context);

await widget.onEditDate!(date);

if (!mounted) return;

await loadRecords();


          },
    icon: const Icon(Icons.edit_outlined),
    label: const Text('編輯當天紀錄'),
  ),
),

              ],
            ),
          ),
        ),
      );
    },
  );
}


  @override
void initState() {
  super.initState();

  final now = DateTime.now();
  selectedMonth = DateTime(now.year, now.month);

  loadRecords();
}

  void changeMonth(int offset) {
    setState(() {
      selectedMonth = DateTime(
        selectedMonth.year,
        selectedMonth.month + offset,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
  return const Scaffold(
    body: Center(
      child: CircularProgressIndicator(),
    ),
  );
}
    final firstDay = DateTime(
      selectedMonth.year,
      selectedMonth.month,
      1,
    );

    final daysInMonth = DateTime(
      selectedMonth.year,
      selectedMonth.month + 1,
      0,
    ).day;

    final startOffset = firstDay.weekday % 7;
    final cellCount = ((startOffset + daysInMonth + 6) ~/ 7) * 7;

    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F6),
      appBar: AppBar(
        title: const Text('營養月曆'),
        backgroundColor: const Color(0xFFFCF9F6),
        centerTitle: true,
      ),
      body: Center(
        child: SizedBox(
  width: 640,
  child: Offstage(
  offstage: false,
  child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => changeMonth(-1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text(
                    '${selectedMonth.year} 年 '
                    '${selectedMonth.month} 月',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF514A50),
                    ),
                  ),
                  IconButton(
                    onPressed: () => changeMonth(1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: ['日', '一', '二', '三', '四', '五', '六']
                    .map(
                      (day) => Expanded(
                        child: Center(
                          child: Text(
                            day,
                            style: const TextStyle(
                              color: Color(0xFF9B9298),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cellCount,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  crossAxisSpacing: 5,
                  mainAxisSpacing: 5,
                  childAspectRatio: 0.9,
                ),
                itemBuilder: (context, index) {
                  final day = index - startOffset + 1;

                  if (day < 1 || day > daysInMonth) {
                    return const SizedBox.shrink();
                  }

                  final today = DateTime.now();

                  final isToday =
                      today.year == selectedMonth.year &&
                      today.month == selectedMonth.month &&
                      today.day == day;

                  
final calories = caloriesForDay(day);

return InkWell(
  onTap: () => showDayDetails(day),
  borderRadius: BorderRadius.circular(12),
  child: Container(
  decoration: BoxDecoration(
    color: isToday
        ? const Color(0xFFE8DFF2)
        : calories != null
            ? const Color(0xFFF3DCE5)
            : Colors.white,
    borderRadius: BorderRadius.circular(12),
  ),
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        '$day',
        style: TextStyle(
          fontWeight: isToday
              ? FontWeight.bold
              : FontWeight.normal,
          color: const Color(0xFF514A50),
        ),
      ),
      if (calories != null) ...[
  const SizedBox(height: 4),
  const Icon(
    Icons.filter_vintage_outlined,
    size: 18,
    color: Color(0xFFAD83CC),
  ),
],
    ],
  ),
  ), 
);
                },
              ),
              
const SizedBox(height: 24),
const Text(
  '🌷 本月營養小結',
  style: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Color(0xFF514A50),
  ),
),

const SizedBox(height: 12),
Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: const Color(0xFFF3EAF8),
    borderRadius: BorderRadius.circular(16),
  ),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      const Text(
        '本月有紀錄天數',
        style: TextStyle(
          fontSize: 14,
          color: Color(0xFF514A50),
        ),
      ),
      Text(
        '$recordedDaysInMonth 天',
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFFB77F98),
        ),
      ),
    ],
  ),
),




              const SizedBox(height: 24),
              const Center(
                child: Text(
                  '每一天的紀錄，都是一點點成長 ♡',
                  style: TextStyle(
                    color: Color(0xFF9B9298),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ), // Center
); // Scaffold
}
}
