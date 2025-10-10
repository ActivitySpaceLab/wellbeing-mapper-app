import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Global data for the app
class GlobalData {
  static String userUUID = "";
}

/// Minimal app entry point for debugging
void main() {
  print('[main.dart] Starting minimal debug app');
  
  try {
    WidgetsFlutterBinding.ensureInitialized();
    print('[main.dart] WidgetsFlutterBinding initialized');
    
    runApp(MinimalDebugApp());
    print('[main.dart] runApp called successfully');
  } catch (error) {
    print('[main.dart] Critical error in main: $error');
  }
}

/// Minimal app widget for debugging crashes
class MinimalDebugApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    print('[main.dart] Building MinimalDebugApp');
    
    return MaterialApp(
      title: 'Wellbeing Mapper - Debug',
      debugShowCheckedModeBanner: false,
      home: DebugHomeScreen(),
    );
  }
}

/// Simple debug home screen
class DebugHomeScreen extends StatefulWidget {
  @override
  _DebugHomeScreenState createState() => _DebugHomeScreenState();
}

class _DebugHomeScreenState extends State<DebugHomeScreen> {
  String _initStatus = "Not started";
  String _userUUID = "Not set";

  @override
  void initState() {
    super.initState();
    _testBasicInitialization();
  }

  void _testBasicInitialization() async {
    try {
      setState(() {
        _initStatus = "Testing essential plugins...";
      });
      
      // Test SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('test_key', 'test_value');
      String? testValue = prefs.getString('test_key');
      
      // Test UUID generation
      const uuid = Uuid();
      String testUUID = uuid.v4();
      GlobalData.userUUID = testUUID;
      
      setState(() {
        _initStatus = "Essential plugins working! SharedPrefs: $testValue";
        _userUUID = testUUID;
      });
      
      print('[main.dart] Essential plugins successful');
      print('[main.dart] SharedPrefs test: $testValue');
      print('[main.dart] UUID: $testUUID');
    } catch (error) {
      setState(() {
        _initStatus = "Error: $error";
      });
      print('[main.dart] Essential plugins error: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    print('[main.dart] Building DebugHomeScreen');
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Wellbeing Mapper - Debug Mode'),
        backgroundColor: Colors.orange,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bug_report,
              size: 64,
              color: Colors.orange,
            ),
            SizedBox(height: 20),
            Text(
              'Debug Mode Active',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'App loaded successfully!',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(16),
              margin: EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    'Initialization Status:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 5),
                  Text(
                    _initStatus,
                    style: TextStyle(fontSize: 14),
                  ),
                  if (_userUUID != "Not set") ...[
                    SizedBox(height: 10),
                    Text(
                      'User UUID:',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _userUUID.substring(0, 8) + "...",
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                print('[main.dart] Test button pressed');
                _showTestDialog(context);
              },
              child: Text('Test App Functions'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                print('[main.dart] Navigation test button pressed');
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => TestScreen(),
                  ),
                );
              },
              child: Text('Test Navigation'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTestDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Test Dialog'),
          content: Text('App functions are working correctly!'),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

/// Test screen for navigation
class TestScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Test Screen'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              size: 64,
              color: Colors.green,
            ),
            SizedBox(height: 20),
            Text(
              'Navigation Working!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Flutter framework is functional',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
