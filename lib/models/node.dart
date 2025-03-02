class Node {
  final int id;
  final String name;
  final String ipAddress;
  final int dataInterval;
  final int moistureThreshold;

  Node({required this.id, required this.name, required this.ipAddress, required this.dataInterval, required this.moistureThreshold});

  factory Node.fromJson(Map<String, dynamic> json) {
    return Node(
      id: json['id'],
      name: json['name'],
      ipAddress: json['ip_address'],
      dataInterval: json['data_interval'],
      moistureThreshold: json['moisture_threshold'],
    );
  }
}