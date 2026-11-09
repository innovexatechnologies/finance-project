import 'package:flutter/material.dart';

class ApplicantsScreen extends StatelessWidget {
  const ApplicantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Applicants ki list properly typed map ke sath
    final List<Map<String, String>> applicants = [
      {
        'name': 'Ali Khan',
        'role': 'Flutter Developer',
        'experience': '2 Years',
      },
      {
        'name': 'Ayesha Ahmed',
        'role': 'Mobile App Specialist',
        'experience': '3 Years',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Applicants'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        itemCount: applicants.length,
        padding: const EdgeInsets.all(16.0),
        itemBuilder: (context, index) {
          final applicant = applicants[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        applicant['name'] ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('${applicant['role'] ?? ''} • ${applicant['experience'] ?? ''}'),
                    ],
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${applicant['name'] ?? 'Applicant'} has been hired!'),
                        ),
                      );
                    },
                    child: const Text('Accept / Hire'),
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