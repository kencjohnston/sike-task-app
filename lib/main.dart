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
import 'utils/app_colors.dart';
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
          colorScheme: AppColors.lightColorScheme(),
          appBarTheme: const AppBarTheme(
            centerTitle: false,
            elevation: 0,
            backgroundColor: AppColors.brandPrimary,
            foregroundColor: Colors.white,
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(AppConstants.borderRadiusMedium),
            ),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            elevation: 4,
            backgroundColor: AppColors.brandSecondary,
            foregroundColor: Colors.white,
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: AppColors.darkColorScheme(),
          appBarTheme: const AppBarTheme(
            centerTitle: false,
            elevation: 0,
            backgroundColor: AppColors.brandPrimaryDark,
            foregroundColor: Colors.white,
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(AppConstants.borderRadiusMedium),
            ),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            elevation: 4,
            backgroundColor: AppColors.brandSecondaryDark,
            foregroundColor: Colors.white,
          ),
        ),
        themeMode: ThemeMode.system,
        home: const TaskListScreen(),
      ),
    );
  }
}
