/// Research on learning principles, not an effectiveness study of Linglossa.
class LearningEvidence {
  const LearningEvidence(this.title, this.finding, this.url);
  final String title, finding, url;
}

const learningEvidence = [
  LearningEvidence(
    'Wörter beim Lesen verstehen',
    'Worterklärungen beim Lesen können den Wortschatzerwerb unterstützen. '
        'Yanagisawa, Webb & Uchihara (2020).',
    'https://www.cambridge.org/core/journals/studies-in-second-language-acquisition/article/abs/how-do-different-forms-of-glossing-contribute-to-l2-vocabulary-learning-from-reading/38124150D59DF3039EE1FF5AE88FE922',
  ),
  LearningEvidence(
    'Wörter selbst abrufen',
    'Wiederholtes Abrufen unterstützt das spätere Erinnern. '
        'Karpicke & Roediger (2008).',
    'https://doi.org/10.1126/science.1152408',
  ),
  LearningEvidence(
    'Mit Abstand wiederholen',
    'Verteilte Übung unterstützt das Behalten. Der passende Abstand hängt '
        'unter anderem vom Lernziel ab. Cepeda et al. (2006).',
    'https://doi.org/10.1037/0033-2909.132.3.354',
  ),
  LearningEvidence(
    'Verstehen und Produzieren verbinden',
    'Rezeptive und produktive Aufgaben üben unterschiedliche Seiten des '
        'Wortwissens. Linglossa ergänzt Lesen durch Abrufen im Satz. Webb (2005).',
    'https://doi.org/10.1017/S0272263105050023',
  ),
];
