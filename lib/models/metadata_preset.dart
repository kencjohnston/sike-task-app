import 'package:flutter/material.dart';
import 'task_enums.dart';

/// A preset combination of task metadata for quick selection
class MetadataPreset {
  final String name;
  final IconData icon;
  final TaskType taskType;
  final List<RequiredResource> resources;
  final TaskContext taskContext;
  final EnergyLevel energyLevel;
  final TimeEstimate timeEstimate;

  const MetadataPreset({
    required this.name,
    required this.icon,
    required this.taskType,
    required this.resources,
    required this.taskContext,
    required this.energyLevel,
    required this.timeEstimate,
  });

  /// Predefined presets for common task types
  static const List<MetadataPreset> defaults = [
    MetadataPreset(
      name: 'Deep Work',
      icon: Icons.psychology,
      taskType: TaskType.creative,
      resources: [RequiredResource.computer, RequiredResource.internet],
      taskContext: TaskContext.home,
      energyLevel: EnergyLevel.high,
      timeEstimate: TimeEstimate.long,
    ),
    MetadataPreset(
      name: 'Quick Errand',
      icon: Icons.directions_run,
      taskType: TaskType.physical,
      resources: [RequiredResource.transportation],
      taskContext: TaskContext.outdoor,
      energyLevel: EnergyLevel.low,
      timeEstimate: TimeEstimate.short,
    ),
    MetadataPreset(
      name: 'Admin',
      icon: Icons.assignment,
      taskType: TaskType.administrative,
      resources: [RequiredResource.computer, RequiredResource.documents],
      taskContext: TaskContext.anywhere,
      energyLevel: EnergyLevel.low,
      timeEstimate: TimeEstimate.medium,
    ),
    MetadataPreset(
      name: 'Phone Call',
      icon: Icons.phone,
      taskType: TaskType.communication,
      resources: [RequiredResource.phone],
      taskContext: TaskContext.anywhere,
      energyLevel: EnergyLevel.medium,
      timeEstimate: TimeEstimate.short,
    ),
    MetadataPreset(
      name: 'Hands-On',
      icon: Icons.build,
      taskType: TaskType.technical,
      resources: [RequiredResource.tools, RequiredResource.materials],
      taskContext: TaskContext.home,
      energyLevel: EnergyLevel.high,
      timeEstimate: TimeEstimate.medium,
    ),
    MetadataPreset(
      name: 'Meeting',
      icon: Icons.groups,
      taskType: TaskType.communication,
      resources: [RequiredResource.computer, RequiredResource.people],
      taskContext: TaskContext.office,
      energyLevel: EnergyLevel.medium,
      timeEstimate: TimeEstimate.medium,
    ),
  ];
}
