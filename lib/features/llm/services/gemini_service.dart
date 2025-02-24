import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'dart:async';  // Add this import for TimeoutException
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
  static const _maxRetries = 3;
  
  // List of fallback models in order of preference
  static const List<String> _fallbackModels = [
    'gemini-ultra',      // Try highest capability first
    'gemini-1.5-pro',    // Then latest pro version
    'gemini-pro',        // Then stable pro version
    'gemini-1.0-pro',    // Then older version as last resort
  ];

  static const List<String> _fallbackVisionModels = [
    'gemini-ultra-vision',           // Try highest capability first
    'gemini-1.5-pro-vision-latest',  // Then latest vision version
    'gemini-1.5-pro-vision',         // Then stable latest version
    'gemini-pro-vision',             // Then stable pro version
    'gemini-1.0-pro-vision',         // Then older version as last resort
  ];

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
    List<String> modelsToTry = [modelName];
    
    // Add fallback models if the initial model is a vision model
    if (modelName.contains('vision')) {
      modelsToTry.addAll(_fallbackVisionModels.where((m) => m != modelName));
    } else {
      modelsToTry.addAll(_fallbackModels.where((m) => m != modelName));
    }

    LlmResponse? lastError;
    
    for (final currentModel in modelsToTry) {
      for (int attempt = 0; attempt < _maxRetries; attempt++) {
        try {
          dev.log('Attempting with model $currentModel (attempt ${attempt + 1})');
          final startTime = DateTime.now();

          final response = await _client.post(
            Uri.parse('$_baseUrl/models/$currentModel:generateContent?key=$_apiKey'),
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
              modelName: currentModel,
              totalDuration: totalDuration,
              promptEvalCount: tokenMetrics['promptTokenCount'],
              evalCount: tokenMetrics['candidatesTokenCount'],
              evalRate: tokenMetrics['totalTokenCount'] / totalDuration,
            );
          } else if (response.statusCode == 503) {
            dev.log('Model $currentModel overloaded (attempt ${attempt + 1})');
            lastError = LlmResponse(
              text: '',
              isError: true,
              errorMessage: 'Model overloaded: ${response.body}',
            );
            // Wait before retrying
            await Future.delayed(Duration(seconds: attempt + 1));
            continue;
          } else {
            dev.log('Error from Gemini API: ${response.body}');
            lastError = LlmResponse(
              text: '',
              isError: true,
              errorMessage: 'Failed to generate response: ${response.statusCode} - ${response.body}',
            );
            break; // Don't retry on non-503 errors
          }
        } catch (e) {
          dev.log('Error in Gemini generateResponse: $e');
          lastError = LlmResponse(
            text: '',
            isError: true,
            errorMessage: 'Error connecting to Gemini API: $e',
          );
          if (e is TimeoutException) {
            continue; // Retry on timeout
          }
          break; // Don't retry on other errors
        }
      }
    }

    return lastError ?? LlmResponse(
      text: '',
      isError: true,
      errorMessage: 'All models failed to generate response',
    );
  }

  Future<LlmResponse> generateResponseWithImage({
    required String prompt,
    required Uint8List imageBytes,
    String mimeType = 'image/jpeg',
    String modelName = 'gemini-pro-vision',
    int maxTokens = 1000,
    double temperature = 0.7,
  }) async {
    List<String> modelsToTry = [modelName, ..._fallbackVisionModels.where((m) => m != modelName)];
    LlmResponse? lastError;

    for (final currentModel in modelsToTry) {
      for (int attempt = 0; attempt < _maxRetries; attempt++) {
        try {
          dev.log('Attempting vision model $currentModel (attempt ${attempt + 1})');
          final startTime = DateTime.now();

          final base64Image = base64Encode(imageBytes);
          final response = await _client.post(
            Uri.parse('$_baseUrl/models/$currentModel:generateContent?key=$_apiKey'),
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
              modelName: currentModel,
              totalDuration: totalDuration,
              promptEvalCount: tokenMetrics['promptTokenCount'],
              evalCount: tokenMetrics['candidatesTokenCount'],
              evalRate: tokenMetrics['totalTokenCount'] / totalDuration,
            );
          } else if (response.statusCode == 503) {
            dev.log('Vision model $currentModel overloaded (attempt ${attempt + 1})');
            lastError = LlmResponse(
              text: '',
              isError: true,
              errorMessage: 'Model overloaded: ${response.body}',
            );
            await Future.delayed(Duration(seconds: attempt + 1));
            continue;
          } else {
            dev.log('Error from Gemini Vision API: ${response.body}');
            lastError = LlmResponse(
              text: '',
              isError: true,
              errorMessage: 'Failed to generate response: ${response.statusCode} - ${response.body}',
            );
            break;
          }
        } catch (e) {
          dev.log('Error in Gemini Vision generateResponse: $e');
          lastError = LlmResponse(
            text: '',
            isError: true,
            errorMessage: 'Error connecting to Gemini Vision API: $e',
          );
          if (e is TimeoutException) {
            continue;
          }
          break;
        }
      }
    }

    return lastError ?? LlmResponse(
      text: '',
      isError: true,
      errorMessage: 'All vision models failed to generate response',
    );
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
      // Pro models for text generation
      'gemini-pro',
      'gemini-1.5-pro',
      'gemini-1.0-pro',
      
      // Vision models for image analysis
      'gemini-pro-vision',
      'gemini-1.5-pro-vision',
      'gemini-1.5-pro-vision-latest',
      'gemini-1.0-pro-vision',
      
      // Specialized models
      'gemini-ultra',  // Higher capability model
      'gemini-ultra-vision',  // Higher capability vision model
    ];
  }

  void dispose() {
    _client.close();
  }
} 