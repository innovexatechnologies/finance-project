import 'package:flutter/material.dart';

class ProfessionalFeedScreen extends StatelessWidget {
  const ProfessionalFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy data taaki UI ki look & feel check ho sake (Baad mein yeh Supabase se fetch hoga)
    final List<Map<String, dynamic>> dummyProjects = [
      {
        'title': 'Flutter E-Commerce App Redesign',
        'company': 'Innovexa Technologies',
        'budget': '\$500 - \$800',
        'description': 'Looking for an experienced Flutter developer to build clean UI/UX and integrate payment gateways.',
      },
      {
        'title': 'Barcode Scanning Mobile Utility',
        'company': 'CodeCraft Solutions',
        'budget': '\$300',
        'description': 'Need a high-performance barcode scanner module implemented in Dart and Flutter.',
      },
      {
        'title': 'Note-Taking App Local Persistence',
        'company': 'ByteWorks',
        'budget': '\$400',
        'description': 'Implement local caching using SharedPreferences and organize screens in feature-first architecture.',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Professional Feed - Projects'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              // Yahan developer apni profile ya applications status screen par ja sakega
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: dummyProjects.length,
        padding: const EdgeInsets.all(12.0),
        itemBuilder: (context, index) {
          final project = dummyProjects[index];
          return Card(
            elevation: 3,
            margin: const EdgeInsets.only(bottom: 16.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Company Name & Budget Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        project['company'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          project['budget'],
                          style: TextStyle(
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Project Title
                  Text(
                    project['title'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Description
                  Text(
                    project['description'],
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Apply Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Applied for ${project['title']}!')),
                        );
                      },
                      child: const Text('Apply Now'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}