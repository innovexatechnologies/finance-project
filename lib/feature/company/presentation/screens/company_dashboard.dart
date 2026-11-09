import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:link_vibe/core/services/app_data_service.dart';
import 'package:link_vibe/feature/auth/presentation/widgets/screens/login_screen.dart';
import 'applicants_screen.dart';
import 'post_project_screen.dart';

class CompanyDashboardScreen extends StatefulWidget {
  const CompanyDashboardScreen({super.key});

  @override
  State<CompanyDashboardScreen> createState() => _CompanyDashboardScreenState();
}

class _CompanyDashboardScreenState extends State<CompanyDashboardScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _companyProjects = [];

  final List<Map<String, dynamic>> _defaultProjects = [
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

  @override
  void initState() {
    super.initState();
    _fetchProjects();
  }

  Future<void> _fetchProjects() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('projects')
          .select()
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> loaded = [];
      for (var item in response) {
        loaded.add({
          'id': item['id'],
          'title': item['title'] ?? 'Untitled Project',
          'budget': item['budget'] ?? 'N/A',
          'applicantsCount': item['applicants_count'] ?? 0,
          'status': item['status'] ?? 'Open',
        });
      }

      final local = AppDataService.instance.getAllProjects().map((p) => {
        'id': p['id'],
        'title': p['title'] ?? 'Untitled Project',
        'budget': p['stipend'] ?? p['budget'] ?? 'N/A',
        'applicantsCount': 1,
        'status': p['status'] ?? 'Open',
      }).toList();

      setState(() {
        _companyProjects = loaded.isNotEmpty ? loaded : (local.isNotEmpty ? local : _defaultProjects);
      });
    } catch (_) {
      // Fallback agar table create na hui ho
      final local = AppDataService.instance.getAllProjects().map((p) => {
        'id': p['id'],
        'title': p['title'] ?? 'Untitled Project',
        'budget': p['stipend'] ?? p['budget'] ?? 'N/A',
        'applicantsCount': 1,
        'status': p['status'] ?? 'Open',
      }).toList();
      setState(() {
        _companyProjects = local.isNotEmpty ? local : _defaultProjects;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Dashboard'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _fetchProjects,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
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
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PostProjectScreen(),
                      ),
                    );
                    if (result == true) {
                      _fetchProjects();
                    }
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Post New'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Projects List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _companyProjects.length,
                      itemBuilder: (context, index) {
                        final project = _companyProjects[index];
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        project['title'],
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Chip(
                                      label: Text(project['status'] ?? 'Open'),
                                      backgroundColor:
                                          project['status'] == 'Open'
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Applicants: ${project['applicantsCount'] ?? 0}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: Colors.blueGrey,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const ApplicantsScreen(),
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
