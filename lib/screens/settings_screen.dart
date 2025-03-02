import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _locationEnabled = true;
  bool _dataBackupEnabled = true;
  bool _autoSyncEnabled = true;
  double _updateFrequency = 60;
  String _temperatureUnit = 'Celsius';

  final List<String> _temperatureUnits = ['Celsius', 'Fahrenheit'];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _darkModeEnabled = prefs.getBool('dark_mode_enabled') ?? false;
      _locationEnabled = prefs.getBool('location_enabled') ?? true;
      _dataBackupEnabled = prefs.getBool('data_backup_enabled') ?? true;
      _autoSyncEnabled = prefs.getBool('auto_sync_enabled') ?? true;
      _updateFrequency = prefs.getDouble('update_frequency') ?? 60;
      _temperatureUnit = prefs.getString('temperature_unit') ?? 'Celsius';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    await prefs.setBool('dark_mode_enabled', _darkModeEnabled);
    await prefs.setBool('location_enabled', _locationEnabled);
    await prefs.setBool('data_backup_enabled', _dataBackupEnabled);
    await prefs.setBool('auto_sync_enabled', _autoSyncEnabled);
    await prefs.setDouble('update_frequency', _updateFrequency);
    await prefs.setString('temperature_unit', _temperatureUnit);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Settings saved', style: GoogleFonts.montserrat(color: Colors.white)),
        backgroundColor: Colors.teal.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildNotificationSettings(),
              const SizedBox(height: 20),
              _buildAppearanceSettings(),
              const SizedBox(height: 20),
              _buildDataSettings(),
              const SizedBox(height: 20),
              _buildAccountSettings(),
              const SizedBox(height: 20),
              _buildVersionInfo(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveSettings,
        backgroundColor: Colors.teal.shade700,
        child: const Icon(Icons.save, color: Colors.white),
      ).animate().scale(duration: 500.ms, curve: Curves.easeOut).fadeIn(duration: 500.ms),
    );
  }

  Widget _buildHeader() {
    return Text(
      'Settings',
      style: GoogleFonts.montserrat(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.teal.shade800),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.1, end: 0, duration: 500.ms, curve: Curves.easeOut);
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal.shade700, size: 24),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal.shade800),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard({required Widget child}) { // Removed fixed height
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: child,
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0, duration: 600.ms);
  }

  Widget _buildNotificationSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Notifications', Icons.notifications),
        _buildSettingsCard(
          child: Column(
            children: [
              _buildSwitchOption('Enable Notifications', 'Receive farm alerts', _notificationsEnabled, (value) => setState(() => _notificationsEnabled = value)),
              const Divider(height: 16),
              _buildSwitchOption('Alert Notifications', 'Sensor alerts', _notificationsEnabled, (value) {}, enabled: _notificationsEnabled),
              const Divider(height: 16),
              _buildSwitchOption('System Notifications', 'System updates', _notificationsEnabled, (value) {}, enabled: _notificationsEnabled),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 600.ms, delay: 100.ms).slideY(begin: 0.2, end: 0, duration: 600.ms, delay: 100.ms);
  }

  Widget _buildAppearanceSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Appearance', Icons.palette),
        _buildSettingsCard(
          child: Column(
            children: [
              _buildSwitchOption('Dark Mode', 'Toggle dark theme', _darkModeEnabled, (value) => setState(() => _darkModeEnabled = value)),
              const Divider(height: 16),
              _buildDropdownOption('Temperature Unit', 'Preferred unit', _temperatureUnit, _temperatureUnits,
                      (value) => setState(() => _temperatureUnit = value ?? 'Celsius')),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 600.ms, delay: 200.ms).slideY(begin: 0.2, end: 0, duration: 600.ms, delay: 200.ms);
  }

  Widget _buildDataSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Data & Sync', Icons.sync),
        _buildSettingsCard(
          child: Column(
            children: [
              _buildSwitchOption('Auto-Sync', 'Sync data automatically', _autoSyncEnabled, (value) => setState(() => _autoSyncEnabled = value)),
              const Divider(height: 16),
              _buildSwitchOption('Data Backup', 'Backup to cloud', _dataBackupEnabled, (value) => setState(() => _dataBackupEnabled = value)),
              const Divider(height: 16),
              _buildSliderOption('Update Frequency', 'Fetch data interval (minutes)', _updateFrequency, 15, 120,
                      (value) => setState(() => _updateFrequency = value)),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 600.ms, delay: 300.ms).slideY(begin: 0.2, end: 0, duration: 600.ms, delay: 300.ms);
  }

  Widget _buildAccountSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Account & Privacy', Icons.account_circle),
        _buildSettingsCard(
          child: Column(
            children: [
              _buildSwitchOption('Location Services', 'Allow location access', _locationEnabled, (value) => setState(() => _locationEnabled = value)),
              const Divider(height: 16),
              _buildActionButton('Privacy Policy', 'View privacy policy', Icons.policy, () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Privacy Policy coming soon', style: GoogleFonts.montserrat(color: Colors.white)), backgroundColor: Colors.teal.shade700),
                );
              }),
              const Divider(height: 16),
              _buildActionButton('Delete Account', 'Permanently delete account', Icons.delete_forever, _showDeleteAccountDialog, color: Colors.red.shade700),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 600.ms, delay: 400.ms).slideY(begin: 0.2, end: 0, duration: 600.ms, delay: 400.ms);
  }

  Widget _buildVersionInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Center(
        child: Text(
          'Smart Farm v1.0.0',
          style: GoogleFonts.montserrat(fontSize: 14, color: Colors.teal.shade700),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms, delay: 500.ms).slideY(begin: 0.2, end: 0, duration: 600.ms, delay: 500.ms);
  }

  Widget _buildSwitchOption(String title, String subtitle, bool value, Function(bool) onChanged, {bool enabled = true}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey.shade800)),
              Text(subtitle, style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: enabled ? onChanged : null,
          activeColor: Colors.teal.shade700,
          activeTrackColor: Colors.teal.shade300,
        ).animate().scale(duration: 300.ms, curve: Curves.easeInOut),
      ],
    );
  }

  Widget _buildDropdownOption<T>(String title, String subtitle, T value, List<T> options, Function(T?) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey.shade800)),
              Text(subtitle, style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.teal.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<T>(
            value: value,
            items: options.map((T option) => DropdownMenuItem<T>(value: option, child: Text(option.toString(), style: GoogleFonts.montserrat(color: Colors.teal.shade700)))).toList(),
            onChanged: onChanged,
            dropdownColor: Colors.white,
            underline: const SizedBox(),
            icon: const Icon(Icons.arrow_drop_down, color: Colors.teal),
          ),
        ),
      ],
    );
  }

  Widget _buildSliderOption(String title, String subtitle, double value, double min, double max, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey.shade800)),
        Text(subtitle, style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey.shade600)),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: value,
                min: min,
                max: max,
                divisions: ((max - min) / 15).round(),
                label: value.round().toString(),
                onChanged: onChanged,
                activeColor: Colors.teal.shade700,
                inactiveColor: Colors.grey.shade300,
              ),
            ),
            Text('${value.round()} min', style: GoogleFonts.montserrat(fontSize: 14, color: Colors.teal.shade700)),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(String title, String subtitle, IconData icon, VoidCallback onTap, {Color? color}) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color ?? Colors.teal.shade700, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w500, color: color ?? Colors.grey.shade800)),
                Text(subtitle, style: GoogleFonts.montserrat(fontSize: 12, color: color?.withOpacity(0.7) ?? Colors.grey.shade600)),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, color: color ?? Colors.teal.shade700, size: 16),
        ],
      ),
    ).animate().scale(duration: 300.ms, curve: Curves.easeInOut);
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Account?', style: GoogleFonts.montserrat(color: Colors.teal.shade800)),
        content: Text('This action cannot be undone. All data will be permanently deleted.', style: GoogleFonts.montserrat(color: Colors.grey.shade800)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.montserrat(color: Colors.teal.shade700)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Account deletion coming soon', style: GoogleFonts.montserrat(color: Colors.white)), backgroundColor: Colors.red.shade700),
              );
            },
            child: Text('Delete', style: GoogleFonts.montserrat(color: Colors.red.shade700)),
          ),
        ],
      ),
    );
  }
}