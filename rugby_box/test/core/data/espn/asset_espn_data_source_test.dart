import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rugby_box/core/data/espn/asset_espn_data_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Vérifie aussi que les assets sont bien déclarés dans pubspec.yaml.
  final source = AssetEspnDataSource(bundle: rootBundle);

  test('lit le scoreboard embarqué', () async {
    final scoreboard = await source.fetchScoreboard('270559', DateTime(2026));

    expect(scoreboard.events, isNotEmpty);
  });

  test('lit le classement embarqué', () async {
    final standings = await source.fetchStandings('270559', 2027);

    expect(standings.children, isNotEmpty);
  });
}
