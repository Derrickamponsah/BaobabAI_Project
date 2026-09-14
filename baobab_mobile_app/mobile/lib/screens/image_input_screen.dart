import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

/// Upload a baobab photo -> backend estimates morphology -> user confirms
/// the (editable) dimensions, then continues to the manual screen to add
/// the descriptors that cannot be derived from an image.
class ImageInputScreen extends StatefulWidget {
  const ImageInputScreen({super.key});
  @override
  State<ImageInputScreen> createState() => _ImageInputScreenState();
}

class _ImageInputScreenState extends State<ImageInputScreen> {
  final _picker = ImagePicker();
  XFile? _imageFile;
  Uint8List? _imageBytes;
  ImageEstimate? _estimate;
  bool _analysing = false;

  final _height = TextEditingController();
  final _crown = TextEditingController();
  final _trunk = TextEditingController();

  Future<void> _pick(ImageSource source) async {
    final x = await _picker.pickImage(source: source, maxWidth: 1600);
    if (x == null) return;
    final bytes = await x.readAsBytes();
    setState(() {
      _imageFile = x;
      _imageBytes = bytes;
      _estimate = null;
    });
    _analyse();
  }

  Future<void> _analyse() async {
    if (_imageFile == null) return;
    setState(() => _analysing = true);
    try {
      final est = await ApiService.instance.analyzeImage(_imageFile!);
      setState(() {
        _estimate = est;
        _height.text = est.heightM.toString();
        _crown.text = est.crownDiameterM.toString();
        _trunk.text = est.trunkDiameterM.toString();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _analysing = false);
    }
  }

  void _continue() {
    final input = BaobabInput(source: 'image')
      ..heightM = double.tryParse(_height.text)
      ..crownDiameterM = double.tryParse(_crown.text)
      ..trunkDiameterM = double.tryParse(_trunk.text);
    // Continue to manual screen to collect altitude + site descriptors.
    Navigator.pushNamed(context, '/manual', arguments: input);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analyse from photo')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (_imageBytes == null)
                    Container(
                      height: 180,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDF1F3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_outlined,
                              size: 48, color: Colors.black38),
                          SizedBox(height: 8),
                          Text('No image selected',
                              style: TextStyle(color: Colors.black45)),
                        ],
                      ),
                    )
                  else
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(_imageBytes!,
                          height: 220, width: double.infinity, fit: BoxFit.cover),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pick(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: const Text('Camera'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pick(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('Gallery'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_analysing)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Estimating tree dimensions…'),
                  ],
                ),
              ),
            ),
          if (_estimate != null) ...[
            _ConfidenceBanner(estimate: _estimate!),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Estimated dimensions (editable)',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    const Text(
                        'Adjust any value if you know it more precisely.',
                        style: TextStyle(color: Colors.black54, fontSize: 13)),
                    const SizedBox(height: 14),
                    _EditField(label: 'Height (m)', controller: _height),
                    _EditField(
                        label: 'Crown diameter (m)', controller: _crown),
                    _EditField(
                        label: 'Trunk diameter (m)', controller: _trunk),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _continue,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Continue to site details'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ConfidenceBanner extends StatelessWidget {
  final ImageEstimate estimate;
  const _ConfidenceBanner({required this.estimate});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 16, color: Colors.black54),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              estimate.notes.isNotEmpty
                  ? estimate.notes.join(' ')
                  : 'Dimensions estimated with ${estimate.confidence} confidence.',
              style: const TextStyle(fontSize: 12, color: Colors.black54, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  const _EditField({required this.label, required this.controller});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
