import 'package:flutter/material.dart';
import 'post_project_screen.dart';

class CompanyDashboardScreen extends StatelessWidget {
  const CompanyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy posted projects list (Baad mein Supabase se fetch hogi)
    final List> companyProjects = [
      {
        'title': 'Flutter E-Commerce App Redesign',
        'budget': '\$500 - \$800',
        'applicantsCount': 3,
        'status': 'Open',
      },
      {
        'title': 'Barcode Scanning Mobile Utility',
        'budget': '\$300',
        'applicantsCount': 1,
        'status': 'In Progress',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Dashboard'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Your Posted Projects',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    // Navigate to Post Project Screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PostProjectScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Post New'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Projects List
            Expanded(
              child: ListView.builder(
                itemCount: companyProjects.length,
                itemBuilder: (context, index) {
                  final project = companyProjects[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                project['title'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Chip(
                                label: Text(project['status']),
                                backgroundColor: project['status'] == 'Open'
                                    ? Colors.green.shade100
                                    : Colors.orange.shade100,
                                labelStyle: TextStyle(
                                  color: project['status'] == 'Open'
                                      ? Colors.green.shade800
                                      : Colors.orange.shade800,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Budget: ${project['budget']}'),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Applicants: ${project['applicantsCount']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blueGrey,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  // Yahan applicants ki list khulegi (Accept/Hire karne ke liye)
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Opening applicants list...'),
                                    ),
                                  );
                                },
                                child: const Text('View Applicants'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
