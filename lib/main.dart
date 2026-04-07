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
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: const MainNavigationScreen(),
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
  String categoryId;
  Map<String, bool> completionMap;
  bool isStreakHabit;
  bool hasNotes;
  int order;
  bool isSystem;
  bool isVisible;

  Habit({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.completionMap,
    required this.isStreakHabit,
    required this.hasNotes,
    required this.order,
    this.isSystem = false,
    this.isVisible = true,
  });

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
  void initState() {
    super.initState();
    _ensureSystemHabitsExist();
  }

  void _ensureSystemHabitsExist() async {
    final habitsRef = FirebaseFirestore.instance.collection('habits');
    final systemHabitNames = ['Mood', 'Sleep', 'Diary', 'Dreams'];
    for (int i = 0; i < systemHabitNames.length; i++) {
      final name = systemHabitNames[i];
      final snap = await habitsRef
          .where('name', isEqualTo: name)
          .where('isSystem', isEqualTo: true)
          .get();
      if (snap.docs.isEmpty) {
        habitsRef.add({
          'name': name,
          'categoryId': '',
          'isStreakHabit': false,
          'hasNotes': false,
          'order': i,
          'isSystem': true,
          'isVisible': true,
          'completionMap': {},
        });
      }
    }
  }

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
            if (!habitSnapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            final habits = habitSnapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return Habit(
                id: doc.id,
                name: data['name'] ?? '',
                categoryId: data['categoryId'] ?? '',
                isStreakHabit: data['isStreakHabit'] ?? false,
                hasNotes: data['hasNotes'] ?? false,
                order: data['order'] ?? 0,
                isSystem: data['isSystem'] ?? false,
                isVisible: data['isVisible'] ?? true,
                completionMap: Map<String, bool>.from(
                  data['completionMap'] ?? {},
                ),
              );
            }).toList();

            return Scaffold(
              body: IndexedStack(
                index: _selectedIndex,
                children: [
                  HabitCalendarScreen(habits: habits, categories: categories),
                  ManageScreen(habits: habits, categories: categories),
                ],
              ),
              bottomNavigationBar: BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: (index) => setState(() => _selectedIndex = index),
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.grid_view_rounded),
                    label: 'Board',
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

// --- CALENDAR BOARD ---
class HabitCalendarScreen extends StatefulWidget {
  final List<Habit> habits;
  final List<HabitCategory> categories;
  const HabitCalendarScreen({
    super.key,
    required this.habits,
    required this.categories,
  });
  @override
  State<HabitCalendarScreen> createState() => _HabitCalendarScreenState();
}

class _HabitCalendarScreenState extends State<HabitCalendarScreen> {
  String _selectedFilterId = 'all';
  final ScrollController _headerHorizontalController = ScrollController();
  final ScrollController _bodyHorizontalController = ScrollController();
  final ScrollController _labelVerticalController = ScrollController();
  final ScrollController _bodyVerticalController = ScrollController();

  @override
  void initState() {
    super.initState();
    _bodyHorizontalController.addListener(() {
      if (_headerHorizontalController.offset !=
          _bodyHorizontalController.offset) {
        _headerHorizontalController.jumpTo(_bodyHorizontalController.offset);
      }
    });
    _bodyVerticalController.addListener(() {
      if (_labelVerticalController.offset != _bodyVerticalController.offset) {
        _labelVerticalController.jumpTo(_bodyVerticalController.offset);
      }
    });
  }

  String _getDateStr(int daysAgo) => DateFormat(
    'yyyy-MM-dd',
  ).format(DateTime.now().subtract(Duration(days: daysAgo)));

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
            textAlignVertical: TextAlignVertical.top,
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

  void _showMoodDialog(int dayIdx) async {
    final dateStr = _getDateStr(dayIdx);
    final docRef = FirebaseFirestore.instance
        .collection('daily_metrics')
        .doc(dateStr);
    final nameCtrl = TextEditingController();
    final emojiCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDS) => StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('moods')
              .orderBy('order')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final moods = snapshot.data!.docs;

