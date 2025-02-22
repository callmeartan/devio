import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/llm_response.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:developer' as dev;
import 'document_service.dart';

class GeminiService {
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  final http.Client _client;
  final DocumentService _documentService;
  static const _timeout = Duration(seconds: 120);

  GeminiService({
    http.Client? client,
    DocumentService? documentService,
  }) : _client = client ?? http.Client(),
       _documentService = documentService ?? DocumentService();

  String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  Future<LlmResponse> generateResponse({
    required String prompt,
    String modelName = 'gemini-pro',
    int maxTokens = 1000,
    double temperature = 0.7,
  }) async {
    try {
      dev.log('Generating Gemini response...');
      final startTime = DateTime.now();

      final response = await _client.post(
        Uri.parse('$_baseUrl/models/$modelName:generateContent?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [{
            'parts': [{
              'text': prompt
            }]
          }],
          'generationConfig': {
            'temperature': temperature,
            'maxOutputTokens': maxTokens,
          },
        }),
      ).timeout(_timeout);

      final endTime = DateTime.now();
      final totalDuration = endTime.difference(startTime).inMicroseconds / 1000000;

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final text = jsonResponse['candidates'][0]['content']['parts'][0]['text'];
        final tokenMetrics = jsonResponse['usageMetadata'];

        return LlmResponse(
          text: text,
          modelName: modelName,
          totalDuration: totalDuration,
          promptEvalCount: tokenMetrics['promptTokenCount'],
          evalCount: tokenMetrics['candidatesTokenCount'],
          evalRate: tokenMetrics['totalTokenCount'] / totalDuration,
        );
      } else {
        dev.log('Error from Gemini API: ${response.body}');
        return LlmResponse(
          text: '',
          isError: true,
          errorMessage: 'Failed to generate response: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      dev.log('Error in Gemini generateResponse: $e');
      return LlmResponse(
        text: '',
        isError: true,
        errorMessage: 'Error connecting to Gemini API: $e',
      );
    }
  }

  Future<LlmResponse> generateResponseWithImage({
    required String prompt,
    required Uint8List imageBytes,
    String mimeType = 'image/jpeg',
    String modelName = 'gemini-pro-vision',
    int maxTokens = 1000,
    double temperature = 0.7,
  }) async {
    try {
      dev.log('Generating Gemini Vision response...');
      final startTime = DateTime.now();

      final base64Image = base64Encode(imageBytes);

      final response = await _client.post(
        Uri.parse('$_baseUrl/models/$modelName:generateContent?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [{
            'parts': [
              {
                'text': prompt,
              },
              {
                'inline_data': {
                  'mime_type': mimeType,
                  'data': base64Image,
                },
              },
            ],
          }],
          'generationConfig': {
            'temperature': temperature,
            'maxOutputTokens': maxTokens,
          },
        }),
      ).timeout(_timeout);

      final endTime = DateTime.now();
      final totalDuration = endTime.difference(startTime).inMicroseconds / 1000000;

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final text = jsonResponse['candidates'][0]['content']['parts'][0]['text'];
        final tokenMetrics = jsonResponse['usageMetadata'];

        return LlmResponse(
          text: text,
          modelName: modelName,
          totalDuration: totalDuration,
          promptEvalCount: tokenMetrics['promptTokenCount'],
          evalCount: tokenMetrics['candidatesTokenCount'],
          evalRate: tokenMetrics['totalTokenCount'] / totalDuration,
        );
      } else {
        dev.log('Error from Gemini Vision API: ${response.body}');
        return LlmResponse(
          text: '',
          isError: true,
          errorMessage: 'Failed to generate response: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      dev.log('Error in Gemini Vision generateResponse: $e');
      return LlmResponse(
        text: '',
        isError: true,
        errorMessage: 'Error connecting to Gemini Vision API: $e',
      );
    }
  }

  Future<LlmResponse> analyzeImage({
    required Uint8List imageBytes,
    String mimeType = 'image/jpeg',
    String prompt = 'Describe this image in detail.',
    String modelName = 'gemini-1.5-pro-vision-latest',
  }) async {
    return generateResponseWithImage(
      prompt: prompt,
      imageBytes: imageBytes,
      mimeType: mimeType,
      modelName: modelName,
    );
  }

  /// Analyzes a document (PDF or DOCX) and returns insights
  Future<LlmResponse> analyzeDocument({
    required File file,
    String customPrompt = '',
    String modelName = 'gemini-1.5-pro',
    int maxTokens = 1000,
    double temperature = 0.7,
  }) async {
    try {
      if (!_documentService.isSupportedDocument(file.path)) {
        return LlmResponse(
          text: '',
          isError: true,
          errorMessage: 'Unsupported document type. Please provide a PDF or DOCX file.',
        );
      }

      // Extract text from document
      final text = await _documentService.extractText(file);
      
      // Split text into manageable chunks
      final chunks = _documentService.splitIntoChunks(text);
      
      // Create analysis prompt
      final prompt = customPrompt.isNotEmpty
          ? customPrompt
          : '''Analyze this document and provide key insights. Include:
             1. Main topics and themes
             2. Key points and findings
             3. Important details and data
             4. Recommendations or conclusions (if any)
             
             Document text:
             ${chunks.first}'''; // Using first chunk for initial analysis

      // Generate response
      return generateResponse(
        prompt: prompt,
        modelName: modelName,
        maxTokens: maxTokens,
        temperature: temperature,
      );
    } catch (e) {
      dev.log('Error analyzing document: $e');
      return LlmResponse(
        text: '',
        isError: true,
        errorMessage: 'Error analyzing document: $e',
      );
    }
  }

  /// Answers questions about a specific document
  Future<LlmResponse> askAboutDocument({
    required File file,
    required String question,
    String modelName = 'gemini-1.5-pro',
    int maxTokens = 1000,
    double temperature = 0.7,
  }) async {
    try {
      if (!_documentService.isSupportedDocument(file.path)) {
        return LlmResponse(
          text: '',
          isError: true,
          errorMessage: 'Unsupported document type. Please provide a PDF or DOCX file.',
        );
      }

      // Extract text from document
      final text = await _documentService.extractText(file);
      
      // Split text into manageable chunks
      final chunks = _documentService.splitIntoChunks(text);
      
      // Create question prompt
      final prompt = '''Answer the following question about this document:
          
          Question: $question
          
          Document text:
          ${chunks.first}'''; // Using first chunk for initial answer

      // Generate response
      return generateResponse(
        prompt: prompt,
        modelName: modelName,
        maxTokens: maxTokens,
        temperature: temperature,
      );
    } catch (e) {
      dev.log('Error answering question about document: $e');
      return LlmResponse(
        text: '',
        isError: true,
        errorMessage: 'Error answering question about document: $e',
      );
    }
  }

  List<String> getAvailableModels() {
    return [
      'gemini-pro',
      'gemini-1.5-pro',
      'gemini-1.5-pro-latest',
      'gemini-1.5-pro-vision',
      'gemini-1.5-pro-vision-latest',
      'gemini-ultra',
      'gemini-ultra-vision',
    ];
  }

  void dispose() {
    _client.close();
  }
} 