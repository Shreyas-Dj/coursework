// The main screen the user sees when they open the app.
// Shows a "New job" button at the top and a scrollable list of recent jobs below.
// Uses setState to manage loading state and the jobs list — no external state manager.
 
import 'package:flutter/material.dart';
import '../../models/job.dart';
import '../../widgets/job_card.dart';
 
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
 
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
 
class _HomeScreenState extends State<HomeScreen> {
  // Whether the screen is currently fetching jobs from the server
  bool _isLoading = false;
 
  // The list of jobs displayed on screen — starts empty until fetched
  List<Job> _jobs = [];
 
  // Which bottom nav tab is selected — 0 = Home
  int _selectedNavIndex = 0;
 
  @override
  void initState() {
    super.initState();
    // Fetch jobs as soon as the screen is first shown
    _loadJobs();
  }
 
  // Fetches the job list from the server and updates the UI.
  // Replace the placeholder data here with a real API call once
  // your server is running and accessible from the device.
  Future<void> _loadJobs() async {
    setState(() => _isLoading = true);
 
    // TODO: Replace with real API call e.g.:
    // final response = await dio.get('http://YOUR_SERVER_IP:8000/jobs');
    // final list = (response.data as List).map((j) => Job.fromJson(j)).toList();
 
    // Placeholder jobs so the UI renders correctly while the server isn't connected
    await Future.delayed(const Duration(milliseconds: 600));
    final placeholderJobs = [
      const Job(
        jobId: '1',
        projectName: 'Garden statue',
        outputFormat: 'glb',
        meshDensity: 'high',
        status: 'completed',
        progress: 100,
        stage: 'Completed',
        fileCount: 42,
      ),
      const Job(
        jobId: '2',
        projectName: 'Front door scan',
        outputFormat: 'obj',
        meshDensity: 'medium',
        status: 'processing',
        progress: 66,
        stage: 'Feature Matching',
        fileCount: 28,
      ),
      const Job(
        jobId: '3',
        projectName: 'Car bonnet',
        outputFormat: 'ply',
        meshDensity: 'low',
        status: 'failed',
        progress: 0,
        stage: 'Failed',
        fileCount: 18,
      ),
      const Job(
        jobId: '4',
        projectName: 'Rock formation',
        outputFormat: 'stl',
        meshDensity: 'high',
        status: 'queued',
        progress: 0,
        stage: 'Queued',
        fileCount: 61,
      ),
    ];
 
    setState(() {
      _jobs = placeholderJobs;
      _isLoading = false;
    });
  }
 
  // Called when the user taps a job card — will navigate to a job detail screen later
  void _onJobTapped(Job job) {
    // TODO: Navigate to job detail screen
    // Navigator.push(context, MaterialPageRoute(
    //   builder: (_) => JobDetailScreen(jobId: job.jobId),
    // ));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tapped: ${job.projectName}')),
    );
  }
 
  // Called when the user taps "New job" — will navigate to the job creation screen later
  void _onNewJobTapped() {
    // TODO: Navigate to new job screen
    // Navigator.push(context, MaterialPageRoute(
    //   builder: (_) => const NewJobScreen(),
    // ));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('New job screen coming soon')),
    );
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
 
      // The body scrolls as one unit — header, button, and job list together
      body: SafeArea(
        child: RefreshIndicator(
          // Pull down to refresh the job list
          onRefresh: _loadJobs,
          color: const Color(0xFF5a8fd4),
          backgroundColor: const Color(0xFF1c1c1a),
          child: CustomScrollView(
            slivers: [
 
              // ── Header ──────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Photogrammetry',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFf0f0ee),
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        '3D mesh reconstruction',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF888888),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
 
              // ── New job button ───────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: GestureDetector(
                    onTap: _onNewJobTapped,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFf0f0ee),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          // Dark icon circle on the left
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFF111111),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Color(0xFFf0f0ee),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Button label and subtitle
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'New job',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF111111),
                                  ),
                                ),
                                SizedBox(height: 1),
                                Text(
                                  'Upload photos to start reconstruction',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF555555),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: Color(0xFF555555),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
 
              // ── Section header ───────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'RECENT JOBS',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF888888),
                          letterSpacing: 0.05,
                        ),
                      ),
                      Text(
                        'View all',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF888888),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
 
              // ── Job list ─────────────────────────────────────────────────
              if (_isLoading)
                // Show a spinner while jobs are being fetched
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 48),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF5a8fd4),
                      ),
                    ),
                  ),
                )
              else if (_jobs.isEmpty)
                // Empty state when no jobs exist yet
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1c1c1a),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: const Color(0xFF2e2e2b), width: 0.5),
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.view_in_ar_rounded,
                            color: Color(0xFF333333),
                            size: 32,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'No jobs yet. Tap "New job" to get started.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF555555),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                // Render one JobCard per job, spaced with a gap between each
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        // Add a gap between cards but not after the last one
                        if (index.isOdd) return const SizedBox(height: 10);
                        final job = _jobs[index ~/ 2];
                        return JobCard(
                          job: job,
                          onTap: () => _onJobTapped(job),
                        );
                      },
                      // Double the count to account for the gap spacers
                      childCount: _jobs.length * 2 - 1,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
 
      // ── Bottom navigation bar ────────────────────────────────────────────
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedNavIndex,
        onTap: (index) => setState(() => _selectedNavIndex = index),
        backgroundColor: const Color(0xFF161614),
        selectedItemColor: const Color(0xFFf0f0ee),
        unselectedItemColor: const Color(0xFF555555),
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_outlined),
            activeIcon: Icon(Icons.list_rounded),
            label: 'Jobs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt_outlined),
            activeIcon: Icon(Icons.camera_alt_rounded),
            label: 'Capture',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}