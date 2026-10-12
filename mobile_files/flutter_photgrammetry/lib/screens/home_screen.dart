// This is the first screen people see. It shows a button to start a scan
// and a list of recent 3D reconstruction jobs.

import 'package:flutter/material.dart';

import 'capture_screen.dart';
import '../models/job.dart';
import '../widgets/job_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // True while the job list is being loaded.
  bool _isLoading = false;

  // The jobs shown on this screen.
  List<Job> _jobs = [];

  // The selected bottom menu item. Home is item 0.
  int _selectedNavIndex = 0;

  @override
  void initState() {
    super.initState();
    // Load the job list when the home screen first opens.
    _loadJobs();
  }

  // Loads jobs and refreshes the screen when they are ready.
  Future<void> _loadJobs() async {
    setState(() => _isLoading = true);

    // Replace the sample jobs below with a request to your server:
    // final response = await dio.get('http://YOUR_SERVER_IP:8000/jobs');
    // final list = (response.data as List).map((j) => Job.fromJson(j)).toList();

    // Sample jobs keep the screen useful while the server is not connected.
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

  // Shows which job was tapped. This can open a job details screen later.
  void _onJobTapped(Job job) {
    // To add a details screen, navigate to it from here:
    // Navigator.push(context, MaterialPageRoute(
    //   builder: (_) => JobDetailScreen(jobId: job.jobId),
    // ));
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Tapped: ${job.projectName}')));
  }

  Future<void> _onNewJobTapped() async {
    // Open the camera screen and wait for it to return the captured photo paths.
    final photoPaths = await Navigator.of(context).push<List<String>>(
      MaterialPageRoute(builder: (_) => const CaptureScreen()),
    );
    // Closing the camera or taking no photos means there is nothing to report.
    if (!mounted || photoPaths == null || photoPaths.isEmpty) return;

    // Photo upload and job creation are not connected yet.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${photoPaths.length} photos captured. Job upload is not set up yet.',
        ),
      ),
    );
  }

  void _onNavigationTapped(int index) {
    if (index == 2) {
      // The Capture menu item opens the camera screen.
      _onNewJobTapped();
    } else {
      // Other menu items just update which item looks selected.
      setState(() => _selectedNavIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),

      // Keep the page safe from the phone's system bars and let it scroll.
      body: SafeArea(
        child: RefreshIndicator(
          // Pull down to load the jobs again.
          onRefresh: _loadJobs,
          color: const Color(0xFF5a8fd4),
          backgroundColor: const Color(0xFF1c1c1a),
          child: CustomScrollView(
            slivers: [
              // App name and short description.
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

              // Tapping this button opens the camera to start a scan.
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: GestureDetector(
                    onTap: _onNewJobTapped,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFf0f0ee),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          // Add icon shown at the left of the button.
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
                          // Button title and short explanation.
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

              // Title above the recent jobs list.
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

              // Show a spinner, an empty message, or the available jobs.
              if (_isLoading)
                // The jobs are still loading.
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
                // There are no jobs to show yet.
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1c1c1a),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF2e2e2b),
                          width: 0.5,
                        ),
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
                // Put the job cards together in one rounded container.
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: ClipRRect(
                      // Round the outside corners of the whole job list.
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1c1c1a),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          children: [
                            for (int i = 0; i < _jobs.length; i++) ...[
                              JobCard(
                                job: _jobs[i],
                                onTap: () => _onJobTapped(_jobs[i]),
                              ),
                              // Separate each job from the next one.
                              if (i < _jobs.length - 1)
                                const Divider(
                                  height: 1,
                                  thickness: 0.5,
                                  color: Color(0xFF2e2e2b),
                                  indent:
                                      74, // Line up the divider with the job text.
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),

      // Menu at the bottom for moving between app sections.
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedNavIndex,
        onTap: _onNavigationTapped,
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
