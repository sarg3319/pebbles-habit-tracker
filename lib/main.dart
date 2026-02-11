import 'package:flutter/material.dart';

void main() => runApp(const PebblesApp());

class PebblesApp extends StatelessWidget {
  const PebblesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true, 
        colorSchemeSeed: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class Habit {
  String name;
  String category;
  List<bool> completionHistory; 
  Habit({required this.name, required this.category, required this.completionHistory});
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  late final List<Habit> globalHabits;

  @override
  void initState() {
    super.initState();
    globalHabits = [
      {"name": "Nap", "cat": "Rest"},
      {"name": "Insomnia", "cat": "Health"},
      {"name": "Went outside", "cat": "Health"},
      {"name": "Read", "cat": "Brain"},
      {"name": "Worked out", "cat": "Health"},
      {"name": "Hair wash", "cat": "Self-care"},
      {"name": "Office", "cat": "Work"},
      {"name": "#2", "cat": "Health"},
      {"name": "Lips", "cat": "Self-care"},
      {"name": "Period", "cat": "Health"},
      {"name": "SD", "cat": "Other"},
      {"name": "Placebo", "cat": "Health"},
    ].map((h) => Habit(
      name: h["name"]!, 
      category: h["cat"]!, 
      completionHistory: List.filled(14, false)
    )).toList();
  }

  void _addHabit(String name, String category) {
    setState(() {
      globalHabits.add(Habit(name: name, category: category, completionHistory: List.filled(14, false)));
    });
  }

  void _removeHabit(int index) {
    setState(() {
      globalHabits.removeAt(index);
    });
  }

  // NEW: Logic to handle the drag-and-drop
  void _reorderHabits(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final Habit item = globalHabits.removeAt(oldIndex);
      globalHabits.insert(newIndex, item);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          HabitCalendarScreen(habits: globalHabits), 
          EditHabitsScreen(
            habits: globalHabits, 
            onAdd: _addHabit, 
            onDelete: _removeHabit,
            onReorder: _reorderHabits, // Pass the new function
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.blue,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.calendar_view_month), label: 'Calendar'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Manage'),
        ],
      ),
    );
  }
}

// --- CALENDAR SCREEN (Stays the same as before) ---
class HabitCalendarScreen extends StatefulWidget {
  final List<Habit> habits;
  const HabitCalendarScreen({super.key, required this.habits});
  @override
  State<HabitCalendarScreen> createState() => _HabitCalendarScreenState();
}

class _HabitCalendarScreenState extends State<HabitCalendarScreen> {
  final int daysToDisplay = 14;
  final ScrollController _headerScroll = ScrollController();
  final List<ScrollController> _rowScrolls = [];

  void _syncControllers() {
    _rowScrolls.clear();
    for (var i = 0; i < widget.habits.length; i++) {
      _rowScrolls.add(ScrollController());
    }
  }

  @override
  void initState() {
    super.initState();
    _syncControllers();
    _headerScroll.addListener(() {
      for (var c in _rowScrolls) {
        if (c.hasClients) c.jumpTo(_headerScroll.offset);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_rowScrolls.length != widget.habits.length) _syncControllers();

    return Scaffold(
      appBar: AppBar(title: const Text("Pebbles", style: TextStyle(fontWeight: FontWeight.bold))),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 50,
              decoration: BoxDecoration(color: Colors.grey[50], border: const Border(bottom: BorderSide(color: Colors.black12))),
              child: Row(
                children: [
                  const SizedBox(width: 120, child: Center(child: Text("Habit", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _headerScroll,
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(daysToDisplay, (i) {
                          DateTime date = DateTime.now().subtract(Duration(days: i));
                          String label = i == 0 ? "Today" : (i == 1 ? "Yest." : "${date.day}/${date.month}");
                          return Container(width: 80, alignment: Alignment.center, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)));
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: widget.habits.length,
                itemBuilder: (context, index) {
                  final h = widget.habits[index];
                  return Container(
                    height: 70,
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black12))),
                    child: Row(
                      children: [
                        Container(
                          width: 120, padding: const EdgeInsets.only(left: 12), 
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start,
                            children: [Text(h.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis), Text(h.category, style: TextStyle(fontSize: 10, color: Colors.blueGrey[400]))])
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            controller: _rowScrolls[index],
                            scrollDirection: Axis.horizontal,
                            physics: const NeverScrollableScrollPhysics(),
                            child: Row(
                              children: List.generate(daysToDisplay, (dIndex) => 
                                GestureDetector(
                                  onTap: () => setState(() => h.completionHistory[dIndex] = !h.completionHistory[dIndex]),
                                  child: Container(width: 80, child: Icon(h.completionHistory[dIndex] ? Icons.check_box : Icons.check_box_outline_blank, color: h.completionHistory[dIndex] ? Colors.blue : Colors.black12, size: 28)))),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- UPDATED EDIT SCREEN (With Reordering!) ---
class EditHabitsScreen extends StatefulWidget {
  final List<Habit> habits;
  final Function(String, String) onAdd;
  final Function(int) onDelete;
  final Function(int, int) onReorder; // New

  const EditHabitsScreen({super.key, required this.habits, required this.onAdd, required this.onDelete, required this.onReorder});

  @override
  State<EditHabitsScreen> createState() => _EditHabitsScreenState();
}

class _EditHabitsScreenState extends State<EditHabitsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Habits")),
      body: ReorderableListView.builder( // Switched to Reorderable!
        itemCount: widget.habits.length,
        onReorder: widget.onReorder,
        itemBuilder: (context, index) {
          final habit = widget.habits[index];
          // Each item in a ReorderableListView MUST have a Key
          return ListTile(
            key: ValueKey(habit.name + index.toString()), 
            leading: const Icon(Icons.reorder),
            title: Text(habit.name, style: const TextStyle(fontWeight: FontWeight.w500)),
            subtitle: Text(habit.category),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => widget.onDelete(index),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context),
        label: const Text("Add Habit"),
        icon: const Icon(Icons.add),
      ),
    );
  }

  // (Add Dialog stays the same)
  void _showAddDialog(BuildContext context) {
    final nameController = TextEditingController();
    String selectedCategory = "Health"; 
    final categories = ["Health", "Work", "Self-care", "Brain", "Rest", "Other"];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Add New Habit"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, autofocus: true, decoration: const InputDecoration(labelText: "Habit Name")),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setDialogState(() => selectedCategory = val!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(onPressed: () {
              if (nameController.text.isNotEmpty) {
                widget.onAdd(nameController.text, selectedCategory);
                Navigator.pop(context);
              }
            }, child: const Text("Add")),
          ],
        ),
      ),
    );
  }
}