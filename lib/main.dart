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
          iconTheme: IconThemeData(color: Colors.black),
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

// --- COLOR PICKER ---
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
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Slider(
          value: hsvColor.hue,
          min: 0,
          max: 360,
          onChanged: (v) => setState(() {
            hsvColor = hsvColor.withHue(v);
            widget.onColorChanged(hsvColor.toColor());
          }),
        ),
      ],
    );
  }
}

// --- MODELS ---
class HabitCategory {
  final String id;
  final String name;
  final Color color;
  HabitCategory({required this.id, required this.name, required this.color});
}

class Habit {
  String id;
  String name;
  String categoryId;
  Map<String, bool> completionMap;
  int order;
  bool isSystem;
  bool isVisible;
  bool isFavorite;
  bool showInAnalytics;
  int backgroundColorValue;
  Habit({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.completionMap,
    required this.order,
    this.isSystem = false,
    this.isVisible = true,
    this.isFavorite = false,
    this.showInAnalytics = false,
    this.backgroundColorValue = 0xFFFFFFFF,
  });

  int getCount(int days) {
    int count = 0;
    DateTime now = DateTime.now();
    for (int i = 0; i < days; i++) {
      if (completionMap[DateFormat(
            'yyyy-MM-dd',
          ).format(now.subtract(Duration(days: i)))] ==
          true)
        count++;
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

// --- NAVIGATION ---
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});
  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  List<String> _selectedFilters = ['all'];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('categories')
          .orderBy('name')
          .snapshots(),
      builder: (context, catSnap) {
        final categories = catSnap.hasData
            ? catSnap.data!.docs
                  .map(
                    (doc) => HabitCategory(
                      id: doc.id,
                      name: doc['name'],
                      color: Color(doc['colorValue']),
                    ),
                  )
                  .toList()
            : <HabitCategory>[];
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('habits')
              .orderBy('order')
              .snapshots(),
          builder: (context, habitSnap) {
            if (!habitSnap.hasData)
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            final habits = habitSnap.data!.docs.map((doc) {
              final d = doc.data() as Map<String, dynamic>;
              return Habit(
                id: doc.id,
                name: d['name'] ?? '',
                categoryId: d['categoryId'] ?? '',
                order: d['order'] ?? 0,
                isSystem: d['isSystem'] ?? false,
                isVisible: d['isVisible'] ?? true,
                isFavorite: d['isFavorite'] ?? false,
                showInAnalytics: d['showInAnalytics'] ?? false,
                backgroundColorValue: d['backgroundColorValue'] ?? 0xFFFFFFFF,
                completionMap: Map<String, bool>.from(d['completionMap'] ?? {}),
              );
            }).toList();

            return Scaffold(
              body: IndexedStack(
                index: _selectedIndex,
                children: [
                  CategoryHomeScreen(
                    onCategoryTap: (id) => setState(() {
                      _selectedFilters = [id];
                      _selectedIndex = 1;
                    }),
                    habits: habits,
                    categories: categories,
                  ),
                  HabitCalendarScreen(
                    habits: habits,
                    categories: categories,
                    initialFilters: _selectedFilters,
                  ),
                  InsightsScreen(habits: habits),
                  ManageScreen(habits: habits, categories: categories),
                ],
              ),
              bottomNavigationBar: BottomNavigationBar(
                currentIndex: _selectedIndex,
                type: BottomNavigationBarType.fixed,
                onTap: (i) => setState(() {
                  _selectedIndex = i;
                  if (i != 1) _selectedFilters = ['all'];
                }),
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

// --- HOME ---
class CategoryHomeScreen extends StatelessWidget {
  final Function(String) onCategoryTap;
  final List<Habit> habits;
  final List<HabitCategory> categories;
  const CategoryHomeScreen({
    super.key,
    required this.onCategoryTap,
    required this.habits,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pebbles")),
      body: GridView(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 160,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
        ),
        children: [
          _card(
            context,
            "Favorites",
            Colors.red,
            Icons.favorite_rounded,
            'favorites',
          ),
          ...categories.map(
            (c) => _card(context, c.name, c.color, Icons.label_rounded, c.id),
          ),
        ],
      ),
    );
  }

  Widget _card(
    BuildContext context,
    String title,
    Color color,
    IconData icon,
    String id,
  ) {
    return GestureDetector(
      onTap: () => onCategoryTap(id),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
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

// --- BOARD ---
class HabitCalendarScreen extends StatefulWidget {
  final List<Habit> habits;
  final List<HabitCategory> categories;
  final List<String> initialFilters;
  const HabitCalendarScreen({
    super.key,
    required this.habits,
    required this.categories,
    required this.initialFilters,
  });
  @override
  State<HabitCalendarScreen> createState() => _HabitCalendarScreenState();
}

class _HabitCalendarScreenState extends State<HabitCalendarScreen> {
  late List<String> _currentFilters;
  bool _isAlphabetical = false;
  final ScrollController _hHead = ScrollController();
  final ScrollController _hBody = ScrollController();
  final ScrollController _vLabel = ScrollController();
  final ScrollController _vBody = ScrollController();

  @override
  void initState() {
    super.initState();
    _currentFilters = List.from(widget.initialFilters);
    _hBody.addListener(() => _hHead.jumpTo(_hBody.offset));
    _vBody.addListener(() => _vLabel.jumpTo(_vBody.offset));
  }

  @override
  void didUpdateWidget(HabitCalendarScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialFilters != oldWidget.initialFilters) {
      _currentFilters = List.from(widget.initialFilters);
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Habit> displayList = widget.habits.where((h) => h.isVisible).toList();

    // --- MULTI-SELECT FILTERING LOGIC ---
    if (!_currentFilters.contains('all')) {
      displayList = displayList.where((h) {
        bool matchesTag = _currentFilters.contains(h.categoryId);
        bool isFavMatch = _currentFilters.contains('favorites') && h.isFavorite;

        // Strictly exclude System habits if we are filtering by specific tags/favorites
        // but include them if 'favorites' is selected (as per your previous request).
        if (h.isSystem) {
          return _currentFilters.contains('favorites');
        }

        return matchesTag || isFavMatch;
      }).toList();
    }

    if (_isAlphabetical)
      displayList.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
    else
      displayList.sort((a, b) => a.order.compareTo(b.order));

    return Scaffold(
      appBar: AppBar(title: const Text("Board"), actions: [_buildFilterMenu()]),
      body: Column(
        children: [
          _buildHeaderRow(),
          Expanded(
            child: Row(
              children: [
                _buildLabelColumn(displayList),
                Expanded(child: _buildGridBody(displayList)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.filter_list_rounded),
      onSelected: (_) {}, // Handled inside itemBuilder
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: StatefulBuilder(
            builder: (context, setPopupState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Sort",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  CheckboxListTile(
                    title: const Text("Alphabetical"),
                    value: _isAlphabetical,
                    onChanged: (v) {
                      setState(() => _isAlphabetical = v!);
                      setPopupState(() {});
                    },
                  ),
                  const Divider(),
                  const Text(
                    "Tags",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  _popupCheckItem("All", "all", setPopupState),
                  _popupCheckItem("Favorites", "favorites", setPopupState),
                  ...widget.categories.map(
                    (c) => _popupCheckItem(c.name, c.id, setPopupState),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _popupCheckItem(String label, String id, StateSetter setPopupState) {
    bool isSelected = _currentFilters.contains(id);
    return CheckboxListTile(
      title: Text(label),
      value: isSelected,
      onChanged: (v) {
        setState(() {
          if (id == 'all') {
            _currentFilters = ['all'];
          } else {
            _currentFilters.remove('all');
            if (v == true)
              _currentFilters.add(id);
            else
              _currentFilters.remove(id);
            if (_currentFilters.isEmpty) _currentFilters = ['all'];
          }
        });
        setPopupState(() {});
      },
    );
  }

  Widget _buildHeaderRow() {
    return Row(
      children: [
        Container(
          width: 130,
          height: 40,
          padding: const EdgeInsets.only(left: 16),
          alignment: Alignment.centerLeft,
          child: const Text(
            "Item",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
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
                  height: 40,
                  alignment: Alignment.center,
                  child: Text(
                    DateFormat(
                      'dd\nE',
                    ).format(DateTime.now().subtract(Duration(days: i))),
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabelColumn(List<Habit> list) {
    return SizedBox(
      width: 130,
      child: ListView.builder(
        controller: _vLabel,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: list.length,
        itemBuilder: (context, i) {
          final h = list[i];
          final cat = widget.categories.firstWhere(
            (c) => c.id == h.categoryId,
            orElse: () =>
                HabitCategory(id: '', name: '', color: Colors.transparent),
          );
          return Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.withOpacity(0.1)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  h.name,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                  ),
                  maxLines: 2,
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
                      color: cat.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      cat.name,
                      style: TextStyle(
                        fontSize: 7,
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
    );
  }

  Widget _buildGridBody(List<Habit> list) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('daily_metrics')
          .snapshots(),
      builder: (context, mSnap) {
        final metrics = mSnap.hasData ? mSnap.data!.docs : [];
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('moods')
              .orderBy('order')
              .snapshots(),
          builder: (context, moodSnap) {
            final moods = moodSnap.hasData ? moodSnap.data!.docs : [];
            return SingleChildScrollView(
              controller: _hBody,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 31 * 55,
                child: ListView.builder(
                  controller: _vBody,
                  itemCount: list.length,
                  itemBuilder: (context, hIdx) => Row(
                    children: List.generate(
                      31,
                      (dIdx) => _gridCell(list[hIdx], dIdx, metrics, moods),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _gridCell(Habit h, int dIdx, List metrics, List moods) {
    final ds = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime.now().subtract(Duration(days: dIdx)));
    Map? data;
    for (var m in metrics) {
      if (m.id == ds) {
        data = m.data() as Map?;
        break;
      }
    }
    Widget child = const SizedBox();
    if (h.name == "Mood") {
      String emoji = "❔";
      if (data?['mood'] != null) {
        for (var m in moods) {
          if (m['name'] == data?['mood']) {
            emoji = m['emoji'];
            break;
          }
        }
      }
      child = Text(emoji, style: const TextStyle(fontSize: 22));
    } else if (h.name == "Sleep") {
      child = Text(
        "${data?['sleep'] ?? '-'}",
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      );
    } else if (h.name == "Diary" || h.name == "Dreams") {
      bool hasText = data?[h.name.toLowerCase()]?.isNotEmpty ?? false;
      child = Icon(
        h.name == "Diary" ? Icons.book : Icons.cloud,
        size: 18,
        color: hasText ? Colors.blue : Colors.grey[100],
      );
    } else {
      bool isDone = h.completionMap[ds] ?? false;
      final color = widget.categories
          .firstWhere(
            (c) => c.id == h.categoryId,
            orElse: () => HabitCategory(id: '', name: '', color: Colors.blue),
          )
          .color;
      child = Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDone ? color : Colors.grey[100],
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        if (h.name == "Mood")
          _showMoodPicker(ds, moods);
        else if (h.name == "Sleep")
          _showSleepPicker(ds, data?['sleep']);
        else if (h.name == "Diary" || h.name == "Dreams")
          _showTextPicker(
            h.name,
            h.name.toLowerCase(),
            ds,
            data?[h.name.toLowerCase()] ?? "",
          );
        else {
          Map<String, bool> next = Map.from(h.completionMap);
          next[ds] = !(h.completionMap[ds] ?? false);
          FirebaseFirestore.instance.collection('habits').doc(h.id).update({
            'completionMap': next,
          });
        }
      },
      child: Container(
        width: 55,
        height: 70,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.withOpacity(0.1)),
            right: BorderSide(color: Colors.grey.withOpacity(0.1)),
          ),
        ),
        child: Center(child: child),
      ),
    );
  }

  void _showMoodPicker(String ds, List moods) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Mood"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: moods
                .map(
                  (m) => ListTile(
                    leading: Text(
                      m['emoji'],
                      style: const TextStyle(fontSize: 26),
                    ),
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
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  void _showSleepPicker(String ds, dynamic cur) {
    final ctrl = TextEditingController(text: cur?.toString() ?? "");
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

  void _showTextPicker(String title, String key, String ds, String initial) {
    final ctrl = TextEditingController(text: initial);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          maxLines: 6,
          decoration: const InputDecoration(border: OutlineInputBorder()),
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

// --- INSIGHTS ---
class InsightsScreen extends StatelessWidget {
  final List<Habit> habits;
  const InsightsScreen({super.key, required this.habits});
  @override
  Widget build(BuildContext context) {
    final list = habits.where((h) => h.showInAnalytics).toList();
    return Scaffold(
      appBar: AppBar(title: const Text("Insights")),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (context, i) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Color(list[i].backgroundColorValue),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    list[i].name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.palette_outlined),
                    onPressed: () => _showColor(context, list[i]),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _stat("7 Days", list[i].getCount(7)),
                  _stat("30 Days", list[i].getCount(30)),
                  _stat("Streak", list[i].calculateStreak),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showColor(BuildContext context, Habit h) {
    Color sel = Color(h.backgroundColorValue);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Color"),
        content: LucidColorPicker(
          initialColor: sel,
          onColorChanged: (c) => sel = c,
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('habits').doc(h.id).update({
                'backgroundColorValue': sel.value,
              });
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Widget _stat(String l, int v) => Column(
    children: [
      Text(l, style: const TextStyle(fontSize: 10, color: Colors.black54)),
      Text(
        "$v",
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    ],
  );
}

// --- SETTINGS ---
class ManageScreen extends StatefulWidget {
  final List<Habit> habits;
  final List<HabitCategory> categories;
  const ManageScreen({
    super.key,
    required this.habits,
    required this.categories,
  });
  @override
  State<ManageScreen> createState() => _ManageScreenState();
}

class _ManageScreenState extends State<ManageScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 28),
            onPressed: () {
              if (_tab.index == 0)
                _editHabit(context);
              else if (_tab.index == 1)
                _editTag(context);
              else
                _editMood(context);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: "Habits"),
            Tab(text: "Tags"),
            Tab(text: "Moods"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          ReorderableListView(
            onReorder: (o, n) {
              if (n > o) n--;
              final l = List<Habit>.from(widget.habits);
              final i = l.removeAt(o);
              l.insert(n, i);
              for (int j = 0; j < l.length; j++) {
                FirebaseFirestore.instance
                    .collection('habits')
                    .doc(l[j].id)
                    .update({'order': j});
              }
            },
            children: widget.habits
                .map(
                  (h) => ListTile(
                    key: ValueKey(h.id),
                    title: Text(h.name),
                    trailing: const Icon(Icons.drag_handle),
                    onTap: () => _editHabit(context, h: h),
                  ),
                )
                .toList(),
          ),
          ListView(
            children: widget.categories
                .map(
                  (c) => ListTile(
                    leading: CircleAvatar(backgroundColor: c.color),
                    title: Text(c.name),
                    onTap: () => _editTag(context, cat: c),
                  ),
                )
                .toList(),
          ),
          _MoodList(),
        ],
      ),
    );
  }

  void _editHabit(BuildContext context, {Habit? h}) {
    final ctrl = TextEditingController(text: h?.name);
    String? cat =
        h?.categoryId ??
        (widget.categories.isNotEmpty ? widget.categories.first.id : null);
    bool fav = h?.isFavorite ?? false;
    bool vis = h?.isVisible ?? true;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDS) => AlertDialog(
          title: Text(h == null ? "New" : "Edit"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                decoration: const InputDecoration(labelText: "Name"),
              ),
              DropdownButtonFormField<String>(
                value: cat,
                items: widget.categories
                    .map(
                      (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                    )
                    .toList(),
                onChanged: (v) => setDS(() => cat = v),
              ),
              SwitchListTile(
                title: const Text("Favorite"),
                value: fav,
                onChanged: (v) => setDS(() => fav = v),
              ),
              SwitchListTile(
                title: const Text("Visible"),
                value: vis,
                onChanged: (v) => setDS(() => vis = v),
              ),
            ],
          ),
          actions: [
            if (h != null && !h.isSystem)
              TextButton(
                onPressed: () {
                  FirebaseFirestore.instance
                      .collection('habits')
                      .doc(h.id)
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
                final d = {
                  'name': ctrl.text,
                  'categoryId': cat,
                  'isFavorite': fav,
                  'isVisible': vis,
                };
                if (h == null)
                  FirebaseFirestore.instance.collection('habits').add({
                    ...d,
                    'order': widget.habits.length,
                    'completionMap': {},
                    'isSystem': false,
                    'backgroundColorValue': 0xFFFFFFFF,
                    'showInAnalytics': false,
                  });
                else
                  FirebaseFirestore.instance
                      .collection('habits')
                      .doc(h.id)
                      .update(d);
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  void _editTag(BuildContext context, {HabitCategory? cat}) {
    final ctrl = TextEditingController(text: cat?.name);
    Color col = cat?.color ?? Colors.blue;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Tag"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: ctrl),
              const SizedBox(height: 15),
              LucidColorPicker(
                initialColor: col,
                onColorChanged: (c) => col = c,
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              FirebaseFirestore.instance
                  .collection('categories')
                  .doc(
                    cat?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  )
                  .set({'name': ctrl.text, 'colorValue': col.value});
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _editMood(BuildContext context) {}
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
        if (!snap.hasData) return const SizedBox();
        final moods = snap.data!.docs;
        return ReorderableListView(
          onReorder: (o, n) {
            if (n > o) n--;
            final l = List.from(moods);
            final i = l.removeAt(o);
            l.insert(n, i);
            for (int j = 0; j < l.length; j++) {
              FirebaseFirestore.instance
                  .collection('moods')
                  .doc(l[j].id)
                  .update({'order': j});
            }
          },
          children: moods
              .map(
                (m) => ListTile(
                  key: ValueKey(m.id),
                  leading: Text(
                    m['emoji'],
                    style: const TextStyle(fontSize: 32),
                  ),
                  title: Text(m['name']),
                  trailing: const Icon(Icons.drag_handle),
                  onTap: () => _editMood(context, m),
                ),
              )
              .toList(),
        );
      },
    );
  }

  void _editMood(BuildContext context, DocumentSnapshot? doc) {
    final eCtrl = TextEditingController(text: doc != null ? doc['emoji'] : "");
    final nCtrl = TextEditingController(text: doc != null ? doc['name'] : "");
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Mood"),
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
              final d = {
                'emoji': eCtrl.text,
                'name': nCtrl.text,
                'order': doc != null ? doc['order'] : 99,
              };
              if (doc == null)
                FirebaseFirestore.instance.collection('moods').add(d);
              else
                FirebaseFirestore.instance
                    .collection('moods')
                    .doc(doc.id)
                    .update(d);
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}
