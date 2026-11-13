import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rugby_box/core/data/espn/http_espn_data_source.dart';

/// Réponse « 200 OK » dont le corps est le fichier [file] des fixtures.
http.Response okFixture(String file) => http.Response.bytes(
  File('test/fixtures/espn/$file').readAsBytesSync(),
  200,
  headers: {'content-type': 'application/json'},
);

void main() {
  group('adresses', () {
    test(
      'scoreboard : date du jour en AAAAMMJJ, mois et jour sur 2 chiffres',
      () {
        final uri = HttpEspnDataSource.scoreboardUri(
          '270559',
          DateTime.utc(2026, 9, 6),
        );

        expect(
          uri.toString(),
          'https://site.api.espn.com/apis/site/v2/sports/rugby/270559/scoreboard?dates=20260906',
        );
      },
    );

    test('classement : saison désignée par son année de fin', () {
      final uri = HttpEspnDataSource.standingsUri('270559', 2027);

      expect(
        uri.toString(),
        'https://site.web.api.espn.com/apis/v2/sports/rugby/270559/standings?season=2027',
      );
    });
  });

  group('réponses', () {
    test('lit le scoreboard et appelle la bonne adresse', () async {
      Uri? called;
      final source = HttpEspnDataSource(
        client: MockClient((request) async {
          called = request.url;
          return okFixture('scoreboard_top14_2026-09-26.json');
        }),
      );

      final scoreboard = await source.fetchScoreboard(
        '270559',
        DateTime.utc(2026, 9, 26),
      );

      expect(scoreboard.events, isNotEmpty);
      expect(called?.queryParameters['dates'], '20260926');
    });

    test('lit le classement', () async {
      final source = HttpEspnDataSource(
        client: MockClient((_) async => okFixture('standings_top14_2027.json')),
      );

      final standings = await source.fetchStandings('270559', 2027);

      expect(standings.children, isNotEmpty);
    });

    test('décode les accents en UTF-8 même sans charset annoncé', () async {
      final source = HttpEspnDataSource(
        client: MockClient(
          (_) async => http.Response.bytes(
            utf8.encode('{"children": [], "note": "Béarn"}'),
            200,
            headers: {'content-type': 'application/json'},
          ),
        ),
      );

      // Le décodage ne doit pas lever : le JSON reste lisible.
      await expectLater(source.fetchStandings('270559', 2027), completes);
    });
  });

  group('pannes prévues : toujours une Exception', () {
    test('statut 503 → EspnHttpException', () async {
      final source = HttpEspnDataSource(
        client: MockClient((_) async => http.Response('fermé', 503)),
      );

      await expectLater(
        source.fetchStandings('270559', 2027),
        throwsA(
          isA<EspnHttpException>().having((e) => e.statusCode, 'statut', 503),
        ),
      );
    });

    test('pas de réseau → ClientException', () async {
      final source = HttpEspnDataSource(
        client: MockClient(
          (_) async => throw http.ClientException('hors ligne'),
        ),
      );

      await expectLater(
        source.fetchStandings('270559', 2027),
        throwsA(isA<http.ClientException>()),
      );
    });

    test('ESPN trop lent → TimeoutException', () async {
      final source = HttpEspnDataSource(
        // Une réponse qui n'arrive jamais.
        client: MockClient((_) => Completer<http.Response>().future),
        timeout: const Duration(milliseconds: 10),
      );

      await expectLater(
        source.fetchStandings('270559', 2027),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('texte qui n\'est pas du JSON → FormatException', () async {
      final source = HttpEspnDataSource(
        client: MockClient((_) async => http.Response('<html>', 200)),
      );

      await expectLater(
        source.fetchStandings('270559', 2027),
        throwsA(isA<FormatException>()),
      );
    });

    test('JSON valide mais pas la forme attendue → FormatException', () async {
      final source = HttpEspnDataSource(
        client: MockClient(
          (_) async => http.Response('{"events": "pas une liste"}', 200),
        ),
      );

      await expectLater(
        source.fetchScoreboard('270559', DateTime.utc(2026, 9, 26)),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
