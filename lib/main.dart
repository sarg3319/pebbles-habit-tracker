import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:share_plus/share_plus.dart';
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
    if (completionMap[todayStr] == true) {
      streak++;
    }

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
      stream: FirebaseFirestore.instance.collection('categories').snapshots(),
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

  String _getDateStr(int daysAgo) {
    return DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime.now().subtract(Duration(days: daysAgo)));
  }

  void _showMoodDialog(int dayIdx) async {
    final dateStr = _getDateStr(dayIdx);
    final docRef = FirebaseFirestore.instance
        .collection('daily_metrics')
        .doc(dateStr);
    final moodSnapshot = await FirebaseFirestore.instance
        .collection('moods')
        .orderBy('order')
        .get();
    final moodsToDisplay = moodSnapshot.docs.isNotEmpty
        ? moodSnapshot.docs
              .map((d) => d.data() as Map<String, dynamic>)
              .toList()
        : [
            {'emoji': '😊', 'name': 'Happy'},
            {'emoji': '😐', 'name': 'Neutral'},
            {'emoji': '😔', 'name': 'Sad'},
          ];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Mood: ${DateFormat('MMM d').format(DateTime.parse(dateStr))}",
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: moodsToDisplay.length,
            itemBuilder: (context, i) => ListTile(
              leading: Text(
                moodsToDisplay[i]['emoji'] ?? '?',
                style: const TextStyle(fontSize: 24),
              ),
              title: Text(moodsToDisplay[i]['name'] ?? ''),
              onTap: () {
                docRef.set({
                  'mood': moodsToDisplay[i]['name'],
                  'date': dateStr,
                }, SetOptions(merge: true));
                Navigator.pop(context);
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showDiaryDialog(int dayIdx) async {
    final dateStr = _getDateStr(dayIdx);
    final docRef = FirebaseFirestore.instance
        .collection('daily_metrics')
        .doc(dateStr);
    final doc = await docRef.get();
    final ctrl = TextEditingController(
      text: doc.exists ? (doc.data() as Map)['diary'] ?? "" : "",
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Diary: ${DateFormat('MMM d').format(DateTime.parse(dateStr))}",
        ),
        content: TextField(
          controller: ctrl,
          minLines: 4,
          maxLines: 6,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              docRef.set({
                'diary': ctrl.text,
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
        title: Text(
          "Sleep: ${DateFormat('MMM d').format(DateTime.parse(dateStr))}",
        ),
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
              docRef.set({
                'sleep': double.tryParse(ctrl.text) ?? 0,
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

  void _showHabitNoteDialog(Habit habit, int dayIdx) async {
    final dateStr = _getDateStr(dayIdx);
    final noteRef = FirebaseFirestore.instance
        .collection('habit_notes')
        .doc("${habit.id}_$dateStr");
    final doc = await noteRef.get();
    final ctrl = TextEditingController(
      text: doc.exists ? doc.data()!['note'] : "",
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("${habit.name} Note"),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(hintText: "Daily note..."),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              noteRef.set({
                'note': ctrl.text,
                'date': dateStr,
                'habitId': habit.id,
              });
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredHabits = widget.habits.where((h) {
      if (!h.isVisible) return false;
      if (_selectedFilterId == 'all') return true;
      return h.categoryId == _selectedFilterId || h.isSystem;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pebbles Board"),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (val) => setState(() => _selectedFilterId = val),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text("All Tags")),
              ...widget.categories.map(
                (c) => PopupMenuItem(value: c.id, child: Text(c.name)),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('daily_metrics')
                  .snapshots(),
              builder: (context, metricSnapshot) {
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('moods')
                      .snapshots(),
                  builder: (context, moodSnapshot) {
                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('habit_notes')
                          .snapshots(),
                      builder: (context, noteSnapshot) {
                        final metrics = metricSnapshot.hasData
                            ? metricSnapshot.data!.docs
                            : [];
                        final moods = moodSnapshot.hasData
                            ? moodSnapshot.data!.docs
                            : [];
                        final notes = noteSnapshot.hasData
                            ? noteSnapshot.data!.docs
                            : [];
                        return Table(
                          defaultColumnWidth: const FixedColumnWidth(45),
                          columnWidths: const {0: FixedColumnWidth(145)},
                          children: [
                            TableRow(
                              children: [
                                const Center(
                                  child: Text(
                                    "Item",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                ...List.generate(
                                  14,
                                  (i) => Center(
                                    child: Text(
                                      DateFormat('E d').format(
                                        DateTime.now().subtract(
                                          Duration(days: i),
                                        ),
                                      ),
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            ...filteredHabits.map(
                              (h) => TableRow(
                                children: [
                                  _buildHabitLabel(h),
                                  ...List.generate(
                                    14,
                                    (dayIdx) => _buildHabitCell(
                                      h,
                                      dayIdx,
                                      metrics,
                                      moods,
                                      notes,
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
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHabitLabel(Habit h) {
    final streakCount = h.calculateStreak;
    return Container(
      height: 55,
      padding: const EdgeInsets.only(right: 8),
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
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (h.isStreakHabit && streakCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                "🔥$streakCount",
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHabitCell(
    Habit h,
    int dayIdx,
    List metrics,
    List moods,
    List notes,
  ) {
    final dateStr = _getDateStr(dayIdx);
    final dayData =
        metrics
                .cast<QueryDocumentSnapshot?>()
                .firstWhere((d) => d!.id == dateStr, orElse: () => null)
                ?.data()
            as Map?;
    if (h.name == "Mood") {
      final moodName = dayData?['mood'];
      final emoji =
          moods.cast<QueryDocumentSnapshot?>().firstWhere(
            (m) => m!['name'] == moodName,
            orElse: () => null,
          )?['emoji'] ??
          "❔";
      return GestureDetector(
        onTap: () => _showMoodDialog(dayIdx),
        child: Container(
          height: 55,
          alignment: Alignment.center,
          child: Text(emoji, style: const TextStyle(fontSize: 22)),
        ),
      );
    }
    if (h.name == "Sleep") {
      final sleep = dayData?['sleep']?.toString() ?? "-";
      return GestureDetector(
        onTap: () => _showSleepDialog(dayIdx),
        child: Container(
          height: 55,
          alignment: Alignment.center,
          child: Text(
            sleep == "0.0" || sleep == "0" ? "-" : sleep,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
    if (h.name == "Diary") {
      final hasDiary = dayData?['diary'] != null && dayData?['diary'] != "";
      return Container(
        height: 55,
        alignment: Alignment.center,
        child: IconButton(
          icon: Icon(
            hasDiary ? Icons.book : Icons.menu_book,
            color: hasDiary ? Colors.blue : Colors.grey[200],
          ),
          onPressed: () => _showDiaryDialog(dayIdx),
        ),
      );
    }
    final cat = widget.categories.firstWhere(
      (c) => c.id == h.categoryId,
      orElse: () => HabitCategory(id: '', name: '', color: Colors.blue),
    );
    bool isDone = h.completionMap[dateStr] ?? false;
    bool hasNote = notes.any(
      (n) => n.id == "${h.id}_$dateStr" && (n.data() as Map)['note'] != "",
    );
    return GestureDetector(
      onTap: () {
        Map<String, bool> newMap = Map.from(h.completionMap);
        newMap[dateStr] = !isDone;
        FirebaseFirestore.instance.collection('habits').doc(h.id).update({
          'completionMap': newMap,
        });
      },
      onLongPress: () => _showHabitNoteDialog(h, dayIdx),
      child: Container(
        height: 55,
        alignment: Alignment.center,
        child: Container(
          height: 30,
          width: 30,
          decoration: BoxDecoration(
            color: isDone ? cat.color : Colors.grey[100],
            shape: BoxShape.circle,
          ),
          child: hasNote
              ? Center(
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

// --- MANAGE SCREEN (EXPORT TAB INCLUDED) ---
class ManageScreen extends StatelessWidget {
  final List<Habit> habits;
  final List<HabitCategory> categories;
  const ManageScreen({
    super.key,
    required this.habits,
    required this.categories,
  });

  void _exportData(BuildContext context) async {
    final metricsSnap = await FirebaseFirestore.instance
        .collection('daily_metrics')
        .get();
    final metricsData = {for (var doc in metricsSnap.docs) doc.id: doc.data()};

    final habitList = habits
        .map(
          (h) => {
            'name': h.name,
            'tag': categories
                .firstWhere(
                  (c) => c.id == h.categoryId,
                  orElse: () =>
                      HabitCategory(id: '', name: 'None', color: Colors.grey),
                )
                .name,
            'completions': h.completionMap,
          },
        )
        .toList();

    final fullExport = {
      'exportDate': DateTime.now().toIso8601String(),
      'habits': habitList,
      'dailyMetrics': metricsData,
    };

    String prettyJson = const JsonEncoder.withIndent('  ').convert(fullExport);
    await Share.share(prettyJson, subject: 'Pebbles Data Export');
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Settings"),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: "Habits"),
              Tab(text: "Tags"),
              Tab(text: "Moods"),
              Tab(text: "Export"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _HabitList(habits: habits, categories: categories),
            _CategoryList(categories: categories),
            _MoodList(),
            _ExportTab(onExport: () => _exportData(context)),
          ],
        ),
      ),
    );
  }
}

class _ExportTab extends StatelessWidget {
  final VoidCallback onExport;
  const _ExportTab({required this.onExport});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.cloud_download_outlined,
            size: 80,
            color: Colors.blueGrey,
          ),
          const SizedBox(height: 20),
          const Text(
            "Data Backup",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
            child: Text(
              "Export your history to a JSON file. You can paste this into a spreadsheet or ChatGPT for personal analysis.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton.icon(
            onPressed: onExport,
            icon: const Icon(Icons.share),
            label: const Text("Export Raw Data"),
          ),
        ],
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
    String? selectedCatId =
        habit?.categoryId ??
        (categories.isNotEmpty ? categories.first.id : null);
    bool isStreak = habit?.isStreakHabit ?? false;
    bool isVisible = habit?.isVisible ?? true;
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
                  decoration: const InputDecoration(labelText: "Name"),
                ),
                DropdownButtonFormField<String>(
                  value: categories.any((c) => c.id == selectedCatId)
                      ? selectedCatId
                      : (categories.isNotEmpty ? categories.first.id : null),
                  items: categories
                      .map(
                        (c) => DropdownMenuItem(
                          value: c.id,
                          child: Row(
                            children: [
                              CircleAvatar(backgroundColor: c.color, radius: 8),
                              const SizedBox(width: 10),
                              Text(c.name),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setDS(() => selectedCatId = v),
                  decoration: const InputDecoration(labelText: "Tag"),
                ),
                SwitchListTile(
                  title: const Text("Show Streak?"),
                  value: isStreak,
                  onChanged: (v) => setDS(() => isStreak = v),
                ),
                SwitchListTile(
                  title: const Text("Visible on Board"),
                  value: isVisible,
                  onChanged: (v) => setDS(() => isVisible = v),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                final data = {
                  'name': nameCtrl.text,
                  'categoryId': selectedCatId ?? '',
                  'isStreakHabit': isStreak,
                  'isVisible': isVisible,
                };
                if (habit == null)
                  FirebaseFirestore.instance.collection('habits').add({
                    ...data,
                    'order': habits.length,
                    'completionMap': {},
                    'isSystem': false,
                    'hasNotes': true,
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: ReorderableListView(
        onReorder: (oldIdx, newIdx) async {
          if (newIdx > oldIdx) newIdx -= 1;
          final list = List<Habit>.from(habits);
          final item = list.removeAt(oldIdx);
          list.insert(newIdx, item);
          for (int i = 0; i < list.length; i++)
            await FirebaseFirestore.instance
                .collection('habits')
                .doc(list[i].id)
                .update({'order': i});
        },
        children: habits.map((h) {
          final cat = categories.firstWhere(
            (c) => c.id == h.categoryId,
            orElse: () => HabitCategory(id: '', name: '', color: Colors.grey),
          );
          return ListTile(
            key: Key(h.id),
            leading: Icon(
              h.isSystem ? Icons.layers : Icons.star,
              color: h.isSystem ? Colors.blue : cat.color,
            ),
            title: Text(h.name),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (h.isSystem)
                  Switch(
                    value: h.isVisible,
                    onChanged: (v) => FirebaseFirestore.instance
                        .collection('habits')
                        .doc(h.id)
                        .update({'isVisible': v}),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showHabitDialog(context, habit: h),
                  ),
                if (!h.isSystem)
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => FirebaseFirestore.instance
                        .collection('habits')
                        .doc(h.id)
                        .delete(),
                  ),
                const Icon(Icons.drag_handle),
              ],
            ),
          );
        }).toList(),
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
    final ctrl = TextEditingController(text: cat?.name ?? "");
    Color selectedCol = cat?.color ?? Colors.blue;
    final colors = [
      Colors.red,
      Colors.orange,
      Colors.yellow[600]!,
      Colors.green,
      Colors.blue,
      Colors.indigo,
      Colors.purple,
      const Color(0xFFFFB3BA),
      const Color(0xFFFFDFBA),
      const Color(0xFFFFFFBA),
      const Color(0xFFBAFFC9),
      const Color(0xFFBAE1FF),
      const Color(0xFFD4B9FF),
      const Color(0xFFF2F2F2),
      Colors.black54,
    ];
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
                  controller: ctrl,
                  decoration: const InputDecoration(labelText: "Tag Name"),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Select Color",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: colors
                      .map(
                        (c) => GestureDetector(
                          onTap: () => setDS(() => selectedCol = c),
                          child: Container(
                            width: 35,
                            height: 35,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selectedCol.value == c.value
                                    ? Colors.black
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: selectedCol.value == c.value
                                ? const Icon(
                                    Icons.check,
                                    size: 20,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                final data = {
                  'name': ctrl.text,
                  'colorValue': selectedCol.value,
                };
                if (cat == null)
                  FirebaseFirestore.instance.collection('categories').add(data);
                else
                  FirebaseFirestore.instance
                      .collection('categories')
                      .doc(cat.id)
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, i) => ListTile(
          leading: CircleAvatar(backgroundColor: categories[i].color),
          title: Text(categories[i].name),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () =>
                    _showCategoryDialog(context, cat: categories[i]),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => FirebaseFirestore.instance
                    .collection('categories')
                    .doc(categories[i].id)
                    .delete(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryDialog(context),
        child: const Icon(Icons.add),
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
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final moods = snapshot.data!.docs;
        return Scaffold(
          body: ReorderableListView(
            onReorder: (oldIdx, newIdx) async {
              if (newIdx > oldIdx) newIdx -= 1;
              final list = List.from(moods);
              final item = list.removeAt(oldIdx);
              list.insert(newIdx, item);
              for (int i = 0; i < list.length; i++)
                await list[i].reference.update({'order': i});
            },
            children: moods
                .map(
                  (doc) => ListTile(
                    key: Key(doc.id),
                    leading: Text(
                      doc['emoji'] ?? "❓",
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(doc['name'] ?? 'Untitled'),
                    trailing: const Icon(Icons.drag_handle),
                  ),
                )
                .toList(),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              final nCtrl = TextEditingController();
              final eCtrl = TextEditingController();
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Add Mood"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: eCtrl,
                        decoration: const InputDecoration(hintText: "Emoji"),
                      ),
                      TextField(
                        controller: nCtrl,
                        decoration: const InputDecoration(hintText: "Name"),
                      ),
                    ],
                  ),
                  actions: [
                    ElevatedButton(
                      onPressed: () {
                        FirebaseFirestore.instance.collection('moods').add({
                          'name': nCtrl.text,
                          'emoji': eCtrl.text,
                          'order': moods.length,
                        });
                        Navigator.pop(context);
                      },
                      child: const Text("Add"),
                    ),
                  ],
                ),
              );
            },
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}
