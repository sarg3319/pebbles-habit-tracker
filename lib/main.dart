import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const PebblesApp());
}

class PebblesApp extends StatelessWidget {
  const PebblesApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFFBFBFE),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) => Colors.white),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return Colors.blue[400];
            return Colors.grey[300];
          }),
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

// --- CONSTANTS & HELPERS ---
final List<Color> pebblePalette = [
  Colors.blue[100]!,
  Colors.green[100]!,
  Colors.red[100]!,
  Colors.orange[100]!,
  Colors.purple[100]!,
  Colors.teal[100]!,
  Colors.pink[100]!,
  Colors.amber[100]!,
  Colors.indigo[100]!,
  Colors.grey[200]!,
];

// Reusable Color Picker Widget
class ColorGridPicker extends StatelessWidget {
  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;
  const ColorGridPicker({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: pebblePalette.map((color) {
        return GestureDetector(
          onTap: () => onColorSelected(color),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: selectedColor.value == color.value
                    ? Colors.black54
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// --- DATA MODELS ---
class HabitCategory {
  final String id;
  final String name;
  final Color color;
  HabitCategory({required this.id, required this.name, required this.color});
}

class Habit {
  String id;
  String name;
  String description;
  String categoryId;
  Map<String, bool> completionMap;
  Map<String, String> notesMap;
  bool isStreakHabit;
  bool hasNotes;
  int order;
  bool isSystem;
  bool isVisible;
  bool isFavorite;
  bool showInAnalytics;
  int backgroundColorValue;

  Habit({
    required this.id,
    required this.name,
    this.description = "",
    required this.categoryId,
    required this.completionMap,
    this.notesMap = const {},
    required this.isStreakHabit,
    required this.hasNotes,
    required this.order,
    this.isSystem = false,
    this.isVisible = true,
    this.isFavorite = false,
    this.showInAnalytics = false,
    this.backgroundColorValue = 0xFFFFFFFF,
  });

  // Analytics Logic
  int getThisWeekCount() {
    int count = 0;
    DateTime now = DateTime.now();
    int daysToSubtract = now.weekday - 1;
    DateTime monday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: daysToSubtract));
    for (int i = 0; i <= now.difference(monday).inDays; i++) {
      String ds = DateFormat(
        'yyyy-MM-dd',
      ).format(monday.add(Duration(days: i)));
      if (completionMap[ds] == true) count++;
    }
    return count;
  }

  int getLastWeekCount() {
    int count = 0;
    DateTime now = DateTime.now();
    int daysToMonday = now.weekday - 1;
    DateTime thisMonday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: daysToMonday));
    DateTime lastMonday = thisMonday.subtract(const Duration(days: 7));
    for (int i = 0; i < 7; i++) {
      String ds = DateFormat(
        'yyyy-MM-dd',
      ).format(lastMonday.add(Duration(days: i)));
      if (completionMap[ds] == true) count++;
    }
    return count;
  }

  int getMonthlyCount() {
    int count = 0;
    for (int i = 0; i < 30; i++) {
      String ds = DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime.now().subtract(Duration(days: i)));
      if (completionMap[ds] == true) count++;
    }
    return count;
  }

  int get calculateStreak {
    int streak = 0;
    DateTime date = DateTime.now();
    String todayStr = DateFormat('yyyy-MM-dd').format(date);
    if (completionMap[todayStr] == true) streak++;
    date = date.subtract(const Duration(days: 1));
    while (true) {
      String ds = DateFormat('yyyy-MM-dd').format(date);
      if (completionMap[ds] == true) {
        streak++;
        date = date.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }
}

// --- MAIN NAVIGATION ---
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});
  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('categories')
          .orderBy('name')
          .snapshots(),
      builder: (context, catSnapshot) {
        List<HabitCategory> categories = catSnapshot.hasData
            ? catSnapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return HabitCategory(
                  id: doc.id,
                  name: data['name'] ?? 'Untitled',
                  color: Color(data['colorValue'] ?? Colors.blue.value),
                );
              }).toList()
            : [];

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('habits')
              .orderBy('order')
              .snapshots(),
          builder: (context, habitSnapshot) {
            if (!habitSnapshot.hasData)
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            final habits = habitSnapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return Habit(
                id: doc.id,
                name: data['name'] ?? '',
                description: data['description'] ?? '',
                categoryId: data['categoryId'] ?? '',
                isStreakHabit: data['isStreakHabit'] ?? false,
                hasNotes: data['hasNotes'] ?? false,
                order: data['order'] ?? 0,
                isSystem: data['isSystem'] ?? false,
                isVisible: data['isVisible'] ?? true,
                isFavorite: data['isFavorite'] ?? false,
                showInAnalytics: data['showInAnalytics'] ?? false,
                backgroundColorValue:
                    data['backgroundColorValue'] ?? 0xFFFFFFFF,
                completionMap: Map<String, bool>.from(
                  data['completionMap'] ?? {},
                ),
                notesMap: Map<String, String>.from(data['notesMap'] ?? {}),
              );
            }).toList();

            return Scaffold(
              body: IndexedStack(
                index: _selectedIndex,
                children: [
                  CategoryHomeScreen(habits: habits, categories: categories),
                  HabitCalendarScreen(
                    habits: habits,
                    categories: categories,
                    initialFilterId: 'all',
                  ),
                  InsightsScreen(habits: habits),
                  ManageScreen(habits: habits, categories: categories),
                ],
              ),
              bottomNavigationBar: BottomNavigationBar(
                currentIndex: _selectedIndex,
                type: BottomNavigationBarType.fixed,
                onTap: (index) => setState(() => _selectedIndex = index),
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home_rounded),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.grid_view_rounded),
                    label: 'Board',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.analytics_rounded),
                    label: 'Insights',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.tune_rounded),
                    label: 'Settings',
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// --- INSIGHTS SCREEN ---
class InsightsScreen extends StatelessWidget {
  final List<Habit> habits;
  const InsightsScreen({super.key, required this.habits});

