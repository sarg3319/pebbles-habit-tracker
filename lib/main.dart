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
  int insightOrder;
  bool isSystem;
  bool isVisible;
  bool isFavorite;
  bool showInAnalytics;
  bool showStreak;
  int backgroundColorValue;
  String description;
  Habit({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.completionMap,
    required this.order,
    this.insightOrder = 0,
    this.isSystem = false,
    this.isVisible = true,
    this.isFavorite = false,
    this.showInAnalytics = false,
    this.showStreak = true,
    this.backgroundColorValue = 0xFFFFFFFF,
    this.description = "",
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
    if (completionMap[DateFormat('yyyy-MM-dd').format(date)] != true) {
      date = date.subtract(const Duration(days: 1));
    }
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
                insightOrder: d['insightOrder'] ?? 0,
                isSystem: d['isSystem'] ?? false,
                isVisible: d['isVisible'] ?? true,
                isFavorite: d['isFavorite'] ?? false,
                showInAnalytics: d['showInAnalytics'] ?? false,
                showStreak: d['showStreak'] ?? true,
                backgroundColorValue: d['backgroundColorValue'] ?? 0xFFFFFFFF,
                description: d['description'] ?? "",
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
                  const JournalScreen(), // NEW SCREEN
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
                    icon: Icon(Icons.book_rounded),
                    label: 'Journal',
                  ), // NEW TAB
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
    if (!_currentFilters.contains('all')) {
      displayList = displayList.where((h) {
        bool matchesTag = _currentFilters.contains(h.categoryId);
        bool isFavMatch = _currentFilters.contains('favorites') && h.isFavorite;
        if (h.isSystem) return _currentFilters.contains('favorites');
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
          if (id == 'all')
            _currentFilters = ['all'];
          else {
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
      child: ReorderableListView.builder(
        scrollController: _vLabel,
        onReorder: (o, n) {
          if (n > o) n--;
          final item = list.removeAt(o);
          list.insert(n, item);
          for (int i = 0; i < list.length; i++) {
            FirebaseFirestore.instance
                .collection('habits')
                .doc(list[i].id)
                .update({'order': i});
          }
        },
        itemCount: list.length,
        itemBuilder: (context, i) {
          final h = list[i];
          final cat = widget.categories.firstWhere(
            (c) => c.id == h.categoryId,
            orElse: () =>
                HabitCategory(id: '', name: '', color: Colors.transparent),
          );
          final streak = h.calculateStreak;
          return GestureDetector(
            key: ValueKey(h.id),
            onLongPress: () => _editHabit(context, h: h),
            child: Container(
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          h.name,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            height: 1.1,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (h.showStreak && streak >= 2)
                        const Text("🔥", style: TextStyle(fontSize: 12)),
                    ],
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
    Map? dayData;
    for (var m in metrics) {
      if (m.id == ds) {
        dayData = m.data() as Map?;
        break;
      }
    }
    Widget child = const SizedBox();
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
      child = Text(emoji, style: const TextStyle(fontSize: 22));
    } else if (h.name == "Sleep") {
      child = Text(
        "${dayData?['sleep'] ?? '-'}",
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      );
    } else if (h.name == "Diary" || h.name == "Dreams") {
      bool hasText = dayData?[h.name.toLowerCase()]?.isNotEmpty ?? false;
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
          _showSleepPicker(ds, dayData?['sleep']);
        else if (h.name == "Diary" || h.name == "Dreams")
          _showTextPicker(context, h.name, h.name.toLowerCase(), ds);
        else {
          Map<String, bool> next = Map.from(h.completionMap);
          next[ds] = !(h.completionMap[ds] ?? false);
          FirebaseFirestore.instance.collection('habits').doc(h.id).update({
            'completionMap': next,
          });
        }
      },
      onLongPress: () => _showHabitDayNote(h, ds),
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

  void _showHabitDayNote(Habit h, String ds) async {
    final docId = "${h.id}_$ds";
    final doc = await FirebaseFirestore.instance
        .collection('habit_notes')
        .doc(docId)
        .get();
    final ctrl = TextEditingController(text: doc.exists ? doc['note'] : "");
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Note: ${h.name} ($ds)"),
        content: SizedBox(
          width: 300,
          height: 180,
          child: TextField(
            controller: ctrl,
            maxLines: 6,
            minLines: 6,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: "Add a specific note...",
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              FirebaseFirestore.instance
                  .collection('habit_notes')
                  .doc(docId)
                  .set({
                    'note': ctrl.text,
                    'habitId': h.id,
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
    final ctrl = TextEditingController(
      text: cur?.toString().replaceAll('.', ',') ?? "",
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Sleep Hours"),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              String normalized = ctrl.text.replaceAll(',', '.');
              FirebaseFirestore.instance
                  .collection('daily_metrics')
                  .doc(ds)
                  .set({
                    'sleep': double.tryParse(normalized) ?? 0.0,
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

  void _editHabit(BuildContext context, {Habit? h}) {
    final ctrl = TextEditingController(text: h?.name);
    final descCtrl = TextEditingController(text: h?.description);
    String? cat =
        h?.categoryId ??
        (widget.categories.isNotEmpty ? widget.categories.first.id : null);
    bool fav = h?.isFavorite ?? false;
    bool vis = h?.isVisible ?? true;
    bool showIns = h?.showInAnalytics ?? false;
    bool strk = h?.showStreak ?? true;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDS) => AlertDialog(
          title: Text(h == null ? "New Habit" : "Edit Habit"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: ctrl,
                  decoration: const InputDecoration(labelText: "Habit Name"),
                ),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: "Description (for AI)",
                  ),
                ),
                DropdownButtonFormField<String>(
                  value: cat,
                  items: widget.categories
                      .map(
                        (c) =>
                            DropdownMenuItem(value: c.id, child: Text(c.name)),
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
                  title: const Text("Visible on Board"),
                  value: vis,
                  onChanged: (v) => setDS(() => vis = v),
                ),
                SwitchListTile(
                  title: const Text("Show in Insights"),
                  value: showIns,
                  onChanged: (v) => setDS(() => showIns = v),
                ),
                SwitchListTile(
                  title: const Text("Enable Streak"),
                  value: strk,
                  onChanged: (v) => setDS(() => strk = v),
                ),
              ],
            ),
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
                  'description': descCtrl.text,
                  'categoryId': cat,
                  'isFavorite': fav,
                  'isVisible': vis,
                  'showInAnalytics': showIns,
                  'showStreak': strk,
                };
                if (h == null)
                  FirebaseFirestore.instance.collection('habits').add({
                    ...d,
                    'order': 99,
                    'completionMap': {},
                    'isSystem': false,
                    'backgroundColorValue': 0xFFFFFFFF,
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
}

// Global Text Picker for reuse
void _showTextPicker(
  BuildContext context,
  String title,
  String key,
  String ds,
) async {
  DocumentSnapshot doc = await FirebaseFirestore.instance
      .collection('daily_metrics')
      .doc(ds)
      .get();
  String currentText = "";
  if (doc.exists) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    currentText = data[key] ?? "";
  }
  final ctrl = TextEditingController(text: currentText);
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text("$title ($ds)"),
      content: SizedBox(
        width: 400,
        height: 250,
        child: TextField(
          controller: ctrl,
          maxLines: 10,
          minLines: 8,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: "Write here...",
          ),
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            FirebaseFirestore.instance.collection('daily_metrics').doc(ds).set({
              key: ctrl.text,
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

// --- NEW JOURNAL SCREEN ---
class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Journal")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('moods').snapshots(),
        builder: (context, moodSnap) {
          final moodsList = moodSnap.hasData ? moodSnap.data!.docs : [];
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('daily_metrics')
                .orderBy('date', descending: true)
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData)
                return const Center(child: CircularProgressIndicator());
              final entries = snap.data!.docs.where((doc) {
                final d = doc.data() as Map<String, dynamic>;
                return (d['diary']?.toString().isNotEmpty ?? false) ||
                    (d['mood'] != null);
              }).toList();

              if (entries.isEmpty)
                return const Center(
                  child: Text("No diary entries yet. Tap 'Board' to write."),
                );

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: entries.length,
                itemBuilder: (context, i) {
                  final data = entries[i].data() as Map<String, dynamic>;
                  final dateStr = data['date'] ?? "Unknown Date";
                  final diaryText = data['diary'] ?? "";
                  final moodName = data['mood'];
                  String emoji = "❔";
                  if (moodName != null) {
                    for (var m in moodsList) {
                      if (m['name'] == moodName) {
                        emoji = m['emoji'];
                        break;
                      }
                    }
                  }

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: Colors.grey.withOpacity(0.1)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Row(
                        children: [
                          Text(emoji, style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 12),
                          Text(
                            dateStr,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          diaryText.isEmpty ? "No note recorded." : diaryText,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.black87),
                        ),
                      ),
                      onTap: () =>
                          _showTextPicker(context, "Diary", "diary", dateStr),
                    ),
                  );
                },
              );
            },
          );
        },
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
    list.sort((a, b) => a.insightOrder.compareTo(b.insightOrder));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Insights"),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_fix_high_rounded),
            onPressed: () => _manageInsights(context, list),
          ),
        ],
      ),
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
              Text(
                list[i].name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _stat("7 Days", list[i].getCount(7)),
                  _stat("30 Days", list[i].getCount(30)),
                  _stat(
                    "Streak",
                    list[i].calculateStreak,
                    active: list[i].showStreak,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _manageInsights(BuildContext context, List<Habit> list) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (context, scroll) => Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                "Manage Insights Order & Color",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            Expanded(
              child: ReorderableListView(
                onReorder: (o, n) {
                  if (n > o) n--;
                  final item = list.removeAt(o);
                  list.insert(n, item);
                  for (int i = 0; i < list.length; i++) {
                    FirebaseFirestore.instance
                        .collection('habits')
                        .doc(list[i].id)
                        .update({'insightOrder': i});
                  }
                },
                children: list
                    .map(
                      (h) => ListTile(
                        key: ValueKey(h.id),
                        title: Text(h.name),
                        leading: CircleAvatar(
                          backgroundColor: Color(h.backgroundColorValue),
                        ),
                        trailing: const Icon(Icons.drag_handle),
                        onTap: () => _showColor(context, h),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showColor(BuildContext context, Habit h) {
    Color sel = Color(h.backgroundColorValue);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Card Color"),
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

  Widget _stat(String l, int v, {bool active = true}) => Column(
    children: [
      Text(l, style: const TextStyle(fontSize: 10, color: Colors.black54)),
      Text(
        active ? "$v" : "-",
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
                _editMood(context, null);
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
            children: widget.habits.map((h) {
              final cat = widget.categories.firstWhere(
                (c) => c.id == h.categoryId,
                orElse: () =>
                    HabitCategory(id: '', name: 'No Tag', color: Colors.grey),
              );
              return ListTile(
                key: ValueKey(h.id),
                title: Row(
                  children: [
                    Text(h.name),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: cat.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
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
                trailing: const Icon(Icons.drag_handle),
                onTap: () => _editHabit(context, h: h),
              );
            }).toList(),
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
    final descCtrl = TextEditingController(text: h?.description);
    String? cat =
        h?.categoryId ??
        (widget.categories.isNotEmpty ? widget.categories.first.id : null);
    bool fav = h?.isFavorite ?? false;
    bool vis = h?.isVisible ?? true;
    bool showIns = h?.showInAnalytics ?? false;
    bool strk = h?.showStreak ?? true;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDS) => AlertDialog(
          title: Text(h == null ? "New" : "Edit"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: ctrl,
                  decoration: const InputDecoration(labelText: "Name"),
                ),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: "Description"),
                ),
                DropdownButtonFormField<String>(
                  value: cat,
                  items: widget.categories
                      .map(
                        (c) =>
                            DropdownMenuItem(value: c.id, child: Text(c.name)),
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
                SwitchListTile(
                  title: const Text("Insights"),
                  value: showIns,
                  onChanged: (v) => setDS(() => showIns = v),
                ),
                SwitchListTile(
                  title: const Text("Streak"),
                  value: strk,
                  onChanged: (v) => setDS(() => strk = v),
                ),
              ],
            ),
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
                  'description': descCtrl.text,
                  'categoryId': cat,
                  'isFavorite': fav,
                  'isVisible': vis,
                  'showInAnalytics': showIns,
                  'showStreak': strk,
                };
                if (h == null)
                  FirebaseFirestore.instance.collection('habits').add({
                    ...d,
                    'order': 99,
                    'completionMap': {},
                    'isSystem': false,
                    'backgroundColorValue': 0xFFFFFFFF,
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
          if (doc != null)
            TextButton(
              onPressed: () {
                FirebaseFirestore.instance
                    .collection('moods')
                    .doc(doc.id)
                    .delete();
                Navigator.pop(context);
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
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
                  onTap: () {
                    final eCtrl = TextEditingController(text: m['emoji']);
                    final nCtrl = TextEditingController(text: m['name']);
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Mood"),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              controller: eCtrl,
                              decoration: const InputDecoration(
                                labelText: "Emoji",
                              ),
                            ),
                            TextField(
                              controller: nCtrl,
                              decoration: const InputDecoration(
                                labelText: "Name",
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              FirebaseFirestore.instance
                                  .collection('moods')
                                  .doc(m.id)
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
                                  .collection('moods')
                                  .doc(m.id)
                                  .update({
                                    'emoji': eCtrl.text,
                                    'name': nCtrl.text,
                                  });
                              Navigator.pop(context);
                            },
                            child: const Text("Save"),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              )
              .toList(),
        );
      },
    );
  }
}
