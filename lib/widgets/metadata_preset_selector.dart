import 'package:flutter/material.dart';
import '../models/metadata_preset.dart';
import '../utils/constants.dart';

/// A horizontal scrollable row of preset cards for quick metadata selection.
class MetadataPresetSelector extends StatelessWidget {
  /// The name of the currently selected preset, or null if custom/none.
  final String? selectedPresetName;

  /// Called when a preset card is tapped.
  final ValueChanged<MetadataPreset> onPresetSelected;

  /// Called when the "Custom" card is tapped.
  final VoidCallback onCustomTap;

  const MetadataPresetSelector({
    Key? key,
    required this.selectedPresetName,
    required this.onPresetSelected,
    required this.onCustomTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const presets = MetadataPreset.defaults;

    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingSmall,
        ),
        itemCount: presets.length + 1, // +1 for the Custom card
        itemBuilder: (context, index) {
          if (index < presets.length) {
            final preset = presets[index];
            final isSelected = selectedPresetName == preset.name;
            return _PresetCard(
              name: preset.name,
              icon: preset.icon,
              isSelected: isSelected,
              onTap: () => onPresetSelected(preset),
              theme: theme,
            );
          }
          // Custom card at the end
          return _PresetCard(
            name: 'Custom',
            icon: Icons.tune,
            isSelected: false,
            isCustom: true,
            onTap: onCustomTap,
            theme: theme,
          );
        },
      ),
    );
  }
}

class _PresetCard extends StatelessWidget {
  final String name;
  final IconData icon;
  final bool isSelected;
  final bool isCustom;
  final VoidCallback onTap;
  final ThemeData theme;

  const _PresetCard({
    required this.name,
    required this.icon,
    required this.isSelected,
    this.isCustom = false,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;
    final backgroundColor = isSelected
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHighest;
    final foregroundColor = isSelected
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;
    final borderColor = isSelected ? colorScheme.primary : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        child: Container(
          width: 72,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius:
                BorderRadius.circular(AppConstants.borderRadiusMedium),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: AppConstants.iconSizeMedium, color: foregroundColor),
              const SizedBox(height: 4),
              Text(
                name,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: foregroundColor,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
