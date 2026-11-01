import 'package:flutter/material.dart' show IconData, Icons;

/// Topic symbols are keyed by the shared content slug, so Home, library and
/// details show the same icon in every learning language.
IconData deckTopicIcon(String slug) => switch (slug) {
  'allgemeine-sprache' => Icons.forum_outlined,
  'alltag-zuhause' => Icons.home_outlined,
  'reisen' => Icons.flight_takeoff_outlined,
  'alltagssprache-redewendungen' => Icons.format_quote_rounded,
  'arbeit-bildung' => Icons.work_outline_rounded,
  'menschen-beziehungen' => Icons.people_outline_rounded,
  'koerper-gesundheit' => Icons.favorite_border_rounded,
  'essen-trinken' => Icons.restaurant_rounded,
  'natur-umwelt' => Icons.eco_outlined,
  'business-email' => Icons.mail_outline_rounded,
  'verbalphrasen' => Icons.account_tree_outlined,
  'irregular_verbs_base' => Icons.text_fields_rounded,
  'irregular_verbs_past' => Icons.history_rounded,
  'irregular_verbs_participle' => Icons.done_all_rounded,
  'generated-vocabulary' => Icons.auto_awesome_outlined,
  _ => Icons.layers_outlined,
};
