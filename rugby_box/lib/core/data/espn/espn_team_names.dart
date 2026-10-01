import 'espn_mapper.dart';

/// Noms français des clubs, par id ESPN.
///
/// ESPN ne fournit que des noms anglicisés (« Bordeaux Begles ») et des
/// sigles en doublon (« STA » pour trois clubs). Une équipe absente d'ici
/// n'est pas rejetée : [mapEspnTeam] se replie sur le `displayName`.
///
/// Noms complets : ceux de la LNR. Sigles : celui du club quand il est
/// d'usage courant (RCT, UBB), sinon un code de ville à 3 lettres (TLS).
const Map<String, EspnTeamNames> espnTeamNames = {
  // Top 14, saison 2026-2027.
  '25912': (name: 'Aviron Bayonnais', shortName: 'BAY'),
  '143737': (name: 'Union Bordeaux-Bègles', shortName: 'UBB'),
  '25916': (name: 'Castres Olympique', shortName: 'CAS'),
  '25917': (name: 'ASM Clermont', shortName: 'ASM'),
  '119318': (name: 'Stade Rochelais', shortName: 'LAR'),
  '143736': (name: 'LOU Rugby', shortName: 'LOU'),
  '25918': (name: 'Montpellier Hérault Rugby', shortName: 'MHR'),
  '270567': (name: 'Section Paloise', shortName: 'PAU'),
  '25920': (name: 'USA Perpignan', shortName: 'USAP'),
  '99855': (name: 'Racing 92', shortName: 'RAC'),
  '25921': (name: 'Stade Français Paris', shortName: 'SFP'),
  '25922': (name: 'Stade Toulousain', shortName: 'TLS'),
  '25986': (name: 'RC Toulon', shortName: 'RCT'),
  '289337': (name: 'RC Vannes', shortName: 'VAN'),
};
