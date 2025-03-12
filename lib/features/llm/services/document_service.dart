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

  /// Splits text into chunks that fit within token limits
  List<String> splitIntoChunks(String text, {int chunkSize = 4000}) {
    final words = text.split(' ');
    final chunks = <String>[];
    String currentChunk = '';

    for (final word in words) {
      if ((currentChunk + ' ' + word).length <= chunkSize) {
        currentChunk += (currentChunk.isEmpty ? '' : ' ') + word;
      } else {
        chunks.add(currentChunk);
        currentChunk = word;
      }
    }

    if (currentChunk.isNotEmpty) {
      chunks.add(currentChunk);
    }

    return chunks;
  }
}
