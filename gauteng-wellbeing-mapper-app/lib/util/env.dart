class ENV {
  // Legacy constant – no longer used since direct tracker-host communication
  // was removed in favour of ResearchServerService. Kept temporarily to avoid
  // breaking any indirect references; can be deleted once confirmed unused.
  @Deprecated('Not used – tracker host is managed by ResearchServerService')
  static const TRACKER_HOST = '';

  static const DEFAULT_SAMPLE_ID = 'default_sample';
}