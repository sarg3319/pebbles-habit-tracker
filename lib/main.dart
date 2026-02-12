import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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

// --- THE DATA MODEL ---
class Habit {
  String id;
  String name;
  String category;
  List<bool> completionHistory;
  bool isStreakHabit;

  Habit({
    required this.id,
    required this.name,
    required this.category,
    required this.completionHistory,
    required this.isStreakHabit,
  });

  // LOGIC: Calculate current streak (counting back from today)
  int get currentStreak {
    if (!isStreakHabit) return 0;
    int streak = 0;
    for (int i = completionHistory.length - 1; i >= 0; i--) {
      if (completionHistory[i]) {
        streak++;
      } else {
        if (streak > 0) break;
      }
    }
    return streak;
  }

  Color get color {
    switch (category) {
      case 'Health': return Colors.green;
      case 'Work': return Colors.orange;
      case 'Brain': return Colors.purple;
      case 'Rest': return Colors.blueGrey;
      default: return Colors.blue;
    }
  }
}

// --- MAIN NAVIGATION (THE BRAIN) ---
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  void _addHabit(String name, String category, bool isStreak) async {
    await FirebaseFirestore.instance.collection('habits').add({
      'name': name,
      'category': category,
      'isStreakHabit': isStreak,
      'completionHistory': List.filled(14, false),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  void _removeHabit(String docId) async {
    await FirebaseFirestore.instance.collection('habits').doc(docId).delete();
  }

  void _toggleHabitDay(Habit habit, int dayIndex) async {
    List<bool> newHistory = List.from(habit.completionHistory);
    newHistory[dayIndex] = !newHistory[dayIndex];

    await FirebaseFirestore.instance
        .collection('habits')
        .doc(habit.id)
        .update({'completionHistory': newHistory});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('habits').orderBy('createdAt').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          List<Habit> habits = snapshot.data!.docs.map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            return Habit(
              id: doc.id,
              name: data['name'] ?? '',
              category: data['category'] ?? 'Health',
              isStreakHabit: data['isStreakHabit'] ?? false,
              completionHistory: List<bool>.from(data['completionHistory'] ?? List.filled(14, false)),
            );
          }).toList();

          return IndexedStack(
            index: _selectedIndex,
            children: [
              HabitCalendarScreen(habits: habits, onToggle: _toggleHabitDay),
              EditHabitsScreen(habits: habits, onAdd: _addHabit, onDelete: _removeHabit),
            ],
          );
        },
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
  }
}

// --- CALENDAR BOARD (THE TABLE) ---
class HabitCalendarScreen extends StatelessWidget {
  final List<Habit> habits;
  final Function(Habit, int) onToggle;

  const HabitCalendarScreen({super.key, required this.habits, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pebbles Board")),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Table(
              defaultColumnWidth: const FixedColumnWidth(45),
              columnWidths: const {0: FixedColumnWidth(120)}, // Wider for name + streak
              children: [
                TableRow(
                  children: [
                    const Center(child: Text("Habit", style: TextStyle(fontWeight: FontWeight.bold))),
                    ...List.generate(14, (i) => Center(
                      child: Text("${i + 1}", style: const TextStyle(fontSize: 12, color: Colors.grey))
                    )),
                  ],
                ),
                ...habits.map((h) => TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(h.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                          if (h.isStreakHabit && h.currentStreak > 0)
                            Text("🔥 ${h.currentStreak}", style: const TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    ...List.generate(14, (dayIdx) {
                      bool isDone = h.completionHistory[dayIdx];
                      return GestureDetector(
                        onTap: () => onToggle(h, dayIdx),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 32,
                            decoration: BoxDecoration(
                              color: isDone ? h.color : Colors.grey[200],
                              shape: BoxShape.circle,
                              border: Border.all(color: isDone ? h.color : Colors.grey[300]!),
                              boxShadow: isDone ? [
                                BoxShadow(color: h.color.withOpacity(0.4), blurRadius: 4, spreadRadius: 1)
                              ] : [],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- MANAGE SCREEN (THE SETTINGS) ---
class EditHabitsScreen extends StatelessWidget {
  final List<Habit> habits;
  final Function(String, String, bool) onAdd; // Updated for streak bool
  final Function(String) onDelete;

  const EditHabitsScreen({super.key, required this.habits, required this.onAdd, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Habits")),
      body: ListView.builder(
        itemCount: habits.length,
        itemBuilder: (context, index) {
          final h = habits[index];
          return ListTile(
            title: Text(h.name),
            subtitle: Text("${h.category}${h.isStreakHabit ? ' • Streak enabled' : ''}"),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => onDelete(h.id),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final controller = TextEditingController();
    String selectedCategory = 'Health';
    bool isStreak = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("New Habit"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: controller, decoration: const InputDecoration(hintText: "Name"), autofocus: true),
              const SizedBox(height: 20),
              DropdownButton<String>(
                value: selectedCategory,
                isExpanded: true,
                items: ['Health', 'Work', 'Brain', 'Rest', 'Other']
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (val) => setDialogState(() => selectedCategory = val!),
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                title: const Text("Track Streak?", style: TextStyle(fontSize: 14)),
                value: isStreak,
                onChanged: (val) => setDialogState(() => isStreak = val),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  onAdd(controller.text, selectedCategory, isStreak);
                  Navigator.pop(context);
                }
              }, 
              child: const Text("Add"),
            ),
          ],
        ),
      ),
    );
  }
}