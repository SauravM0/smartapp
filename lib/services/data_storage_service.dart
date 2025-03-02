import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DataStorageService {
  static const String _sensorDataKey = 'sensor_data';
  static const String _lastUpdatedKey = 'last_updated';
  static const int _maxStoredDataPoints = 1000; // Limit stored data points to prevent excessive storage use

  // Store sensor data in local storage
  static Future<void> storeSensorData(List<Map<String, dynamic>> data) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Get existing data or create empty list
    List<Map<String, dynamic>> existingData = await getSensorData();
    
    // Add new data
    existingData.addAll(data);
    
    // Keep only the last _maxStoredDataPoints data points
    if (existingData.length > _maxStoredDataPoints) {
      existingData = existingData.sublist(
        existingData.length - _maxStoredDataPoints
      );
    }
    
    // Save updated data
    await prefs.setString(_sensorDataKey, jsonEncode(existingData));
    
    // Update last updated timestamp
    await prefs.setString(_lastUpdatedKey, DateTime.now().toString());
  }
  
  // Get stored sensor data
  static Future<List<Map<String, dynamic>>> getSensorData() async {
    final prefs = await SharedPreferences.getInstance();
    
    final String? dataString = prefs.getString(_sensorDataKey);
    if (dataString == null || dataString.isEmpty) {
      return [];
    }
    
    final List<dynamic> decodedData = jsonDecode(dataString);
    return decodedData.map((item) => Map<String, dynamic>.from(item)).toList();
  }
  
  // Get last updated timestamp
  static Future<DateTime?> getLastUpdated() async {
    final prefs = await SharedPreferences.getInstance();
    
    final String? timestamp = prefs.getString(_lastUpdatedKey);
    if (timestamp == null || timestamp.isEmpty) {
      return null;
    }
    
    return DateTime.parse(timestamp);
  }
  
  // Clear all stored sensor data
  static Future<void> clearSensorData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sensorDataKey);
    await prefs.remove(_lastUpdatedKey);
  }
  
  // Get data for a specific sensor type and node
  static Future<List<Map<String, dynamic>>> getDataForNode(int nodeId) async {
    final allData = await getSensorData();
    
    return allData.where((data) => 
      data['node_id'] == nodeId
    ).toList();
  }
  
  // Get data for a specific date range
  static Future<List<Map<String, dynamic>>> getDataInDateRange(
    DateTime startDate, 
    DateTime endDate, 
    {int? nodeId}
  ) async {
    final allData = await getSensorData();
    
    return allData.where((data) {
      // Check if timestamp exists
      if (!data.containsKey('timestamp')) return false;
      
      try {
        final DateTime timestamp = DateTime.parse(data['timestamp']);
        final bool inDateRange = timestamp.isAfter(startDate) && 
                                timestamp.isBefore(endDate);
        
        // If nodeId is specified, filter by node
        if (nodeId != null) {
          return inDateRange && data['node_id'] == nodeId;
        }
        
        return inDateRange;
      } catch (e) {
        return false;
      }
    }).toList();
  }
} 