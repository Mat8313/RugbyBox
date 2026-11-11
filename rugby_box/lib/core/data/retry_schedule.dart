/// Calendrier de réessais à délais croissants, sans minuteur : on lui
/// demande s'il est l'heure, il ne réveille personne.
class RetrySchedule(final List<Duration> delays) {
  int _index = 0;
  DateTime? _nextUtc;

  /// Démarre une série à [nowUtc], ou la recommence si elle était en cours.
  void start(DateTime nowUtc) {
    _index = 0;
    _nextUtc = nowUtc.add(delays.first);
  }

  /// Vrai si un essai est dû à [nowUtc].
  bool isDue(DateTime nowUtc) {
    final next = _nextUtc;
    return next != null && !nowUtc.isBefore(next);
  }

  /// Après un essai fait à [nowUtc] : programme le suivant, ou termine la
  /// série s'il n'y a plus de délai.
  void advance(DateTime nowUtc) {
    _index++;
    _nextUtc = _index < delays.length ? nowUtc.add(delays[_index]) : null;
  }
}
