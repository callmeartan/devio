import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../features/llm/cubit/llm_cubit.dart';
import 'dart:typed_data';

class ModelSelectionUI extends StatefulWidget {
  final List<String> availableModels;
  final String? selectedModel;
  final bool isLoadingModels;
  final VoidCallback onRefresh;
  final VoidCallback onClose;
  final Function(String) onModelSelected;
  final Uint8List? selectedImageBytes;

  const ModelSelectionUI({
    super.key,
    required this.availableModels,
    required this.selectedModel,
    required this.isLoadingModels,
    required this.onRefresh,
    required this.onClose,
    required this.onModelSelected,
    this.selectedImageBytes,
  });

  @override
  State<ModelSelectionUI> createState() => _ModelSelectionUIState();
}

class _ModelSelectionUIState extends State<ModelSelectionUI>
    with SingleTickerProviderStateMixin {
  // Always start expanded
  bool _isExpanded = true;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Start with animation in forward state since we're expanded by default
    _animationController.value = 1.0;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Semi-transparent overlay
          Positioned.fill(
            child: GestureDetector(
              onTap: widget.onClose, // Close on tap outside
              child: Container(
                color: Colors.black.withOpacity(0.3),
              ).animate().fadeIn(duration: const Duration(milliseconds: 200)),
            ),
          ),

          // Floating model selection card
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 600,
                maxHeight: size.height * 0.7, // Reduced max height
              ),
              child: Container(
                width: size.width * 0.95,
                margin: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.shadow.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 5),
                    ),
                  ],
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with title and actions
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.smart_toy_outlined,
                                  size: 20,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Select AI Model',
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Choose the best model for your task',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurface
                                            .withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Refresh button with animation
                              Material(
                                color:
                                    theme.colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                child: IconButton(
                                  icon: Icon(
                                    Icons.refresh,
                                    size: 20,
                                    color: theme.colorScheme.primary,
                                  )
                                      .animate(
                                        onPlay: (controller) =>
                                            widget.isLoadingModels
                                                ? controller.repeat()
                                                : null,
                                      )
                                      .rotate(
                                        duration: const Duration(seconds: 1),
                                      ),
                                  onPressed: widget.onRefresh,
                                  tooltip: 'Refresh models',
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Close button
                              Material(
                                color: theme.colorScheme.surfaceContainerHighest
                                    .withOpacity(0.5),
                                borderRadius: BorderRadius.circular(8),
                                child: IconButton(
                                  icon: Icon(
                                    Icons.close,
                                    size: 20,
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.8),
                                  ),
                                  onPressed: widget.onClose,
                                  tooltip: 'Close model selection',
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Provider selector with enhanced styling
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              _buildProviderSelector(context),
                              const Spacer(),
                              if (widget.isLoadingModels)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  theme.colorScheme.primary),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Loading...',
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Model content area
                        _buildModelContent(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
              .animate()
              .fadeIn(
                duration: const Duration(milliseconds: 300),
              )
              .slideY(
                begin: -0.1,
                end: 0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
              ),
        ],
      ),
    );
  }

  Widget _buildModelContent() {
    if (widget.isLoadingModels) {
      return _buildLoadingState();
    } else if (widget.availableModels.isEmpty) {
      return _buildEmptyState();
    } else {
      return _buildModelSelector(context);
    }
  }

  Widget _buildLoadingState() {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading available models...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 24,
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No models available',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try refreshing or switching to a different provider',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: widget.onRefresh,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderSelector(BuildContext context) {
    final llmCubit = context.read<LlmCubit>();
    final theme = Theme.of(context);

    return PopupMenuButton<LlmProvider>(
      initialValue: llmCubit.currentProvider,
      onSelected: (LlmProvider provider) {
        llmCubit.setProvider(provider);
        widget.onRefresh();
      },
      tooltip: 'Select AI provider',
      color: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 4,
      itemBuilder: (BuildContext context) => <PopupMenuEntry<LlmProvider>>[
        PopupMenuItem<LlmProvider>(
          value: LlmProvider.local,
          child: Row(
            children: [
              Icon(
                Icons.computer,
                color: llmCubit.currentProvider == LlmProvider.local
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withOpacity(0.7),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Local Model',
                style: TextStyle(
                  color: llmCubit.currentProvider == LlmProvider.local
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<LlmProvider>(
          value: LlmProvider.gemini,
          child: Row(
            children: [
              Icon(
                Icons.cloud,
                color: llmCubit.currentProvider == LlmProvider.gemini
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withOpacity(0.7),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Gemini',
                style: TextStyle(
                  color: llmCubit.currentProvider == LlmProvider.gemini
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              llmCubit.currentProvider == LlmProvider.local
                  ? Icons.computer
                  : Icons.cloud,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              llmCubit.currentProvider == LlmProvider.local
                  ? 'Local'
                  : 'Gemini',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: theme.colorScheme.onSurface,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModelSelector(BuildContext context) {
    final filteredModels = _getFilteredModels();
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Group models by type
    final textModels =
        filteredModels.where((m) => !m.contains('vision')).toList();
    final visionModels =
        filteredModels.where((m) => m.contains('vision')).toList();

    // Use a Column with SingleChildScrollView instead of ListView for better sizing
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (textModels.isNotEmpty && widget.selectedImageBytes == null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.text_fields,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Text Models',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ...textModels.map((model) => _buildModelItem(model)),
            if (visionModels.isNotEmpty) const SizedBox(height: 16),
          ],
          if (visionModels.isNotEmpty &&
              (widget.selectedImageBytes != null || textModels.isEmpty)) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.image,
                          size: 14,
                          color: theme.colorScheme.secondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Vision Models',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ...visionModels.map((model) => _buildModelItem(model)),
          ],
          // Note about model availability
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Only showing models that are currently available. Some models may be temporarily unavailable due to high demand.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
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

  Widget _buildModelItem(String model) {
    final theme = Theme.of(context);
    final isRecommended =
        model == 'gemini-1.0-pro' || model == 'gemini-1.0-pro-vision';
    final isSelected = model == widget.selectedModel;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            widget.onModelSelected(model);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary.withOpacity(0.1)
                  : theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary.withOpacity(0.5)
                    : theme.colorScheme.outlineVariant.withOpacity(0.3),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withOpacity(0.5),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : Colors.transparent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _getModelDisplayName(model),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isRecommended)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer
                                    .withOpacity(0.4),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.verified,
                                    size: 12,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Recommended',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getModelDescription(model),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<String> _getFilteredModels() {
    final provider = context.read<LlmCubit>().currentProvider;

    // Filter models based on current context
    return widget.availableModels.where((model) {
      if (provider == LlmProvider.local) {
        return true;
      }
      if (widget.selectedImageBytes != null) {
        return model.contains('vision');
      }
      return !model.contains('vision');
    }).toList();
  }

  String _getModelDisplayName(String model) {
    // Convert model names to more user-friendly display names
    switch (model) {
      case 'gemini-pro':
        return 'Gemini Pro';
      case 'gemini-1.5-pro':
        return 'Gemini 1.5 Pro';
      case 'gemini-1.0-pro':
        return 'Gemini 1.0 Pro';
      case 'gemini-pro-vision':
        return 'Gemini Pro Vision';
      case 'gemini-1.5-pro-vision':
        return 'Gemini 1.5 Pro Vision';
      case 'gemini-1.5-pro-vision-latest':
        return 'Gemini 1.5 Pro Vision (Latest)';
      case 'gemini-1.0-pro-vision':
        return 'Gemini 1.0 Pro Vision';
      case 'gemini-ultra':
        return 'Gemini Ultra';
      case 'gemini-ultra-vision':
        return 'Gemini Ultra Vision';
      default:
        // Handle any other model names by formatting them nicely
        if (model.startsWith('gemini-')) {
          // Remove the 'gemini-' prefix and replace hyphens with spaces
          final formattedName = model.substring(7).replaceAll('-', ' ');
          // Capitalize each word
          final words = formattedName.split(' ');
          final capitalizedWords = words.map((word) => word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1)}'
              : '');
          return 'Gemini ${capitalizedWords.join(' ')}';
        }
        return model;
    }
  }

  String _getModelDescription(String model) {
    // Provide brief descriptions of model capabilities
    if (model.contains('ultra')) {
      return 'Highest capability model with advanced reasoning';
    } else if (model.contains('1.5')) {
      return 'Latest generation with improved capabilities';
    } else if (model.contains('1.0')) {
      return 'Stable version with good performance and reliability';
    } else if (model.contains('vision')) {
      return 'Specialized for image analysis and understanding';
    } else {
      return 'General purpose AI model for text generation';
    }
  }
}
