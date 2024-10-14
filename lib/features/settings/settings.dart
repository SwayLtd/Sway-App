import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sway/core/constants/l10n.dart';

class Settings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final newLang = await _showLanguageDialog(context);
            if (newLang != null) {
              context.read<LanguageCubit>().changeLang(context, newLang);
            }
          },
          child: const Text('Change Language'),
        ),
      ),
    );
  }

  Future<String?> _showLanguageDialog(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Language'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                title: const Text('English'),
                onTap: () => Navigator.pop(context, 'en'),
              ),
              ListTile(
                title: const Text('French'),
                onTap: () => Navigator.pop(context, 'fr'),
              ),
            ],
          ),
        );
      },
    );
  }
}
