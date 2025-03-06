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
      return '${(rate / 1000).toStringAsFixed(1)}k t/s';
    }
    return '${rate.toStringAsFixed(1)} t/s';
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
    
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  'Performance Metrics',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (isExpanded) ...[
              const SizedBox(height: 8),
              _buildMetricRow(
                context,
                'Total Duration',
                _formatDuration(response.totalDuration),
                isHighlight: true,
              ),
              if (response.promptEvalCount != null && response.promptEvalCount! > 0) ...[
                const Divider(height: 12),
                _buildMetricRow(
                  context,
                  'Prompt',
                  _formatTokens(response.promptEvalCount),
                  suffix: 'tokens',
                ),
                _buildMetricRow(
                  context,
                  'Processing',
                  _formatDuration(response.promptEvalDuration),
                ),
                _buildMetricRow(
                  context,
                  'Speed',
                  _formatRate(response.promptEvalRate),
                ),
              ],
              if (response.evalCount != null && response.evalCount! > 0) ...[
                const Divider(height: 12),
                _buildMetricRow(
                  context,
                  'Response',
                  _formatTokens(response.evalCount),
                  suffix: 'tokens',
                ),
                _buildMetricRow(
                  context,
                  'Generation',
                  _formatDuration(response.evalDuration),
                ),
                _buildMetricRow(
                  context,
                  'Speed',
                  _formatRate(response.evalRate),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(
    BuildContext context,
    String label,
    String value,
    {
      bool isHighlight = false,
      String? suffix,
    }
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isHighlight 
                  ? theme.colorScheme.primary 
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: isHighlight ? FontWeight.w600 : FontWeight.w500,
              fontFamily: 'monospace',
            ),
          ),
          if (suffix != null) ...[
            const SizedBox(width: 2),
            Text(
              suffix,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }
} 