import 'dart:convert';

import 'package:http/http.dart' as http;

import '../failures.dart';

// Общая часть всех запросов: GET, проверка кода ответа, разбор JSON-объекта.
// Все ошибки превращаются в WeatherFailure, чтобы остальной код не знал про
// SocketException, ClientException и прочую «сантехнику».
Future<Map<String, dynamic>> getJson(
  http.Client client,
  Uri uri, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final http.Response response;
  try {
    response = await client.get(uri).timeout(timeout);
  } on Exception {
    // Сюда попадает всё, что бывает на проводе: нет сети (ClientException,
    // в том числе с SocketException внутри), обрыв, TLS, таймаут (TimeoutException).
    // dart:io здесь не импортируем: на вебе его нет.
    throw const ConnectionFailure();
  }

  if (response.statusCode != 200) {
    throw ServerFailure(statusCode: response.statusCode);
  }

  try {
    // Декодируем БАЙТЫ как UTF-8 сами. response.body угадывает кодировку по
    // заголовку, и без `charset=utf-8` «Île-de-France» превращается в кракозябры.
    final Object? decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
  } on FormatException {
    // не JSON: падаем ниже
  }
  throw const ServerFailure();
}

// Обёртка для разбора ЧУЖИХ данных: любая неожиданность в их форме
// (нет ключа, не тот тип, число вместо строки) означает «сервер ответил не то».
// Мы ловим именно Object: TypeError и RangeError это Error, а не Exception.
T parseResponse<T>(T Function() parse) {
  try {
    return parse();
  } on Object {
    throw const ServerFailure();
  }
}
