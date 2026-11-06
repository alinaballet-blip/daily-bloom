
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/nutrition_storage.dart';
import 'pages/calendar_page.dart';
import 'pages/settings_page.dart';

void main() {
  runApp(const DailyBloomApp());
}

class BloomColors {
  static const background = Color(0xFFFCF9F6);
  static const text = Color(0xFF514A50);
  static const secondary = Color(0xFF9B9298);
  static const pink = Color(0xFFF3DCE5);
  static const pinkDark = Color(0xFFB77F98);
  static const purple = Color(0xFFE8DFF2);
  static const purpleDark = Color(0xFF9278AA);
  static const yellow = Color(0xFFF5EBCB);
  static const yellowDark = Color(0xFFB39A54);
  static const peach = Color(0xFFF8E7DD);
  static const peachDark = Color(0xFFBC8C70);
}

class DailyBloomApp extends StatelessWidget {
  const DailyBloomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily Bloom',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: BloomColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: BloomColors.purpleDark,
        ),
      ),
      home: const HomePage(),
    );
  }
}

enum MealType { breakfast, lunch, dinner, snacks }

extension MealInfo on MealType {
  String get label {
    switch (this) {
      case MealType.breakfast:
        return '早餐';
      case MealType.lunch:
        return '午餐';
      case MealType.dinner:
        return '晚餐';
      case MealType.snacks:
        return '加餐';
    }
  }

  String get english {
    switch (this) {
      case MealType.breakfast:
        return 'Breakfast';
      case MealType.lunch:
        return 'Lunch';
      case MealType.dinner:
        return 'Dinner';
      case MealType.snacks:
        return 'Snacks';
    }
  }

  IconData get icon {
    switch (this) {
      case MealType.breakfast:
        return Icons.wb_twilight_rounded;
      case MealType.lunch:
        return Icons.lunch_dining_rounded;
      case MealType.dinner:
        return Icons.dinner_dining_rounded;
      case MealType.snacks:
        return Icons.local_cafe_rounded;
    }
  }

  Color get background {
    switch (this) {
      case MealType.breakfast:
        return BloomColors.pink;
      case MealType.lunch:
        return BloomColors.yellow;
      case MealType.dinner:
        return BloomColors.purple;
      case MealType.snacks:
        return BloomColors.peach;
    }
  }

  Color get accent {
    switch (this) {
      case MealType.breakfast:
        return BloomColors.pinkDark;
      case MealType.lunch:
        return BloomColors.yellowDark;
      case MealType.dinner:
        return BloomColors.purpleDark;
      case MealType.snacks:
        return BloomColors.peachDark;
    }
  }
}

class NutritionData {
  final double calories;
  final double protein;
  final double fat;
  final double carbs;
  final String note;

  const NutritionData({
  required this.calories,
  required this.protein,
  required this.fat,
  required this.carbs,
  this.note = '',
});

  static const zero = NutritionData(
    calories: 0,
    protein: 0,
    fat: 0,
    carbs: 0,
  );

  NutritionData operator +(NutritionData other) {
    return NutritionData(
      calories: calories + other.calories,
      protein: protein + other.protein,
      fat: fat + other.fat,
      carbs: carbs + other.carbs,
    );
  }
}

String displayNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value.toStringAsFixed(1);
}


class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    this.selectedDate,
  });

  final DateTime? selectedDate;

  @override
  State<HomePage> createState() => _HomePageState();
}


class _HomePageState extends State<HomePage> {
  final Map<MealType, NutritionData> records = {};
static const List<String> dailyGreetings = [
  'Take care of your little planet.',
  'Even the smallest rose deserves love.',
  'Leave a little room for wonder.',
  'Your heart knows the way home.',
  'A little care makes things bloom.',
  'There is magic in ordinary days.',
  'Let the stars remind you to dream.',
  'Be patient with the things you grow.',
  'Some treasures are felt, not seen.',
  'May your little world be gentle today.',
  'Water your dreams with kindness.',
  'You are a universe worth caring for.',
];
  
  bool isLoading = true;

String get dailyGreeting {
  final today = DateTime.now();
  final dayNumber = DateTime(today.year, today.month, today.day)
      .difference(DateTime(2020, 1, 1))
      .inDays;

  final index = (dayNumber * 7 + dayNumber ~/ 12) %
      dailyGreetings.length;

  return dailyGreetings[index];
}

String get todayKey {
  final date = widget.selectedDate ?? DateTime.now();

  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');

  return '$year-$month-$day';
}

String get displayDate {
  final date = widget.selectedDate ?? DateTime.now();

  return '${date.year} 年 ${date.month} 月 ${date.day} 日';
}



  @override
  void initState() {
    super.initState();
    loadRecords();
  }

  Future<void> loadRecords() async {
    try {
      final allRecords = await NutritionStorage.load();
      final todayRecords = allRecords[todayKey];

      if (!mounted) return;

      setState(() {
        records.clear();

        if (todayRecords is Map) {
          for (final meal in MealType.values) {
            final data = todayRecords[meal.name];

            if (data is Map) {
              records[meal] = NutritionData(
                calories: (data['calories'] as num).toDouble(),
                protein: (data['protein'] as num).toDouble(),
                fat: (data['fat'] as num).toDouble(),
                carbs: (data['carbs'] as num).toDouble(),
                note: data['note'] as String? ?? '',
              );
            }
          }
        }

        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('讀取紀錄失敗：$error')),
      );
    }
  }

