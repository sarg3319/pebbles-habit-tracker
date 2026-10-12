import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
      theme: _pebblesTheme(),
      home: const MainNavigationScreen(),
    );
  }
}

// --- DESIGN TOKENS ---
// iOS system colors: grouped background with white cards, one accent tint,
// and a visible-but-quiet fill for "not yet logged" marks.
const Color _kAccent = Color(0xFF007AFF);
const Color _kGroupedBackground = Color(0xFFF2F2F7);
const Color _kEmptyMark = Color(0xFFE5E5EA);
const Color _kSecondaryLabel = Color(0xFF8E8E93);
const Color _kHairline = Color(0x1F000000);
const Color _kDestructive = Color(0xFFFF3B30);

ThemeData _pebblesTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: _kAccent).copyWith(
    primary: _kAccent,
    surface: Colors.white,
    surfaceTint: Colors.transparent,
    error: _kDestructive,
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  final rounded12 = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  );
  final fieldBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide.none,
  );
  return base.copyWith(
    scaffoldBackgroundColor: _kGroupedBackground,
    // Press feedback is an instant highlight on touch-down, not a ripple
    // that blooms after the finger has already moved on.
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.black.withValues(alpha: 0.06),
    // Cupertino routes slide in from the right, leave the same way, and can
    // be grabbed mid-flight with an edge swipe.
    pageTransitionsTheme: PageTransitionsTheme(
      builders: {
        for (final p in TargetPlatform.values)
          p: const CupertinoPageTransitionsBuilder(),
      },
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: _kGroupedBackground,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Colors.black,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6, // large titles want negative tracking
        height: 1.1,
      ),
      iconTheme: IconThemeData(color: _kAccent),
      actionsIconTheme: IconThemeData(color: _kAccent),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      elevation: 0,
      selectedItemColor: _kAccent,
      unselectedItemColor: _kSecondaryLabel,
      selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 10),
      showUnselectedLabels: true,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      titleTextStyle: const TextStyle(
        color: Colors.black,
        fontSize: 19,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 10,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _kGroupedBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: fieldBorder,
      enabledBorder: fieldBorder,
      focusedBorder: fieldBorder.copyWith(
        borderSide: const BorderSide(color: _kAccent, width: 1.5),
      ),
      floatingLabelStyle: const TextStyle(color: _kAccent),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _kAccent,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: rounded12,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: _kAccent, shape: rounded12),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: const WidgetStatePropertyAll(Colors.white),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? const Color(0xFF34C759)
            : _kEmptyMark,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      side: const BorderSide(color: _kSecondaryLabel, width: 1.5),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white,
      selectedColor: _kAccent.withValues(alpha: 0.14),
      side: BorderSide.none,
      shape: const StadiumBorder(),
      showCheckmark: false,
      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: _kAccent,
      unselectedLabelColor: _kSecondaryLabel,
      indicatorColor: _kAccent,
      dividerColor: _kHairline,
      labelStyle: TextStyle(fontWeight: FontWeight.w600),
    ),
    dividerTheme: const DividerThemeData(color: _kHairline, thickness: 0.5),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: _kAccent),
  );
}

bool _reduceMotion(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false;

// Shrinks on touch-down and springs back on release. Uses a Listener so it
// never competes with the child's tap/long-press recognizers, and starts every
// spring from the current on-screen value so rapid taps stay continuous.
class _PressScale extends StatefulWidget {
  final Widget child;
  const _PressScale({required this.child});
  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale>
    with SingleTickerProviderStateMixin {
  // Critically damped (no overshoot), ~0.3s response.
  static final _spring = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 440,
    ratio: 1.0,
  );
  late final AnimationController _c = AnimationController.unbounded(
    vsync: this,
    value: 1,
  );
  Offset? _down;

  void _to(double target) {
    if (_reduceMotion(context)) {
      _c.value = 1;
      return;
    }
    _c.animateWith(SpringSimulation(_spring, _c.value, target, _c.velocity));
  }

  void _release() {
    _down = null;
    _to(1);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (e) {
        _down = e.position;
        _to(0.92);
      },
      // ~10px of hysteresis: once the finger travels, it's a scroll, not a press.
      onPointerMove: (e) {
        if (_down != null && (e.position - _down!).distance > 10) _release();
      },
      onPointerUp: (_) => _release(),
      onPointerCancel: (_) => _release(),
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) =>
            Transform.scale(scale: _c.value, child: child),
        child: widget.child,
      ),
    );
  }
}

Future<bool> _confirmDelete(BuildContext context, String what) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Delete $what?'),
      content: const Text('This can\'t be undone.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(foregroundColor: _kDestructive),
          child: const Text(
            'Delete',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
  return ok ?? false;
}

Widget _lockedWritingField({
  required TextEditingController controller,
  required String hintText,
  double width = 300,
  double height = 180,
}) {
  return SizedBox(
    width: width,
    height: height,
    child: TextField(
      controller: controller,
      expands: true,
      maxLines: null,
      minLines: null,
      keyboardType: TextInputType.multiline,
      textAlignVertical: TextAlignVertical.top,
      textCapitalization: TextCapitalization.sentences,
      scrollPhysics: const ClampingScrollPhysics(),
      decoration: InputDecoration(hintText: hintText, alignLabelWithHint: true),
    ),
  );
}

Widget _numberOnlyField(TextEditingController controller) {
  return TextField(
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    textInputAction: TextInputAction.done,
    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))],
  );
}

Widget _favoriteHeart({double size = 12}) {
  return Icon(Icons.favorite, size: size, color: Colors.redAccent);
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

String _habitTypeFromData(Map<String, dynamic> d) {
  final type = d['habitType'] ?? d['type'];
  if (type == 'note' || type == 'number' || type == 'check') {
    return type;
  }

  // Keep the older built-in habits working even if they do not have a type yet.
  final name = d['name'] ?? '';
  if (name == 'Diary' || name == 'Dreams') return 'note';
  if (name == 'Sleep' || name == 'Sleep score') return 'number';
  return 'check';
}

class Habit {
  String id;
  String name;
  String categoryId;
  String habitType;
  Map<String, bool> completionMap;
  Map<String, dynamic> valueMap;
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
    this.habitType = 'check',
    required this.completionMap,
    this.valueMap = const {},
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

  static String _dateKey(DateTime date) =>
      DateFormat('yyyy-MM-dd').format(date);

  bool _hasLoggedEntryOn(DateTime date) {
    final key = _dateKey(date);
    switch (habitType) {
      case 'number':
        return double.tryParse(valueMap[key]?.toString() ?? '') != null;
      case 'note':
        return valueMap[key]?.toString().trim().isNotEmpty ?? false;
      default:
        return completionMap[key] == true;
    }
  }

  double? _numericValueOn(DateTime date) {
    final key = _dateKey(date);
    return double.tryParse(valueMap[key]?.toString() ?? '');
  }

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

  int getLoggedCount(int days) {
    int count = 0;
    DateTime now = DateTime.now();
    for (int i = 0; i < days; i++) {
      if (_hasLoggedEntryOn(now.subtract(Duration(days: i)))) count++;
    }
    return count;
  }

  double? averageValue(int days) {
    if (habitType != 'number') return null;
    double total = 0;
    int count = 0;
    DateTime now = DateTime.now();
    for (int i = 0; i < days; i++) {
      final value = _numericValueOn(now.subtract(Duration(days: i)));
      if (value != null) {
        total += value;
        count++;
      }
    }
    if (count == 0) return null;
    return total / count;
  }

  int get calculateStreak {
    int streak = 0;
    DateTime date = DateTime.now();
    if (!_hasLoggedEntryOn(date)) {
      date = date.subtract(const Duration(days: 1));
    }
    while (_hasLoggedEntryOn(date)) {
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
  String _boardTitle = 'Board';

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
                habitType: _habitTypeFromData(d),
                order: d['order'] ?? 0,
                insightOrder: d['insightOrder'] ?? 0,
                isSystem: false,
                isVisible: d['isVisible'] ?? true,
                isFavorite: d['isFavorite'] ?? false,
                showInAnalytics: d['showInAnalytics'] ?? false,
                showStreak: d['showStreak'] ?? true,
                backgroundColorValue: d['backgroundColorValue'] ?? 0xFFFFFFFF,
                description: d['description'] ?? "",
                completionMap: Map<String, bool>.from(d['completionMap'] ?? {}),
                valueMap: Map<String, dynamic>.from(d['valueMap'] ?? {}),
              );
            }).toList();

            return Scaffold(
              body: IndexedStack(
                index: _selectedIndex,
                children: [
                  HabitCalendarScreen(
                    habits: habits,
                    categories: categories,
                    initialFilters: _selectedFilters,
                    title: _boardTitle,
                  ),
                  HomeFlowShell(habits: habits, categories: categories),
                  const JournalScreen(), // NEW SCREEN
                  InsightsScreen(habits: habits, categories: categories),
                  ManageScreen(habits: habits, categories: categories),
                ],
              ),
              bottomNavigationBar: DecoratedBox(
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: _kHairline, width: 0.5),
                  ),
                ),
                child: BottomNavigationBar(
                  currentIndex: _selectedIndex,
                  type: BottomNavigationBarType.fixed,
                  onTap: (i) => setState(() {
                    _selectedIndex = i;
                    if (i != 0) _selectedFilters = ['all'];
                    if (i != 0) _boardTitle = 'Board';
                  }),
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.grid_view_rounded),
                      label: 'Board',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.list_alt_rounded),
                      label: 'List',
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
              ),
            );
          },
        );
      },
    );
  }
}

