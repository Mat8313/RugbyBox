import 'dart:convert';

import 'package:http/http.dart' as http;

import 'espn_data_source.dart';
import 'espn_dtos.dart';

/// ESPN a répondu, mais pas « 200 OK » (404, 500, 503…).
///
/// Panne prévue : c'est une [Exception], le repository et `retryMatches`
/// la rattrapent.
class const EspnHttpException(final int statusCode, final Uri uri)
    implements Exception {
  @override
  String toString() => 'ESPN a répondu $statusCode pour $uri';
}

/// Source réelle : interroge l'API (non officielle, gratuite) d'ESPN.
///
/// Toute panne prévue sort en [Exception] : pas de réseau
/// (`http.ClientException`), délai dépassé (`TimeoutException`), statut
/// HTTP inattendu ([EspnHttpException]), JSON illisible (`FormatException`).
class const HttpEspnDataSource({
  /// Le client HTTP : un vrai `http.Client()` dans l'app, un `MockClient`
  /// dans les tests (aucun appel réseau).
  required final http.Client client,

  /// Au-delà, on abandonne l'appel : l'écran ne reste pas bloqué.
  final Duration timeout = const Duration(seconds: 10),
}) implements EspnDataSource {
  @override
  Future<EspnScoreboardDto> fetchScoreboard(
    String leagueId,
    DateTime day,
  ) async => _parse(
    await _getJson(scoreboardUri(leagueId, day)),
    EspnScoreboardDto.fromJson,
  );

  @override
  Future<EspnStandingsDto> fetchStandings(String leagueId, int season) async =>
      _parse(
        await _getJson(standingsUri(leagueId, season)),
        EspnStandingsDto.fromJson,
      );

  /// `https://site.api.espn.com/apis/site/v2/sports/rugby/{leagueId}/scoreboard?dates=AAAAMMJJ`
  ///
  /// Publique (sans `_`) pour pouvoir la tester directement.
  static Uri scoreboardUri(String leagueId, DateTime day) {
    final month = day.month.toString().padLeft(2, '0');
    final dayOfMonth = day.day.toString().padLeft(2, '0');
    return Uri.https(
      'site.api.espn.com',
      '/apis/site/v2/sports/rugby/$leagueId/scoreboard',
      {'dates': '${day.year}$month$dayOfMonth'},
    );
  }

  /// `https://site.web.api.espn.com/apis/v2/sports/rugby/{leagueId}/standings?season=AAAA`
  static Uri standingsUri(String leagueId, int season) => Uri.https(
    'site.web.api.espn.com',
    '/apis/v2/sports/rugby/$leagueId/standings',
    {'season': '$season'},
  );

  /// Traduit [json] en DTO avec [fromJson].
  ///
  /// Un JSON valide mais pas de la forme attendue (un objet manquant, une
  /// liste à la place d'un texte…) fait lever un `TypeError` : une `Error`,
  /// que personne ne rattraperait. On la change en `FormatException`.
  static T _parse<T>(
    Object? json,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    try {
      return fromJson(json as Map<String, dynamic>);
    } on TypeError catch (error) {
      throw FormatException('Réponse ESPN de forme inattendue : $error');
    }
  }

  /// Envoie un GET à [uri] et rend le JSON décodé (pas encore vérifié).
  Future<Object?> _getJson(Uri uri) async {
    final response = await client.get(uri).timeout(timeout);

    // Tout sauf « 200 OK » est une panne : `http` ne lève rien tout seul.
    if (response.statusCode != 200) {
      throw EspnHttpException(response.statusCode, uri);
    }

    final text = utf8.decode(response.bodyBytes);
    return jsonDecode(text);
  }
}
