// database_utils.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway_events/core/services/database_service.dart';
import 'package:sway_events/core/widgets/database_widgets.dart';

class DatabaseUtils extends StatefulWidget {
  const DatabaseUtils({super.key});

  @override
  State<DatabaseUtils> createState() => _DatabaseUtilsState();
}

class _DatabaseUtilsState extends State<DatabaseUtils> {
  final DatabaseService _databaseService = DatabaseService();
  User? _user;
  @override
  void initState() {
    _getAuth();
    super.initState();
    _databaseService.initialize();
  }

  Future<void> _getAuth() async {
    try {
      setState(() {
        _user = Supabase.instance.client.auth.currentUser;
      });
      Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        setState(() {
          _user = data.session?.user;
        });
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching authentication state: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Example'),
      ),
      body: _user == null ? const LoginForm() : const ProfileForm(),
    );
  }
}