// --- HOME ---
class HomeFlowShell extends StatefulWidget {
  final List<Habit> habits;
  final List<HabitCategory> categories;
  const HomeFlowShell({
    super.key,
    required this.habits,
    required this.categories,
  });

  @override
  State<HomeFlowShell> createState() => _HomeFlowShellState();
}

class _HomeFlowShellState extends State<HomeFlowShell> {
  bool _showBoard = false;
  String _filterId = 'all';
  String _title = 'Board';
  String? _singleHabitId;

  void _openBoard(String filterId, String title, {String? singleHabitId}) {
    setState(() {
      _showBoard = true;
      _boardSettledAway = false;
      _filterId = filterId;
      _title = title;
      _singleHabitId = singleHabitId;
    });
  }

  void _goBackHome() {
    setState(() {
      _showBoard = false;
      _filterId = 'all';
      _title = 'Board';
      _singleHabitId = null;
    });
  }

  // Keeps the board out of paint/hit-testing once it has fully slid away.
  bool _boardSettledAway = true;

  @override
  Widget build(BuildContext context) {
    // Same path in and out (from/to the right edge), and the list recedes a
    // little underneath, like a navigation push. Implicit animations restart
    // from the current position, so a quick back-and-forth never jumps.
    final duration = _reduceMotion(context)
        ? Duration.zero
        : const Duration(milliseconds: 380);
    const curve = Curves.easeOutCubic;
    return Stack(
      children: [
        AnimatedSlide(
          offset: _showBoard ? const Offset(-0.25, 0) : Offset.zero,
          duration: duration,
          curve: curve,
          child: IgnorePointer(
            ignoring: _showBoard,
            child: ExcludeSemantics(
              excluding: _showBoard,
              child: CategoryHomeScreen(
                onOpenBoard: _openBoard,
                habits: widget.habits,
                categories: widget.categories,
              ),
            ),
          ),
        ),
        Offstage(
          offstage: _boardSettledAway,
          child: AnimatedSlide(
            offset: _showBoard ? Offset.zero : const Offset(1, 0),
            duration: duration,
            curve: curve,
            onEnd: () {
              if (!_showBoard) setState(() => _boardSettledAway = true);
            },
            child: IgnorePointer(
              ignoring: !_showBoard,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 24)],
                ),
                child: HabitCalendarScreen(
                  habits: widget.habits,
                  categories: widget.categories,
                  initialFilters: [_filterId],
                  title: _title,
                  onBackToHome: _goBackHome,
                  showHiddenHabits: true,
                  forceAlphabetical: true,
                  singleHabitId: _singleHabitId,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CategoryHomeScreen extends StatefulWidget {
  final void Function(String filterId, String title, {String? singleHabitId})
  onOpenBoard;
  final List<Habit> habits;
  final List<HabitCategory> categories;
  const CategoryHomeScreen({
    super.key,
    required this.onOpenBoard,
    required this.habits,
    required this.categories,
  });

  @override
  State<CategoryHomeScreen> createState() => _CategoryHomeScreenState();
}

class _CategoryHomeScreenState extends State<CategoryHomeScreen> {
  final Set<String> _expandedSections = <String>{};

  Future<void> _toggleVisible(Habit habit) async {
    await FirebaseFirestore.instance.collection('habits').doc(habit.id).update({
      'isVisible': !habit.isVisible,
    });
  }

  void _toggleSection(String id) {
    setState(() {
      if (_expandedSections.contains(id)) {
        _expandedSections.remove(id);
      } else {
        _expandedSections.add(id);
      }
    });
  }

  Widget _sectionHeader({
    required String id,
    required String title,
    required Color color,
    required bool expanded,
    required VoidCallback onOpen,
  }) {
    return Material(
      color: color.withOpacity(0.14),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.22)),
        ),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: onOpen,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: () => _toggleSection(id),
              icon: AnimatedRotation(
                turns: expanded ? 0.5 : 0,
                duration: _reduceMotion(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                child: const Icon(Icons.keyboard_arrow_down_rounded),
              ),
              color: _kSecondaryLabel,
              tooltip: expanded ? 'Collapse' : 'Expand',
            ),
          ],
        ),
      ),
    );
  }

  Widget _habitRow({required Habit habit}) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () =>
              widget.onOpenBoard('all', habit.name, singleHabitId: habit.id),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withOpacity(0.06)),
            ),
            child: ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 0,
              ),
              leading: habit.isFavorite ? _favoriteHeart(size: 14) : null,
              trailing: habit.isVisible
                  ? IconButton(
                      icon: const Icon(Icons.visibility_rounded, size: 18),
                      tooltip: 'Hide from board',
                      onPressed: () => _toggleVisible(habit),
                    )
                  : IconButton(
                      icon: const Icon(Icons.visibility_off_outlined, size: 18),
                      tooltip: 'Show on board',
                      onPressed: () => _toggleVisible(habit),
                    ),
              iconColor: habit.isVisible ? _kAccent : _kSecondaryLabel,
              title: Text(
                habit.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: habit.isVisible ? Colors.black : _kSecondaryLabel,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _section({
    required String id,
    required String title,
    required Color color,
    required List<Habit> habits,
    required String openTitle,
  }) {
    if (habits.isEmpty) return const SizedBox.shrink();
    final expanded = _expandedSections.contains(id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            id: id,
            title: title,
            color: color,
            expanded: expanded,
            onOpen: () => widget.onOpenBoard(id, openTitle),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                children: habits
                    .map((habit) => _habitRow(habit: habit))
                    .toList(),
              ),
            ),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: _reduceMotion(context)
                ? Duration.zero
                : const Duration(milliseconds: 240),
            sizeCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allHabits = widget.habits;
    final favorites = allHabits.where((h) => h.isFavorite).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final uncategorized = allHabits.where((h) => h.categoryId.isEmpty).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return Scaffold(
      appBar: AppBar(title: const Text("Pebbles")),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          if (favorites.isNotEmpty)
            _section(
              id: 'favorites',
              title: 'Favorites',
              color: Colors.redAccent,
              habits: favorites,
              openTitle: 'Favorites',
            ),
          ...widget.categories.map((c) {
            final sectionHabits =
                allHabits.where((h) => h.categoryId == c.id).toList()..sort(
                  (a, b) =>
                      a.name.toLowerCase().compareTo(b.name.toLowerCase()),
                );
            return _section(
              id: c.id,
              title: c.name,
              color: c.color,
              habits: sectionHabits,
              openTitle: c.name,
            );
          }),
          if (uncategorized.isNotEmpty)
            _section(
              id: 'untagged',
              title: 'No Tag',
              color: Colors.grey,
              habits: uncategorized,
              openTitle: 'No Tag',
            ),
        ],
      ),
    );
  }
}

