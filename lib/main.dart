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
  List<bool> completionHistory;
  bool isStreakHabit;
  bool hasNotes;
  int order;

  Habit({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.completionHistory,
    required this.isStreakHabit,
    required this.hasNotes,
    required this.order,
  });

  int get currentStreak {
    if (!isStreakHabit) return 0;
    int streak = 0;
    for (int i = 0; i < completionHistory.length; i++) {
      if (completionHistory[i]) streak++;
      else if (streak > 0) break;
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
              return HabitCategory(id: doc.id, name: data['name'] ?? 'Untitled', color: Color(data['colorValue'] ?? Colors.blue.value));
            }).toList()
          : [];

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('habits').orderBy('order').snapshots(),
          builder: (context, habitSnapshot) {
            if (!habitSnapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
            
            final habits = habitSnapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return Habit(
                id: doc.id,
                name: data['name'] ?? '',
                categoryId: data['categoryId'] ?? '',
                isStreakHabit: data['isStreakHabit'] ?? false,
                hasNotes: data['hasNotes'] ?? false,
                order: data['order'] ?? 0,
                completionHistory: List<bool>.from(data['completionHistory'] ?? List.filled(14, false)),
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
                  BottomNavigationBarItem(icon: Icon(Icons.grid_on), label: 'Board'),
                  BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Manage'),
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
  const HabitCalendarScreen({super.key, required this.habits, required this.categories});

  @override
  State<HabitCalendarScreen> createState() => _HabitCalendarScreenState();
}

class _HabitCalendarScreenState extends State<HabitCalendarScreen> {
  String _selectedFilterId = 'all';

  void _showMoodDialog(int dayIdx) async {
    final date = DateTime.now().subtract(Duration(days: dayIdx));
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final docRef = FirebaseFirestore.instance.collection('daily_metrics').doc(dateStr);
    final doc = await docRef.get();
    
    final moodSnapshot = await FirebaseFirestore.instance.collection('moods').orderBy('order').get();
    final moods = moodSnapshot.docs;
    String? currentMood = doc.exists ? (doc.data() as Map)['mood'] : null;

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Mood: ${DateFormat('MMM d').format(date)}"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: moods.length,
            itemBuilder: (context, i) => ListTile(
              leading: Text(moods[i]['emoji'] ?? '?', style: const TextStyle(fontSize: 24)),
              title: Text(moods[i]['name'] ?? 'Unknown'),
              trailing: currentMood == moods[i]['name'] ? const Icon(Icons.check, color: Colors.green) : null,
              onTap: () async {
                await docRef.set({'mood': moods[i]['name'], 'date': dateStr}, SetOptions(merge: true));
                Navigator.pop(context);
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showDiaryDialog(int dayIdx) async {
    final date = DateTime.now().subtract(Duration(days: dayIdx));
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final docRef = FirebaseFirestore.instance.collection('daily_metrics').doc(dateStr);
    final doc = await docRef.get();
    final ctrl = TextEditingController(text: doc.exists ? (doc.data() as Map)['diary'] ?? "" : "");

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Diary: ${DateFormat('MMM d').format(date)}"),
        content: TextField(controller: ctrl, minLines: 5, maxLines: 8, decoration: const InputDecoration(border: OutlineInputBorder())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(onPressed: () async {
            await docRef.set({'diary': ctrl.text, 'date': dateStr}, SetOptions(merge: true));
            Navigator.pop(context);
          }, child: const Text("Save")),
        ],
      ),
    );
  }

  void _showSleepDialog(int dayIdx) async {
    final date = DateTime.now().subtract(Duration(days: dayIdx));
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final docRef = FirebaseFirestore.instance.collection('daily_metrics').doc(dateStr);
    final doc = await docRef.get();
    final ctrl = TextEditingController(text: doc.exists ? (doc.data() as Map)['sleep']?.toString() ?? "" : "");

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Sleep: ${DateFormat('MMM d').format(date)}"),
        content: TextField(controller: ctrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(suffixText: "hours")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(onPressed: () async {
            await docRef.set({'sleep': double.tryParse(ctrl.text) ?? 0, 'date': dateStr}, SetOptions(merge: true));
            Navigator.pop(context);
          }, child: const Text("Update")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredHabits = _selectedFilterId == 'all' 
        ? widget.habits 
        : widget.habits.where((h) => h.categoryId == _selectedFilterId).toList();

    bool showSystemRows = _selectedFilterId == 'all';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pebbles Board"),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (val) => setState(() => _selectedFilterId = val),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text("All Tags")),
              ...widget.categories.map((c) => PopupMenuItem(value: c.id, child: Text(c.name))),
            ],
          )
        ],
      ),
      body: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('daily_metrics').snapshots(),
              builder: (context, metricSnapshot) {
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('moods').orderBy('order').snapshots(),
                  builder: (context, moodSnapshot) {
                    final metricDocs = metricSnapshot.hasData ? metricSnapshot.data!.docs : [];
                    final moodDocs = moodSnapshot.hasData ? moodSnapshot.data!.docs : [];

                    return Table(
                      defaultColumnWidth: const FixedColumnWidth(45),
                      columnWidths: const {0: FixedColumnWidth(130)},
                      children: [
                        // --- HEADER ---
                        TableRow(children: [
                          const Center(child: Text("Item", style: TextStyle(fontWeight: FontWeight.bold))),
                          ...List.generate(14, (i) {
                            final date = DateTime.now().subtract(Duration(days: i));
                            return Center(child: Text(DateFormat('E d').format(date), style: const TextStyle(fontSize: 10)));
                          }),
                        ]),
                        // --- MOOD (Only if all selected) ---
                        if(showSystemRows) TableRow(children: [
                          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text("Mood", style: TextStyle(fontWeight: FontWeight.w600))),
                          ...List.generate(14, (i) {
                            final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(Duration(days: i)));
                            final dayDoc = metricDocs.cast<QueryDocumentSnapshot?>().firstWhere((d) => d!.id == dateStr, orElse: () => null);
                            final moodName = dayDoc != null ? (dayDoc.data() as Map)['mood'] : null;
                            final emoji = moodDocs.cast<QueryDocumentSnapshot?>().firstWhere((m) => m!['name'] == moodName, orElse: () => null)?['emoji'] ?? "";
                            return GestureDetector(onTap: () => _showMoodDialog(i), child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))));
                          }),
                        ]),
                        // --- DIARY ---
                        if(showSystemRows) TableRow(children: [
                          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text("Diary", style: TextStyle(fontWeight: FontWeight.w600))),
                          ...List.generate(14, (i) {
                            final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(Duration(days: i)));
                            final dayDoc = metricDocs.cast<QueryDocumentSnapshot?>().firstWhere((d) => d!.id == dateStr, orElse: () => null);
                            final hasDiary = dayDoc != null && (dayDoc.data() as Map)['diary'] != null && (dayDoc.data() as Map)['diary'] != "";
                            return IconButton(icon: Icon(hasDiary ? Icons.book : Icons.menu_book, color: hasDiary ? Colors.blue : Colors.grey[200]), onPressed: () => _showDiaryDialog(i));
                          }),
                        ]),
                        // --- SLEEP ---
                        if(showSystemRows) TableRow(children: [
                          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text("Sleep (h)", style: TextStyle(fontWeight: FontWeight.w600))),
                          ...List.generate(14, (i) {
                            final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(Duration(days: i)));
                            final dayDoc = metricDocs.cast<QueryDocumentSnapshot?>().firstWhere((d) => d!.id == dateStr, orElse: () => null);
                            final sleepVal = dayDoc != null ? (dayDoc.data() as Map)['sleep']?.toString() ?? "-" : "-";
                            return GestureDetector(onTap: () => _showSleepDialog(i), child: Container(height: 48, alignment: Alignment.center, child: Text(sleepVal == "0.0" ? "-" : sleepVal, style: const TextStyle(fontWeight: FontWeight.bold))));
                          }),
                        ]),
                        // --- HABITS ---
                        ...filteredHabits.map((h) {
                          final cat = widget.categories.firstWhere((c) => c.id == h.categoryId, orElse: () => HabitCategory(id: '', name: '', color: Colors.blue));
                          return TableRow(children: [
                            Container(
                              height: 50,
                              alignment: Alignment.centerLeft,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(h.name, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis, maxLines: 2),
                                  if (h.isStreakHabit && h.currentStreak > 0) Text("🔥 ${h.currentStreak}", style: const TextStyle(fontSize: 10, color: Colors.orange)),
                                ],
                              ),
                            ),
                            ...List.generate(14, (dayIdx) {
                              bool isDone = h.completionHistory[dayIdx];
                              return GestureDetector(
                                onTap: () {
                                  List<bool> newH = List.from(h.completionHistory);
                                  newH[dayIdx] = !newH[dayIdx];
                                  FirebaseFirestore.instance.collection('habits').doc(h.id).update({'completionHistory': newH});
                                },
                                child: Center(child: Container(height: 30, width: 30, decoration: BoxDecoration(color: isDone ? cat.color : Colors.grey[100], shape: BoxShape.circle))),
                              );
                            }),
                          ]);
                        }),
                      ],
                    );
                  }
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// --- MANAGE SCREEN ---
class ManageScreen extends StatelessWidget {
  final List<Habit> habits;
  final List<HabitCategory> categories;
  const ManageScreen({super.key, required this.habits, required this.categories});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(title: const Text("Settings"), bottom: const TabBar(tabs: [Tab(text: "Habits"), Tab(text: "Tags"), Tab(text: "Moods")])),
        body: TabBarView(children: [_HabitList(habits: habits, categories: categories), _CategoryList(categories: categories), const _MoodList()]),
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
    String? selectedCatId = habit?.categoryId ?? (categories.isNotEmpty ? categories.first.id : null);
    bool isStreak = habit?.isStreakHabit ?? false;
    bool hasNotes = habit?.hasNotes ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDS) => AlertDialog(
          title: Text(habit == null ? "New Habit" : "Edit Habit"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Name")),
              DropdownButtonFormField<String>(
                value: categories.any((c) => c.id == selectedCatId) ? selectedCatId : (categories.isNotEmpty ? categories.first.id : null),
                items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                onChanged: (v) => setDS(() => selectedCatId = v),
                decoration: const InputDecoration(labelText: "Tag"),
              ),
              SwitchListTile(title: const Text("Streak?"), value: isStreak, onChanged: (v) => setDS(() => isStreak = v)),
              SwitchListTile(title: const Text("Notes?"), value: hasNotes, onChanged: (v) => setDS(() => hasNotes = v)),
            ],
          ),
          actions: [
            ElevatedButton(onPressed: () {
              final data = {'name': nameCtrl.text, 'categoryId': selectedCatId, 'isStreakHabit': isStreak, 'hasNotes': hasNotes};
              if (habit == null) {
                FirebaseFirestore.instance.collection('habits').add({...data, 'order': habits.length, 'completionHistory': List.filled(14, false), 'createdAt': FieldValue.serverTimestamp()});
              } else {
                FirebaseFirestore.instance.collection('habits').doc(habit.id).update(data);
              }
              Navigator.pop(context);
            }, child: const Text("Save"))
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
          for (int i = 0; i < list.length; i++) {
            await FirebaseFirestore.instance.collection('habits').doc(list[i].id).update({'order': i});
          }
        },
        children: habits.map((h) => ListTile(
          key: Key(h.id),
          title: Text(h.name),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(icon: const Icon(Icons.edit), onPressed: () => _showHabitDialog(context, habit: h)),
            IconButton(icon: const Icon(Icons.delete), onPressed: () => FirebaseFirestore.instance.collection('habits').doc(h.id).delete()),
            const Icon(Icons.drag_handle),
          ]),
        )).toList(),
      ),
      floatingActionButton: FloatingActionButton(onPressed: () => _showHabitDialog(context), child: const Icon(Icons.add)),
    );
  }
}

