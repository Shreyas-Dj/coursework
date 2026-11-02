import 'package:flutter/material.dart';

import 'capture_screen.dart';

class NewProjectScreen extends StatefulWidget {
  const NewProjectScreen({super.key});

  @override
  State<NewProjectScreen> createState() => _NewProjectScreenState();
}

class _NewProjectScreenState extends State<NewProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  static String _draftName = '';
  static String _draftObjectSize = 'Medium';
  static String _draftOutputFormat = 'OBJ';
  static String _draftMeshDensity = 'Medium';

  static const List<String> _existingProjectNames = [
    'Garden statue',
    'Front door scan',
    'Car bonnet',
    'Rock formation',
  ];

  String get _objectSize => _draftObjectSize;
  String get _outputFormat => _draftOutputFormat;
  String get _meshDensity => _draftMeshDensity;

  @override
  void initState() {
    super.initState();
    _nameController.text = _draftName;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    final rawName = _nameController.text.trim();
    if (rawName.isEmpty) return false;
    if (_existingProjectNames.contains(rawName)) return false;
    return true;
  }

  void _startCapture() {
    if (!_formKey.currentState!.validate()) return;
    if (!_isFormValid) return;

    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const CaptureScreen()));
  }

  String? _validateProjectName(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Project name is required';
    }
    if (_existingProjectNames.contains(trimmed)) {
      return 'This project name already exists';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        foregroundColor: const Color(0xFFF0F0EE),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: const Text(
          'New Project',
          style: TextStyle(
            color: Color(0xFFF0F0EE),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  'Configure a new scan',
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF888888),
                    letterSpacing: 0.12,
                  ),
                ),
                const SizedBox(height: 18),
                _fieldLabel('Project name'),
                TextFormField(
                  controller: _nameController,
                  onChanged: (value) {
                    _draftName = value;
                    setState(() {});
                  },
                  validator: _validateProjectName,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  style: const TextStyle(color: Color(0xFFF0F0EE)),
                  decoration: InputDecoration(
                    hintText: 'Red Mug, Trainers, Vase...',
                    hintStyle: const TextStyle(color: Color(0xFF666666)),
                    filled: true,
                    fillColor: const Color(0xFF1C1C1A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFF5A8FD4),
                        width: 1.2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                _fieldLabel('Object size'),
                _segmentedChoiceRow(
                  values: const ['Small', 'Medium', 'Large'],
                  value: _objectSize,
                  selectedColor: const Color(0xFF25B4E8),
                  textColor: const Color(0xFFF0F0EE),
                  selectedTextColor: const Color(0xFF111111),
                  onChanged: (value) =>
                      setState(() => _draftObjectSize = value),
                ),
                const SizedBox(height: 22),
                _fieldLabel('Output format'),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1A),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _outputFormat,
                      dropdownColor: const Color(0xFF1C1C1A),
                      icon: const Icon(Icons.arrow_drop_down_rounded),
                      style: const TextStyle(color: Color(0xFFF0F0EE)),
                      items: const [
                        DropdownMenuItem(value: 'OBJ', child: Text('OBJ')),
                        DropdownMenuItem(value: 'STL', child: Text('STL')),
                        DropdownMenuItem(value: 'PLY', child: Text('PLY')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _draftOutputFormat = value);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                _fieldLabel('Mesh density'),
                _segmentedChoiceRow(
                  values: const ['Low', 'Medium', 'High'],
                  value: _meshDensity,
                  selectedColor: const Color(0xFF3BD5C1),
                  textColor: const Color(0xFFF0F0EE),
                  selectedTextColor: const Color(0xFF111111),
                  onChanged: (value) =>
                      setState(() => _draftMeshDensity = value),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF2E2E2B),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(
                            Icons.lightbulb_outline_rounded,
                            color: Color(0xFF25B4E8),
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Tips',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFF0F0EE),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '• Keep the object evenly lit and avoid glare\n• Use a plain, contrasting background\n• Keep the camera level and rotate around the subject\n• Aim for 20+ overlapping shots before finishing',
                        style: TextStyle(color: Color(0xFFBDBDBD), height: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isFormValid ? _startCapture : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25B4E8),
                      foregroundColor: const Color(0xFF111111),
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Start Capture',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _segmentedChoiceRow({
    required List<String> values,
    required String value,
    required Color selectedColor,
    required Color textColor,
    required Color selectedTextColor,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2E2E2B), width: 1),
      ),
      child: Row(
        children: values.map((option) {
          final isSelected = option == value;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? selectedColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    color: isSelected ? selectedTextColor : textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFFB5B5B5),
        ),
      ),
    );
  }
}
