import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:image_blur_detector/di/app_module.dart';
import 'package:image_blur_detector/image_analysis/ui/image_quality.dart';
import 'package:image_picker/image_picker.dart';

import 'image_analysis/models/analysis_result.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blur Detector',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _image;
  AnalysisResult? _mlkitResult;
  bool _isAnalyzing = false;
  final _imagePicker = ImagePicker();

  Future<void> _analyzeImage(File image) async {
    setState(() {
      _isAnalyzing = true;
      _mlkitResult = null;
    });

    try {
      final result = await AppModule.documentAnalyzer().analyze(image);
      print('Analysis result: $result');

      setState(() {
        _mlkitResult = result;
        _isAnalyzing = false;
      });

      final message = QualityIndicator.analyzeQuality(result);
      if (!message.contains('buena')) {
        _showQualityWarningDialog(message);
      }
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _isAnalyzing = true;
    });

    try {
      if (source == ImageSource.camera) {
        // setup scanner options
        final options = DocumentScannerOptions(
          pageLimit: 1,
          documentFormat: DocumentFormat.jpeg,
          mode: ScannerMode.full,
          isGalleryImport: false,
        );

        final scanner = DocumentScanner(options: options);
        final result = await scanner.scanDocument();

        if (result.images.isNotEmpty) {
          final File image = File(result.images.first);
          setState(() => _image = image);
          await _analyzeImage(image);
        }
      } else {
        // keep gallery access
        final pickedFile = await _imagePicker.pickImage(
          source: source,
          imageQuality: 100,
        );

        if (pickedFile != null) {
          final File image = File(pickedFile.path);
          setState(() => _image = image);
          await _analyzeImage(image);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  void _showQualityWarningDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded,
            color: Colors.orange, size: 48),
        title: const Text('Advertencia de Calidad'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Usar de todos modos'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            },
            icon: const Icon(Icons.camera_alt),
            label: const Text('Tomar otra foto'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Quality Analyzer'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                if (_image != null) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 300,
                    child: Image.file(_image!),
                  ),
                  const SizedBox(height: 20),
                  if (_mlkitResult != null) _buildAnalysisResult(_mlkitResult!),
                ] else
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('No hay imagen seleccionada'),
                  ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isAnalyzing
                          ? null
                          : () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Tomar Foto'),
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton.icon(
                      onPressed: _isAnalyzing
                          ? null
                          : () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Galería'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_isAnalyzing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Analizando imagen...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnalysisResult(AnalysisResult result) {
    final message = QualityIndicator.analyzeQuality(result);
    final isGoodQuality = message.contains('buena');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Icon(
              isGoodQuality ? Icons.check_circle : Icons.warning_amber_rounded,
              color: isGoodQuality ? Colors.green : Colors.orange,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: isGoodQuality ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    AppModule.documentAnalyzer().dispose();
    super.dispose();
  }
}
