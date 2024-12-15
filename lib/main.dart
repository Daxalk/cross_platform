import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'api_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runApp(const ScheduleApp());
}

class ScheduleApp extends StatelessWidget {
  const ScheduleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Расписание',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ru', 'RU'),
      ],
      locale: const Locale('ru', 'RU'),
      home: const ScheduleScreen(),
    );
  }
}

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late Future<List<dynamic>> schedule;
  DateTime focusedDate = DateTime.now();
  TextEditingController groupController = TextEditingController();

// Можно добавить другие группы
  final List<Group> groups = [
    Group('ПИ21-1', '137226'),
    Group('ПИ21-2', '137267'),
    Group('ПИ21-3', '137269'),
    Group('ПИ21-4', '137270'),
    Group('ПИ21-5', '137271'),
    Group('ПИ21-6', '137272'),
    Group('ПМ21-1', '137228'),
    Group('ПМ21-2', '137274'),
    Group('ПМ21-3', '137275'),
    Group('ПМ21-4', '137276'),
    Group('ПМ21-5', '137277'),
  ];

  @override
  void initState() {
    super.initState();
    schedule = Future.value([]);
  }

  void _loadScheduleForSelectedWeek() {
    if (groupController.text.isEmpty) return;

    final selectedGroup = groups.firstWhere(
      (group) => group.name == groupController.text,
      orElse: () => Group('', ''),
    );

    if (selectedGroup.name.isEmpty) return;

    final startOfWeek =
        focusedDate.subtract(Duration(days: focusedDate.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    setState(() {
      schedule = fetchSchedule(
        selectedGroup.id,
        _formatDate(startOfWeek),
        _formatDate(endOfWeek),
      );
    });
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  Map<String, List<dynamic>> groupByDay(List<dynamic> data) {
    Map<String, List<dynamic>> groupedData = {};
    for (var item in data) {
      String day = item['dayOfWeekString'] ?? 'Неизвестный день';
      if (!groupedData.containsKey(day)) {
        groupedData[day] = [];
      }
      groupedData[day]!.add(item);
    }
    return groupedData;
  }

  void _onGroupSelected(Group selectedGroup) {
    setState(() {
      groupController.text = selectedGroup.name;
      _loadScheduleForSelectedWeek();
    });
  }

  void _resetToCurrentWeek() {
    setState(() {
      focusedDate = DateTime.now();
      _loadScheduleForSelectedWeek();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Расписание'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _resetToCurrentWeek,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Autocomplete<Group>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                return groups.where((group) => group.name
                    .toLowerCase()
                    .contains(textEditingValue.text.toLowerCase()));
              },
              onSelected: (Group selectedGroup) {
                _onGroupSelected(selectedGroup);
              },
              displayStringForOption: (Group option) => option.name,
              fieldViewBuilder:
                  (context, controller, focusNode, onEditingComplete) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    hintText: 'Введите группу',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onEditingComplete: onEditingComplete,
                );
              },
            ),
          ),
          TableCalendar(
            locale: 'ru_RU',
            focusedDay: focusedDate,
            firstDay: DateTime(2024), // Можно установить диапазон
            lastDay: DateTime(2025),
            calendarFormat: CalendarFormat.week,
            startingDayOfWeek: StartingDayOfWeek.monday,
            headerStyle: const HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
            ),
            onPageChanged: (focusedDay) {
              setState(() {
                focusedDate = focusedDay;
                _loadScheduleForSelectedWeek();
              });
            },
          ),
          const SizedBox(height: 10),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: schedule,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Ошибка: ${snapshot.error}'));
                } else if (snapshot.hasData) {
                  if (snapshot.data!.isEmpty) {
                    return const Center(child: Text('Нет расписания'));
                  }

                  final groupedSchedule = groupByDay(snapshot.data!);

                  return ListView(
                    children: groupedSchedule.entries.map((entry) {
                      final day = entry.key;
                      final lessons = entry.value;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              day,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                              ),
                            ),
                          ),
                          ...lessons.map((lesson) {
                            return Card(
                              elevation: 3,
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              child: ListTile(
                                title: Text(
                                  lesson['discipline'] ??
                                      'Название пары отсутствует',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  '${lesson['beginLesson'] ?? 'Не указано'} - ${lesson['endLesson'] ?? 'Не указано'}\n'
                                  'Адрес: ${lesson['building'] ?? 'Не указан'}, ${lesson['auditorium'] ?? 'Аудитория не указана'}\n'
                                  'Группы: ${lesson['group'] ?? 'Не указаны'}\n'
                                  'Преподаватель: ${lesson['lecturer'] ?? 'Не указан'}',
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      );
                    }).toList(),
                  );
                } else {
                  return const Center(child: Text('Нет данных'));
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class Group {
  final String name;
  final String id;

  Group(this.name, this.id);
}
