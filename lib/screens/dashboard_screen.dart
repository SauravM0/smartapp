import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService apiService = ApiService();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      // appBar: AppBar(
      //   title: const Text('Smart Irrigation Dashboard', style: TextStyle(fontWeight: FontWeight.w600)),
      //   foregroundColor: Colors.white,
      //   backgroundColor: Colors.teal.shade600,
      //   elevation: 0,
      //   actions: [
      //     IconButton(
      //       icon: const Icon(Icons.refresh, size: 28, color: Colors.white), // Already white due to foregroundColor
      //       onPressed: () => setState(() {}),
      //       tooltip: 'Refresh Dashboard',
      //     ),
      //   ],
      // ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - AppBar().preferredSize.height - MediaQuery.of(context).padding.top,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusCard(),
                const SizedBox(height: 25),
                _buildSection('Node Management', [
                  _buildEndpointButton('List Nodes', '/list_nodes', Icons.list),
                  _buildEndpointButton('Add Node', '/add_node', Icons.add),
                  _buildEndpointButton('Update Node', '/update_node/1', Icons.edit),
                  _buildEndpointButton('Remove Node', '/remove_node/1', Icons.delete),
                ]),
                const SizedBox(height: 25),
                _buildSection('Plant Management', [
                  _buildEndpointButton('List Plants', '/list_plants', Icons.local_florist),
                  _buildEndpointButton('Add Plant', '/add_plant', Icons.add),
                  _buildEndpointButton('Assign Plant', '/assign_plant/1/1', Icons.assignment),
                ]),
                const SizedBox(height: 25),
                _buildSection('Data Handling', [
                  _buildEndpointButton('Latest Data', '/latest_data/1', Icons.data_usage),
                  _buildEndpointButton('Get Data', '/get_data/1', Icons.get_app),
                  _buildEndpointButton('Submit Data', '/submit_data/1', Icons.send),
                ]),
                const SizedBox(height: 25),
                _buildSection('Valve Control', [
                  _buildEndpointButton('Get Valve', '/get_valve/1', Icons.water_drop),
                  _buildEndpointButton('Assign Valve', '/assign_valve/1', Icons.assignment),
                  _buildEndpointButton('Update Valve', '/update_valve/1', Icons.edit),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> buttons) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.teal.shade800,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 15),
        _buildButtonGrid(buttons),
      ],
    );
  }

  Widget _buildStatusCard() {
    return FutureBuilder<dynamic>(
      future: apiService.fetchData('/status'),
      builder: (context, snapshot) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: snapshot.connectionState == ConnectionState.waiting
                  ? _buildLoadingCard()
                  : snapshot.hasError
                  ? _buildErrorCard('Server offline: ${snapshot.error}')
                  : IntrinsicHeight(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud, color: Colors.white, size: 30), // Changed to white
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Status: ${snapshot.data['status']}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal.shade800,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Timestamp: ${snapshot.data['timestamp']}',
                      style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingCard() {
    return const SizedBox(
      height: 80,
      child: Center(
        child: SpinKitWave(color: Colors.teal, size: 40), // SpinKitWave remains teal for visibility
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return SizedBox(
      height: 80,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 40), // Changed to white
            const SizedBox(height: 10),
            Expanded(
              child: Text(
                error,
                style: TextStyle(color: Colors.red.shade600, fontSize: 16),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButtonGrid(List<Widget> buttons) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.8,
      mainAxisSpacing: 15,
      crossAxisSpacing: 15,
      children: buttons,
    );
  }

  Widget _buildEndpointButton(String label, String endpoint, IconData icon, {bool isPost = false}) {
    return ElevatedButton(
      onPressed: () => _showDataDialog(label, endpoint, isPost),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.teal.shade600,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 10),
        elevation: 4,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: Colors.white), // Changed to white
          const SizedBox(height: 6),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showDataDialog(String title, String endpoint, bool isPost) async {
    setState(() => isLoading = true);
    try {
      dynamic data = isPost
          ? await apiService.postData(endpoint, {
        'name': 'Test',
        'ip_address': '192.168.1.1',
        'data_interval': 60,
        'moisture_threshold': 30,
        'moisture_level': 45,
        'valve_id': 1,
        'new_state': 'on',
      })
          : await apiService.fetchData(endpoint);
      setState(() => isLoading = false);

      String displayText = data is Map<String, dynamic>
          ? data.entries.map((e) => '${e.key}: ${e.value}').join('\n')
          : data is List<dynamic>
          ? data.map((item) => item.toString()).join('\n')
          : data.toString();

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(title, style: TextStyle(color: Colors.teal.shade800)),
          content: SizedBox(
            width: double.maxFinite,
            height: MediaQuery.of(context).size.height * 0.3,
            child: isLoading
                ? const Center(child: SpinKitWave(color: Colors.teal, size: 40))
                : SingleChildScrollView(
              child: Text(displayText, style: TextStyle(fontSize: 16, color: Colors.grey.shade800)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close', style: TextStyle(color: Colors.teal.shade600)),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() => isLoading = false);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Error', style: TextStyle(color: Colors.red)),
          content: SizedBox(
            height: 100,
            child: Center(
              child: Text('Failed to fetch data: $e', style: TextStyle(color: Colors.grey.shade800)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close', style: TextStyle(color: Colors.teal.shade600)),
            ),
          ],
        ),
      );
    }
  }
}