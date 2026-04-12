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
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

// --- FIXED LUCID COLOR PICKER ---
class LucidColorPicker extends StatefulWidget {
  final Color initialColor;
  final ValueChanged<Color> onColorChanged;
  const LucidColorPicker({
    super.key,
    required this.initialColor,
    required this.onColorChanged,
  });

  @override
  State<LucidColorPicker> createState() => _LucidColorPickerState();
}

class _LucidColorPickerState extends State<LucidColorPicker> {
  late HSVColor hsvColor;

  @override
  void initState() {
    super.initState();
    hsvColor = HSVColor.fromColor(widget.initialColor);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onPanUpdate: (details) {
            RenderBox box = context.findRenderObject() as RenderBox;
            Offset localOffset = box.globalToLocal(details.globalPosition);
            setState(() {
              double s = (localOffset.dx / 220).clamp(0.0, 1.0);
              double v = 1.0 - (localOffset.dy / 220).clamp(0.0, 1.0);
              hsvColor = hsvColor.withSaturation(s).withValue(v);
              widget.onColorChanged(hsvColor.toColor());
            });
          },
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: hsvColor.withSaturation(1).withValue(1).toColor(),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    gradient: const LinearGradient(
                      colors: [Colors.white, Colors.transparent],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    gradient: const LinearGradient(
                      colors: [Colors.transparent, Colors.black],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                Positioned(
                  left: hsvColor.saturation * 220 - 12,
                  top: (1 - hsvColor.value) * 220 - 12,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      color: hsvColor.toColor(),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          "Hue Selection",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        Slider(
          value: hsvColor.hue,
          min: 0,
          max: 360,
          activeColor: Colors.blueGrey,
          onChanged: (v) => setState(() {
            hsvColor = hsvColor.withHue(v);
            widget.onColorChanged(hsvColor.toColor());
          }),
        ),
      ],
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

  int getWeeklyCount() {
    int count = 0;
    DateTime now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      String ds = DateFormat(
        'yyyy-MM-dd',
      ).format(now.subtract(Duration(days: i)));
      if (completionMap[ds] == true) count++;
    }
    return count;
  }

  int getMonthlyCount() {
    int count = 0;
    DateTime now = DateTime.now();
    for (int i = 0; i < 30; i++) {
      String ds = DateFormat(
        'yyyy-MM-dd',
      ).format(now.subtract(Duration(days: i)));
      if (completionMap[ds] == true) count++;
    }
    return count;
  }

  int get calculateStreak {
    int streak = 0;
    DateTime date = DateTime.now();
    while (completionMap[DateFormat('yyyy-MM-dd').format(date)] == true) {
      streak++;
      date = date.subtract(const Duration(days: 1));
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

// --- INSIGHTS ---
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
          title: Text("Module Color: ${h.name}"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min, // Fixed: Corrected MainAxisSize
              children: [
                LucidColorPicker(
                  initialColor: selectedColor,
                  onColorChanged: (c) => selectedColor = c,
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  title: const Text("Show in Insights"),
                  value: show,
                  onChanged: (v) => setDS(() => show = v),
                ),
              ],
            ),
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
      appBar: AppBar(title: const Text("Insights")),
      body: analyticsHabits.isEmpty
          ? const Center(
              child: Text("Enable 'Insights' for habits in Settings"),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: analyticsHabits.length,
              itemBuilder: (context, i) {
                final h = analyticsHabits[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Color(h.backgroundColorValue),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
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
                              fontSize: 20,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.palette_outlined),
                            onPressed: () => _showInsightSettings(context, h),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _analyticItem("7 Days", h.getWeeklyCount()),
                          _analyticItem("30 Days", h.getMonthlyCount()),
                          _analyticItem("Streak", h.calculateStreak),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _analyticItem(String label, int value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "$value",
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
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
      appBar: AppBar(title: const Text("Pebbles")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: GridView(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 160,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.0,
          ),
          children: [
            _buildCatCard(
              context,
              "Favorites",
              Colors.red,
              Icons.favorite_rounded,
              'favorites',
            ),
            ...categories.map(
              (cat) => _buildCatCard(
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

  Widget _buildCatCard(
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
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// --- THE BOARD (CALENDAR) ---
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
  final ScrollController _hHead = ScrollController();
  final ScrollController _hBody = ScrollController();
  final ScrollController _vLabel = ScrollController();
  final ScrollController _vBody = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedFilterId = widget.initialFilterId;
    _hBody.addListener(() => _hHead.jumpTo(_hBody.offset));
    _vBody.addListener(() => _vLabel.jumpTo(_vBody.offset));
  }

  @override
  Widget build(BuildContext context) {
    List<Habit> filtered = widget.habits.where((h) => h.isVisible).toList();
    if (_selectedFilterId == 'favorites') {
      filtered = filtered.where((h) => h.isFavorite || h.isSystem).toList();
    } else if (_selectedFilterId != 'all') {
      filtered = filtered
          .where((h) => h.categoryId == _selectedFilterId || h.isSystem)
          .toList();
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Board")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('daily_metrics')
            .snapshots(),
        builder: (context, metricSnap) {
          final metrics = metricSnap.hasData ? metricSnap.data!.docs : [];
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('moods')
                .orderBy('order')
                .snapshots(),
            builder: (context, moodSnap) {
              final moods = moodSnap.hasData ? moodSnap.data!.docs : [];
              return Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 130,
                        height: 50,
                        padding: const EdgeInsets.only(left: 16),
                        alignment: Alignment.centerLeft,
                        child: const Text(
                          "Item",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          controller: _hHead,
                          scrollDirection: Axis.horizontal,
                          physics: const NeverScrollableScrollPhysics(),
                          child: Row(
                            children: List.generate(
                              31,
                              (i) => Container(
                                width: 55,
                                height: 50,
                                alignment: Alignment.center,
                                child: Text(
                                  DateFormat('dd\nE').format(
                                    DateTime.now().subtract(Duration(days: i)),
                                  ),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    height: 1.2,
                                  ),
                                  textAlign: TextAlign.center,
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
                          width: 130,
                          child: ListView.builder(
                            controller: _vLabel,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filtered.length,
                            itemBuilder: (context, i) {
                              final h = filtered[i];
                              final cat = widget.categories.firstWhere(
                                (c) => c.id == h.categoryId,
                                orElse: () => HabitCategory(
                                  id: '',
                                  name: '',
                                  color: Colors.transparent,
                                ),
                              );
                              return Container(
                                height: 70,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                alignment: Alignment.centerLeft,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      h.name,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (cat.name.isNotEmpty)
                                      Container(
                                        margin: const EdgeInsets.only(top: 2),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: cat.color.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          cat.name,
                                          style: TextStyle(
                                            fontSize: 8,
                                            color: cat.color,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            controller: _hBody,
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: 31 * 55,
                              child: ListView.builder(
                                controller: _vBody,
                                itemCount: filtered.length,
                                itemBuilder: (context, hIdx) => Row(
                                  children: List.generate(
                                    31,
                                    (dIdx) => _buildGridCell(
                                      filtered[hIdx],
                                      dIdx,
                                      metrics,
                                      moods,
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

  Widget _buildGridCell(Habit h, int dIdx, List metrics, List moods) {
    final ds = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime.now().subtract(Duration(days: dIdx)));

    // SAFE FIND: Avoiding TypeErrors
    Map? dayData;
    for (var m in metrics) {
      if (m.id == ds) {
        dayData = m.data() as Map?;
        break;
      }
    }

    if (h.name == "Mood") {
      String emoji = "❔";
      if (dayData?['mood'] != null) {
        for (var m in moods) {
          if (m['name'] == dayData?['mood']) {
            emoji = m['emoji'];
            break;
          }
        }
      }
      return GestureDetector(
        onTap: () => _showMoodPicker(ds, moods),
        child: Container(
          width: 55,
          height: 70,
          decoration: _cellBorder(),
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 22)),
          ),
        ),
      );
    }

    if (h.name == "Sleep") {
      return GestureDetector(
        onTap: () => _showSleepEntry(ds, dayData?['sleep']),
        child: Container(
          width: 55,
          height: 70,
          decoration: _cellBorder(),
          child: Center(
            child: Text(
              dayData?['sleep']?.toString() ?? "-",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );
    }

    if (h.name == "Diary" || h.name == "Dreams") {
      bool hasText = dayData?[h.name.toLowerCase()]?.isNotEmpty ?? false;
      return GestureDetector(
        onTap: () => _showTextEntry(
          h.name,
          h.name.toLowerCase(),
          ds,
          dayData?[h.name.toLowerCase()] ?? "",
        ),
        child: Container(
          width: 55,
          height: 70,
          decoration: _cellBorder(),
          child: Icon(
            h.name == "Diary" ? Icons.book : Icons.cloud,
            color: hasText ? Colors.blue : Colors.grey[200],
          ),
        ),
      );
    }

    bool isDone = h.completionMap[ds] ?? false;
    final cat = widget.categories.firstWhere(
      (c) => c.id == h.categoryId,
      orElse: () => HabitCategory(id: '', name: '', color: Colors.blue),
    );

    return GestureDetector(
      onTap: () {
        Map<String, bool> newMap = Map.from(h.completionMap);
        newMap[ds] = !isDone;
        FirebaseFirestore.instance.collection('habits').doc(h.id).update({
          'completionMap': newMap,
        });
      },
      child: Container(
        width: 55,
        height: 70,
        decoration: _cellBorder(),
        child: Center(
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDone ? cat.color : Colors.grey[100],
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _cellBorder() => BoxDecoration(
    border: Border(
      bottom: BorderSide(color: Colors.grey.withOpacity(0.1)),
      right: BorderSide(color: Colors.grey.withOpacity(0.1)),
    ),
  );

  void _showMoodPicker(String ds, List moods) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Daily Mood"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: moods.map((m) {
              return ListTile(
                leading: Text(m['emoji'], style: const TextStyle(fontSize: 24)),
                title: Text(m['name']),
                onTap: () {
                  FirebaseFirestore.instance
                      .collection('daily_metrics')
                      .doc(ds)
                      .set({
                        'mood': m['name'],
                        'date': ds,
                      }, SetOptions(merge: true));
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _showSleepEntry(String ds, dynamic current) {
    final ctrl = TextEditingController(text: current?.toString() ?? "");
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Sleep Hours"),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              FirebaseFirestore.instance
                  .collection('daily_metrics')
                  .doc(ds)
                  .set({
                    'sleep': double.tryParse(ctrl.text) ?? 0.0,
                    'date': ds,
                  }, SetOptions(merge: true));
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showTextEntry(String title, String key, String ds, String initial) {
    final ctrl = TextEditingController(text: initial);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("$title ($ds)"),
        content: TextField(
          controller: ctrl,
          maxLines: 10,
          textCapitalization: TextCapitalization.sentences,
          autocorrect: false,
          enableSuggestions: false,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: "Start typing...",
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              FirebaseFirestore.instance
                  .collection('daily_metrics')
                  .doc(ds)
                  .set({key: ctrl.text, 'date': ds}, SetOptions(merge: true));
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
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
            _MoodList(),
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
    String? selCat = (habit != null && habit.categoryId.isNotEmpty)
        ? habit.categoryId
        : (categories.isNotEmpty ? categories.first.id : null);
    bool isVis = habit?.isVisible ?? true;
    bool isFav = habit?.isFavorite ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDS) => AlertDialog(
          title: Text(habit == null ? "New Habit" : "Edit Habit"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  autocorrect: false,
                  decoration: const InputDecoration(labelText: "Name"),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selCat,
                  decoration: const InputDecoration(labelText: "Tag"),
                  items: categories
                      .map(
                        (c) =>
                            DropdownMenuItem(value: c.id, child: Text(c.name)),
                      )
                      .toList(),
                  onChanged: (v) => setDS(() => selCat = v),
                ),
                SwitchListTile(
                  title: const Text("Favorite"),
                  value: isFav,
                  onChanged: (v) => setDS(() => isFav = v),
                ),
                SwitchListTile(
                  title: const Text("Visible"),
                  value: isVis,
                  onChanged: (v) => setDS(() => isVis = v),
                ),
              ],
            ),
          ),
          actions: [
            if (habit != null && !habit.isSystem)
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
                  'categoryId': selCat,
                  'isVisible': isVis,
                  'isFavorite': isFav,
                };
                if (habit == null)
                  FirebaseFirestore.instance.collection('habits').add({
                    ...data,
                    'order': habits.length,
                    'completionMap': {},
                    'showInAnalytics': false,
                    'backgroundColorValue': 0xFFFFFFFF,
                    'isSystem': false,
                  });
                else
                  FirebaseFirestore.instance
                      .collection('habits')
                      .doc(habit.id)
                      .update(data);
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
  Widget build(BuildContext context) => Scaffold(
    floatingActionButton: FloatingActionButton(
      onPressed: () => _showHabitDialog(context),
      child: const Icon(Icons.add),
    ),
    body: ListView.builder(
      itemCount: habits.length,
      itemBuilder: (context, i) => ListTile(
        title: Text(habits[i].name),
        onTap: () => _showHabitDialog(context, habit: habits[i]),
      ),
    ),
  );
}

class _CategoryList extends StatelessWidget {
  final List<HabitCategory> categories;
  const _CategoryList({required this.categories});

  void _showCategoryDialog(BuildContext context, {HabitCategory? cat}) {
    final nameCtrl = TextEditingController(text: cat?.name ?? "");
    Color tempColor = cat?.color ?? Colors.blue;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDS) => AlertDialog(
          title: Text(cat == null ? "New Tag" : "Edit Tag"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  autocorrect: false,
                  decoration: const InputDecoration(labelText: "Tag Name"),
                ),
                const SizedBox(height: 24),
                LucidColorPicker(
                  initialColor: tempColor,
                  onColorChanged: (c) => tempColor = c,
                ),
              ],
            ),
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
                FirebaseFirestore.instance
                    .collection('categories')
                    .doc(
                      cat?.id ??
                          DateTime.now().millisecondsSinceEpoch.toString(),
                    )
                    .set({
                      'name': nameCtrl.text,
                      'colorValue': tempColor.value,
                    }, SetOptions(merge: true));
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
  Widget build(BuildContext context) => Scaffold(
    floatingActionButton: FloatingActionButton(
      onPressed: () => _showCategoryDialog(context),
      child: const Icon(Icons.add),
    ),
    body: ListView.builder(
      itemCount: categories.length,
      itemBuilder: (context, i) => ListTile(
        leading: CircleAvatar(backgroundColor: categories[i].color),
        title: Text(categories[i].name),
        onTap: () => _showCategoryDialog(context, cat: categories[i]),
      ),
    ),
  );
}

class _MoodList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('moods')
          .orderBy('order')
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator());
        final moods = snap.data!.docs;
        return Scaffold(
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showMoodDialog(context),
            child: const Icon(Icons.add),
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
            itemBuilder: (context, i) => ListTile(
              key: ValueKey(moods[i].id),
              leading: Text(
                moods[i]['emoji'],
                style: const TextStyle(fontSize: 24),
              ),
              title: Text(moods[i]['name']),
              onTap: () => _showMoodDialog(context, doc: moods[i]),
            ),
          ),
        );
      },
    );
  }

  void _showMoodDialog(BuildContext context, {DocumentSnapshot? doc}) {
    final eCtrl = TextEditingController(text: doc != null ? doc['emoji'] : "");
    final nCtrl = TextEditingController(text: doc != null ? doc['name'] : "");
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Mood Settings"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: eCtrl,
              decoration: const InputDecoration(labelText: "Emoji"),
            ),
            TextField(
              controller: nCtrl,
              decoration: const InputDecoration(labelText: "Name"),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              final data = {
                'emoji': eCtrl.text,
                'name': nCtrl.text,
                'order': doc != null ? doc['order'] : 99,
              };
              if (doc == null)
                FirebaseFirestore.instance.collection('moods').add(data);
              else
                FirebaseFirestore.instance
                    .collection('moods')
                    .doc(doc.id)
                    .update(data);
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}
