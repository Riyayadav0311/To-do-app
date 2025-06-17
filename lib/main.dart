import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/task.dart';
import 'todo_home_page.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Catch and log any Flutter errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
  };

  try {
    await Hive.initFlutter();
    Hive.registerAdapter(TaskAdapter());

    // OPTIONAL: uncomment below line ONCE if you're facing white screen due to data corruption
     await Hive.deleteBoxFromDisk('tasks'); 

    await Hive.openBox<Task>('tasks');

    await _setupNotifications();
    await scheduleDailyNotifications();

    runApp(const MyApp());
  } catch (e, stackTrace) {
    debugPrint("Startup error: $e");
    debugPrint("Stack trace: $stackTrace");
    runApp(const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text(
            'Something went wrong while starting the app.',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    ));
  }
}

Future<void> _setupNotifications() async {
  tz.initializeTimeZones();
  const AndroidInitializationSettings androidInit =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings settings =
      InitializationSettings(android: androidInit);
  await flutterLocalNotificationsPlugin.initialize(settings);
}

Future<void> scheduleDailyNotifications() async {
  final List<int> times = [9, 14, 20]; // 9 AM, 2 PM, 8 PM
  for (int i = 0; i < times.length; i++) {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      i,
      'Daily Reminder',
      '📝 Don’t forget to complete your tasks!',
      _nextInstanceOfHour(times[i]),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Daily Reminder',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}

tz.TZDateTime _nextInstanceOfHour(int hour) {
  final now = tz.TZDateTime.now(tz.local);
  var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour);
  if (scheduled.isBefore(now)) {
    scheduled = scheduled.add(const Duration(days: 1));
  }
  return scheduled;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To-Do List',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFE8F5E9),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFE3F2FD),
        ),
      ),
      themeMode: ThemeMode.system,
      home: const TodoHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
