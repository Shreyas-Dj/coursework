class Job {
  // The unique ID returned by POST /jobs — used to poll status and fetch results
  final String jobId;
 
  // The name the user gave the project when submitting
  final String projectName;
 
  // Output format chosen by the user: obj, glb, ply, or stl
  final String outputFormat;
 
  // Mesh density chosen by the user: low, medium, or high
  final String meshDensity;
 
  // Current status of the job: queued, processing, completed, or failed
  final String status;
 
  // How far through processing the job is, from 0 to 100
  final int progress;
 
  // Which COLMAP stage is currently running, e.g. "Feature Extraction"
  final String stage;
 
  // How many photos were uploaded for this job
  final int fileCount;
 
  // Constructor — all fields are required
  const Job({
    required this.jobId,
    required this.projectName,
    required this.outputFormat,
    required this.meshDensity,
    required this.status,
    required this.progress,
    required this.stage,
    required this.fileCount,
  });
 
  // Factory constructor that builds a Job from the JSON map returned by the server.
  // Called like: Job.fromJson(responseData)
  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      jobId: json['job_id'] as String,
      projectName: json['project_name'] as String,
      outputFormat: json['output_format'] as String,
      meshDensity: json['mesh_density'] as String,
      status: json['status'] as String,
      progress: json['progress'] as int,
      stage: json['stage'] as String,
      fileCount: (json['files'] as List).length,
    );
  }
}
 