// --- BOARD ---
class HabitCalendarScreen extends StatefulWidget {
  final List<Habit> habits;
  final List<HabitCategory> categories;
  final List<String> initialFilters;
  final String title;
  final VoidCallback? onBackToHome;
  final bool showHiddenHabits;
  final bool forceAlphabetical;
  final String? singleHabitId;
  const HabitCalendarScreen({
    super.key,
    required this.habits,
    required this.categories,
    required this.initialFilters,
    this.title = 'Board',
    this.onBackToHome,
    this.showHiddenHabits = false,
    this.forceAlphabetical = false,
    this.singleHabitId,
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
    List<Habit> displayList = widget.showHiddenHabits
        ? List.from(widget.habits)
        : widget.habits.where((h) => h.isVisible).toList();
    if (!_currentFilters.contains('all')) {
      displayList = displayList.where((h) {
        bool matchesTag = _currentFilters.contains(h.categoryId);
        bool isFavMatch = _currentFilters.contains('favorites') && h.isFavorite;
        bool isUntaggedMatch =
            _currentFilters.contains('untagged') && h.categoryId.isEmpty;
        return matchesTag || isFavMatch || isUntaggedMatch;
      }).toList();
    }
    if (widget.singleHabitId != null) {
      displayList = displayList
          .where((h) => h.id == widget.singleHabitId)
          .toList();
    }
    if (widget.forceAlphabetical || _isAlphabetical)
      displayList.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
    else
      displayList.sort((a, b) => a.order.compareTo(b.order));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: widget.onBackToHome == null
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: widget.onBackToHome,
              ),
        actions: [_buildFilterMenu()],
      ),
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
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: _kSecondaryLabel,
            ),
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
                  child: Container(
                    width: 38,
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    decoration: i == 0
                        ? BoxDecoration(
                            color: _kAccent,
                            borderRadius: BorderRadius.circular(9),
                          )
                        : null,
                    child: Text(
                      DateFormat(
                        'dd\nE',
                      ).format(DateTime.now().subtract(Duration(days: i))),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        height: 1.25,
                        color: i == 0 ? Colors.white : _kSecondaryLabel,
                        fontFeatures: const [ui.FontFeature.tabularFigures()],
                      ),
                      textAlign: TextAlign.center,
                    ),
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
            onLongPress: () {
              HapticFeedback.mediumImpact();
              _editHabit(context, h: h);
            },
            child: Container(
              height: 70,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.centerLeft,
              decoration: const BoxDecoration(
                color: _kGroupedBackground,
                border: Border(
                  bottom: BorderSide(color: _kHairline, width: 0.5),
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
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            height: 1.15,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (h.isFavorite) ...[
                        const SizedBox(width: 4),
                        _favoriteHeart(),
                      ],
                      if (h.showStreak &&
                          h.habitType == 'check' &&
                          ![
                            'Mood',
                            'Sleep',
                            'Sleep score',
                            'Diary',
                            'Dreams',
                          ].contains(h.name) &&
                          streak >= 2)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Text("🔥", style: TextStyle(fontSize: 12)),
                        ),
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
                        color: cat.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        cat.name,
                        style: TextStyle(
                          fontSize: 8,
                          letterSpacing: 0.2,
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
    } else if (h.name == "Sleep score") {
      child = Text(
        "${dayData?['sleep_score'] ?? '-'}",
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      );
    } else if (h.name == "Diary" || h.name == "Dreams") {
      bool hasText = dayData?[h.name.toLowerCase()]?.isNotEmpty ?? false;
      child = Icon(
        h.name == "Diary" ? Icons.book : Icons.cloud,
        size: 18,
        color: hasText ? _kAccent : _kEmptyMark,
      );
    } else if (h.habitType == "note") {
      bool hasText = (h.valueMap[ds]?.toString().isNotEmpty ?? false);
      child = Icon(
        Icons.notes,
        size: 18,
        color: hasText ? _kAccent : _kEmptyMark,
      );
    } else if (h.habitType == "number") {
      child = Text(
        "${h.valueMap[ds] ?? '-'}",
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      );
    } else {
      bool isDone = h.completionMap[ds] ?? false;
      final color = widget.categories
          .firstWhere(
            (c) => c.id == h.categoryId,
            orElse: () => HabitCategory(id: '', name: '', color: Colors.blue),
          )
          .color;
      child = AnimatedContainer(
        duration: _reduceMotion(context)
            ? Duration.zero
            : const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDone ? color : _kEmptyMark,
        ),
        child: isDone
            ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
            : null,
      );
    }

    return GestureDetector(
      onTap: () {
        if (h.name == "Mood") {
          _showMoodPicker(ds, moods);
        } else if (h.name == "Sleep") {
          _showNumberPicker(ds, dayData?['sleep'], 'sleep', 'Sleep Hours');
        } else if (h.name == "Sleep score") {
          _showNumberPicker(
            ds,
            dayData?['sleep_score'],
            'sleep_score',
            'Sleep Score',
          );
        } else if (h.name == "Diary" || h.name == "Dreams") {
          _showTextPicker(context, h.name, h.name.toLowerCase(), ds);
        } else if (h.habitType == "note") {
          _showHabitTextPicker(h, ds);
        } else if (h.habitType == "number") {
          _showHabitNumberPicker(h, ds);
        } else {
          HapticFeedback.lightImpact();
          Map<String, bool> next = Map.from(h.completionMap);
          next[ds] = !(h.completionMap[ds] ?? false);
          FirebaseFirestore.instance.collection('habits').doc(h.id).update({
            'completionMap': next,
          });
        }
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        _showHabitDayNote(h, ds);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 55,
        height: 70,
        decoration: BoxDecoration(
          color: dIdx == 0 ? _kAccent.withValues(alpha: 0.04) : null,
          border: const Border(
            bottom: BorderSide(color: _kHairline, width: 0.5),
            right: BorderSide(color: _kHairline, width: 0.5),
          ),
        ),
        child: Center(child: _PressScale(child: child)),
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
        content: _lockedWritingField(
          controller: ctrl,
          hintText: "Add a specific note...",
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

  void _showNumberPicker(
    String ds,
    dynamic cur,
    String fieldName,
    String title,
  ) {
    final ctrl = TextEditingController(
      text: cur?.toString().replaceAll('.', ',') ?? "",
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: _numberOnlyField(ctrl),
        actions: [
          ElevatedButton(
            onPressed: () {
              String normalized = ctrl.text.replaceAll(',', '.');
              FirebaseFirestore.instance
                  .collection('daily_metrics')
                  .doc(ds)
                  .set({
                    fieldName: double.tryParse(normalized) ?? 0.0,
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

  void _showHabitTextPicker(Habit h, String ds) {
    final ctrl = TextEditingController(text: h.valueMap[ds]?.toString() ?? "");
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("${h.name} ($ds)"),
        content: _lockedWritingField(
          controller: ctrl,
          hintText: "Write your note...",
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              final next = Map<String, dynamic>.from(h.valueMap);
              next[ds] = ctrl.text;
              FirebaseFirestore.instance.collection('habits').doc(h.id).update({
                'valueMap': next,
              });
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showHabitNumberPicker(Habit h, String ds) {
    final ctrl = TextEditingController(
      text: h.valueMap[ds]?.toString().replaceAll('.', ',') ?? "",
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("${h.name} ($ds)"),
        content: _numberOnlyField(ctrl),
        actions: [
          ElevatedButton(
            onPressed: () {
              final next = Map<String, dynamic>.from(h.valueMap);
              final normalized = ctrl.text.replaceAll(',', '.');
              next[ds] = double.tryParse(normalized) ?? 0.0;
              FirebaseFirestore.instance.collection('habits').doc(h.id).update({
                'valueMap': next,
              });
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
    String habitType = h?.habitType ?? 'check';
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
                DropdownButtonFormField<String>(
                  value: habitType,
                  decoration: const InputDecoration(labelText: "Habit Type"),
                  items: const [
                    DropdownMenuItem(value: 'check', child: Text('Check mark')),
                    DropdownMenuItem(value: 'note', child: Text('Note')),
                    DropdownMenuItem(value: 'number', child: Text('Number')),
                  ],
                  onChanged: (v) => setDS(() => habitType = v ?? 'check'),
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
            if (h != null)
              TextButton(
                onPressed: () async {
                  if (!await _confirmDelete(context, '"${h.name}"')) return;
                  FirebaseFirestore.instance
                      .collection('habits')
                      .doc(h.id)
                      .delete();
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text(
                  "Delete",
                  style: TextStyle(color: _kDestructive),
                ),
              ),
            ElevatedButton(
              onPressed: () {
                final d = {
                  'name': ctrl.text,
                  'description': descCtrl.text,
                  'categoryId': cat,
                  'habitType': habitType,
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
                    'valueMap': {},
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
      content: _lockedWritingField(
        controller: ctrl,
        hintText: "Write here...",
        width: 400,
        height: 250,
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
// "Sat, Oct 10, 2026" reads faster than "2026-10-10"; falls back to the raw key.
String _journalDate(String key) {
  try {
    return DateFormat(
      'EEE, MMM d, yyyy',
    ).format(DateFormat('yyyy-MM-dd').parseStrict(key));
  } catch (_) {
    return key;
  }
}

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
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      "No diary entries yet. Tap 'Board' to write.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _kSecondaryLabel),
                    ),
                  ),
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
                    margin: const EdgeInsets.only(bottom: 12),
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Row(
                        children: [
                          Text(emoji, style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 12),
                          Text(
                            _journalDate(dateStr),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              letterSpacing: -0.2,
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
                          style: TextStyle(
                            color: diaryText.isEmpty
                                ? _kSecondaryLabel
                                : Colors.black87,
                            height: 1.4,
                          ),
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
class InsightsScreen extends StatefulWidget {
  final List<Habit> habits;
  final List<HabitCategory> categories;
  const InsightsScreen({
    super.key,
    required this.habits,
    this.categories = const [],
  });

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  int _insightsTab = 0;

  @override
  Widget build(BuildContext context) {
    final navigation = PreferredSize(
      preferredSize: const Size.fromHeight(56),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: SizedBox(
          width: double.infinity,
          child: SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Relationships')),
              ButtonSegment(value: 1, label: Text('Averages')),
              ButtonSegment(value: 2, label: Text('Year')),
            ],
            selected: {_insightsTab},
            showSelectedIcon: false,
            onSelectionChanged: (selection) =>
                setState(() => _insightsTab = selection.single),
          ),
        ),
      ),
    );
    // Keep selections and scroll positions when switching between views.
    return IndexedStack(
      index: _insightsTab,
      children: [
        PebblesExplorer(habits: widget.habits, navigation: navigation),
        InsightsAveragesScreen(habits: widget.habits, navigation: navigation),
        PebblesYearScreen(
          habits: widget.habits,
          categories: widget.categories,
          navigation: navigation,
        ),
      ],
    );
  }
}

class InsightsAveragesScreen extends StatelessWidget {
  final List<Habit> habits;
  final PreferredSizeWidget? navigation;
  const InsightsAveragesScreen({
    super.key,
    required this.habits,
    this.navigation,
  });

  // Older built-in habits store their daily values in `daily_metrics`,
  // whereas custom habits store them in each habit's `valueMap`.
  String? _dailyMetricField(Habit habit) {
    switch (habit.name) {
      case 'Sleep':
        return 'sleep';
      case 'Sleep score':
        return 'sleep_score';
      case 'Diary':
        return 'diary';
      case 'Dreams':
        return 'dreams';
      default:
        return null;
    }
  }

  String _insightHabitType(Habit habit) {
    if (habit.name == 'Sleep' || habit.name == 'Sleep score') return 'number';
    if (habit.name == 'Diary' || habit.name == 'Dreams') return 'note';
    return habit.habitType;
  }

  String _dateKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  dynamic _valueOn(
    Habit habit,
    DateTime date,
    Map<String, Map<String, dynamic>> dailyMetrics,
  ) {
    final key = _dateKey(date);
    final metricField = _dailyMetricField(habit);
    if (metricField != null) {
      return dailyMetrics[key]?[metricField];
    }
    return habit.valueMap[key];
  }

  bool _hasLoggedEntryOn(
    Habit habit,
    DateTime date,
    Map<String, Map<String, dynamic>> dailyMetrics,
  ) {
    final value = _valueOn(habit, date, dailyMetrics);
    switch (_insightHabitType(habit)) {
      case 'number':
        return double.tryParse(value?.toString() ?? '') != null;
      case 'note':
        return value?.toString().trim().isNotEmpty ?? false;
      default:
        return habit.completionMap[_dateKey(date)] == true;
    }
  }

  double? _averageValue(
    Habit habit,
    int days,
    Map<String, Map<String, dynamic>> dailyMetrics,
  ) {
    double total = 0;
    int count = 0;
    final today = DateTime.now();
    for (int i = 0; i < days; i++) {
      final value = double.tryParse(
        _valueOn(
              habit,
              today.subtract(Duration(days: i)),
              dailyMetrics,
            )?.toString() ??
            '',
      );
      if (value != null) {
        total += value;
        count++;
      }
    }
    return count == 0 ? null : total / count;
  }

  int _loggedCount(
    Habit habit,
    int days,
    Map<String, Map<String, dynamic>> dailyMetrics,
  ) {
    int count = 0;
    final today = DateTime.now();
    for (int i = 0; i < days; i++) {
      if (_hasLoggedEntryOn(
        habit,
        today.subtract(Duration(days: i)),
        dailyMetrics,
      )) {
        count++;
      }
    }
    return count;
  }

  int _checkCount(Habit habit, int days) {
    int count = 0;
    final today = DateTime.now();
    for (int i = 0; i < days; i++) {
      if (habit.completionMap[_dateKey(today.subtract(Duration(days: i)))] ==
          true) {
        count++;
      }
    }
    return count;
  }

  int _streak(Habit habit, Map<String, Map<String, dynamic>> dailyMetrics) {
    int streak = 0;
    DateTime date = DateTime.now();
    if (!_hasLoggedEntryOn(habit, date, dailyMetrics)) {
      date = date.subtract(const Duration(days: 1));
    }
    while (_hasLoggedEntryOn(habit, date, dailyMetrics)) {
      streak++;
      date = date.subtract(const Duration(days: 1));
    }
    return streak;
  }

  @override
  Widget build(BuildContext context) {
    final list = habits.where((h) => h.showInAnalytics).toList();
    list.sort((a, b) => a.insightOrder.compareTo(b.insightOrder));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('daily_metrics')
          .snapshots(),
      builder: (context, metricsSnap) {
        final dailyMetrics = <String, Map<String, dynamic>>{};
        if (metricsSnap.hasData) {
          for (final doc in metricsSnap.data!.docs) {
            dailyMetrics[doc.id] = Map<String, dynamic>.from(
              doc.data() as Map<String, dynamic>,
            );
          }
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text("Insights"),
            bottom: navigation,
            actions: [
              IconButton(
                tooltip: 'Order & colors',
                icon: const Icon(Icons.auto_fix_high_rounded),
                onPressed: () => _manageInsights(context, list),
              ),
            ],
          ),
          body: metricsSnap.hasError
              ? const Center(child: Text("Couldn't load insight data."))
              : !metricsSnap.hasData
              ? const Center(child: CircularProgressIndicator())
              : list.isEmpty
              ? const Center(
                  child: Text(
                    "No habits selected for Insights. Enable 'Show in Insights' in a habit's settings.",
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final habit = list[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Color(habit.backgroundColorValue),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0F000000),
                            blurRadius: 16,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            habit.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 19,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              if (_insightHabitType(habit) == 'number') ...[
                                _stat(
                                  "7 Day Avg",
                                  _averageValue(habit, 7, dailyMetrics),
                                ),
                                _stat(
                                  "30 Day Avg",
                                  _averageValue(habit, 30, dailyMetrics),
                                ),
                              ] else if (_insightHabitType(habit) ==
                                  'note') ...[
                                _stat(
                                  "7 Logs",
                                  _loggedCount(habit, 7, dailyMetrics),
                                ),
                                _stat(
                                  "30 Logs",
                                  _loggedCount(habit, 30, dailyMetrics),
                                ),
                              ] else ...[
                                _stat("7 Days", _checkCount(habit, 7)),
                                _stat("30 Days", _checkCount(habit, 30)),
                              ],
                              if (habit.showStreak &&
                                  _insightHabitType(habit) == 'check' &&
                                  habit.name != 'Mood')
                                _stat("Streak", _streak(habit, dailyMetrics)),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        );
      },
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
              padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
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

  String _formatStatValue(Object? value) {
    if (value == null) return "-";
    if (value is double) {
      final fixed = value.toStringAsFixed(1);
      return fixed.endsWith('.0')
          ? fixed.substring(0, fixed.length - 2)
          : fixed;
    }
    return value.toString();
  }

  Widget _stat(String l, Object? v, {bool active = true}) => Column(
    children: [
      Text(
        l.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4, // small caps want positive tracking
          color: Colors.black54,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        active ? _formatStatValue(v) : "-",
        style: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          fontFeatures: [ui.FontFeature.tabularFigures()],
        ),
      ),
    ],
  );
}

// --- TWO-VARIABLE EXPLORER ---
// Historical moods are saved as names in daily_metrics. This lookup does not
// rewrite those records or change the mood picker.
class PebblesMoodScale {
  static const Map<String, int> scores = {
    'Sad': 1,
    'Rough': 2,
    'Run down': 3,
    'Fine but a bit low': 4,
    'Tired but ok': 5,
    'Fine': 5,
    'Good': 6,
    'Great': 7,
    'Happy': 8,
    'Too happy': 9,
  };

  static int? score(Object? mood) => scores[mood?.toString().trim()];
  static bool isSpecial(Object? mood) => mood?.toString().trim() == 'Too happy';
}

class _ExplorerMetric {
  final String id;
  final String label;
  final String type; // numeric, mood, event
  final Habit? habit;
  const _ExplorerMetric(this.id, this.label, this.type, [this.habit]);
}

class _ExplorerPoint {
  final DateTime date;
  final double x;
  final double y;
  final bool special;
  const _ExplorerPoint(this.date, this.x, this.y, this.special);
}

class PebblesExplorer extends StatefulWidget {
  final List<Habit> habits;
  final PreferredSizeWidget? navigation;
  const PebblesExplorer({super.key, required this.habits, this.navigation});
  @override
  State<PebblesExplorer> createState() => _PebblesExplorerState();
}

class _PebblesExplorerState extends State<PebblesExplorer> {
  String xId = 'sleep';
  String yId = 'mood';
  int days = 90; // 0 = all available records
  final Set<String> selectedEventIds = <String>{};
  bool _compareExpanded = false;
  bool _patternsExpanded = true;
  bool _chooseRowsExpanded = false;
  static const String _rowsKey = 'pebbles_insights_selected_rows_v1';

  @override
  void initState() {
    super.initState();
    _loadSelectedRows();
  }

  Future<void> _loadSelectedRows() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_rowsKey);
    final ids = stored ?? <String>['mood', 'sleep_score'];
    if (!mounted) return;
    setState(() {
      selectedEventIds
        ..clear()
        ..addAll(ids);
    });
  }

  void _setRowSelected(String id, bool enabled) {
    setState(() {
      if (enabled) {
        selectedEventIds.add(id);
      } else {
        selectedEventIds.remove(id);
      }
    });
    _saveSelectedRows();
  }

  Future<void> _saveSelectedRows() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_rowsKey, selectedEventIds.toList());
  }

  List<_ExplorerMetric> get metrics {
    final result = <_ExplorerMetric>[
      const _ExplorerMetric('mood', 'Mood', 'mood'),
      const _ExplorerMetric('sleep', 'Sleep', 'numeric'),
      const _ExplorerMetric('sleep_score', 'Sleep score', 'numeric'),
    ];
    for (final habit in widget.habits) {
      if (['Sleep', 'Sleep score', 'Diary', 'Dreams'].contains(habit.name))
        continue;
      if (habit.habitType == 'number') {
        result.add(
          _ExplorerMetric('habit:${habit.id}', habit.name, 'numeric', habit),
        );
      } else if (habit.habitType != 'note') {
        result.add(
          _ExplorerMetric('habit:${habit.id}', habit.name, 'event', habit),
        );
      }
    }
    return result;
  }

  double? value(
    _ExplorerMetric metric,
    String date,
    Map<String, dynamic> daily,
  ) {
    if (metric.type == 'event')
      return metric.habit!.completionMap[date] == true ? 1 : null;
    if (metric.type == 'mood')
      return PebblesMoodScale.score(daily['mood'])?.toDouble();
    final raw = metric.habit == null
        ? daily[metric.id]
        : metric.habit!.valueMap[date];
    return double.tryParse(raw?.toString().replaceAll(',', '.') ?? '');
  }

  DateTime? parseDate(String key) {
    try {
      return DateFormat('yyyy-MM-dd').parseStrict(key);
    } catch (_) {
      return null;
    }
  }

  double? correlation(List<_ExplorerPoint> points) {
    if (points.length < 3) return null;
    final mx = points.map((p) => p.x).reduce((a, b) => a + b) / points.length;
    final my = points.map((p) => p.y).reduce((a, b) => a + b) / points.length;
    double xx = 0, yy = 0, xy = 0;
    for (final p in points) {
      final dx = p.x - mx, dy = p.y - my;
      xx += dx * dx;
      yy += dy * dy;
      xy += dx * dy;
    }
    if (xx == 0 || yy == 0) return null;
    return xy / math.sqrt(xx * yy);
  }

  DateTime _eventStartDate(
    Iterable<String> dailyKeys,
    Iterable<String> eventKeys,
    List<_ExplorerPoint> points,
  ) {
    final dates = <DateTime>[
      ...dailyKeys.map(parseDate).whereType<DateTime>(),
      ...eventKeys.map(parseDate).whereType<DateTime>(),
      ...points.map((p) => p.date),
    ];
    if (dates.isEmpty) return DateTime.now().subtract(const Duration(days: 89));
    dates.sort();
    return dates.first;
  }

  @override
  Widget build(BuildContext context) {
    final choices = metrics;
    final eventHabits = widget.habits
        .where(
          (h) =>
              h.habitType == 'check' &&
              !['Sleep', 'Sleep score', 'Diary', 'Dreams'].contains(h.name),
        )
        .toList();
    final x = choices.firstWhere(
      (m) => m.id == xId,
      orElse: () => choices.first,
    );
    final y = choices.firstWhere(
      (m) => m.id == yId,
      orElse: () => choices.first,
    );
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('daily_metrics')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return Scaffold(
            appBar: AppBar(
              title: Text(
                widget.navigation == null
                    ? 'Explore relationships'
                    : 'Insights',
              ),
              bottom: widget.navigation,
            ),
            body: const Center(child: Text('Could not load data.')),
          );
        if (!snapshot.hasData)
          return Scaffold(
            appBar: AppBar(
              title: Text(
                widget.navigation == null
                    ? 'Explore relationships'
                    : 'Insights',
              ),
              bottom: widget.navigation,
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        final daily = <String, Map<String, dynamic>>{};
        for (final doc in snapshot.data!.docs) {
          daily[doc.id] = Map<String, dynamic>.from(
            doc.data() as Map<String, dynamic>,
          );
        }
        final keys = <String>{...daily.keys};
        for (final metric in [x, y]) {
          if (metric.habit != null) {
            keys.addAll(metric.habit!.valueMap.keys);
            keys.addAll(metric.habit!.completionMap.keys);
          }
        }
        final cutoff = days == 0
            ? null
            : DateTime.now().subtract(Duration(days: days - 1));
        final activeEvents = eventHabits
            .where((h) => selectedEventIds.contains(h.id))
            .toList();
        final eventDates = <String, Set<String>>{};
        for (final habit in activeEvents) {
          for (final entry in habit.completionMap.entries) {
            if (entry.value != true) continue;
            final date = parseDate(entry.key);
            if (date == null ||
                date.isAfter(DateTime.now().add(const Duration(days: 1))))
              continue;
            if (cutoff != null &&
                date.isBefore(DateTime(cutoff.year, cutoff.month, cutoff.day)))
              continue;
            eventDates.putIfAbsent(entry.key, () => <String>{}).add(habit.id);
          }
        }
        final points = <_ExplorerPoint>[];
        final specialDates = <DateTime>[];
        int excludedSpecial = 0;
        for (final key in keys) {
          final date = parseDate(key);
          if (date == null ||
              date.isAfter(DateTime.now().add(const Duration(days: 1))))
            continue;
          if (cutoff != null &&
              date.isBefore(DateTime(cutoff.year, cutoff.month, cutoff.day)))
            continue;
          final entry = daily[key] ?? <String, dynamic>{};
          final vx = value(x, key, entry), vy = value(y, key, entry);
          final special =
              ((x.type == 'mood' || y.type == 'mood') &&
              PebblesMoodScale.isSpecial(entry['mood']));
          if (special) specialDates.add(date);
          if (vx == null || vy == null) continue;
          if (special) excludedSpecial++;
          points.add(_ExplorerPoint(date, vx, vy, special));
        }
        points.sort((a, b) => a.date.compareTo(b.date));
        final ordinary = points.where((p) => !p.special).toList();
        final numericPair =
            x.type != 'event' && y.type != 'event' && x.id != y.id;
        final r = numericPair ? correlation(ordinary) : null;
        final eventMode = x.type == 'event' || y.type == 'event';
        final rowChoices = <_ExplorerMetric>[
          ...choices.where((m) => m.type != 'event'),
          ...choices.where((m) => m.type == 'event'),
        ];
        final visibleRows = rowChoices
            .where((m) => selectedEventIds.contains(m.id))
            .toList();
        final today = DateTime.now();
        final endDay = DateTime(today.year, today.month, today.day);
        final allDates = <DateTime>[
          ...daily.keys.map(parseDate).whereType<DateTime>(),
          for (final h in widget.habits) ...[
            ...h.completionMap.keys.map(parseDate).whereType<DateTime>(),
            ...h.valueMap.keys.map(parseDate).whereType<DateTime>(),
          ],
        ].where((d) => !d.isAfter(endDay)).toList()..sort();
        final firstDay = days == 0
            ? (allDates.isEmpty
                  ? endDay.subtract(const Duration(days: 29))
                  : allDates.first)
            : endDay.subtract(Duration(days: days - 1));
        final totalDays = endDay.difference(firstDay).inDays + 1;
        const cellWidth = 24.0;
        const cellGap = 3.0;
        final timelineWidth = totalDays * (cellWidth + cellGap);
        const timelineRowHeight = 36.0;
        // Use the same newest-first date for both headers and metric cells.
        DateTime timelineDate(int index) =>
            DateTime(endDay.year, endDay.month, endDay.day - index);
        final eventPalette = <Color>[
          Colors.deepOrange,
          Colors.teal,
          Colors.indigo,
          Colors.pink,
          Colors.amber,
          Colors.green,
          Colors.blueGrey,
          Colors.purple,
        ];
        final eventColor = <String, Color>{};
        for (var i = 0; i < eventHabits.length; i++) {
          eventColor['habit:${eventHabits[i].id}'] =
              eventPalette[i % eventPalette.length];
        }

        Widget timelineRow(_ExplorerMetric metric) {
          return SizedBox(
            height: timelineRowHeight,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: List.generate(totalDays, (index) {
                  final date = timelineDate(index);
                  final key = DateFormat('yyyy-MM-dd').format(date);
                  final record = daily[key] ?? <String, dynamic>{};
                  final number = value(metric, key, record);
                  final recorded = number != null;
                  Color color = const Color(0xFFE6E8EC);
                  if (recorded) {
                    if (metric.type == 'mood') {
                      color = _moodColor(number.toInt());
                    } else if (metric.type == 'event') {
                      color = eventColor[metric.id] ?? Colors.blueGrey;
                    } else if (metric.id == 'sleep_score') {
                      color = _gradientColor(number / 100);
                    } else if (metric.id == 'sleep') {
                      // Duration is a quantity, not an automatic wellbeing rating.
                      // 0–12 hours is a display range only; longer durations cap at full saturation.
                      color = _gradientColor(number / 12);
                    } else {
                      // Numeric custom habits use a neutral tint, not an assumed good/bad scale.
                      color = const Color(0xFF648BB4);
                    }
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: cellGap),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(3),
                      onTap: () {
                        final detail = !recorded
                            ? 'No value recorded'
                            : metric.type == 'mood'
                            ? '${record['mood']} · ${number.toInt()}/9${number == 9 ? ' · special state' : ''}'
                            : metric.type == 'event'
                            ? 'Occurrence recorded'
                            : '${number.toStringAsFixed(number == number.roundToDouble() ? 0 : 1)}${metric.id == 'sleep_score'
                                  ? '/100'
                                  : metric.id == 'sleep'
                                  ? ' hours'
                                  : ''}';
                        showDialog<void>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(
                              '${metric.label} · ${DateFormat('MMM d, yyyy').format(date)}',
                            ),
                            content: Text(detail),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Container(
                        width: cellWidth,
                        height: 22,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: metric.type == 'event' && recorded
                            ? const Center(
                                child: Icon(
                                  Icons.circle,
                                  color: Colors.white,
                                  size: 6,
                                ),
                              )
                            : null,
                      ),
                    ),
                  );
                }),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              widget.navigation == null ? 'Explore relationships' : 'Insights',
            ),
            bottom: widget.navigation,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Select a time range',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final option in const [
                    (30, '30 days'),
                    (90, '90 days'),
                    (365, '1 year'),
                    (0, 'All time'),
                  ])
                    ChoiceChip(
                      label: Text(option.$2),
                      selected: days == option.$1,
                      onSelected: (_) => setState(() => days = option.$1),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Card(
                clipBehavior: Clip.antiAlias,
                child: AnimatedSize(
                  duration: _reduceMotion(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: Column(
                    children: [
                      ListTile(
                        title: const Text(
                          'Daily patterns',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${visibleRows.length} rows · color-coded by date',
                        ),
                        trailing: Icon(
                          _patternsExpanded
                              ? Icons.expand_less
                              : Icons.expand_more,
                        ),
                        onTap: () => setState(
                          () => _patternsExpanded = !_patternsExpanded,
                        ),
                      ),
                      if (_patternsExpanded)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text(
                                  'Choose rows',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  '${visibleRows.length} selected',
                                ),
                                trailing: Icon(
                                  _chooseRowsExpanded
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                ),
                                onTap: () => setState(
                                  () => _chooseRowsExpanded =
                                      !_chooseRowsExpanded,
                                ),
                              ),
                              if (_chooseRowsExpanded) ...[
                                Row(
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        setState(
                                          () => selectedEventIds.addAll(
                                            rowChoices.map((m) => m.id),
                                          ),
                                        );
                                        _saveSelectedRows();
                                      },
                                      child: const Text('Select all'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        setState(
                                          () => selectedEventIds.clear(),
                                        );
                                        _saveSelectedRows();
                                      },
                                      child: const Text('Clear'),
                                    ),
                                  ],
                                ),
                                ...rowChoices.map(
                                  (metric) => CheckboxListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(metric.label),
                                    value: selectedEventIds.contains(metric.id),
                                    onChanged: (enabled) => _setRowSelected(
                                      metric.id,
                                      enabled ?? false,
                                    ),
                                  ),
                                ),
                              ],
                              if (visibleRows.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text(
                                    'Choose rows to display a daily timeline.',
                                  ),
                                )
                              else ...[
                                const Text(
                                  'Swipe sideways to explore dates. Tap any square to see its value.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                // Labels stay outside the shared horizontal viewport.
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 110,
                                      child: Column(
                                        children: [
                                          const SizedBox(height: 28),
                                          ...visibleRows.map(
                                            (metric) => SizedBox(
                                              height: timelineRowHeight,
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        right: 8,
                                                      ),
                                                  child: Tooltip(
                                                    message: metric.label,
                                                    child: Text(
                                                      metric.label,
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w600,
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
                                    Expanded(
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: SizedBox(
                                          width: timelineWidth,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              SizedBox(
                                                height: 28,
                                                child: Row(
                                                  children: List.generate(
                                                    totalDays,
                                                    (index) {
                                                      final date = timelineDate(
                                                        index,
                                                      );
                                                      return SizedBox(
                                                        width:
                                                            cellWidth + cellGap,
                                                        child: Text(
                                                          date.day == 1 ||
                                                                  index == 0 ||
                                                                  date.day %
                                                                          5 ==
                                                                      0
                                                              ? '${date.day}'
                                                              : '',
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 10,
                                                                color: Colors
                                                                    .black54,
                                                              ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ),
                                              ...visibleRows.map(timelineRow),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Wrap(
                                  spacing: 12,
                                  runSpacing: 4,
                                  children: [
                                    Text(
                                      'Red → yellow → green: mood / sleep score',
                                      style: TextStyle(fontSize: 11),
                                    ),
                                    Text(
                                      'Purple: Too happy',
                                      style: TextStyle(fontSize: 11),
                                    ),
                                    Text(
                                      'Grey: no entry',
                                      style: TextStyle(fontSize: 11),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Checkbox marks mean recorded occurrences only; grey does not mean the event did not happen. Sleep duration color shows amount, not quality.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Card(
                clipBehavior: Clip.antiAlias,
                child: AnimatedSize(
                  duration: _reduceMotion(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: Column(
                    children: [
                      ListTile(
                        title: const Text(
                          'Compare two metrics',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: const Text(
                          'Explore relationships with a scatter plot',
                        ),
                        trailing: Icon(
                          _compareExpanded
                              ? Icons.expand_less
                              : Icons.expand_more,
                        ),
                        onTap: () => setState(
                          () => _compareExpanded = !_compareExpanded,
                        ),
                      ),
                      if (_compareExpanded)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DropdownButtonFormField<String>(
                                value: x.id,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'X axis / first metric',
                                ),
                                items: choices
                                    .map(
                                      (m) => DropdownMenuItem(
                                        value: m.id,
                                        child: Text(m.label),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => xId = v ?? xId),
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                value: y.id,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Y axis / second metric',
                                ),
                                items: choices
                                    .map(
                                      (m) => DropdownMenuItem(
                                        value: m.id,
                                        child: Text(m.label),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => yId = v ?? yId),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Matched recorded days: ${points.length}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (excludedSpecial > 0)
                                Text(
                                  'Too happy: $excludedSpecial special-state days excluded from correlation.',
                                ),
                              const SizedBox(height: 8),
                              if (x.id == y.id)
                                const Text(
                                  'Choose two different metrics to compare.',
                                )
                              else if (points.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(32),
                                  child: Center(
                                    child: Text(
                                      'No days have both metrics recorded in this period.',
                                    ),
                                  ),
                                )
                              else
                                SizedBox(
                                  height: 310,
                                  child: CustomPaint(
                                    painter: _PebblesScatterPainter(
                                      points: points,
                                      xLabel: x.label,
                                      yLabel: y.label,
                                      eventMode: eventMode,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 8),
                              if (r != null)
                                Text(
                                  'Pearson correlation (ordinary mood days): ${r.toStringAsFixed(2)} · n=${ordinary.length}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              if (numericPair && r == null && points.isNotEmpty)
                                const Text(
                                  'Correlation unavailable: at least 3 matched, varying ordinary observations are needed.',
                                ),
                              if (eventMode)
                                const Text(
                                  'Checkbox habits show recorded occurrences only; unchecked days are unknown.',
                                ),
                              if (x.type == 'mood' || y.type == 'mood')
                                const Text(
                                  'Mood scores: Sad 1 · Rough 2 · Run down 3 · Fine but a bit low 4 · Fine / Tired but ok 5 · Good 6 · Great 7 · Happy 8. Too happy 9 is a special state.',
                                ),
                              const SizedBox(height: 8),
                              const Text(
                                'Exploratory associations do not establish cause and effect. Missing entries are not treated as zero.',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PebblesEventBandsPainter extends CustomPainter {
  final List<Habit> habits;
  final Map<String, Set<String>> eventDates;
  final DateTime start;
  final DateTime end;
  const _PebblesEventBandsPainter({
    required this.habits,
    required this.eventDates,
    required this.start,
    required this.end,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const labelWidth = 105.0, right = 12.0, top = 8.0;
    final plotWidth = size.width - labelWidth - right;
    if (plotWidth <= 0) return;
    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    final span = math.max(1, endDay.difference(startDay).inDays);
    void label(
      String value,
      Offset at, {
      double fontSize = 10,
      Color color = Colors.black87,
    }) {
      final tp = TextPainter(
        text: TextSpan(
          text: value,
          style: TextStyle(fontSize: fontSize, color: color),
        ),
        textDirection: ui.TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: labelWidth - 8);
      tp.paint(canvas, at);
    }

    final palette = <Color>[
      Colors.deepOrange,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.amber.shade800,
      Colors.green.shade700,
      Colors.purple,
      Colors.blueGrey,
    ];
    for (var i = 0; i < habits.length; i++) {
      final y = top + 14 + i * 28.0;
      final color = palette[i % palette.length];
      label(habits[i].name, Offset(0, y - 7));
      canvas.drawRect(
        Rect.fromLTWH(labelWidth, y - 9, plotWidth, 18),
        Paint()..color = color.withOpacity(.07),
      );
      canvas.drawLine(
        Offset(labelWidth, y + 9),
        Offset(labelWidth + plotWidth, y + 9),
        Paint()..color = Colors.black12,
      );
      for (final entry in eventDates.entries) {
        if (!entry.value.contains(habits[i].id)) continue;
        final day = DateTime.tryParse(entry.key);
        if (day == null) continue;
        final offset = day.difference(startDay).inDays;
        if (offset < 0 || offset > span) continue;
        final x = labelWidth + offset / span * plotWidth;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(x, y), width: 4.0, height: 17),
            const Radius.circular(2),
          ),
          Paint()..color = color,
        );
      }
    }
    final baseline = top + habits.length * 28.0 + 8;
    label(
      DateFormat('MMM d, yyyy').format(startDay),
      Offset(labelWidth, baseline),
      fontSize: 9,
      color: Colors.black54,
    );
    final last = DateFormat('MMM d, yyyy').format(endDay);
    final tp = TextPainter(
      text: TextSpan(
        text: last,
        style: const TextStyle(fontSize: 9, color: Colors.black54),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(size.width - right - tp.width, baseline));
  }

  @override
  bool shouldRepaint(covariant _PebblesEventBandsPainter old) => true;
}

class _PebblesScatterPainter extends CustomPainter {
  final List<_ExplorerPoint> points;
  final String xLabel, yLabel;
  final bool eventMode;
  const _PebblesScatterPainter({
    required this.points,
    required this.xLabel,
    required this.yLabel,
    required this.eventMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const left = 46.0, right = 14.0, top = 16.0, bottom = 46.0;
    final width = size.width - left - right,
        height = size.height - top - bottom;
    if (width <= 0 || height <= 0) return;
    double minX = points.map((p) => p.x).reduce(math.min),
        maxX = points.map((p) => p.x).reduce(math.max);
    double minY = points.map((p) => p.y).reduce(math.min),
        maxY = points.map((p) => p.y).reduce(math.max);
    if (minX == maxX) {
      minX -= 1;
      maxX += 1;
    }
    if (minY == maxY) {
      minY -= 1;
      maxY += 1;
    }
    final axes = Paint()
      ..color = Colors.black38
      ..strokeWidth = 1;
    canvas.drawLine(const Offset(left, top), Offset(left, top + height), axes);
    canvas.drawLine(
      Offset(left, top + height),
      Offset(left + width, top + height),
      axes,
    );
    void text(String label, Offset offset, {double font = 11}) {
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(color: Colors.black87, fontSize: font),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp.paint(canvas, offset);
    }

    text(maxY.toStringAsFixed(1), const Offset(2, top));
    text(minY.toStringAsFixed(1), Offset(2, top + height - 12));
    text(minX.toStringAsFixed(1), Offset(left, top + height + 6));
    text(maxX.toStringAsFixed(1), Offset(left + width - 28, top + height + 6));
    text(xLabel, Offset(left + width / 2 - 24, size.height - 16));
    text(yLabel, const Offset(3, 0));
    for (final p in points) {
      final px = left + (p.x - minX) / (maxX - minX) * width;
      final py = top + height - (p.y - minY) / (maxY - minY) * height;
      final paint = Paint()
        ..color = p.special
            ? Colors.deepPurple
            : (eventMode ? Colors.deepOrange : Colors.blue.shade600);
      if (p.special) {
        canvas.drawCircle(
          Offset(px, py),
          7,
          Paint()..color = Colors.deepPurple.withOpacity(.15),
        );
        canvas.drawCircle(Offset(px, py), 4.5, paint);
      } else {
        canvas.drawCircle(Offset(px, py), 4, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PebblesScatterPainter old) => true;
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(h.name),
                    if (h.isFavorite) ...[
                      const SizedBox(width: 4),
                      _favoriteHeart(),
                    ],
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
    String habitType = h?.habitType ?? 'check';
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
                DropdownButtonFormField<String>(
                  value: habitType,
                  decoration: const InputDecoration(labelText: "Type"),
                  items: const [
                    DropdownMenuItem(value: 'check', child: Text('Check mark')),
                    DropdownMenuItem(value: 'note', child: Text('Note')),
                    DropdownMenuItem(value: 'number', child: Text('Number')),
                  ],
                  onChanged: (v) => setDS(() => habitType = v ?? 'check'),
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
            if (h != null)
              TextButton(
                onPressed: () async {
                  if (!await _confirmDelete(context, '"${h.name}"')) return;
                  FirebaseFirestore.instance
                      .collection('habits')
                      .doc(h.id)
                      .delete();
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text(
                  "Delete",
                  style: TextStyle(color: _kDestructive),
                ),
              ),
            ElevatedButton(
              onPressed: () {
                final d = {
                  'name': ctrl.text,
                  'description': descCtrl.text,
                  'categoryId': cat,
                  'habitType': habitType,
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
                    'valueMap': {},
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
              onPressed: () async {
                if (!await _confirmDelete(context, 'this mood')) return;
                FirebaseFirestore.instance
                    .collection('moods')
                    .doc(doc.id)
                    .delete();
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text(
                "Delete",
                style: TextStyle(color: _kDestructive),
              ),
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
                            onPressed: () async {
                              if (!await _confirmDelete(context, 'this mood')) {
                                return;
                              }
                              FirebaseFirestore.instance
                                  .collection('moods')
                                  .doc(m.id)
                                  .delete();
                              if (context.mounted) Navigator.pop(context);
                            },
                            child: const Text(
                              "Delete",
                              style: TextStyle(color: _kDestructive),
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

Color _moodColor(int score) {
  switch (score) {
    case 1:
      return const Color(0xFFC94C54);
    case 2:
      return const Color(0xFFD86A55);
    case 3:
      return const Color(0xFFE39B59);
    case 4:
      return const Color(0xFFEBCA6B);
    case 5:
      return const Color(0xFFE9DF9A);
    case 6:
      return const Color(0xFFA6CD83);
    case 7:
      return const Color(0xFF62B784);
    case 8:
      return const Color(0xFF2A9D72);
    case 9:
      return const Color(0xFF9870CB);
    default:
      return Colors.grey.shade200;
  }
}

Color _gradientColor(double ratio) {
  final t = ratio.clamp(0.0, 1.0);
  const stops = [
    Color(0xFFC94C54),
    Color(0xFFE39B59),
    Color(0xFFEBCA6B),
    Color(0xFFA6CD83),
    Color(0xFF2A9D72),
  ];
  final index = math.min(3, (t * 4).floor());
  return Color.lerp(stops[index], stops[index + 1], t * 4 - index)!;
}

// A compact calendar: each metric has twelve month rows and 31 day columns.
class PebblesYearScreen extends StatefulWidget {
  final List<Habit> habits;
  final List<HabitCategory> categories;
  final PreferredSizeWidget navigation;
  const PebblesYearScreen({
    super.key,
    required this.habits,
    required this.categories,
    required this.navigation,
  });
  @override
  State<PebblesYearScreen> createState() => _PebblesYearScreenState();
}

class _PebblesYearScreenState extends State<PebblesYearScreen> {
  int _year = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Insights'), bottom: widget.navigation),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('daily_metrics')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Couldn't load year data."));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final daily = <String, Map<String, dynamic>>{
            for (final doc in snapshot.data!.docs)
              doc.id: Map<String, dynamic>.from(doc.data() as Map),
          };
          Habit? builtIn(String name) {
            for (final habit in widget.habits) {
              if (habit.name == name) return habit;
            }
            return null;
          }

          final metrics = <_ExplorerMetric>[
            _ExplorerMetric('mood', 'Mood', 'mood', builtIn('Mood')),
            _ExplorerMetric('sleep', 'Sleep', 'numeric', builtIn('Sleep')),
            _ExplorerMetric(
              'sleep_score',
              'Sleep score',
              'numeric',
              builtIn('Sleep score'),
            ),
            for (final habit in widget.habits)
              if (!['Mood', 'Sleep', 'Sleep score'].contains(habit.name))
                _ExplorerMetric(
                  'habit:${habit.id}',
                  habit.name,
                  ['Diary', 'Dreams'].contains(habit.name) ||
                          habit.habitType == 'note'
                      ? 'note'
                      : habit.habitType == 'number'
                      ? 'numeric'
                      : 'event',
                  habit,
                ),
          ];
          final groups = <String, List<_ExplorerMetric>>{};
          for (final metric in metrics) {
            final tag = metric.habit?.categoryId ?? '';
            groups.putIfAbsent(tag, () => []).add(metric);
          }
          final tagIds = [
            ...widget.categories
                .where((c) => groups.containsKey(c.id))
                .map((c) => c.id),
            ...groups.keys.where(
              (id) => !widget.categories.any((c) => c.id == id),
            ),
          ];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: 'Previous year',
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => setState(() => _year--),
                  ),
                  Text(
                    '$_year',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Next year',
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _year < DateTime.now().year
                        ? () => setState(() => _year++)
                        : null,
                  ),
                ],
              ),
              const Text(
                'Each square is one day. Months run from January to December; days run left to right. Tap a square for details.',
                style: TextStyle(fontSize: 12, color: _kSecondaryLabel),
              ),
              const SizedBox(height: 12),
              for (final tagId in tagIds) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    widget.categories.where((c) => c.id == tagId).isEmpty
                        ? (tagId.isEmpty ? 'No Tag' : 'Other metrics')
                        : widget.categories
                              .firstWhere((c) => c.id == tagId)
                              .name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                for (final metric in groups[tagId]!)
                  _calendar(context, metric, daily),
              ],
              const Text(
                'Mood and sleep score: red → yellow → green. Purple mood: Too happy. Sleep colours show duration, not quality. Other recorded values use the tag colour; grey means no entry. Unchecked habits are unknown.',
                style: TextStyle(fontSize: 11, color: _kSecondaryLabel),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _calendar(
    BuildContext context,
    _ExplorerMetric metric,
    Map<String, Map<String, dynamic>> daily,
  ) {
    Color tagColor = const Color(0xFF648BB4);
    for (final tag in widget.categories) {
      if (tag.id == metric.habit?.categoryId) tagColor = tag.color;
    }
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              metric.label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                final pitch = (constraints.maxWidth - 30) / 31;
                return Column(
                  children: [
                    for (int month = 1; month <= 12; month++)
                      Row(
                        children: [
                          SizedBox(
                            width: 30,
                            child: Text(
                              DateFormat('MMM').format(DateTime(_year, month)),
                              style: const TextStyle(
                                fontSize: 9,
                                color: _kSecondaryLabel,
                              ),
                            ),
                          ),
                          for (int day = 1; day <= 31; day++)
                            SizedBox(
                              width: pitch,
                              height: pitch + 2,
                              child: day > DateTime(_year, month + 1, 0).day
                                  ? const SizedBox()
                                  : _day(
                                      context,
                                      metric,
                                      DateTime(_year, month, day),
                                      daily,
                                      tagColor,
                                    ),
                            ),
                        ],
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  Widget _day(
    BuildContext context,
    _ExplorerMetric metric,
    DateTime date,
    Map<String, Map<String, dynamic>> daily,
    Color tagColor,
  ) {
    final now = DateTime.now();
    if (date.isAfter(DateTime(now.year, now.month, now.day))) {
      return const SizedBox();
    }
    final key = DateFormat('yyyy-MM-dd').format(date);
    final record = daily[key] ?? <String, dynamic>{};
    dynamic raw;
    if (metric.id == 'mood') {
      raw = record['mood'];
    } else if (metric.id == 'sleep' || metric.id == 'sleep_score') {
      raw = record[metric.id];
    } else if (metric.type == 'event') {
      raw = metric.habit!.completionMap[key] == true
          ? 'Occurrence recorded'
          : null;
    } else if (metric.habit!.name == 'Diary' ||
        metric.habit!.name == 'Dreams') {
      raw = record[metric.habit!.name.toLowerCase()];
    } else {
      raw = metric.habit!.valueMap[key];
    }
    final number = double.tryParse(raw?.toString().replaceAll(',', '.') ?? '');
    final score = metric.type == 'mood' ? PebblesMoodScale.score(raw) : null;
    final recorded = metric.type == 'mood'
        ? score != null
        : metric.type == 'numeric'
        ? number != null && number.isFinite
        : raw != null && raw.toString().trim().isNotEmpty;
    Color color = const Color(0xFFE6E8EC);
    if (recorded) {
      color = metric.type == 'mood'
          ? _moodColor(score!)
          : metric.id == 'sleep_score'
          ? _gradientColor(number! / 100)
          : metric.id == 'sleep'
          ? _gradientColor(number! / 12)
          : tagColor;
    }
    final detail = recorded
        ? '$raw${metric.id == 'sleep'
              ? ' hours'
              : metric.id == 'sleep_score'
              ? '/100'
              : ''}'
        : 'No value recorded';
    final title = '${metric.label} · ${DateFormat('MMM d, yyyy').format(date)}';
    return Semantics(
      label: '$title: $detail',
      button: true,
      child: Tooltip(
        message: '$title: $detail',
        child: InkWell(
          onTap: () => showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(title),
              content: Text(detail),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(1),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
