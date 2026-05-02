// This is a simple script to add the import for state_extension_helpers.dart
// to all files that use maybeWhen or whenOrNull with AuthState or LlmState
//
// To use this script:
// 1. Run it with `dart scripts/add_extension_imports.dart`
// 2. It will modify all the necessary files to add the import

import 'dart:io';

void main() async {
  // List of files to check
  final filesToCheck = [
    'lib/screens/landing_screen.dart',
    'lib/screens/auth_screen.dart',
    'lib/screens/llm_chat_screen.dart',
    'lib/features/profile/presentation/profile_screen.dart',
    'lib/features/profile/presentation/edit_profile_screen.dart',
    'lib/features/settings/presentation/settings_screen.dart',
  ];

  final importLine =
      "import 'package:devio/utils/state_extension_helpers.dart';";

  for (final file in filesToCheck) {
    try {
      final fileObj = File(file);
      if (!await fileObj.exists()) {
        print('File not found: $file');
        continue;
      }

      String content = await fileObj.readAsString();

      // Check if the file already has the import
      if (content.contains(importLine)) {
        print('Import already exists in $file');
        continue;
      }

      // Check if the file uses AuthState or LlmState with maybeWhen or whenOrNull
      if (content.contains('.maybeWhen(') || content.contains('.whenOrNull(')) {
        // Add the import after the last import statement
        final lastImportIndex = content.lastIndexOf('import ');
        if (lastImportIndex == -1) {
          // No imports found, add at the beginning
          content = importLine + '\n\n' + content;
        } else {
          // Find the end of the last import statement
          final endOfImport = content.indexOf(';', lastImportIndex) + 1;
          content = content.substring(0, endOfImport) +
              '\n' +
              importLine +
              content.substring(endOfImport);
        }

        // Write the modified content back to the file
        await fileObj.writeAsString(content);
        print('Added import to $file');
      } else {
        print('No usage of maybeWhen or whenOrNull in $file');
      }
    } catch (e) {
      print('Error processing $file: $e');
    }
  }

  print('Done adding imports');
}
