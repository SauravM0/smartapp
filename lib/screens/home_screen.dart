import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  final Function(int) onNavigate;

  const HomeScreen({super.key, required this.onNavigate});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final ApiService apiService = ApiService();
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  Map<String, dynamic>? _weatherData;
  Map<String, dynamic>? _humidityData;
  bool _isLoadingWeather = false;
  bool _isLoadingHumidity = false;
  String? _weatherError;
  String? _humidityError;

  final Map<String, dynamic> _farmerData = {
    'name': 'John Smith',
    'farmName': 'Green Valley Farm',
    'location': 'California, USA',
    'farmSize': '120 acres',
    'cropsGrown': 'Corn, Wheat, Soybeans',
    'farmingExperience': '15 years',
  };

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _fetchWeatherData();
    _fetchHumidityData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetchWeatherData() async {
    if (_isLoadingWeather) return;
    setState(() => _isLoadingWeather = true);
    try {
      final data = await apiService.fetchWeatherData();
      setState(() {
        _weatherData = data;
        _isLoadingWeather = false;
      });
    } catch (e) {
      setState(() {
        _weatherError = e.toString();
        _isLoadingWeather = false;
      });
    }
  }

  Future<void> _fetchHumidityData() async {
    if (_isLoadingHumidity) return;
    setState(() => _isLoadingHumidity = true);
    try {
      final data = await apiService.fetchHumidityData(1);
      setState(() {
        _humidityData = data;
        _isLoadingHumidity = false;
      });
    } catch (e) {
      setState(() {
        _humidityError = e.toString();
        _isLoadingHumidity = false;
      });
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGreetingHeader(),
                const SizedBox(height: 20),
                _buildOverviewSection(),
                const SizedBox(height: 20),
                _buildQuickAccessSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGreetingHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_getGreeting()}, ${_farmerData['name']}',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.teal),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                _farmerData['farmName'],
                style: TextStyle(fontSize: 16, color: Colors.teal.shade700),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.teal.withOpacity(0.2),
          child: Text(
            _farmerData['name'].split(' ').map((e) => e[0]).join(),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal),
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildWeatherCard()),
            const SizedBox(width: 12),
            Expanded(child: _buildHumidityCard()),
          ],
        ),
        const SizedBox(height: 12),
        _buildStatusCard(),
      ],
    );
  }

  Widget _buildWeatherCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: _isLoadingWeather
          ? _buildLoadingCard('Weather', Colors.orange.shade700)
          : _weatherError != null
          ? _buildErrorCard('Weather', _weatherError!, Colors.orange.shade700)
          : _weatherData == null
          ? _buildInfoCard('Weather', Icons.wb_sunny, Colors.orange.shade700, 'No data', 'Tap to refresh', _fetchWeatherData)
          : _buildInfoCard(
        'Weather',
        Icons.wb_sunny,
        Colors.orange.shade700,
        '${_weatherData!['current']['temp']}°C ${_weatherData!['current']['condition']}',
        'Tap for forecast',
        _showWeatherDialog,
      ),
    );
  }

  Widget _buildHumidityCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: _isLoadingHumidity
          ? _buildLoadingCard('Humidity', Colors.blue.shade700)
          : _humidityError != null
          ? _buildErrorCard('Humidity', _humidityError!, Colors.blue.shade700)
          : _humidityData == null
          ? _buildInfoCard('Humidity', Icons.water_drop, Colors.blue.shade700, 'No data', 'Tap to refresh', _fetchHumidityData)
          : _buildInfoCard(
        'Humidity',
        Icons.water_drop,
        Colors.blue.shade700,
        '${_humidityData!['current']}% ${_humidityData!['current'] < _humidityData!['optimal_min'] ? 'Below' : _humidityData!['current'] > _humidityData!['optimal_max'] ? 'Above' : 'Optimal'}',
        'Tap for details',
        _showHumidityDialog,
      ),
    );
  }

  Widget _buildStatusCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: FutureBuilder<dynamic>(
        future: apiService.fetchData('/status'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingCard('System Status', Colors.teal.shade700);
          } else if (snapshot.hasError) {
            return _buildErrorCard('System Status', 'Server offline: ${snapshot.error}', Colors.red.shade700);
          } else {
            bool isOnline = snapshot.data['status'] == 'online';
            return _buildInfoCard(
              'System Status',
              isOnline ? Icons.cloud_done : Icons.cloud_off,
              isOnline ? Colors.teal.shade700 : Colors.orange.shade700,
              isOnline ? 'Online' : 'Limited',
              'Last Updated: ${snapshot.data['timestamp']}',
                  () {},
            );
          }
        },
      ),
    );
  }

  Widget _buildLoadingCard(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(children: [
            Icon(Icons.circle, color: color, size: 24),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(fontSize: 16, color: Colors.grey.shade800, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 12),
          SpinKitPulse(color: color, size: 30),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String title, String error, Color color) {
    return InkWell(
      onTap: title == 'Weather' ? _fetchWeatherData : title == 'Humidity' ? _fetchHumidityData : () => setState(() {}),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(children: [
              Icon(Icons.error_outline, color: color, size: 24),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontSize: 16, color: Colors.grey.shade800, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 12),
            Text('Error', style: TextStyle(fontSize: 18, color: color, fontWeight: FontWeight.bold)),
            Text('Tap to retry', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, IconData icon, Color color, String mainValue, String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Flexible(
                child: Text(title, style: TextStyle(fontSize: 16, color: Colors.grey.shade800, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
              ),
            ]),
            const SizedBox(height: 12),
            Text(mainValue, style: TextStyle(fontSize: 20, color: Colors.grey.shade900, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
            Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Access',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _buildQuickAccessIcon('Dashboard', Icons.dashboard, Colors.teal.shade700, () => widget.onNavigate(0)),
              const SizedBox(width: 16),
              _buildQuickAccessIcon('Analytics', Icons.analytics, Colors.teal.shade700, () => widget.onNavigate(1)),
              const SizedBox(width: 16),
              _buildQuickAccessIcon('Alerts', Icons.notifications, Colors.teal.shade700, () => widget.onNavigate(2)),
              const SizedBox(width: 16),
              _buildQuickAccessIcon('Settings', Icons.settings, Colors.teal.shade700, () => widget.onNavigate(3)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAccessIcon(String label, IconData icon, Color color, VoidCallback onTap) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Column(
        children: [
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.teal.withOpacity(0.1),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Icon(icon, color: color, size: 32),
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  void _showWeatherDialog() {
    if (_weatherData == null) {
      _fetchWeatherData();
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Weather Forecast', style: TextStyle(color: Colors.teal)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${_weatherData!['current']['temp']}°C ${_weatherData!['current']['condition']}', style: TextStyle(color: Colors.grey.shade800)),
            const SizedBox(height: 8),
            Text('Tap refresh for full forecast', style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _fetchWeatherData();
            },
            child: const Text('Refresh', style: TextStyle(color: Colors.teal)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.teal)),
          ),
        ],
      ),
    );
  }

  void _showHumidityDialog() {
    if (_humidityData == null) {
      _fetchHumidityData();
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Humidity Details', style: TextStyle(color: Colors.teal)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${_humidityData!['current']}%', style: TextStyle(color: Colors.grey.shade800)),
            const SizedBox(height: 8),
            Text('Optimal: ${_humidityData!['optimal_min']}-${_humidityData!['optimal_max']}%', style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _fetchHumidityData();
            },
            child: const Text('Refresh', style: TextStyle(color: Colors.teal)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.teal)),
          ),
        ],
      ),
    );
  }
}