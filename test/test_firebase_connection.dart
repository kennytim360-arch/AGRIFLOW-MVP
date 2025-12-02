/// test_firebase_connection.dart - Firebase connection test script
///
/// Part of AgriFlow - Irish Cattle Portfolio Management
library;

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agriflow/config/firebase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(home: FirebaseTestScreen()));
}

class FirebaseTestScreen extends StatefulWidget {
  const FirebaseTestScreen({super.key});

  @override
  State<FirebaseTestScreen> createState() => _FirebaseTestScreenState();
}

class _FirebaseTestScreenState extends State<FirebaseTestScreen> {
  String _status = 'Initializing...';
  List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _testConnection();
  }

  void _log(String message) {
    print(message);
    setState(() {
      _logs.add(
        '${DateTime.now().toIso8601String().split('T')[1].substring(0, 8)}: $message',
      );
    });
  }

  Future<void> _testConnection() async {
    try {
      _log('Initializing Firebase...');
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: FirebaseConfig.apiKey,
          appId: FirebaseConfig.appId,
          messagingSenderId: FirebaseConfig.messagingSenderId,
          projectId: FirebaseConfig.projectId,
          storageBucket: FirebaseConfig.storageBucket,
          authDomain: FirebaseConfig.authDomain,
        ),
      );
      _log('✅ Firebase Initialized');

      _log('Testing Anonymous Auth...');
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      _log('✅ Authenticated as: ${userCredential.user?.uid}');

      _log('Testing Firestore Read...');
      // Try to read public collection
      final snapshot = await FirebaseFirestore.instance
          .collection('pricePulses')
          .limit(1)
          .get();
      _log('✅ Firestore Read Success. Docs found: ${snapshot.docs.length}');

      _log('Testing Firestore Write...');
      await FirebaseFirestore.instance.collection('connection_tests').add({
        'timestamp': FieldValue.serverTimestamp(),
        'platform': 'test_script',
        'uid': userCredential.user?.uid,
      });
      _log('✅ Firestore Write Success');

      setState(() => _status = 'SUCCESS: All systems operational');
    } catch (e) {
      _log('❌ ERROR: $e');
      setState(() => _status = 'FAILED: See logs');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firebase Connection Test')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: _status.startsWith('SUCCESS')
                ? Colors.green.shade100
                : Colors.red.shade100,
            width: double.infinity,
            child: Text(
              _status,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _logs.length,
              itemBuilder: (context, index) => Text(
                _logs[index],
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
