import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:devio/features/storage/cubit/storage_mode_cubit.dart';
import 'package:devio/features/storage/models/storage_mode.dart';
import 'package:devio/blocs/auth/auth_cubit.dart';
import 'package:go_router/go_router.dart';
import 'package:devio/router.dart'; // Import the router file

class StorageModeSelector extends StatelessWidget {
  const StorageModeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StorageModeCubit, StorageModeState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
              child: Text(
                'Storage Mode',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Choose where your data is stored. Local Mode keeps all data on your device only.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildModeCard(
              context,
              mode: StorageMode.cloud,
              isSelected: !state.mode.isLocal,
              icon: Icons.cloud_outlined,
              title: 'Cloud Mode',
              description:
                  'Data is synced with the cloud and available across devices',
            ),
            const SizedBox(height: 8),
            _buildModeCard(
              context,
              mode: StorageMode.local,
              isSelected: state.mode.isLocal,
              icon: Icons.smartphone_outlined,
              title: 'Local Mode',
              description:
                  'Data is stored only on this device and not synced to the cloud',
            ),
            if (state.isChangingMode)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            if (state.errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  state.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Note: Changing storage mode will not migrate your existing data. You will start with a fresh profile in the new mode.',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildModeCard(
    BuildContext context, {
    required StorageMode mode,
    required bool isSelected,
    required IconData icon,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: isSelected ? 2 : 0,
      color: isSelected
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withOpacity(0.3),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _selectMode(context, mode),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                icon,
                size: 28,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: theme.colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectMode(BuildContext context, StorageMode mode) {
    final cubit = context.read<StorageModeCubit>();

    // Show confirmation dialog before changing mode
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Switch to ${mode.displayName}?'),
        content: Text(
          'Changing storage mode will sign you out and you will need to sign in again. '
          'Your existing data will not be migrated to the new mode.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              cubit.changeMode(mode);

              // Use the new method that handles both sign out and navigation
              context.read<AuthCubit>().signOutAndNavigate(
                    (path) => context.go(path),
                  );
            },
            child: const Text('Switch Mode'),
          ),
        ],
      ),
    );
  }
}
