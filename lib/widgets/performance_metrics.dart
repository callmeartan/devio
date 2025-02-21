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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(left: 56, top: 4, bottom: 8),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    size: 16,
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
                if (response.metrics.containsKey('total_duration'))
                  _buildMetricRow(
                    context,
                    'Total Duration',
                    '${response.metrics['total_duration']?.toStringAsFixed(2)}s',
                  ),
                if (response.metrics.containsKey('load_duration'))
                  _buildMetricRow(
                    context,
                    'Load Duration',
                    '${response.metrics['load_duration']?.toStringAsFixed(2)}s',
                  ),
                if (response.metrics.containsKey('prompt_eval_count'))
                  _buildMetricRow(
                    context,
                    'Prompt Tokens',
                    '${response.metrics['prompt_eval_count']}',
                  ),
                if (response.metrics.containsKey('eval_count'))
                  _buildMetricRow(
                    context,
                    'Response Tokens',
                    '${response.metrics['eval_count']}',
                  ),
                if (response.metrics.containsKey('prompt_eval_rate'))
                  _buildMetricRow(
                    context,
                    'Prompt Rate',
                    '${response.metrics['prompt_eval_rate']?.toStringAsFixed(1)} t/s',
                  ),
                if (response.metrics.containsKey('eval_rate'))
                  _buildMetricRow(
                    context,
                    'Response Rate',
                    '${response.metrics['eval_rate']?.toStringAsFixed(1)} t/s',
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricRow(BuildContext context, String label, String value) {
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
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
} 