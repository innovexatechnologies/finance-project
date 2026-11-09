import 'package:flutter/material.dart';

class MyApplicationsScreen extends StatelessWidget {
  const MyApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy applications data
    final List<Map<String, String>> myApplications = [
      {
        'title': 'Flutter E-Commerce App Redesign',
        'company': 'Innovexa Technologies',
        'status': 'Pending',
      },
      {
        'title': 'Barcode Scanning Mobile Utility',
        'company': 'CodeCraft Solutions',
        'status': 'Accepted',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Applications'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        itemCount: myApplications.length,
        padding: const EdgeInsets.all(16.0),
        itemBuilder: (context, index) {
          final app = myApplications[index];
          final isAccepted = app['status'] == 'Accepted';
          
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListTile(
              title: Text(
                app['title'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('Company: ${app['company'] ?? ''}'),
              trailing: Chip(
                label: Text(app['status'] ?? ''),
                backgroundColor: isAccepted ? Colors.green.shade100 : Colors.orange.shade100,
                labelStyle: TextStyle(
                  color: isAccepted ? Colors.green.shade800 : Colors.orange.shade800,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}