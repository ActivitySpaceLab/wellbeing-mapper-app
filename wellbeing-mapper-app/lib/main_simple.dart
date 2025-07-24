import 'package:flutter/material.dart';

/// Minimal app to test basic Flutter functionality
void main() {
  print('[main_simple.dart] Starting minimal app');
  runApp(MinimalApp());
}

class MinimalApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    print('[main_simple.dart] Building MinimalApp');
    return MaterialApp(
      title: 'Minimal Test',
      home: Scaffold(
        appBar: AppBar(
          title: Text('Minimal Test App'),
          backgroundColor: Colors.green,
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
                'Minimal Flutter App Works!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'Basic framework is functional',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