class _CategoryList extends StatelessWidget {
  final List<HabitCategory> categories;
  const _CategoryList({required this.categories});

  void _showCategoryDialog(BuildContext context, {HabitCategory? cat}) {
    final ctrl = TextEditingController(text: cat?.name ?? "");
    Color selectedCol = cat?.color ?? Colors.blue;
    showDialog(context: context, builder: (context) => StatefulBuilder(builder: (context, setDS) => AlertDialog(
      title: Text(cat == null ? "New Tag" : "Edit Tag"),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: ctrl, decoration: const InputDecoration(labelText: "Tag Name")),
        const SizedBox(height: 10),
        Wrap(spacing: 8, children: [Colors.red, Colors.green, Colors.blue, Colors.orange, Colors.purple].map((c) => GestureDetector(
          onTap: () => setDS(() => selectedCol = c),
          child: CircleAvatar(backgroundColor: c, radius: 15, child: selectedCol.value == c.value ? const Icon(Icons.check, size: 14) : null),
        )).toList()),
      ]),
      actions: [ElevatedButton(onPressed: () {
        final data = {'name': ctrl.text, 'colorValue': selectedCol.value};
        if (cat == null) FirebaseFirestore.instance.collection('categories').add(data);
        else FirebaseFirestore.instance.collection('categories').doc(cat.id).update(data);
        Navigator.pop(context);
      }, child: const Text("Save"))],
    )));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, i) => ListTile(
          leading: CircleAvatar(backgroundColor: categories[i].color),
          title: Text(categories[i].name),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(icon: const Icon(Icons.edit), onPressed: () => _showCategoryDialog(context, cat: categories[i])),
            IconButton(icon: const Icon(Icons.delete), onPressed: () => FirebaseFirestore.instance.collection('categories').doc(categories[i].id).delete()),
          ]),
        ),
      ),
      floatingActionButton: FloatingActionButton(onPressed: () => _showCategoryDialog(context), child: const Icon(Icons.add)),
    );
  }
}