  void _showInsightSettings(BuildContext context, Habit h) {
    Color selectedColor = Color(h.backgroundColorValue);
    bool show = h.showInAnalytics;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDS) => AlertDialog(
          title: Text("Insight Settings: ${h.name}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Background Color:",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ColorGridPicker(
                selectedColor: selectedColor,
                onColorSelected: (c) => setDS(() => selectedColor = c),
              ),
              const SizedBox(height: 20),
              SwitchListTile(
                title: const Text("Show in Insights?"),
                value: show,
                onChanged: (v) => setDS(() => show = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                FirebaseFirestore.instance
                    .collection('habits')
                    .doc(h.id)
                    .update({
                      'backgroundColorValue': selectedColor.value,
                      'showInAnalytics': show,
                    });
                Navigator.pop(context);
              },
              child: const Text("Apply"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final analyticsHabits = habits.where((h) => h.showInAnalytics).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text("Insights"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_chart_rounded),
            onPressed: () => _showAddAnalyticsHabit(context),
          ),
        ],
      ),
      body: analyticsHabits.isEmpty
          ? const Center(child: Text("No insights enabled. Tap + to add."))
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: analyticsHabits.length,
              itemBuilder: (context, i) {
                final h = analyticsHabits[i];
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Color(h.backgroundColorValue),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            h.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              letterSpacing: -0.5,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.palette_outlined, size: 20),
                            onPressed: () => _showInsightSettings(context, h),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _analyticItem("This Week", h.getThisWeekCount()),
                          _analyticItem("Last Week", h.getLastWeekCount()),
                          _analyticItem("30 Days", h.getMonthlyCount()),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  void _showAddAnalyticsHabit(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Enable Insights"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: habits
                .map(
                  (h) => CheckboxListTile(
                    title: Text(h.name),
                    value: h.showInAnalytics,
                    onChanged: (v) {
                      FirebaseFirestore.instance
                          .collection('habits')
                          .doc(h.id)
                          .update({'showInAnalytics': v});
                      Navigator.pop(context);
                    },
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _analyticItem(String label, int value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        Text(
          "$value",
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

// --- HOME SCREEN ---
class CategoryHomeScreen extends StatelessWidget {
  final List<Habit> habits;
  final List<HabitCategory> categories;
  const CategoryHomeScreen({
    super.key,
    required this.habits,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Home")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 150,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.0,
          ),
          children: [
            _buildCategoryButton(
              context,
              "Favorites",
              Colors.red,
              Icons.favorite_rounded,
              'favorites',
            ),
            ...categories.map(
              (cat) => _buildCategoryButton(
                context,
                cat.name,
                cat.color,
                Icons.label_rounded,
                cat.id,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryButton(
    BuildContext context,
    String title,
    Color color,
    IconData icon,
    String filterId,
  ) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HabitCalendarScreen(
            habits: habits,
            categories: categories,
            initialFilterId: filterId,
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- CALENDAR BOARD ---
class HabitCalendarScreen extends StatefulWidget {
  final List<Habit> habits;
  final List<HabitCategory> categories;
  final String initialFilterId;
  const HabitCalendarScreen({
    super.key,
    required this.habits,
    required this.categories,
    required this.initialFilterId,
  });

  @override
  State<HabitCalendarScreen> createState() => _HabitCalendarScreenState();
}

class _HabitCalendarScreenState extends State<HabitCalendarScreen> {
  late String _selectedFilterId;
  final ScrollController _headerHorizontalController = ScrollController();
  final ScrollController _bodyHorizontalController = ScrollController();
  final ScrollController _labelVerticalController = ScrollController();
  final ScrollController _bodyVerticalController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedFilterId = widget.initialFilterId;
    _bodyHorizontalController.addListener(() {
      if (_headerHorizontalController.offset !=
          _bodyHorizontalController.offset)
        _headerHorizontalController.jumpTo(_bodyHorizontalController.offset);
    });
    _bodyVerticalController.addListener(() {
      if (_labelVerticalController.offset != _bodyVerticalController.offset)
        _labelVerticalController.jumpTo(_bodyVerticalController.offset);
    });
  }

  String _getDateStr(int daysAgo) => DateFormat(
    'yyyy-MM-dd',
  ).format(DateTime.now().subtract(Duration(days: daysAgo)));

  @override
  Widget build(BuildContext context) {
    List<Habit> filteredHabits = widget.habits
        .where((h) => h.isVisible)
        .toList();
    if (_selectedFilterId == 'favorites') {
      filteredHabits = filteredHabits
          .where((h) => h.isFavorite || h.isSystem)
          .toList();
    } else if (_selectedFilterId != 'all') {
      filteredHabits = filteredHabits
          .where((h) => h.categoryId == _selectedFilterId || h.isSystem)
          .toList();
    }

    const double labelWidth = 145.0;
    const double cellWidth = 50.0;
    const double rowHeight = 78.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedFilterId == 'favorites' ? "Favorites" : "Board"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('daily_metrics')
            .snapshots(),
        builder: (context, metricSnapshot) {
          final metrics = metricSnapshot.hasData
              ? metricSnapshot.data!.docs
              : [];
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('moods')
                .orderBy('order')
                .snapshots(),
            builder: (context, moodSnapshot) {
              final moodsData = moodSnapshot.hasData
                  ? moodSnapshot.data!.docs
                  : [];
              return Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: labelWidth,
                        height: 40,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 16),
                        child: const Text(
                          "Item",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          controller: _headerHorizontalController,
                          scrollDirection: Axis.horizontal,
                          physics: const NeverScrollableScrollPhysics(),
                          child: Row(
                            children: List.generate(
                              31,
                              (i) => Container(
                                width: cellWidth,
                                height: 40,
                                alignment: Alignment.center,
                                child: Text(
                                  DateFormat('E\nd').format(
                                    DateTime.now().subtract(Duration(days: i)),
                                  ),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        SizedBox(
                          width: labelWidth,
                          child: ListView.builder(
                            controller: _labelVerticalController,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredHabits.length,
                            itemBuilder: (context, i) =>
                                _buildHabitLabel(filteredHabits[i], rowHeight),
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            controller: _bodyHorizontalController,
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: cellWidth * 31,
                              child: ListView.builder(
                                controller: _bodyVerticalController,
                                itemCount: filteredHabits.length,
                                itemBuilder: (context, hIdx) => Row(
                                  children: List.generate(
                                    31,
                                    (dayIdx) => SizedBox(
                                      width: cellWidth,
                                      height: rowHeight,
                                      child: _buildHabitCell(
                                        filteredHabits[hIdx],
                                        dayIdx,
                                        metrics,
                                        moodsData,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHabitLabel(Habit h, double height) {
    final streak = h.calculateStreak;
    final cat = widget.categories.firstWhere(
      (c) => c.id == h.categoryId,
      orElse: () => HabitCategory(id: '', name: '', color: Colors.transparent),
    );
    return Container(
      height: height,
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.05)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  h.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    height: 1.1,
                  ),
                  maxLines: 2,
                ),
              ),
              if (h.isStreakHabit && streak > 0)
                Text(
                  " 🔥$streak",
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          if (cat.name.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: cat.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  cat.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 8.5,
                    color: cat.color.withAlpha(220),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHabitCell(Habit h, int dayIdx, List metrics, List moodsData) {
    final dateStr = _getDateStr(dayIdx);
    final dayData =
        metrics
                .cast<QueryDocumentSnapshot?>()
                .firstWhere((d) => d!.id == dateStr, orElse: () => null)
                ?.data()
            as Map?;
    final cat = widget.categories.firstWhere(
      (c) => c.id == h.categoryId,
      orElse: () => HabitCategory(id: '', name: '', color: Colors.blue),
    );
    bool isDone = h.completionMap[dateStr] ?? false;
    bool hasNote = h.notesMap[dateStr]?.isNotEmpty ?? false;
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.05)),
        ),
      ),
      child: _getHabitWidget(
        h,
        dayIdx,
        dayData,
        moodsData,
        isDone,
        hasNote,
        cat,
        dateStr,
      ),
    );
  }

  Widget _getHabitWidget(
    Habit h,
    int dayIdx,
    Map? dayData,
    List moodsData,
    bool isDone,
    bool hasNote,
    HabitCategory cat,
    String dateStr,
  ) {
    if (h.name == "Mood") {
      String displayEmoji = "❔";
      if (dayData?['mood'] != null) {
        final moodDoc = moodsData.cast<QueryDocumentSnapshot?>().firstWhere(
          (m) => (m!.data() as Map)['name'] == dayData?['mood'],
          orElse: () => null,
        );
        if (moodDoc != null)
          displayEmoji = (moodDoc.data() as Map)['emoji'] ?? "😊";
      }
      return GestureDetector(
        onTap: () => _showMoodDialog(dayIdx),
        child: Center(
          child: Text(displayEmoji, style: const TextStyle(fontSize: 22)),
        ),
      );
    }
    if (h.name == "Sleep")
      return GestureDetector(
        onTap: () => _showSleepDialog(dayIdx),
        child: Center(
          child: Text(
            dayData?['sleep']?.toString() ?? "-",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
    if (h.name == "Diary" || h.name == "Dreams") {
      bool hasVal =
          dayData?[h.name.toLowerCase()] != null &&
          dayData?[h.name.toLowerCase()] != "";
      return IconButton(
        icon: Icon(
          h.name == "Diary" ? Icons.book : Icons.cloud,
          color: hasVal
              ? (h.name == "Diary" ? Colors.blue : Colors.purple)
              : Colors.grey[200],
        ),
        onPressed: () =>
            _showTextEntryDialog(h.name, h.name.toLowerCase(), dayIdx),
      );
    }
    return GestureDetector(
      onTap: () {
        Map<String, bool> newMap = Map.from(h.completionMap);
        newMap[dateStr] = !isDone;
        FirebaseFirestore.instance.collection('habits').doc(h.id).update({
          'completionMap': newMap,
        });
      },
      onLongPress: () => _showHabitNoteDialog(h, dateStr),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              height: 24,
              width: 24,
              decoration: BoxDecoration(
                color: isDone ? cat.color : Colors.grey[100],
                shape: BoxShape.circle,
              ),
            ),
            if (hasNote)
              Positioned(
                top: 10,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showHabitNoteDialog(Habit h, String dateStr) {
    final ctrl = TextEditingController(text: h.notesMap[dateStr] ?? "");
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Note for ${h.name}"),
        content: SizedBox(
          width: double.maxFinite,
          height: 200,
          child: TextField(
            controller: ctrl,
            maxLines: null,
            expands: true,
            textCapitalization:
                TextCapitalization.sentences, // Capitalizes sentences
            autocorrect: false, // Disabled for more control
            enableSuggestions: false, // Disabled to prevent keyboard overlays
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: "Add details or symptoms...",
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Map<String, String> newNotes = Map.from(h.notesMap);
              newNotes[dateStr] = ctrl.text;
              FirebaseFirestore.instance.collection('habits').doc(h.id).update({
                'notesMap': newNotes,
              });
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showTextEntryDialog(String title, String fieldKey, int dayIdx) async {
    final dateStr = _getDateStr(dayIdx);
    final docRef = FirebaseFirestore.instance
        .collection('daily_metrics')
        .doc(dateStr);
    final doc = await docRef.get();
    final ctrl = TextEditingController(
      text: doc.exists ? (doc.data() as Map)[fieldKey] ?? "" : "",
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "$title: ${DateFormat('MMM d').format(DateTime.parse(dateStr))}",
        ),
        content: SizedBox(
          height: 200,
          width: double.maxFinite,
          child: TextField(
            controller: ctrl,
            maxLines: null,
            expands: true,
            textCapitalization: TextCapitalization.sentences,
            autocorrect: false,
            enableSuggestions: false,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: "Start writing...",
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              docRef.set({
                fieldKey: ctrl.text,
                'date': dateStr,
              }, SetOptions(merge: true));
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showSleepDialog(int dayIdx) async {
    final dateStr = _getDateStr(dayIdx);
    final docRef = FirebaseFirestore.instance
        .collection('daily_metrics')
        .doc(dateStr);
    final doc = await docRef.get();
    final ctrl = TextEditingController(
      text: doc.exists ? (doc.data() as Map)['sleep']?.toString() ?? "" : "",
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Sleep Hours"),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(suffixText: "hours"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              double? val = double.tryParse(ctrl.text.replaceFirst(',', '.'));
              docRef.set({
                'sleep': val ?? 0.0,
                'date': dateStr,
              }, SetOptions(merge: true));
              Navigator.pop(context);
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  void _showMoodDialog(int dayIdx) async {
    final dateStr = _getDateStr(dayIdx);
    final docRef = FirebaseFirestore.instance
        .collection('daily_metrics')
        .doc(dateStr);
    showDialog(
      context: context,
      builder: (context) => StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('moods')
            .orderBy('order')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final moods = snapshot.data!.docs;
          return AlertDialog(
            title: const Text("Select Mood"),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: ListView(
                children: moods.map((m) {
                  final data = m.data() as Map;
                  return ListTile(
                    leading: Text(
                      data['emoji'] ?? '?',
                      style: const TextStyle(fontSize: 22),
                    ),
                    title: Text(data['name'] ?? ''),
                    onTap: () {
                      docRef.set({
                        'mood': data['name'],
                        'date': dateStr,
                      }, SetOptions(merge: true));
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}

// --- SETTINGS ---
class ManageScreen extends StatelessWidget {
  final List<Habit> habits;
  final List<HabitCategory> categories;
  const ManageScreen({
    super.key,
    required this.habits,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Settings"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Habits"),
              Tab(text: "Tags"),
              Tab(text: "Moods"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _HabitList(habits: habits, categories: categories),
            _CategoryList(categories: categories),
            _MoodSettingsList(),
          ],
        ),
      ),
    );
  }
}

class _HabitList extends StatelessWidget {
  final List<Habit> habits;
  final List<HabitCategory> categories;
  const _HabitList({required this.habits, required this.categories});

  void _showHabitDialog(BuildContext context, {Habit? habit}) {
    final nameCtrl = TextEditingController(text: habit?.name ?? "");
    final descCtrl = TextEditingController(text: habit?.description ?? "");
    String? selCat =
        habit?.categoryId ??
        (categories.isNotEmpty ? categories.first.id : null);
    bool isStreak = habit?.isStreakHabit ?? false;
    bool isVis = habit?.isVisible ?? true;
    bool isFav = habit?.isFavorite ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDS) => AlertDialog(
          title: Text(habit == null ? "New Habit" : "Edit ${habit.name}"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  autocorrect: false,
                  decoration: const InputDecoration(labelText: "Public Name"),
                ),
                TextField(
                  controller: descCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  autocorrect: false,
                  decoration: const InputDecoration(labelText: "Description"),
                  maxLines: 2,
                ),
                DropdownButtonFormField<String>(
                  value: categories.any((c) => c.id == selCat) ? selCat : null,
                  items: categories
                      .map(
                        (c) =>
                            DropdownMenuItem(value: c.id, child: Text(c.name)),
                      )
                      .toList(),
                  onChanged: (v) => setDS(() => selCat = v),
                  decoration: const InputDecoration(labelText: "Tag"),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text("Favorite"),
                  value: isFav,
                  secondary: const Icon(Icons.favorite, color: Colors.red),
                  onChanged: (v) => setDS(() => isFav = v),
                ),
                SwitchListTile(
                  title: const Text("Show Streak?"),
                  value: isStreak,
                  onChanged: (v) => setDS(() => isStreak = v),
                ),
                SwitchListTile(
                  title: const Text("Visible on Board"),
                  value: isVis,
                  onChanged: (v) => setDS(() => isVis = v),
                ),
              ],
            ),
          ),
          actions: [
            if (habit != null)
              TextButton(
                onPressed: () {
                  FirebaseFirestore.instance
                      .collection('habits')
                      .doc(habit.id)
                      .delete();
                  Navigator.pop(context);
                },
                child: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ElevatedButton(
              onPressed: () {
                final data = {
                  'name': nameCtrl.text,
                  'description': descCtrl.text,
                  'categoryId': selCat ?? '',
                  'isStreakHabit': isStreak,
                  'isVisible': isVis,
                  'isFavorite': isFav,
                };
                if (habit == null) {
                  FirebaseFirestore.instance.collection('habits').add({
                    ...data,
                    'order': habits.length,
                    'completionMap': {},
                    'notesMap': {},
                    'showInAnalytics': false,
                    'backgroundColorValue': 0xFFFFFFFF,
                  });
                } else {
                  FirebaseFirestore.instance
                      .collection('habits')
                      .doc(habit.id)
                      .update(data);
                }
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showHabitDialog(context),
          ),
        ],
      ),
      body: ReorderableListView.builder(
        itemCount: habits.length,
        onReorder: (oldIdx, newIdx) {
          if (newIdx > oldIdx) newIdx -= 1;
          final list = List<Habit>.from(habits);
          final item = list.removeAt(oldIdx);
          list.insert(newIdx, item);
          for (int i = 0; i < list.length; i++) {
            FirebaseFirestore.instance
                .collection('habits')
                .doc(list[i].id)
                .update({'order': i});
          }
        },
        itemBuilder: (context, index) {
          final h = habits[index];
          final cat = categories.firstWhere(
            (c) => c.id == h.categoryId,
            orElse: () =>
                HabitCategory(id: '', name: 'None', color: Colors.grey),
          );
          return ListTile(
            key: ValueKey(h.id),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    h.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                if (h.isSystem)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        "SYSTEM",
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: cat.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    cat.name,
                    style: TextStyle(
                      fontSize: 10,
                      color: cat.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: h.description.isNotEmpty
                ? Text(
                    h.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  )
                : null,
            trailing: h.isFavorite
                ? const Icon(Icons.favorite, color: Colors.red)
                : const Icon(Icons.drag_handle),
            onTap: () => _showHabitDialog(context, habit: h),
          );
        },
      ),
    );
  }
}

class _CategoryList extends StatelessWidget {
  final List<HabitCategory> categories;
  const _CategoryList({required this.categories});

  void _showCategoryDialog(BuildContext context, {HabitCategory? cat}) {
    final nameCtrl = TextEditingController(text: cat?.name ?? "");
    Color selectedColor = cat?.color ?? Colors.blue[100]!;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDS) => AlertDialog(
          title: Text(cat == null ? "New Tag" : "Edit Tag"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameCtrl,
                textCapitalization: TextCapitalization.sentences,
                autocorrect: false,
                decoration: const InputDecoration(labelText: "Tag Name"),
              ),
              const SizedBox(height: 20),
              const Text(
                "Tag Color:",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ColorGridPicker(
                selectedColor: selectedColor,
                onColorSelected: (c) => setDS(() => selectedColor = c),
              ),
            ],
          ),
          actions: [
            if (cat != null)
              TextButton(
                onPressed: () {
                  FirebaseFirestore.instance
                      .collection('categories')
                      .doc(cat.id)
                      .delete();
                  Navigator.pop(context);
                },
                child: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.isNotEmpty) {
                  final data = {
                    'name': nameCtrl.text,
                    'colorValue': selectedColor.value,
                  };
                  if (cat == null) {
                    FirebaseFirestore.instance
                        .collection('categories')
                        .add(data);
                  } else {
                    FirebaseFirestore.instance
                        .collection('categories')
                        .doc(cat.id)
                        .update(data);
                  }
                  Navigator.pop(context);
                }
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCategoryDialog(context),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, i) => ListTile(
          leading: CircleAvatar(backgroundColor: categories[i].color),
          title: Text(categories[i].name),
          onLongPress: () => _showCategoryDialog(context, cat: categories[i]),
        ),
      ),
    );
  }
}

class _MoodSettingsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('moods')
          .orderBy('order')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final moods = snapshot.data!.docs;
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () =>
                    _showMoodEditDialog(context, count: moods.length),
              ),
            ],
          ),
          body: ReorderableListView.builder(
            itemCount: moods.length,
            onReorder: (oldIdx, newIdx) {
              if (newIdx > oldIdx) newIdx -= 1;
              final list = List<DocumentSnapshot>.from(moods);
              final item = list.removeAt(oldIdx);
              list.insert(newIdx, item);
              for (int i = 0; i < list.length; i++) {
                FirebaseFirestore.instance
                    .collection('moods')
                    .doc(list[i].id)
                    .update({'order': i});
              }
            },
            itemBuilder: (context, index) {
              final m = moods[index];
              final data = m.data() as Map;
              return ListTile(
                key: ValueKey(m.id),
                leading: Text(
                  data['emoji'] ?? '?',
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text(data['name'] ?? ''),
                trailing: const Icon(Icons.drag_handle),
                onTap: () => _showMoodEditDialog(context, moodDoc: m),
              );
            },
          ),
        );
      },
    );
  }

  void _showMoodEditDialog(
    BuildContext context, {
    DocumentSnapshot? moodDoc,
    int? count,
  }) {
    final nameCtrl = TextEditingController(
      text: moodDoc != null ? (moodDoc.data() as Map)['name'] : "",
    );
    final emojiCtrl = TextEditingController(
      text: moodDoc != null ? (moodDoc.data() as Map)['emoji'] : "",
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(moodDoc == null ? "New Mood" : "Edit Mood"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emojiCtrl,
              decoration: const InputDecoration(labelText: "Emoji"),
            ),
            TextField(
              controller: nameCtrl,
              textCapitalization: TextCapitalization.sentences,
              autocorrect: false,
              decoration: const InputDecoration(labelText: "Mood Name"),
            ),
          ],
        ),
        actions: [
          if (moodDoc != null)
            TextButton(
              onPressed: () {
                FirebaseFirestore.instance
                    .collection('moods')
                    .doc(moodDoc.id)
                    .delete();
                Navigator.pop(context);
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ElevatedButton(
            onPressed: () {
              final data = {'name': nameCtrl.text, 'emoji': emojiCtrl.text};
              if (moodDoc == null) {
                FirebaseFirestore.instance.collection('moods').add({
                  ...data,
                  'order': count ?? 0,
                });
              } else {
                FirebaseFirestore.instance
                    .collection('moods')
                    .doc(moodDoc.id)
                    .update(data);
              }
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}
