import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../cubit/llm_cubit.dart';
import '../cubit/llm_state.dart';

class ImageAnalysisScreen extends StatefulWidget {
  const ImageAnalysisScreen({super.key});

  @override
  State<ImageAnalysisScreen> createState() => _ImageAnalysisScreenState();
}

class _ImageAnalysisScreenState extends State<ImageAnalysisScreen> {
  final TextEditingController _promptController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  Uint8List? _selectedImageBytes;
  String? _selectedImagePath;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _selectedImagePath = image.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image first')),
      );
      return;
    }

    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a prompt')),
      );
      return;
    }

    context.read<LlmCubit>().generateResponseWithImage(
          prompt: prompt,
          imageBytes: _selectedImageBytes!,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Analysis'),
      ),
      body: BlocBuilder<LlmCubit, LlmState>(
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_selectedImageBytes != null) ...[
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          _selectedImageBytes!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image),
                  label: Text(_selectedImagePath != null
                      ? 'Change Image'
                      : 'Select Image'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _promptController,
                  decoration: const InputDecoration(
                    labelText: 'Enter your prompt',
                    hintText: 'What would you like to know about this image?',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: state.maybeWhen(
                    loading: () => null,
                    orElse: () => _analyzeImage,
                  ),
                  child: state.maybeWhen(
                    loading: () => const CircularProgressIndicator(),
                    orElse: () => const Text('Analyze Image'),
                  ),
                ),
                const SizedBox(height: 16),
                state.maybeWhen(
                  success: (response) => SelectableText.rich(
                    TextSpan(
                      text: 'Analysis Result:\n',
                      style: Theme.of(context).textTheme.titleMedium,
                      children: [
                        TextSpan(
                          text: response.text,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                  error: (message) => SelectableText.rich(
                    TextSpan(
                      text: 'Error:\n',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.red,
                          ),
                      children: [
                        TextSpan(
                          text: message,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.red,
                              ),
                        ),
                      ],
                    ),
                  ),
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
} 