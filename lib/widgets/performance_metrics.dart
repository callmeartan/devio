import 'package:flutter/material.dart';
import '../features/llm/models/llm_response.dart';

class PerformanceMetrics extends StatelessWidget {
  final LlmResponse response;
  final bool isExpanded;
  final VoidCallback onToggle;

  const PerformanceMetrics({
    super.key,
    required this.response,
    required this.isExpanded,
    required this.onToggle,
  });

  Widget _buildMetricRow(
      BuildContext context, String label, String value, String? unit,
      {bool isHighlight = false}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          Row(
            children: [
              Text(
                value,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isHighlight
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                  fontWeight: isHighlight ? FontWeight.w600 : FontWeight.normal,
                  fontFamily: 'monospace',
                ),
              ),
              if (unit != null)
                Text(
                  ' $unit',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(double? seconds) {
    if (seconds == null || seconds == 0) return '-';
    if (seconds < 0.001) {
      return '${(seconds * 1000000).toStringAsFixed(1)}μs';
    } else if (seconds < 1) {
      return '${(seconds * 1000).toStringAsFixed(1)}ms';
    } else {
      return '${seconds.toStringAsFixed(1)}s';
    }
  }

  String _formatRate(double? rate) {
    if (rate == null || rate == 0) return '-';
    if (rate >= 1000) {
      return '${(rate / 1000).toStringAsFixed(1)}k';
    }
    return rate.toStringAsFixed(1);
  }

  String _formatTokens(int? tokens) {
    if (tokens == null || tokens == 0) return '-';
    if (tokens >= 1000) {
      return '${(tokens / 1000).toStringAsFixed(1)}k';
    }
    return tokens.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Check if we have any valid metrics
    final hasMetrics =
        response.totalDuration != null && response.totalDuration! > 0;

    if (!hasMetrics) return const SizedBox.shrink();

    return Column(
      children: [
        // Metrics Toggle Button
        Padding(
          padding: const EdgeInsets.only(
            left: 0,
            right: 0,
            top: 4,
          ),
          child: Material(
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.speed_rounded,
                      size: 14,
                      color: theme.colorScheme.primary.withOpacity(0.8),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Performance Metrics',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: theme.colorScheme.primary.withOpacity(0.8),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Metrics Content
        if (isExpanded)
          Container(
            margin: const EdgeInsets.only(
              left: 0,
              right: 0,
              top: 4,
            ),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.05),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main metrics
                _buildMetricRow(
                  context,
                  'Total Time',
                  _formatDuration(response.totalDuration),
                  null,
                  isHighlight: true,
                ),

                // Prompt metrics
                if (response.promptEvalCount != null &&
                    response.promptEvalCount! > 0) ...[
                  const Divider(height: 12),
                  _buildMetricRow(
                    context,
                    'Prompt',
                    _formatTokens(response.promptEvalCount),
                    'tokens',
                  ),
                  _buildMetricRow(
                    context,
                    'Processing',
                    _formatDuration(response.promptEvalDuration),
                    null,
                  ),
                  _buildMetricRow(
                    context,
                    'Speed',
                    _formatRate(response.promptEvalRate),
                    't/s',
                  ),
                ],

                // Generation metrics
                if (response.evalCount != null && response.evalCount! > 0) ...[
                  const Divider(height: 12),
                  _buildMetricRow(
                    context,
                    'Response',
                    _formatTokens(response.evalCount),
                    'tokens',
                  ),
                  _buildMetricRow(
                    context,
                    'Generation',
                    _formatDuration(response.evalDuration),
                    null,
                  ),
                  _buildMetricRow(
                    context,
                    'Speed',
                    _formatRate(response.evalRate),
                    't/s',
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