            return AlertDialog(
              title: const Text("Select or Manage Moods"),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 45,
                          child: TextField(
                            controller: emojiCtrl,
                            decoration: const InputDecoration(
                              hintText: "😊",
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: nameCtrl,
                            decoration: const InputDecoration(
                              hintText: "Mood name",
                              isDense: true,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle,
                            color: Colors.blue,
                          ),
                          onPressed: () {
                            if (nameCtrl.text.isNotEmpty) {
                              FirebaseFirestore.instance
                                  .collection('moods')
                                  .add({
                                    'name': nameCtrl.text,
                                    'emoji': emojiCtrl.text.isEmpty
                                        ? "😊"
                                        : emojiCtrl.text,
                                    'order': moods.length,
                                  });
                              nameCtrl.clear();
                              emojiCtrl.clear();
                            }
                          },
                        ),
                      ],
                    ),
                    const Divider(),
                    Expanded(
                      child: moods.isEmpty
                          ? const Center(child: Text("No moods yet."))
                          : ReorderableListView(
                              shrinkWrap: true,
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
                              children: moods.map((m) {
                                final data = m.data() as Map<String, dynamic>;
                                return ListTile(
                                  key: Key(m.id),
                                  leading: Text(
                                    data['emoji'] ?? '?',
                                    style: const TextStyle(fontSize: 22),
                                  ),
                                  title: Text(data['name'] ?? ''),
                                  trailing: const Icon(
                                    Icons.drag_handle,
                                    size: 20,
                                  ),
                                  onTap: () {
                                    docRef.set({
                                      'mood': data['name'],
                                      'date': dateStr,
                                    }, SetOptions(merge: true));
                                    Navigator.pop(context);
                                  },
                                  onLongPress: () {
                                    FirebaseFirestore.instance
                                        .collection('moods')
                                        .doc(m.id)
                                        .delete();
                                  },
                                );
                              }).toList(),
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                ),
              ],
            );
          },
        ),
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
          decoration: const InputDecoration(
            suffixText: "hours",
            hintText: "e.g. 7.5",
          ),
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

  @override
  Widget build(BuildContext context) {
    List<Habit> filteredHabits = widget.habits
        .where((h) => h.isVisible)
        .toList();

    if (_selectedFilterId == 'alphabetical') {
      filteredHabits.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
    } else if (_selectedFilterId != 'all') {
      filteredHabits = filteredHabits
          .where((h) => h.categoryId == _selectedFilterId || h.isSystem)
          .toList();
    }

    const double labelWidth = 140.0;
    const double cellWidth = 50.0;
    const double rowHeight = 55.0;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pebbles Board"),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (val) => setState(() => _selectedFilterId = val),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Row(
                  children: [
                    Icon(Icons.sort),
                    SizedBox(width: 8),
                    Text("Custom Order"),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'alphabetical',
                child: Row(
                  children: [
                    Icon(Icons.sort_by_alpha),
                    SizedBox(width: 8),
                    Text("Alphabetical (A-Z)"),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              ...widget.categories.map(
                (c) => PopupMenuItem(value: c.id, child: Text(c.name)),
              ),
            ],
          ),
        ],
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
            stream: FirebaseFirestore.instance.collection('moods').snapshots(),
            builder: (context, moodSnapshot) {
              final moodsData = moodSnapshot.hasData
                  ? moodSnapshot.data!.docs
                  : [];

              return Column(
                children: [
                  Container(
                    color: bgColor,
                    child: Row(
                      children: [
                        Container(
                          width: labelWidth,
                          height: 50,
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
                              children: List.generate(31, (i) {
                                final date = DateTime.now().subtract(
                                  Duration(days: i),
                                );
                                return Container(
                                  width: cellWidth,
                                  height: 50,
                                  alignment: Alignment.center,
                                  child: Text(
                                    DateFormat('E\nd').format(date),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Container(
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
    return Container(
      height: height,
      padding: const EdgeInsets.only(left: 16, right: 8),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Expanded(
            child: Text(
              h.name,
              style: TextStyle(
                fontWeight: h.isSystem ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (h.isStreakHabit && streak > 0)
            Text(
              "🔥$streak",
              style: const TextStyle(
                fontSize: 11,
                color: Colors.orange,
                fontWeight: FontWeight.bold,
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

    if (h.name == "Mood") {
      String? moodName = dayData?['mood'];
      String displayEmoji = "❔";

      if (moodName != null) {
        final moodDoc = moodsData.cast<QueryDocumentSnapshot?>().firstWhere(
          (m) => (m!.data() as Map<String, dynamic>)['name'] == moodName,
          orElse: () => null,
        );

        if (moodDoc != null) {
          final data = moodDoc.data() as Map<String, dynamic>;
          displayEmoji = data['emoji'] ?? "😊";
        }
      }
      return GestureDetector(
        onTap: () => _showMoodDialog(dayIdx),
        child: Center(
          child: Text(displayEmoji, style: const TextStyle(fontSize: 22)),
        ),
      );
    }
    if (h.name == "Sleep") {
      return GestureDetector(
        onTap: () => _showSleepDialog(dayIdx),
        child: Center(
          child: Text(
            dayData?['sleep']?.toString() ?? "-",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
    if (h.name == "Diary") {
      bool hasVal = dayData?['diary'] != null && dayData?['diary'] != "";
      return IconButton(
        icon: Icon(
          hasVal ? Icons.book : Icons.menu_book,
          color: hasVal ? Colors.blue : Colors.grey[300],
        ),
        onPressed: () => _showTextEntryDialog("Diary", "diary", dayIdx),
      );
    }
    if (h.name == "Dreams") {
      bool hasVal = dayData?['dreams'] != null && dayData?['dreams'] != "";
      return IconButton(
        icon: Icon(
          hasVal ? Icons.cloud : Icons.cloud_outlined,
          color: hasVal ? Colors.purple : Colors.grey[300],
        ),
        onPressed: () => _showTextEntryDialog("Dreams", "dreams", dayIdx),
      );
    }
    final cat = widget.categories.firstWhere(
      (c) => c.id == h.categoryId,
      orElse: () => HabitCategory(id: '', name: '', color: Colors.blue),
    );
    bool isDone = h.completionMap[dateStr] ?? false;
    return GestureDetector(
      onTap: () async {
        Map<String, bool> newMap = Map.from(h.completionMap);
        bool newValue = !isDone;
        newMap[dateStr] = newValue;

        // 1. KEEP your existing system
        await FirebaseFirestore.instance.collection('habits').doc(h.id).update({
          'completionMap': newMap,
        });

        await FirebaseFirestore.instance.collection('habit_events').add({
          'userId': 'test_user',
          'habitId': h.id,
          'habitName': h.name,
          'date': dateStr,
          'completed': newValue, // true OR false
          'createdAt': FieldValue.serverTimestamp(),
        });
      },
      child: Center(
        child: Container(
          height: 30,
          width: 30,
          decoration: BoxDecoration(
            color: isDone ? cat.color : Colors.grey[300],
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

// --- SETTINGS SCREEN ---
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
    String? selCat =
        habit?.categoryId ??
        (categories.isNotEmpty ? categories.first.id : null);
    bool isStreak = habit?.isStreakHabit ?? false;
    bool isVis = habit?.isVisible ?? true;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDS) => AlertDialog(
          title: Text(habit == null ? "New Habit" : "Edit ${habit.name}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (habit?.isSystem != true)
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: "Name"),
                ),
              if (habit?.isSystem != true)
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
              if (habit?.isSystem != true)
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
          actions: [
            ElevatedButton(
              onPressed: () {
                final data = {
                  'name': nameCtrl.text,
                  'categoryId': selCat ?? '',
                  'isStreakHabit': isStreak,
                  'isVisible': isVis,
                };
                if (habit == null) {
                  FirebaseFirestore.instance.collection('habits').add({
                    ...data,
                    'order': habits.length,
                    'isSystem': false,
                    'completionMap': {},
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
      body: ReorderableListView(
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
        children: habits
            .map(
              (h) => ListTile(
                key: Key(h.id),
                title: Text(
                  h.name,
                  style: TextStyle(
                    fontWeight: h.isSystem
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                trailing: const Icon(Icons.drag_handle),
                onTap: () => _showHabitDialog(context, habit: h),
              ),
            )
            .toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showHabitDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _CategoryList extends StatelessWidget {
  final List<HabitCategory> categories;
  const _CategoryList({required this.categories});

  void _showCategoryDialog(BuildContext context, {HabitCategory? cat}) {
    final nameCtrl = TextEditingController(text: cat?.name ?? "");
    HSVColor hsvColor = HSVColor.fromColor(cat?.color ?? Colors.blue);

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
                  decoration: const InputDecoration(labelText: "Tag Name"),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Pick Color",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onPanUpdate: (details) {
                    RenderBox box = context.findRenderObject() as RenderBox;
                    Offset localOffset = box.globalToLocal(
                      details.globalPosition,
                    );
                    setDS(() {
                      double s = (localOffset.dx / 200).clamp(0.0, 1.0);
                      double v = (1.0 - (localOffset.dy / 150)).clamp(0.0, 1.0);
                      hsvColor = hsvColor.withSaturation(s).withValue(v);
                    });
                  },
                  child: Container(
                    height: 150,
                    width: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white,
                          hsvColor.withSaturation(1).withValue(1).toColor(),
                        ],
                      ),
                    ),
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Slider(
                  value: hsvColor.hue,
                  min: 0,
                  max: 360,
                  activeColor: hsvColor.toColor(),
                  onChanged: (v) => setDS(() => hsvColor = hsvColor.withHue(v)),
                ),
                CircleAvatar(backgroundColor: hsvColor.toColor(), radius: 15),
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
                if (nameCtrl.text.isNotEmpty) {
                  final data = {
                    'name': nameCtrl.text,
                    'colorValue': hsvColor.toColor().value,
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
      body: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, i) => ListTile(
          leading: CircleAvatar(backgroundColor: categories[i].color),
          title: Text(categories[i].name),
          onLongPress: () => _showCategoryDialog(context, cat: categories[i]),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryDialog(context),
        child: const Icon(Icons.add),
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
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final moods = snapshot.data!.docs;
        return Scaffold(
          body: ReorderableListView(
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
            children: moods.map((m) {
              final data = m.data() as Map<String, dynamic>;
              return ListTile(
                key: Key(m.id),
                leading: Text(
                  data['emoji'] ?? '?',
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text(data['name'] ?? ''),
                trailing: const Icon(Icons.drag_handle),
                onLongPress: () => FirebaseFirestore.instance
                    .collection('moods')
                    .doc(m.id)
                    .delete(),
              );
            }).toList(),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddMoodDialog(context, moods.length),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  void _showAddMoodDialog(BuildContext context, int count) {
    final nameCtrl = TextEditingController();
    final emojiCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("New Mood"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emojiCtrl,
              decoration: const InputDecoration(labelText: "Emoji"),
            ),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "Name"),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('moods').add({
                'name': nameCtrl.text,
                'emoji': emojiCtrl.text.isEmpty ? "😊" : emojiCtrl.text,
                'order': count,
              });
              Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }
}
