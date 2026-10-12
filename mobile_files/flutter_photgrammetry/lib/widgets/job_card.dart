// A reusable widget that displays a single job as a card in the home screen list.
// Receives a Job object and an onTap callback — it doesn't manage any state itself.
 
import 'package:flutter/material.dart';
import '../models/job.dart';
 
class JobCard extends StatelessWidget {
  // The job data to display
  final Job job;
 
  // Called when the user taps the card — the home screen handles navigation
  final VoidCallback onTap;
 
  const JobCard({
    super.key,
    required this.job,
    required this.onTap,
  });
 
  // Returns the badge colour and label text based on the job's current status
  _BadgeStyle _getBadgeStyle(String status) {
    switch (status) {
      case 'completed':
        return _BadgeStyle(
          background: const Color(0xFF1a2e1a),
          textColor: const Color(0xFF5a9e5a),
          label: 'Completed',
        );
      case 'processing':
        return _BadgeStyle(
          background: const Color(0xFF1e2535),
          textColor: const Color(0xFF5a8fd4),
          label: 'Processing',
        );
      case 'failed':
        return _BadgeStyle(
          background: const Color(0xFF2e1a1a),
          textColor: const Color(0xFFc45a5a),
          label: 'Failed',
        );
      case 'queued':
      default:
        return _BadgeStyle(
          background: const Color(0xFF252520),
          textColor: const Color(0xFF8a8a70),
          label: 'Queued',
        );
    }
  }
 
  @override
  Widget build(BuildContext context) {
    // Resolve the badge colours and label for this job's status
    final badge = _getBadgeStyle(job.status);
 
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        // No border or radius here — the parent container in home_screen.dart
        // handles the outer shape and groups all cards together
        decoration: const BoxDecoration(
          color: Color(0xFF1c1c1a),
        ),
        child: Row(
          children: [
 
            // Left icon representing the job type
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFF2a2a28),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.view_in_ar_rounded,
                color: Color(0xFF5a8fd4),
                size: 22,
              ),
            ),
 
            const SizedBox(width: 12),
 
            // Middle section: job name, format, density, and photo count
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Project name — truncated with ellipsis if too long
                  Text(
                    job.projectName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFf0f0ee),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // Subtitle: output format, mesh density, and number of photos
                  Text(
                    '${job.outputFormat.toUpperCase()} · '
                    '${_capitalize(job.meshDensity)} density · '
                    '${job.fileCount} photos',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            ),
 
            const SizedBox(width: 10),
 
            // Right section: status badge and optional progress bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Coloured status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: badge.background,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: badge.textColor,
                    ),
                  ),
                ),
 
                // Only show the progress bar when the job is actively processing
                if (job.status == 'processing') ...[
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 72,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Thin progress bar filled to the current percentage
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: job.progress / 100,
                            minHeight: 3,
                            backgroundColor: const Color(0xFF2a2a28),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF5a8fd4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        // Stage name and percentage below the bar
                        Text(
                          '${job.stage} · ${job.progress}%',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF555555),
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
 
            const SizedBox(width: 8),
 
            // Chevron arrow indicating the card is tappable
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF444444),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
 
  // Helper to capitalise the first letter of a string (e.g. "high" → "High")
  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
 
// Private helper class to bundle badge colour and label together
class _BadgeStyle {
  final Color background;
  final Color textColor;
  final String label;
 
  _BadgeStyle({
    required this.background,
    required this.textColor,
    required this.label,
  });
}