  Future<void> saveRecords() async {
    final allRecords = await NutritionStorage.load();
    final todayRecords = <String, dynamic>{};

    for (final entry in records.entries) {
      todayRecords[entry.key.name] = {
        'calories': entry.value.calories,
        'protein': entry.value.protein,
        'fat': entry.value.fat,
        'carbs': entry.value.carbs,
        'note': entry.value.note,
      };
    }

    allRecords[todayKey] = todayRecords;

    await NutritionStorage.save(allRecords);
  }


  NutritionData get dailyTotal {
    return records.values.fold(
      NutritionData.zero,
      (total, meal) => total + meal,
    );
  }

  Future<void> editMeal(MealType meal) async {
    final result = await showModalBottomSheet<NutritionData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: BloomColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (context) {
        return MealEditor(
          meal: meal,
          initial: records[meal],
        );
      },
    );

    
if (result != null) {
  setState(() {
    records[meal] = result;
  });

  await saveRecords();
}
  }

  Future<void> clearMeal(MealType meal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('清除${meal.label}紀錄？'),
        content: const Text('清除後，當日營養總計也會重新計算。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('確認清除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
  setState(() {
    records.remove(meal);
  });

  await saveRecords();
}
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
    final total = dailyTotal;

    return Scaffold(
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: '首頁',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            label: '月曆',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: '設定',
          ),
        ],
        
