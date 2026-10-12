import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

// Colors used throughout the dark camera screen.
const _backgroundColor = Color(0xFF111111);
const _surfaceColor = Color(0xFF1C1C1A);
const _accentColor = Color(0xFF25B4E8);
const _primaryTextColor = Color(0xFFF0F0EE);
const _mutedTextColor = Color(0xFF888888);
const List<Color> _captureAccentStops = [
  Color(0xFF25B4E8),
  Color(0xFF3BD5C1),
  Color(0xFFB38BFF),
  Color(0xFFFFB454),
];

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen>
    with WidgetsBindingObserver {
  // The controller connects the camera to the live preview and shutter.
  CameraController? _cameraController;
  // Photos taken during this scan stay here until the screen closes.
  final List<XFile> _photos = [];
  // A message to show if the camera cannot be started.
  String? _cameraError;
  // These flags keep the controls in sync while the camera is busy.
  bool _isInitializing = false;
  bool _isCapturing = false;
  bool _flashEnabled = false;
  // Start with the rear camera when one is available.
  CameraLensDirection _lensDirection = CameraLensDirection.back;

  @override
  void initState() {
    super.initState();
    // Watch for the app being paused so we can release the camera safely.
    WidgetsBinding.instance.addObserver(this);
    // Turn on the camera as soon as this screen opens.
    _initializeCamera();
  }

  @override
  void dispose() {
    // Stop watching the app and release the camera when leaving this screen.
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    // Close the camera when the app is hidden, then reopen it when the app returns.
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _cameraController = null;
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera({CameraDescription? camera}) async {
    if (_isInitializing) return;
    _isInitializing = true;
    CameraController? pendingController;

    try {
      // Find the available cameras on this phone.
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw CameraException(
          'NoCameraAvailable',
          'No camera was found on this device.',
        );
      }

      // Use the requested camera, or choose the one that matches our current side.
      final selectedCamera =
          camera ??
          cameras.firstWhere(
            (availableCamera) =>
                availableCamera.lensDirection == _lensDirection,
            orElse: () => cameras.first,
          );
      final controller = CameraController(
        selectedCamera,
        ResolutionPreset.high,
        // Taking pictures does not need microphone access.
        enableAudio: false,
      );
      pendingController = controller;
      await controller.initialize();

      if (!mounted) return;
      await controller.setFlashMode(FlashMode.off);
      if (!mounted) return;
      // Save the ready camera so the screen can show its preview.
      setState(() {
        _cameraController = controller;
        _cameraError = null;
        _lensDirection = selectedCamera.lensDirection;
        _flashEnabled = false;
      });
      pendingController = null;
    } on CameraException catch (error) {
      if (!mounted) return;
      // Show a helpful message instead of leaving the preview blank.
      setState(() {
        _cameraError = _cameraErrorMessage(error);
        _cameraController = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _cameraError = 'Unable to start the camera: $error';
        _cameraController = null;
      });
    } finally {
      // If setup stopped early, close the camera controller we just created.
      await pendingController?.dispose();
      _isInitializing = false;
    }
  }

  String _cameraErrorMessage(CameraException error) {
    // Explain common camera problems in words that are useful to the user.
    switch (error.code) {
      case 'CameraAccessDenied':
      case 'CameraAccessDeniedWithoutPrompt':
        return 'Camera access is off. Allow camera access in your device settings.';
      case 'NoCameraAvailable':
        return error.description ?? 'No camera was found on this device.';
      default:
        return error.description ??
            'Unable to start the camera (${error.code}).';
    }
  }

  Future<void> _takePhoto() async {
    final controller = _cameraController;
    // Do nothing until the camera is ready, or while another photo is being taken.
    if (controller == null || !controller.value.isInitialized || _isCapturing) {
      return;
    }

    setState(() => _isCapturing = true);
    try {
      // Take a photo and add it to the strip of captured photos.
      final photo = await controller.takePicture();
      if (!mounted) return;
      setState(() => _photos.add(photo));
    } on CameraException catch (error) {
      if (!mounted) return;
      _showMessage(_cameraErrorMessage(error));
    } catch (error) {
      if (!mounted) return;
      _showMessage('Could not capture the photo: $error');
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _toggleFlash() async {
    final controller = _cameraController;
    if (controller == null) return;

    final enableFlash = !_flashEnabled;
    try {
      // Turn the camera light on or off and update its button.
      await controller.setFlashMode(
        enableFlash ? FlashMode.torch : FlashMode.off,
      );
      if (mounted) setState(() => _flashEnabled = enableFlash);
    } on CameraException catch (error) {
      if (mounted) _showMessage(_cameraErrorMessage(error));
    }
  }

  Future<void> _switchCamera() async {
    late final List<CameraDescription> cameras;
    try {
      cameras = await availableCameras();
    } on CameraException catch (error) {
      if (mounted) _showMessage(_cameraErrorMessage(error));
      return;
    } catch (error) {
      if (mounted) _showMessage('Unable to switch camera: $error');
      return;
    }
    if (!mounted) return;
    if (cameras.length < 2) {
      _showMessage('This device has only one camera.');
      return;
    }

    // Pick the other side of the phone, then start its camera.
    final direction = _lensDirection == CameraLensDirection.back
        ? CameraLensDirection.front
        : CameraLensDirection.back;
    final camera = cameras.firstWhere(
      (availableCamera) => availableCamera.lensDirection == direction,
      orElse: () => cameras.first,
    );
    final oldController = _cameraController;
    setState(() {
      _cameraController = null;
      _cameraError = null;
    });
    await oldController?.dispose();
    await _initializeCamera(camera: camera);
  }

  void _finishCapture() {
    // Send the saved photo file paths back to the screen that opened the camera.
    Navigator.of(context).pop(_photos.map((photo) => photo.path).toList());
  }

  void _showMessage(String message) {
    // Show a short message at the bottom of the screen.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _reviewPhoto(XFile photo) {
    // Open a larger preview so the photo can be checked or removed.
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: _surfaceColor,
        insetPadding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              child: FutureBuilder(
                future: photo.readAsBytes(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox(
                      height: 300,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return Image.memory(
                    snapshot.data!,
                    height: 360,
                    width: double.infinity,
                    fit: BoxFit.contain,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Photo ${_photos.indexOf(photo) + 1}',
                      style: const TextStyle(
                        color: _primaryTextColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() => _photos.remove(photo));
                      Navigator.of(dialogContext).pop();
                    },
                    child: const Text(
                      'Remove',
                      style: TextStyle(color: Color(0xFFFF7770)),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = _cameraController;

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(
            children: [
              // Close and Done buttons.
              _buildTopBar(),
              const SizedBox(height: 18),
              // Instructions and the number of photos still needed.
              _buildCaptureSummary(),
              const SizedBox(height: 16),
              // Show the camera picture, or an explanation if the camera is unavailable.
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (controller != null && controller.value.isInitialized)
                        CameraPreview(controller)
                      else
                        _buildCameraPlaceholder(),
                      if (controller != null && controller.value.isInitialized)
                        const IgnorePointer(child: _ViewfinderOverlay()),
                      Positioned(
                        top: 14,
                        right: 14,
                        child: _IconControl(
                          icon: _flashEnabled
                              ? Icons.flash_on_rounded
                              : Icons.flash_off_rounded,
                          label: _flashEnabled
                              ? 'Turn flash off'
                              : 'Turn flash on',
                          onPressed: _toggleFlash,
                          active: _flashEnabled,
                          accentColor: _activeAccentColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              // A reminder to move around the subject between photos.
              _buildGuidance(),
              const SizedBox(height: 12),
              // Small previews of the latest photos.
              _buildRecentPhotos(),
              const SizedBox(height: 12),
              // Buttons for reviewing, taking, and switching cameras.
              _buildCameraControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    // Keep the close button, screen title, and Done button on one line.
    final accentColor = _activeAccentColor;
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          _IconControl(
            icon: Icons.close_rounded,
            label: 'Close capture',
            onPressed: () => Navigator.of(context).maybePop(),
            accentColor: _activeAccentColor,
          ),
          Expanded(
            child: Text(
              'NEW SCAN',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: accentColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
          ),
          TextButton(
            onPressed: _photos.isEmpty ? null : _finishCapture,
            style: TextButton.styleFrom(
              foregroundColor: accentColor,
              disabledForegroundColor: const Color(0xFF555555),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text(
              'Done',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptureSummary() {
    final count = _photos.length;
    final accentColor = _activeAccentColor;
    // Show a different tip once at least 30 photos have been taken.
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                count < 30
                    ? 'Move around your subject for full coverage'
                    : 'Great coverage. Keep going for extra detail',
                style: const TextStyle(color: _mutedTextColor, fontSize: 12),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2E2E2B)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.photo_camera_back_outlined,
                size: 16,
                color: accentColor,
              ),
              const SizedBox(width: 7),
              Text(
                '$count',
                style: const TextStyle(
                  color: _primaryTextColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Text(
                ' / 30+',
                style: TextStyle(color: _mutedTextColor, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCameraPlaceholder() {
    final error = _cameraError;
    final accentColor = _activeAccentColor;
    // Show camera status and offer another try if camera setup failed.
    return Container(
      color: const Color(0xFF090909),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            error == null ? Icons.camera_alt_outlined : Icons.no_photography,
            color: error == null ? accentColor : const Color(0xFFFF7770),
            size: 38,
          ),
          const SizedBox(height: 14),
          Text(
            error ?? (_isInitializing ? 'Starting camera…' : 'Camera preview'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: _primaryTextColor, fontSize: 14),
          ),
          if (error != null) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _initializeCamera,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try again'),
            ),
          ] else if (_isInitializing) ...[
            const SizedBox(height: 16),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGuidance() {
    // Remind people to overlap photos so the 3D scan has enough detail.
    final accentColor = _activeAccentColor;
    return Row(
      children: [
        Icon(Icons.tips_and_updates_outlined, color: accentColor, size: 17),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _captureGuidanceMessage,
            style: const TextStyle(color: _mutedTextColor, fontSize: 12),
          ),
        ),
        Text(
          '${_photos.length} captured',
          style: const TextStyle(
            color: _primaryTextColor,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentPhotos() {
    if (_photos.isEmpty) {
      // Show an empty strip until the first photo is taken.
      return Container(
        height: 58,
        width: double.infinity,
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: const Color(0xFF2E2E2B)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.collections_outlined, color: _mutedTextColor, size: 17),
            SizedBox(width: 8),
            Text(
              'Your photos will appear here',
              style: TextStyle(color: _mutedTextColor, fontSize: 12),
            ),
          ],
        ),
      );
    }

    // Show the newest photos first and keep the strip compact.
    final recentPhotos = _photos.reversed.take(3).toList();
    return SizedBox(
      height: 58,
      child: Row(
        children: [
          for (final photo in recentPhotos)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => _reviewPhoto(photo),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: FutureBuilder(
                    future: photo.readAsBytes(),
                    builder: (context, snapshot) => Container(
                      width: 58,
                      height: 58,
                      color: _surfaceColor,
                      child: snapshot.hasData
                          ? Image.memory(snapshot.data!, fit: BoxFit.cover)
                          : const Icon(
                              Icons.image_outlined,
                              color: _mutedTextColor,
                            ),
                    ),
                  ),
                ),
              ),
            ),
          if (_photos.length > 3)
            Text(
              '+${_photos.length - 3}',
              style: const TextStyle(color: _mutedTextColor, fontSize: 12),
            ),
          const Spacer(),
          TextButton.icon(
            onPressed: _photos.isEmpty
                ? null
                : () => _reviewPhoto(_photos.last),
            icon: const Icon(Icons.open_in_full_rounded, size: 15),
            label: const Text('Review'),
            style: TextButton.styleFrom(
              foregroundColor: _mutedTextColor,
              disabledForegroundColor: const Color(0xFF555555),
              textStyle: const TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraControls() {
    // Keep the shutter in the middle and the other controls on each side.
    return SizedBox(
      height: 78,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 64,
            child: _photos.isEmpty
                ? const SizedBox(width: 44, height: 44)
                : GestureDetector(
                    onTap: () => _reviewPhoto(_photos.last),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: FutureBuilder(
                        future: _photos.last.readAsBytes(),
                        builder: (context, snapshot) => Container(
                          width: 44,
                          height: 44,
                          color: _surfaceColor,
                          child: snapshot.hasData
                              ? Image.memory(snapshot.data!, fit: BoxFit.cover)
                              : const Icon(
                                  Icons.image_outlined,
                                  color: _mutedTextColor,
                                ),
                        ),
                      ),
                    ),
                  ),
          ),
          Semantics(
            button: true,
            label: 'Take photo',
            child: GestureDetector(
              onTap: _takePhoto,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: controllerReady
                        ? _primaryTextColor
                        : _mutedTextColor,
                    width: 3,
                  ),
                ),
                padding: const EdgeInsets.all(6),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: controllerReady
                        ? _primaryTextColor
                        : const Color(0xFF555555),
                  ),
                  child: _isCapturing
                      ? const Padding(
                          padding: EdgeInsets.all(17),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _backgroundColor,
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 64,
            child: Align(
              alignment: Alignment.centerRight,
              child: _IconControl(
                icon: Icons.flip_camera_android_rounded,
                label: 'Switch camera',
                onPressed: _switchCamera,
                enabled: controllerReady && !_isInitializing,
                accentColor: _activeAccentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color get _activeAccentColor {
    final progress = (_photos.length / 30).clamp(0.0, 1.0).toDouble();
    final position = progress * (_captureAccentStops.length - 1);
    final startIndex = position.floor();
    if (startIndex >= _captureAccentStops.length - 1) {
      return _captureAccentStops.last;
    }
    return Color.lerp(
      _captureAccentStops[startIndex],
      _captureAccentStops[startIndex + 1],
      position - startIndex,
    )!;
  }

  String get _captureGuidanceMessage {
    final count = _photos.length;
    if (count == 0) {
      return 'Keep the subject centered and overlap each shot';
    }
    if (count < 10) {
      return 'Rotate slightly between shots for even coverage';
    }
    if (count < 20) {
      return 'Aim for overlap and keep the subject framed steadily';
    }
    return 'Great coverage. Keep at it bro for extra detail';
  }

  bool get controllerReady =>
      _cameraController != null && _cameraController!.value.isInitialized;
}

// A round button used for camera actions such as flash and camera switching.
class _IconControl extends StatelessWidget {
  const _IconControl({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.active = false,
    this.enabled = true,
    this.accentColor = _accentColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool active;
  final bool enabled;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: active ? accentColor.withValues(alpha: 0.16) : _surfaceColor,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled ? onPressed : null,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(
              icon,
              color: enabled
                  ? (active ? accentColor : _primaryTextColor)
                  : _mutedTextColor,
              size: 19,
            ),
          ),
        ),
      ),
    );
  }
}

class _ViewfinderOverlay extends StatelessWidget {
  const _ViewfinderOverlay();

  @override
  Widget build(BuildContext context) {
    // Draw the photo guide lines over the live camera picture.
    return CustomPaint(painter: _ViewfinderPainter());
  }
}

class _ViewfinderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Divide the picture into thirds to help line up each shot.
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 0.7;
    for (var division = 1; division < 3; division++) {
      final x = size.width * division / 3;
      final y = size.height * division / 3;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw a small box in the center to mark the focus area.
    final focusPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final focusRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: 46,
      height: 46,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(focusRect, const Radius.circular(4)),
      focusPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
