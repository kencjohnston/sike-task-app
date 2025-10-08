// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TaskAdapter extends TypeAdapter<Task> {
  @override
  final int typeId = 0;

  @override
  Task read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Task(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String?,
      isCompleted: fields[3] as bool,
      createdAt: fields[4] as DateTime,
      updatedAt: fields[5] as DateTime,
      priority: fields[6] as int,
      parentTaskId: fields[7] as String?,
      subtaskIds: (fields[8] as List?)?.cast<String>(),
      nestingLevel: fields[9] as int,
      sortOrder: fields[10] as int,
      taskType: fields[11] as TaskType,
      requiredResources: (fields[12] as List?)?.cast<RequiredResource>(),
      taskContext: fields[13] as TaskContext,
      energyRequired: fields[14] as EnergyLevel,
      timeEstimate: fields[15] as TimeEstimate,
      dueDate: fields[16] as DateTime?,
      recurrenceRule: fields[17] as RecurrenceRule?,
      parentRecurringTaskId: fields[18] as String?,
      originalDueDate: fields[19] as DateTime?,
      isArchived: fields[20] as bool,
      archivedAt: fields[21] as DateTime?,
      completedAt: fields[22] as DateTime?,
      currentStreak: fields[23] as int?,
      longestStreak: fields[24] as int?,
      isSkipped: fields[25] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer
      ..writeByte(26)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.isCompleted)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt)
      ..writeByte(6)
      ..write(obj.priority)
      ..writeByte(7)
      ..write(obj.parentTaskId)
      ..writeByte(8)
      ..write(obj.subtaskIds)
      ..writeByte(9)
      ..write(obj.nestingLevel)
      ..writeByte(10)
      ..write(obj.sortOrder)
      ..writeByte(11)
      ..write(obj.taskType)
      ..writeByte(12)
      ..write(obj.requiredResources)
      ..writeByte(13)
      ..write(obj.taskContext)
      ..writeByte(14)
      ..write(obj.energyRequired)
      ..writeByte(15)
      ..write(obj.timeEstimate)
      ..writeByte(16)
      ..write(obj.dueDate)
      ..writeByte(17)
      ..write(obj.recurrenceRule)
      ..writeByte(18)
      ..write(obj.parentRecurringTaskId)
      ..writeByte(19)
      ..write(obj.originalDueDate)
      ..writeByte(20)
      ..write(obj.isArchived)
      ..writeByte(21)
      ..write(obj.archivedAt)
      ..writeByte(22)
      ..write(obj.completedAt)
      ..writeByte(23)
      ..write(obj.currentStreak)
      ..writeByte(24)
      ..write(obj.longestStreak)
      ..writeByte(25)
      ..write(obj.isSkipped);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