class _MoodList extends StatelessWidget {
  const _MoodList();
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('moods').orderBy('order').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final moods = snapshot.data!.docs;
        return Scaffold(
          body: ReorderableListView(
            onReorder: (oldIdx, newIdx) async {
              if (newIdx > oldIdx) newIdx -= 1;
              final list = List.from(moods);
              final item = list.removeAt(oldIdx);
              list.insert(newIdx, item);
              for (int i = 0; i < list.length; i++) await list[i].reference.update({'order': i});
            },
            children: moods.map((doc) => ListTile(
              key: Key(doc.id),
              leading: Text(doc['emoji'] ?? "❓", style: const TextStyle(fontSize: 24)),
              title: Text(doc['name'] ?? 'Untitled'),
              trailing: const Icon(Icons.drag_handle),
            )).toList(),
          ),
          floatingActionButton: FloatingActionButton(onPressed: () {
            final nCtrl = TextEditingController(); final eCtrl = TextEditingController();
            showDialog(context: context, builder: (context) => AlertDialog(
              title: const Text("Add Mood"),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(controller: eCtrl, decoration: const InputDecoration(hintText: "Emoji")),
                TextField(controller: nCtrl, decoration: const InputDecoration(hintText: "Name")),
              ]),
              actions: [ElevatedButton(onPressed: () {
                FirebaseFirestore.instance.collection('moods').add({'name': nCtrl.text, 'emoji': eCtrl.text, 'order': moods.length});
                Navigator.pop(context);
              }, child: const Text("Add"))],
            ));
          }, child: const Icon(Icons.add)),
        );
      },
    );
  }
}