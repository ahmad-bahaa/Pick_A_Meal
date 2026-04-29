import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.onThemeChanged});

  final Function(ThemeMode) onThemeChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _apiKey = '';
  ThemeMode _currentThemeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _apiKey = prefs.getString('gemini_api_key') ?? '';
      final themeIndex = prefs.getInt('theme_mode') ?? 0;
      _currentThemeMode = ThemeMode.values[themeIndex];
    });
  }

  Future<void> _saveApiKey(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', value);
    setState(() {
      _apiKey = value;
    });
  }

  Future<void> _saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', mode.index);
    widget.onThemeChanged(mode);
  }

  Future<void> _launchUrl() async {
    final Uri url = Uri.parse('https://aistudio.google.com/app/apikey');
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  void _showApiKeyDialog() {
    final controller = TextEditingController(text: _apiKey);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gemini API Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 14,
                ),
                children: [
                  const TextSpan(text: "Get your free API key at "),
                  TextSpan(
                    text: "Google AI Studio",
                    style: const TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()..onTap = _launchUrl,
                  ),
                  const TextSpan(text: "."),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'API Key',
                border: OutlineInputBorder(),
                hintText: 'Enter your API key',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _saveApiKey(controller.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const ListTile(
            title: Text('Appearance', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ListTile(
            title: const Text('Theme Mode'),
            trailing: DropdownButton<ThemeMode>(
              value: _currentThemeMode,
              onChanged: (ThemeMode? newValue) {
                if (newValue != null) {
                  setState(() {
                    _currentThemeMode = newValue;
                  });
                  _saveThemeMode(newValue);
                }
              },
              items: const [
                DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
              ],
            ),
          ),
          const Divider(),
          const ListTile(
            title: Text('AI Configuration', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.vpn_key),
            title: const Text('Gemini API Key'),
            subtitle: Text(_apiKey.isEmpty ? 'Not set' : '••••••••••••••••'),
            trailing: const Icon(Icons.edit),
            onTap: _showApiKeyDialog,
          ),
          const Divider(),
          const ListTile(
            title: Text('Developer Information', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const ListTile(
            leading: Icon(Icons.person),
            title: Text('Developer Name'),
            subtitle: Text('Ahmad Bahaa'),
          ),
          const ListTile(
            leading: Icon(Icons.phone),
            title: Text('Phone Number'),
            subtitle: Text('+201126052979'),
          ),
          const ListTile(
            leading: Icon(Icons.email),
            title: Text('Email'),
            subtitle: Text('Ahmad.Bahaa.Scr@gmail.com'),
          ),
        ],
      ),
    );
  }
}
