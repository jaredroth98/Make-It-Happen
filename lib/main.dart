import 'package:flutter/material.dart';
import 'screens/goals_screen.dart';
import 'screens/accountability_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/account_screen.dart';

// 1. The Spark Plug
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MakeItHappenApp());
}

// 2. The App Configuration
class MakeItHappenApp extends StatelessWidget {
  const MakeItHappenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Make It Happen',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true, // Modern Google styling
      ),
      home: const LoginScreen(),
    );
  }
}

// 3. The Navigation Logic (Stateful because the tab changes)
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  // This variable keeps track of which tab is active (starts at 0: Goals)
  int _selectedIndex = 0;

  // These are the "Screens" we will navigate between.
  static List<Widget> _screens = [
    const GoalsScreen(),
    const Center(child: Text('Social screen UI goes here', style: TextStyle(fontSize: 24))),
    const AccountabilityScreen(),
    const Center(child: Text("Learn UI goes here", style: TextStyle(fontSize: 24))),
    const AccountScreen(),
  ];

  // The function that runs when a tab is tapped
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Make It Happen"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),

      // The main context changes based on the selected index
      body: _screens[_selectedIndex],

      // The Tabs at the bottom
      bottomNavigationBar: BottomNavigationBar(
        // Colors and Styling
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blueGrey[900],
        unselectedItemColor: Colors.grey,

        // The current active tab
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,

        // The Buttons
        items: const[
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline),
            label: "Goals",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: "Social",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shield_outlined),
            label: 'Accountability',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: "Learn",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: "Account",
          ),
        ],
      ),
    );
  }
}