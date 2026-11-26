/// Heure de Paris et horloge système, sans dépendre du fuseau configuré sur
/// la machine (le Pi pourrait être resté en UTC).
library;

/// L'horloge système n'est pas encore à l'heure (le Pi n'a pas d'horloge
/// matérielle : avant la synchro NTP, il peut se croire dans le passé).
///
/// Panne prévue : `retryMatches` la relance comme les autres.
class const ClockNotSyncedException(final DateTime nowUtc)
    implements Exception {
  @override
  String toString() => 'Horloge pas encore synchronisée ($nowUtc)';
}

/// Avant cette date, l'heure système est forcément fausse : l'app n'existait
/// pas encore.
final minPlausibleUtc = DateTime.utc(2026, 11, 1);

/// Dernier dimanche de [month] en [year], à 1 h UTC : l'heure où la France
/// change d'heure (en mars et en octobre).
DateTime lastSundayAt1hUtc(int year, int month) {
  final lastDay = DateTime.utc(year, month + 1, 0); // jour 0 = veille du 1er
  final back = lastDay.weekday % DateTime.sunday; // dimanche = 7 → 0
  return DateTime.utc(year, month, lastDay.day - back, 1);
}

/// Vrai si [nowUtc] peut être la vraie heure.
bool isClockPlausible(DateTime nowUtc) => nowUtc.isAfter(minPlausibleUtc);

/// La date du jour à Paris, pour [nowUtc] (heures à zéro, en UTC pour éviter
/// tout fuseau caché).
DateTime parisDay(DateTime nowUtc) {
  final paris = parisTime(nowUtc);
  return DateTime.utc(paris.year, paris.month, paris.day);
}

/// L'heure affichée à Paris pour l'instant [utc] : heure d'été (UTC+2) entre
/// le dernier dimanche de mars et le dernier dimanche d'octobre, sinon heure
/// d'hiver (UTC+1). Le résultat reste marqué UTC (aucun fuseau caché) : seuls
/// ses chiffres sont ceux de Paris.
DateTime parisTime(DateTime utc) {
  final summerStart = lastSundayAt1hUtc(utc.year, DateTime.march);
  final summerEnd = lastSundayAt1hUtc(utc.year, DateTime.october);
  final isSummer = utc.isBefore(summerEnd) && utc.isAfter(summerStart);

  return isSummer
      ? utc.add(const Duration(hours: 2))
      : utc.add(const Duration(hours: 1));
}