onDestinationSelected: (index) {
  if (index == 1) {
    Navigator.push(
      context,
      MaterialPageRoute(
        
builder: (context) => CalendarPage(

onEditDate: (date) async {
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => HomePage(
        selectedDate: date,
      ),
    ),
  );
},

),

      ),
    );
  } else if (index == 2) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => const SettingsPage(),
    ),
  );
}
},

      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: BloomColors.purple,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.spa_rounded,
                        color: BloomColors.purpleDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daily Bloom',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: BloomColors.text,
                          ),
                        ),
                        Text(
                          'YOUR NUTRITION JOURNAL',
                          style: TextStyle(
                            fontSize: 9,
                            letterSpacing: 1.4,
                            color: BloomColors.secondary,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.favorite_border_rounded,
                      color: BloomColors.pinkDark,
                    ),
                  ],
                ),
                const SizedBox(height: 34),
                Text(
                  displayDate,
                  style: const TextStyle(
                    color: BloomColors.secondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
  widget.selectedDate == null
      ? dailyGreeting
      : '編輯當天的營養紀錄 ♡',
                  style: widget.selectedDate == null
    ? GoogleFonts.quicksand(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: BloomColors.text,
      )
    : const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: BloomColors.text,
      ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        BloomColors.pink,
                        BloomColors.purple,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.local_fire_department_rounded,
                            color: BloomColors.pinkDark,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text('今日總熱量'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            displayNumber(total.calories),
                            style: const TextStyle(
                              fontSize: 46,
                              fontWeight: FontWeight.bold,
                              color: BloomColors.text,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(
                              left: 6,
                              bottom: 10,
                            ),
                            child: Text('kcal'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: Colors.white70),
                      const SizedBox(height: 8),
                      Text(
                        '已記錄 ${records.length} / 4 餐'
                        ' · 每一份紀錄，都是對自己的照顧。',
                        style: const TextStyle(
                          fontSize: 12,
                          color: BloomColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                const SectionTitle(
                  title: '營養攝取',
                  subtitle: 'NUTRITION SUMMARY',
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns =
                        constraints.maxWidth >= 520 ? 3 : 2;
                    return GridView.count(
                      crossAxisCount: columns,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.55,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        NutritionCard(
                          label: '蛋白質',
                          value: total.protein,
                          color: BloomColors.purple,
                          accent: BloomColors.purpleDark,
                          icon: Icons.fitness_center_rounded,
                        ),
                        NutritionCard(
                          label: '脂肪',
                          value: total.fat,
                          color: BloomColors.yellow,
                          accent: BloomColors.yellowDark,
                          icon: Icons.water_drop_rounded,
                        ),
                        NutritionCard(
                          label: '碳水化合物',
                          value: total.carbs,
                          color: BloomColors.peach,
                          accent: BloomColors.peachDark,
                          icon: Icons.grain_rounded,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 32),
                const SectionTitle(
                  title: '每日飲食',
                  subtitle: "TODAY'S MEALS",
                ),
                const SizedBox(height: 16),
                ...MealType.values.map((meal) {
                  final data = records[meal];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => editMeal(meal),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFFF0EAE8),
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(13),
                                decoration: BoxDecoration(
                                  color: meal.background,
                                  borderRadius:
                                      BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  meal.icon,
                                  color: meal.accent,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      meal.label,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: BloomColors.text,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      meal.english,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: BloomColors.secondary,
                                      ),
                                    ),
                                    if (data != null && data.note.isNotEmpty) ...[
  const SizedBox(height: 6),
  Text(
    data.note,
    style: const TextStyle(
      fontSize: 12,
      color: BloomColors.secondary,
    ),
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
  ),
],
                                  ],
                                ),
                              ),
                              Text(
                                data == null
                                    ? '尚未記錄'
                                    : '${displayNumber(data.calories)} kcal',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: BloomColors.secondary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                data == null
                                    ? Icons.add_circle_outline
                                    : Icons.edit_outlined,
                                color: meal.accent,
                              ),
                              if (data != null)
                                IconButton(
                                  tooltip: '清除紀錄',
                                  onPressed: () => clearMeal(meal),
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 19,
                                    color: BloomColors.secondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 24),
                const Center(
                  child: Text(
                    'Made with love ♡ Daily Bloom',
                    style: TextStyle(
                      fontSize: 11,
                      color: BloomColors.secondary,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const SectionTitle({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: BloomColors.text,
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            subtitle,
            style: const TextStyle(
              fontSize: 9,
              letterSpacing: 1,
              color: BloomColors.secondary,
            ),
          ),
        ),
      ],
    );
  }
}

class NutritionCard extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final Color accent;
  final IconData icon;

  const NutritionCard({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    required this.accent,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: accent, size: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: BloomColors.text,
                ),
              ),
              const SizedBox(height: 4),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: displayNumber(value),
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        color: accent,
                      ),
                    ),
                    const TextSpan(
                      text: ' g',
                      style: TextStyle(
                        fontSize: 12,
                        color: BloomColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MealEditor extends StatefulWidget {
  final MealType meal;
  final NutritionData? initial;

  const MealEditor({
    super.key,
    required this.meal,
    this.initial,
  });

  @override
  State<MealEditor> createState() => _MealEditorState();
}

class _MealEditorState extends State<MealEditor> {
  final formKey = GlobalKey<FormState>();

  late final TextEditingController caloriesController;
  late final TextEditingController proteinController;
  late final TextEditingController fatController;
  late final TextEditingController carbsController;
  late final TextEditingController noteController;

  @override
  void initState() {
    super.initState();

    String initialValue(double? value) {
      return value == null ? '' : displayNumber(value);
    }

    caloriesController = TextEditingController(
      text: initialValue(widget.initial?.calories),
    );
    proteinController = TextEditingController(
      text: initialValue(widget.initial?.protein),
    );
    fatController = TextEditingController(
      text: initialValue(widget.initial?.fat),
    );
    carbsController = TextEditingController(
      text: initialValue(widget.initial?.carbs),
    );
    noteController = TextEditingController(
  text: widget.initial?.note ?? '',
);
  }

  @override
  void dispose() {
    caloriesController.dispose();
    proteinController.dispose();
    fatController.dispose();
    carbsController.dispose();
    noteController.dispose();
    super.dispose();
  }

  Widget numberField(
    String label,
    String unit,
    TextEditingController controller,
  ) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
      ),
      decoration: InputDecoration(
        labelText: label,
        suffixText: unit,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '請輸入$label';
        }

        final number = double.tryParse(value.trim());

        if (number == null ||
            !number.isFinite ||
            number < 0) {
          return '請輸入有效的非負數字';
        }

        return null;
      },
    );
  }

  void save() {
    if (!formKey.currentState!.validate()) {
      return;
    }

    Navigator.pop(
      context,
      NutritionData(
        calories: double.parse(caloriesController.text.trim()),
        protein: double.parse(proteinController.text.trim()),
        fat: double.parse(fatController.text.trim()),
        carbs: double.parse(carbsController.text.trim()),
        note: noteController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight =
        MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        24,
        20,
        keyboardHeight + 24,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: BloomColors.purple,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  '${widget.initial == null ? '新增' : '編輯'}${widget.meal.label}紀錄',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: BloomColors.text,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '填入 ChatGPT 估算的營養總計 ♡',
                  style: TextStyle(
                    color: BloomColors.secondary,
                  ),
                ),
                const SizedBox(height: 24),
                numberField(
                  '熱量',
                  'kcal',
                  caloriesController,
                ),
                const SizedBox(height: 12),
                numberField(
                  '蛋白質',
                  'g',
                  proteinController,
                ),
                const SizedBox(height: 12),
                numberField(
                  '脂肪',
                  'g',
                  fatController,
                ),
                const SizedBox(height: 12),
                numberField(
                  '碳水化合物',
                  'g',
                  carbsController,
                ),
                const SizedBox(height: 12),
TextFormField(
  controller: noteController,
  maxLines: 3,
  minLines: 2,
  keyboardType: TextInputType.multiline,
  decoration: InputDecoration(
    labelText: '📝 飲食備註',
    hintText: '例如：雞腿便當（無飯）、無糖豆漿',
    alignLabelWithHint: true,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
    ),
  ),
),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: save,
                    style: FilledButton.styleFrom(
                      backgroundColor: BloomColors.purpleDark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('儲存紀錄 ♡'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
