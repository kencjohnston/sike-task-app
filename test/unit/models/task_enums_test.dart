import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sike/models/task_enums.dart';

void main() {
  group('TaskType Enum', () {
    test('should have correct number of values', () {
      expect(TaskType.values.length, 5);
    });

    test('should have correct enum values', () {
      expect(TaskType.values, [
        TaskType.creative,
        TaskType.administrative,
        TaskType.technical,
        TaskType.communication,
        TaskType.physical,
      ]);
    });

    group('displayLabel extension', () {
      test('should return correct display label for creative', () {
        expect(TaskType.creative.displayLabel, 'Creative');
      });

      test('should return correct display label for administrative', () {
        expect(TaskType.administrative.displayLabel, 'Administrative');
      });

      test('should return correct display label for technical', () {
        expect(TaskType.technical.displayLabel, 'Technical');
      });

      test('should return correct display label for communication', () {
        expect(TaskType.communication.displayLabel, 'Communication');
      });

      test('should return correct display label for physical', () {
        expect(TaskType.physical.displayLabel, 'Physical');
      });
    });

    group('icon extension', () {
      test('should return correct icon for creative', () {
        expect(TaskType.creative.icon, Icons.lightbulb_outline);
      });

      test('should return correct icon for administrative', () {
        expect(TaskType.administrative.icon, Icons.assignment_outlined);
      });

      test('should return correct icon for technical', () {
        expect(TaskType.technical.icon, Icons.code);
      });

      test('should return correct icon for communication', () {
        expect(TaskType.communication.icon, Icons.chat_bubble_outline);
      });

      test('should return correct icon for physical', () {
        expect(TaskType.physical.icon, Icons.fitness_center);
      });
    });
  });

  group('RequiredResource Enum', () {
    test('should have correct number of values', () {
      expect(RequiredResource.values.length, 8);
    });

    test('should have correct enum values', () {
      expect(RequiredResource.values, [
        RequiredResource.computer,
        RequiredResource.phone,
        RequiredResource.internet,
        RequiredResource.materials,
        RequiredResource.tools,
        RequiredResource.transportation,
        RequiredResource.people,
        RequiredResource.documents,
      ]);
    });

    group('displayLabel extension', () {
      test('should return correct display label for computer', () {
        expect(RequiredResource.computer.displayLabel, 'Computer');
      });

      test('should return correct display label for phone', () {
        expect(RequiredResource.phone.displayLabel, 'Phone');
      });

      test('should return correct display label for internet', () {
        expect(RequiredResource.internet.displayLabel, 'Internet');
      });

      test('should return correct display label for materials', () {
        expect(RequiredResource.materials.displayLabel, 'Materials');
      });

      test('should return correct display label for tools', () {
        expect(RequiredResource.tools.displayLabel, 'Tools');
      });

      test('should return correct display label for transportation', () {
        expect(RequiredResource.transportation.displayLabel, 'Transportation');
      });

      test('should return correct display label for people', () {
        expect(RequiredResource.people.displayLabel, 'People');
      });

      test('should return correct display label for documents', () {
        expect(RequiredResource.documents.displayLabel, 'Documents');
      });
    });

    group('icon extension', () {
      test('should return correct icon for computer', () {
        expect(RequiredResource.computer.icon, Icons.computer);
      });

      test('should return correct icon for phone', () {
        expect(RequiredResource.phone.icon, Icons.phone_android);
      });

      test('should return correct icon for internet', () {
        expect(RequiredResource.internet.icon, Icons.wifi);
      });

      test('should return correct icon for materials', () {
        expect(RequiredResource.materials.icon, Icons.inventory_2_outlined);
      });

      test('should return correct icon for tools', () {
        expect(RequiredResource.tools.icon, Icons.build_outlined);
      });

      test('should return correct icon for transportation', () {
        expect(RequiredResource.transportation.icon, Icons.directions_car);
      });

      test('should return correct icon for people', () {
        expect(RequiredResource.people.icon, Icons.people_outline);
      });

      test('should return correct icon for documents', () {
        expect(RequiredResource.documents.icon, Icons.description_outlined);
      });
    });
  });

  group('TaskContext Enum', () {
    test('should have correct number of values', () {
      expect(TaskContext.values.length, 5);
    });

    test('should have correct enum values', () {
      expect(TaskContext.values, [
        TaskContext.home,
        TaskContext.office,
        TaskContext.outdoor,
        TaskContext.anywhere,
        TaskContext.specificRoom,
      ]);
    });

    group('displayLabel extension', () {
      test('should return correct display label for home', () {
        expect(TaskContext.home.displayLabel, 'Home');
      });

      test('should return correct display label for office', () {
        expect(TaskContext.office.displayLabel, 'Office');
      });

      test('should return correct display label for outdoor', () {
        expect(TaskContext.outdoor.displayLabel, 'Outdoor');
      });

      test('should return correct display label for anywhere', () {
        expect(TaskContext.anywhere.displayLabel, 'Anywhere');
      });

      test('should return correct display label for specificRoom', () {
        expect(TaskContext.specificRoom.displayLabel, 'Specific Room');
      });
    });

    group('icon extension', () {
      test('should return correct icon for home', () {
        expect(TaskContext.home.icon, Icons.home_outlined);
      });

      test('should return correct icon for office', () {
        expect(TaskContext.office.icon, Icons.business_outlined);
      });

      test('should return correct icon for outdoor', () {
        expect(TaskContext.outdoor.icon, Icons.park_outlined);
      });

      test('should return correct icon for anywhere', () {
        expect(TaskContext.anywhere.icon, Icons.public);
      });

      test('should return correct icon for specificRoom', () {
        expect(TaskContext.specificRoom.icon, Icons.meeting_room_outlined);
      });
    });
  });

  group('EnergyLevel Enum', () {
    test('should have correct number of values', () {
      expect(EnergyLevel.values.length, 3);
    });

    test('should have correct enum values', () {
      expect(EnergyLevel.values, [
        EnergyLevel.high,
        EnergyLevel.medium,
        EnergyLevel.low,
      ]);
    });

    group('displayLabel extension', () {
      test('should return correct display label for high', () {
        expect(EnergyLevel.high.displayLabel, 'High Energy');
      });

      test('should return correct display label for medium', () {
        expect(EnergyLevel.medium.displayLabel, 'Medium Energy');
      });

      test('should return correct display label for low', () {
        expect(EnergyLevel.low.displayLabel, 'Low Energy');
      });
    });

    group('icon extension', () {
      test('should return correct icon for high', () {
        expect(EnergyLevel.high.icon, Icons.bolt);
      });

      test('should return correct icon for medium', () {
        expect(EnergyLevel.medium.icon, Icons.electric_bolt_outlined);
      });

      test('should return correct icon for low', () {
        expect(EnergyLevel.low.icon, Icons.battery_charging_full);
      });
    });
  });

  group('TimeEstimate Enum', () {
    test('should have correct number of values', () {
      expect(TimeEstimate.values.length, 5);
    });

    test('should have correct enum values', () {
      expect(TimeEstimate.values, [
        TimeEstimate.veryShort,
        TimeEstimate.short,
        TimeEstimate.medium,
        TimeEstimate.long,
        TimeEstimate.veryLong,
      ]);
    });

    group('displayLabel extension', () {
      test('should return correct display label for veryShort', () {
        expect(TimeEstimate.veryShort.displayLabel, 'Very Short (<15 min)');
      });

      test('should return correct display label for short', () {
        expect(TimeEstimate.short.displayLabel, 'Short (15-30 min)');
      });

      test('should return correct display label for medium', () {
        expect(TimeEstimate.medium.displayLabel, 'Medium (30-60 min)');
      });

      test('should return correct display label for long', () {
        expect(TimeEstimate.long.displayLabel, 'Long (1-2 hr)');
      });

      test('should return correct display label for veryLong', () {
        expect(TimeEstimate.veryLong.displayLabel, 'Very Long (2+ hr)');
      });
    });

    group('icon extension', () {
      test('should return correct icon for veryShort', () {
        expect(TimeEstimate.veryShort.icon, Icons.timer_outlined);
      });

      test('should return correct icon for short', () {
        expect(TimeEstimate.short.icon, Icons.timer_3_outlined);
      });

      test('should return correct icon for medium', () {
        expect(TimeEstimate.medium.icon, Icons.schedule);
      });

      test('should return correct icon for long', () {
        expect(TimeEstimate.long.icon, Icons.hourglass_bottom);
      });

      test('should return correct icon for veryLong', () {
        expect(TimeEstimate.veryLong.icon, Icons.hourglass_full);
      });
    });
  });
}
