import 'dart:convert';
import 'package:http/http.dart' as http;

Future<List<dynamic>> fetchSchedule(
    String groupId, String startDate, String endDate) async {
  final String url =
      'https://ruz.fa.ru/api/schedule/group/$groupId?start=$startDate&finish=$endDate&lng=1';

  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Ошибка загрузки расписания');
  }
}
