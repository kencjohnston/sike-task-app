import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'models/task.dart';
import 'models/task_enums.dart';
import 'models/recurrence_rule.dart';
import 'providers/task_provider.dart';
import 'screens/task_list_screen.dart';
import 'services/migration_service.dart';
import 'services/task_service.dart';
import 'utils/app_logger.dart';
import 'utils/constants.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(TaskAdapter());

  // Register enum adapters
  Hive.registerAdapter(TaskTypeAdapter());
  Hive.registerAdapter(RequiredResourceAdapter());
  Hive.registerAdapter(TaskContextAdapter());
  Hive.registerAdapter(EnergyLevelAdapter());
  Hive.registerAdapter(TimeEstimateAdapter());
  Hive.registerAdapter(DueDateStatusAdapter());
  Hive.registerAdapter(RecurrencePatternAdapter());
  Hive.registerAdapter(MonthlyRecurrenceTypeAdapter());

  // Register recurrence rule adapter
  Hive.registerAdapter(RecurrenceRuleAdapter());

  // Open the tasks box
  await Hive.openBox<Task>('tasks');

  // Run migrations
  try {
    AppLogger.info('Checking if migration to v2 is needed...');
    final needsMigration = await MigrationService.needsMigration();
    if (needsMigration) {
      AppLogger.info('Running migration to version 2...');
      await MigrationService.migrateToVersion2();
      AppLogger.info('Migration to v2 completed successfully');
    } else {
      AppLogger.info('Migration to v2 not needed, database is up to date');
    }

    // Check and run v3 migration
    AppLogger.info('Checking if migration to v3 is needed...');
    final needsV3Migration = await MigrationService.needsMigrationToV3();
    if (needsV3Migration) {
      AppLogger.info('Running migration to version 3...');
      await MigrationService.migrateToVersion3();
      AppLogger.info('Migration to v3 completed successfully');
    } else {
      AppLogger.info('Migration to v3 not needed, schema is up to date');
    }

    final currentSchema = await MigrationService.getSchemaVersion();
    AppLogger.info('Current schema version: $currentSchema');
  } catch (e, stackTrace) {
    AppLogger.error('Error during migration', e, stackTrace);
    // Continue with app launch even if migration fails
    // User can manually trigger migration or app can handle gracefully
  }

  // Initialize TaskService
  final taskService = TaskService();
  await taskService.init();

  runApp(MyApp(taskService: taskService));
}

class MyApp extends StatelessWidget {
  final TaskService taskService;

  const MyApp({Key? key, required this.taskService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => TaskProvider(taskService)..loadTasks(),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF87CEEB), // Light blue
            primary: const Color(0xFF87CEEB), // Light blue
            secondary: const Color(0xFFE91E63), // Pink
            tertiary: const Color(0xFF9C27B0), // Purple
            brightness: Brightness.light,
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: false,
            elevation: 0,
            backgroundColor: Color(0xFF87CEEB), // Light blue
            foregroundColor: Colors.white,
          ),
          cardTheme: CardTheme(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(AppConstants.borderRadiusMedium),
            ),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            elevation: 4,
            backgroundColor: Color(0xFFE91E63), // Pink
            foregroundColor: Colors.white,
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF5FA8D3), // Darker light blue
            primary: const Color(0xFF5FA8D3), // Darker light blue
            secondary: const Color(0xFFC2185B), // Darker pink
            tertiary: const Color(0xFF7B1FA2), // Darker purple
            brightness: Brightness.dark,
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: false,
            elevation: 0,
            backgroundColor: Color(0xFF5FA8D3), // Darker light blue
            foregroundColor: Colors.white,
          ),
          cardTheme: CardTheme(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(AppConstants.borderRadiusMedium),
            ),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            elevation: 4,
            backgroundColor: Color(0xFFC2185B), // Darker pink
            foregroundColor: Colors.white,
          ),
        ),
        themeMode: ThemeMode.system,
        home: const TaskListScreen(),
      ),
    );
  }
}
