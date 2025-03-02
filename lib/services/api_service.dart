import 'dart:convert';
import 'package:http/http.dart' as http;
import 'data_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class ApiService {
  // Base URL for the API - change this to your server's address
  final String baseUrl = 'http://ip'; // For Android emulator
  // Use 'http://localhost:5000' for iOS simulator or web
  // Use your actual server IP for physical devices

  // Node Management
  Future<dynamic> addNode(String name, String ipAddress, {int dataInterval = 60, int moistureThreshold = 30}) async {
    final response = await postData('/add_node', {
      'name': name,
      'ip_address': ipAddress,
      'data_interval': dataInterval,
      'moisture_threshold': moistureThreshold,
    });
    return response;
  }

  Future<dynamic> updateNode(int nodeId, Map<String, dynamic> data) async {
    final response = await putData('/update_node/$nodeId', data);
    return response;
  }

  Future<List<dynamic>> listNodes() async {
    final response = await fetchData('/list_nodes');
    return response;
  }

  Future<dynamic> removeNode(int nodeId) async {
    final response = await deleteData('/remove_node/$nodeId');
    return response;
  }

  // Plant Management
  Future<dynamic> addPlant(String name, int wateringInterval, int idealMoistureMin, int idealMoistureMax, {String notes = ''}) async {
    final response = await postData('/add_plant', {
      'name': name,
      'watering_interval': wateringInterval,
      'ideal_moisture_min': idealMoistureMin,
      'ideal_moisture_max': idealMoistureMax,
      'notes': notes,
    });
    return response;
  }

  Future<dynamic> assignPlant(int nodeId, int plantId) async {
    final response = await putData('/assign_plant/$nodeId/$plantId', {});
    return response;
  }

  Future<List<dynamic>> listPlants() async {
    final response = await fetchData('/list_plants');
    return response;
  }

  // Data Handling
  Future<dynamic> submitData(int nodeId, double moistureLevel) async {
    final response = await postData('/submit_data/$nodeId', {
      'moisture_level': moistureLevel,
    });
    return response;
  }

  Future<List<dynamic>> getData(int nodeId) async {
    final response = await fetchData('/get_data/$nodeId');
    return response;
  }

  Future<dynamic> latestData(int nodeId) async {
    final response = await fetchData('/latest_data/$nodeId');
    return response;
  }

  // Status Check
  Future<dynamic> checkStatus() async {
    final response = await fetchData('/status');
    return response;
  }

  // Generic GET request
  Future<dynamic> fetchData(String endpoint) async {
    return await compute(_fetchData, {'baseUrl': baseUrl, 'endpoint': endpoint});
  }

  static Future<dynamic> _fetchData(Map<String, String> params) async {
    final baseUrl = params['baseUrl'];
    final endpoint = params['endpoint'];
    try {
      final response = await http.get(Uri.parse('$baseUrl$endpoint')).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Generic POST request
  Future<dynamic> postData(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to post data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Generic PUT request
  Future<dynamic> putData(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Generic DELETE request
  Future<dynamic> deleteData(String endpoint) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to delete data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Fetch humidity data for a specific node
  Future<Map<String, dynamic>> fetchHumidityData(int nodeId) async {
    try {
      final latestData = await fetchData('/latest_data/$nodeId');
      
      // Get historical data for trends
      final historicalData = await fetchData('/get_data/$nodeId');
      
      // Get plant info to determine optimal range
      final nodes = await fetchData('/list_nodes');
      final node = nodes.firstWhere(
        (node) => node['id'] == nodeId, 
        orElse: () => {'plant_id': null}
      );
      
      Map<String, dynamic> plantInfo = {
        'ideal_moisture_min': 60,
        'ideal_moisture_max': 70,
      };
      
      if (node['plant_id'] != null) {
        final plants = await fetchData('/list_plants');
        final plant = plants.firstWhere(
          (plant) => plant['id'] == node['plant_id'],
          orElse: () => {
            'ideal_moisture_min': 60,
            'ideal_moisture_max': 70,
          }
        );
        plantInfo = plant;
      }
      
      // Calculate statistics
      double average = 0;
      double highest = 0;
      double lowest = 100;
      
      if (historicalData.isNotEmpty) {
        double sum = 0;
        for (var data in historicalData) {
          double moisture = data['moisture_level'].toDouble();
          sum += moisture;
          if (moisture > highest) highest = moisture;
          if (moisture < lowest) lowest = moisture;
        }
        average = sum / historicalData.length;
      }
      
      return {
        'current': latestData['moisture_level'],
        'timestamp': latestData['timestamp'],
        'optimal_min': plantInfo['ideal_moisture_min'],
        'optimal_max': plantInfo['ideal_moisture_max'],
        'average': average.toStringAsFixed(1),
        'highest': highest.toStringAsFixed(1),
        'lowest': lowest.toStringAsFixed(1),
      };
    } catch (e) {
      // Return mock data if server is not available
      return {
        'current': 65,
        'timestamp': DateTime.now().toString(),
        'optimal_min': 60,
        'optimal_max': 70,
        'average': '63',
        'highest': '68',
        'lowest': '58',
      };
    }
  }
  
  // Fetch weather data (this would typically come from a weather API)
  // For now, we'll use mock data since your server doesn't have weather endpoints
  Future<Map<String, dynamic>> fetchWeatherData() async {
    try {
      // Check if server is online
      await fetchData('/status');
      
      // In a real app, you would integrate with a weather API here
      // For now, return mock data
      return {
        'current': {
          'temp': 28,
          'condition': 'Sunny',
          'humidity': 45,
          'wind': 8,
        },
        'forecast': [
          {'day': 'Today', 'temp': 28, 'condition': 'Sunny'},
          {'day': 'Tomorrow', 'temp': 26, 'condition': 'Cloudy'},
          {'day': 'Wednesday', 'temp': 24, 'condition': 'Rain'},
          {'day': 'Thursday', 'temp': 25, 'condition': 'Cloudy'},
          {'day': 'Friday', 'temp': 27, 'condition': 'Sunny'},
        ],
        'timestamp': DateTime.now().toString(),
      };
    } catch (e) {
      // Return mock data if server is not available
      return {
        'current': {
          'temp': 28,
          'condition': 'Sunny',
          'humidity': 45,
          'wind': 8,
        },
        'forecast': [
          {'day': 'Today', 'temp': 28, 'condition': 'Sunny'},
          {'day': 'Tomorrow', 'temp': 26, 'condition': 'Cloudy'},
          {'day': 'Wednesday', 'temp': 24, 'condition': 'Rain'},
          {'day': 'Thursday', 'temp': 25, 'condition': 'Cloudy'},
          {'day': 'Friday', 'temp': 27, 'condition': 'Sunny'},
        ],
        'timestamp': DateTime.now().toString(),
      };
    }
  }
  
  // Fetch historical sensor data and store it locally
  Future<List<Map<String, dynamic>>> fetchAndStoreHistoricalData(int nodeId) async {
    try {
      final data = await fetchData('/get_data/$nodeId');
      
      // Format data for storage
      List<Map<String, dynamic>> formattedData = [];
      for (var item in data) {
        formattedData.add({
          'node_id': nodeId,
          'moisture_level': item['moisture_level'],
          'timestamp': item['timestamp'],
        });
      }
      
      // Store data locally
      await DataStorageService.storeSensorData(formattedData);
      
      return formattedData;
    } catch (e) {
      // If server is not available, return locally stored data
      return await DataStorageService.getDataForNode(nodeId);
    }
  }
  
  // Fetch data for all nodes and store locally
  Future<Map<int, List<Map<String, dynamic>>>> fetchAndStoreAllNodesData() async {
    try {
      // Get list of all nodes
      final nodes = await fetchData('/list_nodes');
      
      Map<int, List<Map<String, dynamic>>> allNodesData = {};
      
      // Fetch data for each node
      for (var node in nodes) {
        final nodeId = node['id'];
        final nodeData = await fetchAndStoreHistoricalData(nodeId);
        allNodesData[nodeId] = nodeData;
      }
      
      return allNodesData;
    } catch (e) {
      // Return empty map if server is not available
      return {};
    }
  }
}