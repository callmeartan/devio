import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';
import 'dart:developer' as dev;

class DocumentService {
  /// Extracts text content from a PDF file
  Future<String> extractText(File file) async {
    try {
      final extension = path.extension(file.path).toLowerCase();
      
      if (extension != '.pdf') {
        throw UnsupportedError('Currently only PDF files are supported');
      }

      return await _extractPdfText(file);
    } catch (e) {
      dev.log('Error extracting text from document: $e');
      rethrow;
    }
  }

  /// Extracts text from a PDF file
  Future<String> _extractPdfText(File file) async {
    try {
      // Load the PDF document
      final bytes = await file.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);
      final PdfTextExtractor extractor = PdfTextExtractor(document);
      
      // Extract text from all pages
      final buffer = StringBuffer();
      for (int i = 0; i < document.pages.count; i++) {
        final text = extractor.extractText(startPageIndex: i);
        buffer.writeln(text);
      }

      // Clean up
      document.dispose();
      return buffer.toString();
    } catch (e) {
      dev.log('Error extracting text from PDF: $e');
      rethrow;
    }
  }

  /// Checks if the file is a supported document type
  bool isSupportedDocument(String filePath) {
    final mimeType = lookupMimeType(filePath);
    return mimeType == 'application/pdf';
  }

  /// Splits text into chunks that fit within Gemini's token limit
  List<String> splitIntoChunks(String text, {int maxChunkSize = 30000}) {
    final words = text.split(' ');
    final chunks = <String>[];
    var currentChunk = StringBuffer();
    var currentSize = 0;

    for (final word in words) {
      // Approximate token count (rough estimate)
      final wordSize = word.length ~/ 4;
      
      if (currentSize + wordSize > maxChunkSize) {
        chunks.add(currentChunk.toString());
        currentChunk = StringBuffer();
        currentSize = 0;
      }

      if (currentChunk.isNotEmpty) {
        currentChunk.write(' ');
      }
      currentChunk.write(word);
      currentSize += wordSize;
    }

    if (currentChunk.isNotEmpty) {
      chunks.add(currentChunk.toString());
    }

    return chunks;
  }
} 