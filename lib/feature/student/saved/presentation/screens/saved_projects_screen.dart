import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:link_vibe/core/constants/app_colors.dart';
import 'package:link_vibe/feature/student/project_details/presentation/screens/student_project_details_screen.dart';

class SavedProjectsScreen extends StatefulWidget {
  const SavedProjectsScreen({super.key});

  @override
  State<SavedProjectsScreen> createState() => _SavedProjectsScreenState();
}

class _SavedProjectsScreenState extends State<SavedProjectsScreen> {
  final List<Map<String, dynamic>> _saved = [
    {
      'title': 'Market Research on AI Tools',
      'company': 'Google',
      'duration': '3-5 days',
      'workMode': 'Remote',
      'status': 'Open',
      'description':
          'Conduct comprehensive market research on the latest enterprise AI tools.',
      'skills': ['Research', 'Analysis'],
    },
    {
      'title': 'UI/UX Design for Web App',
      'company': 'Microsoft',
      'duration': '5-7 days',
      'workMode': 'Remote',
      'status': 'Open',
      'description':
          'Create high-fidelity wireframes and prototype components using Figma.',
      'skills': ['Figma', 'UI/UX'],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Saved Projects'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _saved.isEmpty
          ? Center(
              child: Text(
                'No saved projects yet',
                style: GoogleFonts.inter(color: AppColors.grayText),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _saved.length,
              itemBuilder: (context, index) {
                final project = _saved[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.lightGray),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      project['title'],
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.deepNavy,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        '${project['company']} • ${project['duration']}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.grayText,
                        ),
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.bookmark_remove_rounded,
                          color: Colors.redAccent),
                      onPressed: () {
                        setState(() {
                          _saved.removeAt(index);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Removed from saved projects'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              StudentProjectDetailsScreen(project: project),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
