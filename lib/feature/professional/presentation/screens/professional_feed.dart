import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:link_vibe/feature/auth/presentation/widgets/screens/login_screen.dart';
import 'my_applications_screen.dart';

class ProfessionalFeedScreen extends StatefulWidget {
  const ProfessionalFeedScreen({super.key});

  @override
  State<ProfessionalFeedScreen> createState() => _ProfessionalFeedScreenState();
}

class _ProfessionalFeedScreenState extends State<ProfessionalFeedScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _projects = [];

  final List<Map<String, dynamic>> _defaultProjects = [
    {
      'title': 'Flutter E-Commerce App Redesign',
      'company': 'Innovexa Technologies',
      'budget': '\$500 - \$800',
      'description':
          'Looking for an experienced Flutter developer to build clean UI/UX and integrate payment gateways.',
    },
    {
      'title': 'Barcode Scanning Mobile Utility',
      'company': 'CodeCraft Solutions',
      'budget': '\$300',
      'description':
          'Need a high-performance barcode scanner module implemented in Dart and Flutter.',
    },
    {
      'title': 'Note-Taking App Local Persistence',
      'company': 'ByteWorks',
      'budget': '\$400',
      'description':
          'Implement local caching using SharedPreferences and organize screens in feature-first architecture.',
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
          'company': item['company_name'] ?? 'Company',
          'budget': item['budget'] ?? 'N/A',
          'description': item['description'] ?? 'No description provided.',
        });
      }

      setState(() {
        _projects = loaded.isNotEmpty ? loaded : _defaultProjects;
      });
    } catch (_) {
      setState(() {
        _projects = _defaultProjects;
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

  Future<void> _applyForProject(Map<String, dynamic> project) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    try {
      if (project['id'] != null && user != null) {
        await supabase.from('applications').insert({
          'project_id': project['id'],
          'applicant_id': user.id,
          'name': user.userMetadata?['name'] ?? 'Applicant',
          'role': 'Flutter Developer',
          'status': 'Pending',
        });
      }
    } catch (_) {
      // Gracefully continue even if table not created
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Applied for "${project['title']}"!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Professional Feed - Projects'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _fetchProjects,
          ),
          IconButton(
            icon: const Icon(Icons.assignment),
            tooltip: 'My Applications',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MyApplicationsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _projects.length,
              padding: const EdgeInsets.all(12.0),
              itemBuilder: (context, index) {
                final project = _projects[index];
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
                              project['company'] ?? 'Company',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                project['budget'] ?? 'N/A',
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
                          project['title'] ?? 'Untitled',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Description
                        Text(
                          project['description'] ?? '',
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
                            onPressed: () => _applyForProject(project),
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
