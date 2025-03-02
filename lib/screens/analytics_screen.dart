import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/data_storage_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  _AnalyticsScreenState createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> with SingleTickerProviderStateMixin {
  final ApiService apiService = ApiService();
  bool isLoading = true;
  String? errorMessage;

  late TabController _tabController;
  List<Map<String, dynamic>> sensorData = [];
  Map<int, List<Map<String, dynamic>>> nodeData = {};
  List<int> availableNodes = [];
  int selectedNodeId = 1;

  DateTime startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime endDate = DateTime.now();
  String selectedTimeRange = '7 days';

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
    _startPeriodicRefresh();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _loadData(silent: true);
    });
  }

  Future<void> _loadData({bool silent = false}) async {
    if (!silent) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final allNodesData = await apiService.fetchAndStoreAllNodesData();

      Map<int, List<Map<String, dynamic>>> groupedData = allNodesData.isEmpty
          ? await _fetchLocalData()
          : allNodesData;

      setState(() {
        nodeData = groupedData;
        availableNodes = groupedData.keys.toList();
        if (availableNodes.isNotEmpty && !availableNodes.contains(selectedNodeId)) {
          selectedNodeId = availableNodes.first;
        }
        if (!silent) isLoading = false;
      });

      _filterDataByDateRange();
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        if (!silent) isLoading = false;
      });
    }
  }

  Future<Map<int, List<Map<String, dynamic>>>> _fetchLocalData() async {
    final localData = await DataStorageService.getSensorData();
    Map<int, List<Map<String, dynamic>>> groupedData = {};
    for (var data in localData) {
      final nodeId = data['node_id'];
      groupedData.putIfAbsent(nodeId, () => []).add(data);
    }
    return groupedData;
  }

  void _filterDataByDateRange() {
    if (nodeData.isEmpty || !nodeData.containsKey(selectedNodeId)) {
      setState(() => sensorData = []);
      return;
    }

    final filteredData = nodeData[selectedNodeId]!
        .where((data) => _isInDateRange(data['timestamp']))
        .toList()
      ..sort((a, b) => DateTime.parse(a['timestamp']).compareTo(DateTime.parse(b['timestamp'])));

    setState(() => sensorData = filteredData);
  }

  bool _isInDateRange(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      return date.isAfter(startDate) && date.isBefore(endDate.add(const Duration(days: 1)));
    } catch (e) {
      return false;
    }
  }

  void _setTimeRange(String range) {
    final now = DateTime.now();
    switch (range) {
      case '24 hours':
        startDate = now.subtract(const Duration(hours: 24));
        break;
      case '7 days':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case '30 days':
        startDate = now.subtract(const Duration(days: 30));
        break;
      case '90 days':
        startDate = now.subtract(const Duration(days: 90));
        break;
    }
    endDate = now;
    setState(() => selectedTimeRange = range);
    _filterDataByDateRange();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: isLoading
                ? _buildLoadingIndicator()
                : errorMessage != null
                ? _buildErrorMessage()
                : _buildTabContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _buildNodeSelector()),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.teal),
                onPressed: () => _loadData(silent: false),
                tooltip: 'Refresh Data',
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTimeRangeButton('24 hours'),
                _buildTimeRangeButton('7 days'),
                _buildTimeRangeButton('30 days'),
                _buildTimeRangeButton('90 days'),
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: const Icon(Icons.date_range, size: 16, color: Colors.teal),
                  label: const Text('Custom'),
                  onPressed: _showDateRangePicker,
                  style: TextButton.styleFrom(foregroundColor: Colors.teal),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Moisture'),
              Tab(text: 'Statistics'),
              Tab(text: 'History'),
            ],
            labelColor: Colors.teal.shade700,
            unselectedLabelColor: Colors.grey.shade600,
            indicatorColor: Colors.teal.shade700,
          ),
        ],
      ),
    );
  }

  Widget _buildNodeSelector() {
    if (availableNodes.isEmpty) {
      return const Text('No nodes available', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold));
    }
    return DropdownButtonFormField<int>(
      value: availableNodes.contains(selectedNodeId) ? selectedNodeId : availableNodes.first,
      decoration: InputDecoration(
        labelText: 'Select Node',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      items: availableNodes.map((nodeId) => DropdownMenuItem<int>(value: nodeId, child: Text('Node $nodeId'))).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => selectedNodeId = value);
          _filterDataByDateRange();
        }
      },
    );
  }

  Widget _buildTimeRangeButton(String range) {
    final isSelected = selectedTimeRange == range;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ElevatedButton(
        onPressed: () => _setTimeRange(range),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.teal.shade100 : Colors.grey.shade100,
          foregroundColor: isSelected ? Colors.teal.shade700 : Colors.grey.shade700,
          elevation: 0,
        ),
        child: Text(range),
      ),
    );
  }

  void _showDateRangePicker() async {
    final pickedRange = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: startDate, end: endDate),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: Colors.teal.shade700)),
        child: child!,
      ),
    );
    if (pickedRange != null) {
      setState(() {
        startDate = pickedRange.start;
        endDate = pickedRange.end;
        selectedTimeRange = 'Custom';
      });
      _filterDataByDateRange();
    }
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildMoistureTab(),
        _buildStatisticsTab(),
        _buildHistoryTab(),
      ],
    );
  }

  Widget _buildMoistureTab() {
    if (sensorData.isEmpty) return _buildNoDataMessage();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Moisture Levels', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal.shade800)),
          const SizedBox(height: 4),
          Text('${DateFormat('MMM d, yyyy').format(startDate)} - ${DateFormat('MMM d, yyyy').format(endDate)}',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          const SizedBox(height: 16),
          Expanded(child: _buildMoistureChart()),
          const SizedBox(height: 16),
          _buildMoistureRangeIndicator(),
        ],
      ),
    );
  }

  Widget _buildMoistureChart() {
    final values = sensorData.map((data) => (data['moisture_level'] as num).toDouble()).toList();
    final minY = values.isEmpty ? 0.0 : (values.reduce((a, b) => a < b ? a : b) * 0.9).clamp(0, 100).toDouble();
    final maxY = values.isEmpty ? 100.0 : (values.reduce((a, b) => a > b ? a : b) * 1.1).clamp(0, 100).toDouble();

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: true, horizontalInterval: 20),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: (sensorData.length / 5).ceil().toDouble(),
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= sensorData.length) return const SizedBox.shrink();
                final date = DateTime.parse(sensorData[value.toInt()]['timestamp']);
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(DateFormat('MM/dd HH:mm').format(date),
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 10), textAlign: TextAlign.center),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, interval: 20)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.shade300)),
        minX: 0,
        maxX: sensorData.length - 1.0,
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(sensorData.length, (index) => FlSpot(index.toDouble(), values[index])),
            isCurved: true,
            color: Colors.teal.shade700,
            barWidth: 3,
            belowBarData: BarAreaData(show: true, color: Colors.teal.withOpacity(0.2)),
          ),
        ],
      ),
    );
  }

  Widget _buildMoistureRangeIndicator() {
    const double optimalMin = 60;
    const double optimalMax = 70;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Optimal Moisture Range', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal.shade800)),
        const SizedBox(height: 8),
        Container(
          height: 20,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: const LinearGradient(colors: [Colors.red, Colors.teal, Colors.red], stops: [0.0, 0.5, 1.0]),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('0%', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            Text('$optimalMin% - $optimalMax%', style: TextStyle(color: Colors.teal.shade800, fontSize: 12, fontWeight: FontWeight.bold)),
            Text('100%', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatisticsTab() {
    if (sensorData.isEmpty) return _buildNoDataMessage();
    final values = sensorData.map((data) => (data['moisture_level'] as num).toDouble()).toList();
    final average = values.isEmpty ? 0 : values.reduce((a, b) => a + b) / values.length;
    final min = values.isEmpty ? 0 : values.reduce((a, b) => a < b ? a : b);
    final max = values.isEmpty ? 0 : values.reduce((a, b) => a > b ? a : b);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Moisture Statistics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal.shade800)),
          const SizedBox(height: 4),
          Text('${DateFormat('MMM d, yyyy').format(startDate)} - ${DateFormat('MMM d, yyyy').format(endDate)}',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          const SizedBox(height: 16),
          _buildStatCard('Average Moisture', '${average.toStringAsFixed(1)}%', Icons.speed, Colors.amber),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatCard('Minimum', '${min.toStringAsFixed(1)}%', Icons.arrow_downward, Colors.red)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Maximum', '${max.toStringAsFixed(1)}%', Icons.arrow_upward, Colors.teal)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
            ]),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (sensorData.isEmpty) return _buildNoDataMessage();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sensor History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal.shade800)),
          const SizedBox(height: 4),
          Text('${DateFormat('MMM d, yyyy').format(startDate)} - ${DateFormat('MMM d, yyyy').format(endDate)}',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          const SizedBox(height: 16),
          Expanded(child: _buildHistoryList()),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    return ListView.builder(
      itemCount: sensorData.length,
      itemBuilder: (context, index) {
        final data = sensorData[sensorData.length - 1 - index];
        final moisture = (data['moisture_level'] as num).toDouble();
        final timestamp = data['timestamp'];
        final (color, text) = moisture < 30
            ? (Colors.red, 'Too Dry')
            : moisture > 70
            ? (Colors.red, 'Too Wet')
            : (Colors.teal, 'Optimal');

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              child: Icon(Icons.water_drop, color: Colors.white),
            ),
            title: Text('Moisture: ${moisture.toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Node: $selectedNodeId', style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
                Text(_formatDateTime(timestamp), style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
              child: Text(text, style: TextStyle(color: color, fontSize: 12)),
            ),
          ),
        );
      },
    );
  }

  String _formatDateTime(String timestamp) =>
      DateTime.tryParse(timestamp)?.let((date) => DateFormat('MMM d, yyyy HH:mm').format(date)) ?? timestamp;

  Widget _buildLoadingIndicator() => const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [SpinKitCircle(color: Colors.teal), SizedBox(height: 16), Text('Loading sensor data...')],
    ),
  );

  Widget _buildErrorMessage() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 48),
        const SizedBox(height: 16),
        const Text('Failed to load data', style: TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(errorMessage ?? 'Unknown error', style: TextStyle(color: Colors.grey.shade700, fontSize: 14), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => _loadData(silent: false),
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade50, foregroundColor: Colors.teal.shade700),
        ),
      ],
    ),
  );

  Widget _buildNoDataMessage() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.info_outline, color: Colors.teal, size: 48),
        const SizedBox(height: 16),
        const Text('No data available', style: TextStyle(color: Colors.teal, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('No sensor data for the selected period.', style: TextStyle(color: Colors.grey, fontSize: 14), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => _loadData(silent: false),
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade50, foregroundColor: Colors.teal.shade700),
        ),
      ],
    ),
  );
}

extension NullableExtension<T> on T? {
  R? let<R>(R Function(T) block) => this != null ? block(this!) : null;
}