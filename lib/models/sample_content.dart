import 'package:flutter/cupertino.dart';

import 'exercise_models.dart';
import 'grammar_models.dart';
import 'home_models.dart';
import 'story_models.dart';
import 'word_list_models.dart';

// Synthetic placeholder content until the offline pipeline generates the v1
// content pack and the Drift layer derives real numbers.

const sampleBreakdown = VocabBreakdown(
  due: 12,
  building: 208,
  mastered: 180,
  unseen: 600,
);

const sampleGoal = DailyGoal(done: 4, target: 10);

const sampleWeek = WeekProgress([
  DayMark.met,
  DayMark.met,
  DayMark.missed,
  DayMark.met,
  DayMark.today,
  DayMark.upcoming,
  DayMark.upcoming,
]);

const sampleDecks = [
  Deck(
    id: 'reisen-unterwegs',
    name: 'Reisen & Unterwegs',
    description:
        'Lerne Englisch für Bahnhof, Flughafen, Hotel und alles, was '
        'dazwischen passiert.',
    icon: CupertinoIcons.airplane,
    difficulty: DeckDifficulty.beginner,
    totalWords: 420,
    seenWords: 210,
    masteredWords: 176,
    isActive: true,
    recentWords: [
      SeenWord(word: 'platform', translation: 'der Bahnsteig'),
      SeenWord(word: 'delay', translation: 'die Verspätung'),
      SeenWord(word: 'luggage', translation: 'das Gepäck'),
      SeenWord(word: 'departure', translation: 'die Abfahrt'),
      SeenWord(word: 'receipt', translation: 'die Quittung'),
    ],
  ),
  Deck(
    id: 'alltag-konversation',
    name: 'Alltägliche Konversation',
    description:
        'Smalltalk, Verabredungen und die kleinen Sätze, die jeden Tag '
        'vorkommen.',
    icon: CupertinoIcons.chat_bubble_2,
    difficulty: DeckDifficulty.beginner,
    totalWords: 380,
    seenWords: 120,
    masteredWords: 65,
    isActive: true,
    recentWords: [
      SeenWord(word: 'appointment', translation: 'der Termin'),
      SeenWord(word: 'neighbour', translation: 'der Nachbar'),
      SeenWord(word: 'borrow', translation: 'ausleihen'),
    ],
  ),
  Deck(
    id: 'medizin',
    name: 'Medizin',
    description:
        'Lerne Englisch rund um das Thema Medizin, Anatomie und Gesundheit.',
    icon: CupertinoIcons.heart,
    difficulty: DeckDifficulty.advanced,
    totalWords: 532,
    seenWords: 53,
    masteredWords: 30,
    isActive: false,
    recentWords: [
      SeenWord(word: 'prescription', translation: 'das Rezept'),
      SeenWord(word: 'fever', translation: 'das Fieber'),
      SeenWord(word: 'injury', translation: 'die Verletzung'),
      SeenWord(word: 'swollen', translation: 'geschwollen'),
      SeenWord(word: 'ward', translation: 'die Station'),
    ],
  ),
  Deck(
    id: 'essen-einkaufen',
    name: 'Essen & Einkaufen',
    description:
        'Vom Wochenmarkt bis zum Restaurant: bestellen, fragen, zahlen.',
    icon: CupertinoIcons.cart,
    difficulty: DeckDifficulty.beginner,
    totalWords: 350,
    seenWords: 40,
    masteredWords: 12,
    isActive: false,
  ),
  Deck(
    id: 'business',
    name: 'Business',
    description: 'Meetings, Verhandlungen und Präsentationen auf Englisch.',
    icon: CupertinoIcons.briefcase,
    difficulty: DeckDifficulty.intermediate,
    totalWords: 450,
    seenWords: 0,
    masteredWords: 0,
    isActive: false,
  ),
  Deck(
    id: 'e-mail',
    name: 'E-Mail & Korrespondenz',
    description: 'Anfragen, Absagen und Nachfassen – schriftlich und höflich.',
    icon: CupertinoIcons.envelope,
    difficulty: DeckDifficulty.intermediate,
    totalWords: 300,
    seenWords: 0,
    masteredWords: 0,
    isActive: false,
  ),
];

const sampleStories = [
  Story(
    id: 'last-train-to-seville',
    title: 'The Last Train to Seville',
    topic: 'Reisen',
    level: 'A2',
    readingMinutes: 4,
  ),
  Story(
    id: 'grandmothers-recipe',
    title: "My Grandmother's Recipe",
    topic: 'Küche',
    level: 'A2',
    readingMinutes: 5,
  ),
  Story(
    id: 'night-in-the-emergency-room',
    title: 'A Night in the Emergency Room',
    topic: 'Medizin',
    level: 'B1',
    readingMinutes: 7,
  ),
  Story(
    id: 'saturday-market',
    title: 'The Saturday Market',
    topic: 'Alltag',
    level: 'A1',
    readingMinutes: 3,
  ),
  Story(
    id: 'letters-from-buenos-aires',
    title: 'Letters from Buenos Aires',
    topic: 'Kultur',
    level: 'B1',
    readingMinutes: 6,
  ),
  Story(
    id: 'lost-luggage',
    title: 'Lost Luggage',
    topic: 'Reisen',
    level: 'A2',
    readingMinutes: 4,
  ),
  Story(
    id: 'the-night-bus',
    title: 'The Night Bus',
    topic: 'Reisen',
    level: 'B1',
    readingMinutes: 6,
  ),
  Story(
    id: 'the-new-neighbour',
    title: 'The New Neighbour',
    topic: 'Alltag',
    level: 'A2',
    readingMinutes: 4,
  ),
  Story(
    id: 'a-quiet-sunday',
    title: 'A Quiet Sunday',
    topic: 'Alltag',
    level: 'A1',
    readingMinutes: 3,
  ),
];

const sampleContinueReading = ReadingProgress(
  storyId: 'last-train-to-seville',
  fraction: 0.4,
);

const _storyTexts = {
  'last-train-to-seville': StoryText(
    storyId: 'last-train-to-seville',
    paragraphs: [
      'The station was almost empty when Clara arrived. A cold wind moved '
          'through the hall, and the old clock above the gate said ten '
          'minutes to midnight.',
      'She looked at her ticket again. The last train to Seville was late, '
          'but nobody seemed to know why. A man behind the counter shrugged '
          'and went back to his newspaper.',
      'Clara sat down on a bench and opened her book. She had waited three '
          'years for this journey. Ten more minutes would not change '
          'anything.',
    ],
  ),
};

StoryText sampleStoryText(String storyId) =>
    _storyTexts[storyId] ??
    StoryText(
      storyId: storyId,
      paragraphs: const [
        'This story is a placeholder. The final text will come from the '
            'offline content pipeline.',
        'Tap any word to look it up and add it to your practice.',
      ],
    );

const _dictionary = {
  'station': WordEntry(
    headword: 'station',
    partOfSpeech: 'Substantiv',
    translation: 'der Bahnhof',
  ),
  'empty': WordEntry(
    headword: 'empty',
    partOfSpeech: 'Adjektiv',
    translation: 'leer',
  ),
  'arrived': WordEntry(
    headword: 'arrive',
    partOfSpeech: 'Verb',
    translation: 'ankommen',
  ),
  'wind': WordEntry(
    headword: 'wind',
    partOfSpeech: 'Substantiv',
    translation: 'der Wind',
  ),
  'clock': WordEntry(
    headword: 'clock',
    partOfSpeech: 'Substantiv',
    translation: 'die Uhr',
  ),
  'midnight': WordEntry(
    headword: 'midnight',
    partOfSpeech: 'Substantiv',
    translation: 'die Mitternacht',
  ),
  'ticket': WordEntry(
    headword: 'ticket',
    partOfSpeech: 'Substantiv',
    translation: 'die Fahrkarte',
  ),
  'late': WordEntry(
    headword: 'late',
    partOfSpeech: 'Adjektiv',
    translation: 'verspätet',
  ),
  'counter': WordEntry(
    headword: 'counter',
    partOfSpeech: 'Substantiv',
    translation: 'der Schalter',
  ),
  'shrugged': WordEntry(
    headword: 'shrug',
    partOfSpeech: 'Verb',
    translation: 'mit den Schultern zucken',
  ),
  'newspaper': WordEntry(
    headword: 'newspaper',
    partOfSpeech: 'Substantiv',
    translation: 'die Zeitung',
  ),
  'bench': WordEntry(
    headword: 'bench',
    partOfSpeech: 'Substantiv',
    translation: 'die Bank',
  ),
  'waited': WordEntry(
    headword: 'wait',
    partOfSpeech: 'Verb',
    translation: 'warten',
  ),
  'journey': WordEntry(
    headword: 'journey',
    partOfSpeech: 'Substantiv',
    translation: 'die Reise',
  ),
};

WordEntry sampleLookup(String surface) =>
    _dictionary[surface.toLowerCase()] ?? WordEntry.unknown(surface);

/// Headword → mark for words already in the learner's vocabulary.
const sampleWordMarks = {
  'station': WordMark.mastered,
  'ticket': WordMark.active,
  'late': WordMark.active,
};

/// Stories opened before this session, so "Aus deinen Stories" isn't empty.
const sampleReadStoryIds = {'last-train-to-seville'};

const sampleExerciseTexts = [
  ExerciseText(
    info: Story(
      id: 'text-last-train-to-seville',
      title: 'The Last Train to Seville',
      topic: 'Reisen',
      level: 'A2',
      readingMinutes: 4,
    ),
    sourceStoryId: 'last-train-to-seville',
    paragraphs: [
      'The station was almost {empty|empty|adjective} when Clara '
          '{arrived|arrive|verb}. A cold wind {moved|move|verb} through the '
          'hall, and the old {clock|clock|noun} above the gate said ten '
          'minutes to midnight.',
      'She {looked|look|verb} at her ticket again. The last train to '
          'Seville was {late|late|adjective}, but nobody seemed to know why.',
    ],
  ),
  ExerciseText(
    info: Story(
      id: 'text-saturday-market',
      title: 'The Saturday Market',
      topic: 'Alltag',
      level: 'A1',
      readingMinutes: 2,
    ),
    sourceStoryId: 'saturday-market',
    paragraphs: [
      'On Saturdays, the {market|market|noun} {opens|open|verb} early. '
          'People {buy|buy|verb} fresh {bread|bread|noun} and '
          '{talk|talk|verb} with their neighbours.',
    ],
  ),
  ExerciseText(
    info: Story(
      id: 'text-slow-morning',
      title: 'A Slow Morning',
      topic: 'Alltag',
      level: 'A2',
      readingMinutes: 3,
    ),
    paragraphs: [
      'Tom {woke|wake|verb} up late on Sunday. He {dressed|dress|verb} '
          'slowly and {made|make|verb} a cup of {tea|tea|noun}. The kitchen '
          'was {quiet|quiet|adjective}, and the rain {fell|fall|verb} softly '
          'on the window.',
      'After breakfast, he {called|call|verb} his sister. They '
          '{talked|talk|verb} about their {plans|plan|noun} for the summer.',
    ],
  ),
  ExerciseText(
    info: Story(
      id: 'text-at-the-station',
      title: 'At the Station',
      topic: 'Reisen',
      level: 'A2',
      readingMinutes: 2,
    ),
    paragraphs: [
      'The train {left|leave|verb} at nine. Anna {ran|run|verb} to the '
          '{platform|platform|noun}, but the doors were already closed. She '
          '{bought|buy|verb} a new {ticket|ticket|noun} and '
          '{waited|wait|verb} for the next one.',
    ],
  ),
  ExerciseText(
    info: Story(
      id: 'text-visit-to-the-doctor',
      title: 'A Visit to the Doctor',
      topic: 'Medizin',
      level: 'B1',
      readingMinutes: 3,
    ),
    paragraphs: [
      'Maria {felt|feel|verb} tired for a whole week, so she '
          '{booked|book|verb} an {appointment|appointment|noun}. The doctor '
          '{listened|listen|verb} {carefully|careful|adverb} and '
          '{wrote|write|verb} a {prescription|prescription|noun}.',
    ],
  ),
];

/// Pre-generated sentence translations, keyed by the English sentence as it
/// reads with every gap filled.
const _sentenceTranslations = {
  'The station was almost empty when Clara arrived.':
      'Der Bahnhof war fast leer, als Clara ankam.',
  'A cold wind moved through the hall, and the old clock above the gate '
          'said ten minutes to midnight.':
      'Ein kalter Wind zog durch die Halle, und die alte Uhr über dem Tor '
      'zeigte zehn vor Mitternacht.',
  'She looked at her ticket again.': 'Sie sah noch einmal auf ihre Fahrkarte.',
  'The last train to Seville was late, but nobody seemed to know why.':
      'Der letzte Zug nach Sevilla hatte Verspätung, aber niemand schien '
      'zu wissen, warum.',
  'A man behind the counter shrugged and went back to his newspaper.':
      'Ein Mann hinter dem Schalter zuckte mit den Schultern und las weiter '
      'in seiner Zeitung.',
  'Clara sat down on a bench and opened her book.':
      'Clara setzte sich auf eine Bank und schlug ihr Buch auf.',
  'She had waited three years for this journey.':
      'Sie hatte drei Jahre auf diese Reise gewartet.',
  'Ten more minutes would not change anything.':
      'Zehn Minuten mehr würden nichts ändern.',
  'On Saturdays, the market opens early.': 'Samstags öffnet der Markt früh.',
  'People buy fresh bread and talk with their neighbours.':
      'Die Leute kaufen frisches Brot und unterhalten sich mit ihren '
      'Nachbarn.',
  'Tom woke up late on Sunday.': 'Tom wachte am Sonntag spät auf.',
  'He dressed slowly and made a cup of tea.':
      'Er zog sich langsam an und machte sich eine Tasse Tee.',
  'The kitchen was quiet, and the rain fell softly on the window.':
      'Die Küche war still, und der Regen fiel leise ans Fenster.',
  'After breakfast, he called his sister.':
      'Nach dem Frühstück rief er seine Schwester an.',
  'They talked about their plans for the summer.':
      'Sie sprachen über ihre Pläne für den Sommer.',
  'The train left at nine.': 'Der Zug fuhr um neun ab.',
  'Anna ran to the platform, but the doors were already closed.':
      'Anna rannte zum Bahnsteig, aber die Türen waren schon geschlossen.',
  'She bought a new ticket and waited for the next one.':
      'Sie kaufte eine neue Fahrkarte und wartete auf den nächsten.',
  'Maria felt tired for a whole week, so she booked an appointment.':
      'Maria war eine ganze Woche lang müde, also machte sie einen Termin.',
  'The doctor listened carefully and wrote a prescription.':
      'Die Ärztin hörte aufmerksam zu und schrieb ein Rezept.',
};

String sampleTranslateSentence(String sentence) =>
    _sentenceTranslations[sentence.trim()] ?? 'Übersetzung folgt.';

/// Seen words for the Wortliste, relative to [now] so "Zuletzt gesehen" reads
/// sensibly whenever the app runs.
List<VocabWord> sampleVocabulary(DateTime now) {
  VocabWord word(
    String headword,
    String partOfSpeech,
    String translation, {
    required String sentence,
    required String sentenceTranslation,
    required int box,
    required int daysAgo,
    required int reviews,
    bool favorite = false,
    bool playlist = false,
  }) => VocabWord(
    id: headword,
    entry: WordEntry(
      headword: headword,
      partOfSpeech: partOfSpeech,
      translation: translation,
    ),
    sentence: sentence,
    sentenceTranslation: sentenceTranslation,
    box: box,
    lastSeenAt: now.subtract(Duration(days: daysAgo, hours: 2)),
    reviewCount: reviews,
    isFavorite: favorite,
    inPlaylist: playlist,
  );

  return [
    word(
      'platform',
      'Substantiv',
      'der Bahnsteig',
      sentence: 'Anna ran to the platform, but the doors were already closed.',
      sentenceTranslation:
          'Anna rannte zum Bahnsteig, aber die Türen waren schon geschlossen.',
      box: 3,
      daysAgo: 2,
      reviews: 5,
      playlist: true,
    ),
    word(
      'ticket',
      'Substantiv',
      'die Fahrkarte',
      sentence: 'She looked at her ticket again.',
      sentenceTranslation: 'Sie sah noch einmal auf ihre Fahrkarte.',
      box: 2,
      daysAgo: 0,
      reviews: 3,
    ),
    word(
      'station',
      'Substantiv',
      'der Bahnhof',
      sentence: 'The station was almost empty when Clara arrived.',
      sentenceTranslation: 'Der Bahnhof war fast leer, als Clara ankam.',
      box: 5,
      daysAgo: 21,
      reviews: 9,
      favorite: true,
    ),
    word(
      'appointment',
      'Substantiv',
      'der Termin',
      sentence:
          'Maria felt tired for a whole week, so she booked an appointment.',
      sentenceTranslation:
          'Maria war eine ganze Woche lang müde, also machte sie einen '
          'Termin.',
      box: 1,
      daysAgo: 1,
      reviews: 1,
      playlist: true,
    ),
    word(
      'journey',
      'Substantiv',
      'die Reise',
      sentence: 'She had waited three years for this journey.',
      sentenceTranslation: 'Sie hatte drei Jahre auf diese Reise gewartet.',
      box: 4,
      daysAgo: 9,
      reviews: 6,
    ),
    word(
      'borrow',
      'Verb',
      'ausleihen',
      sentence: 'Can I borrow your umbrella until tomorrow?',
      sentenceTranslation: 'Kann ich mir deinen Schirm bis morgen ausleihen?',
      box: 2,
      daysAgo: 3,
      reviews: 2,
    ),
    word(
      'delay',
      'Substantiv',
      'die Verspätung',
      sentence: 'The delay was announced only five minutes before departure.',
      sentenceTranslation:
          'Die Verspätung wurde erst fünf Minuten vor der Abfahrt '
          'angekündigt.',
      box: 3,
      daysAgo: 5,
      reviews: 4,
    ),
    word(
      'quiet',
      'Adjektiv',
      'still, ruhig',
      sentence:
          'The kitchen was quiet, and the rain fell softly on the window.',
      sentenceTranslation:
          'Die Küche war still, und der Regen fiel leise ans Fenster.',
      box: 5,
      daysAgo: 64,
      reviews: 7,
    ),
    word(
      'prescription',
      'Substantiv',
      'das Rezept',
      sentence: 'The doctor listened carefully and wrote a prescription.',
      sentenceTranslation:
          'Die Ärztin hörte aufmerksam zu und schrieb ein Rezept.',
      box: 1,
      daysAgo: 0,
      reviews: 2,
    ),
    word(
      'neighbour',
      'Substantiv',
      'der Nachbar',
      sentence: 'People buy fresh bread and talk with their neighbours.',
      sentenceTranslation:
          'Die Leute kaufen frisches Brot und unterhalten sich mit ihren '
          'Nachbarn.',
      box: 4,
      daysAgo: 16,
      reviews: 5,
      favorite: true,
    ),
  ];
}

/// Grammar rules of English, explained in German, three per level.
const sampleGrammarRules = [
  GrammarRule(
    id: 'articles',
    title: 'Artikel',
    summary: 'a, an und the – und wann keiner steht',
    level: GrammarLevel.beginner,
    sections: [
      GrammarSection(
        heading: 'Unbestimmter Artikel',
        paragraphs: [
          'Das Englische kennt nur einen unbestimmten Artikel. Vor einem '
              'Konsonantenlaut steht *a*, vor einem Vokallaut *an*. '
              'Entscheidend ist der Laut, nicht der Buchstabe: *an hour*, '
              'aber *a university*.',
        ],
        examples: [
          GrammarExample('She is *a* teacher.', 'Sie ist Lehrerin.'),
          GrammarExample(
            'We waited for *an* hour.',
            'Wir haben eine Stunde gewartet.',
          ),
        ],
        pitfall: GrammarPitfall(
          wrong: 'She is teacher.',
          right: 'She is *a* teacher.',
        ),
      ),
      GrammarSection(
        heading: 'Bestimmter Artikel',
        paragraphs: [
          '*The* gilt für alle Geschlechter und für Einzahl wie Mehrzahl. '
              'Allgemeine Aussagen stehen ohne Artikel: *Life is short*, '
              'nicht *The life is short*.',
        ],
        examples: [
          GrammarExample(
            '*The* station was almost empty.',
            'Der Bahnhof war fast leer.',
          ),
          GrammarExample(
            'Music helps me relax.',
            'Musik hilft mir, mich zu entspannen.',
          ),
        ],
      ),
    ],
  ),
  GrammarRule(
    id: 'plural',
    title: 'Pluralbildung',
    summary: 'Endung -s, -es und die unregelmäßigen Formen',
    level: GrammarLevel.beginner,
    sections: [
      GrammarSection(
        heading: 'Regelmäßige Mehrzahl',
        paragraphs: [
          'Die meisten Substantive hängen *-s* an: *book* → *books*. Nach '
              'Zischlauten (s, x, ch, sh) steht *-es*: *bus* → *buses*, '
              '*watch* → *watches*. Endet ein Wort auf Konsonant + y, wird '
              'daraus *-ies*: *city* → *cities*.',
        ],
        examples: [
          GrammarExample(
            'Two *trains* left at midnight.',
            'Um Mitternacht fuhren zwei Züge ab.',
          ),
          GrammarExample(
            'The *cities* were full of tourists.',
            'Die Städte waren voller Touristen.',
          ),
        ],
      ),
      GrammarSection(
        heading: 'Unregelmäßige Mehrzahl',
        paragraphs: [
          'Einige häufige Wörter bilden die Mehrzahl ohne Endung: *man* → '
              '*men*, *child* → *children*, *person* → *people*. *People* '
              'steht immer mit einem Verb in der Mehrzahl.',
        ],
        examples: [
          GrammarExample(
            '*People* buy fresh bread here.',
            'Die Leute kaufen hier frisches Brot.',
          ),
        ],
        pitfall: GrammarPitfall(
          wrong: 'The people is friendly.',
          right: 'The people *are* friendly.',
        ),
      ),
    ],
  ),
  GrammarRule(
    id: 'simple-present',
    title: 'Simple Present',
    summary: 'Gewohnheiten, Fakten und das -s in der 3. Person',
    level: GrammarLevel.beginner,
    sections: [
      GrammarSection(
        heading: 'Bildung',
        paragraphs: [
          'Das Simple Present ist die Grundform des Verbs. Nur in der '
              '3. Person Einzahl (he, she, it) kommt *-s* hinzu: *I work*, '
              'aber *she works*.',
          'Fragen und Verneinungen bildest du mit *do* bzw. *does*. Das '
              'Hauptverb bleibt dann in der Grundform: *Does she work?*',
        ],
        examples: [
          GrammarExample(
            'Clara *reads* every evening.',
            'Clara liest jeden Abend.',
          ),
          GrammarExample(
            'He *doesn\'t know* why the train is late.',
            'Er weiß nicht, warum der Zug Verspätung hat.',
          ),
        ],
        pitfall: GrammarPitfall(
          wrong: 'Does she works here?',
          right: 'Does she *work* here?',
        ),
      ),
    ],
  ),
  GrammarRule(
    id: 'present-perfect',
    title: 'Present Perfect',
    summary: 'Vergangenes mit Bezug zur Gegenwart',
    level: GrammarLevel.intermediate,
    sections: [
      GrammarSection(
        heading: 'Wann du es brauchst',
        paragraphs: [
          'Das Present Perfect (*have/has* + Partizip) verbindet die '
              'Vergangenheit mit dem Jetzt: Etwas hat begonnen und dauert '
              'an, oder sein Ergebnis zählt jetzt. Steht ein abgeschlossener '
              'Zeitpunkt dabei (*yesterday*, *in 2019*), nimmst du das Simple '
              'Past.',
        ],
        examples: [
          GrammarExample(
            'I *have lived* here since 2010.',
            'Ich wohne seit 2010 hier.',
          ),
          GrammarExample(
            'She *has* just *finished* her book.',
            'Sie hat gerade ihr Buch beendet.',
          ),
        ],
        pitfall: GrammarPitfall(
          wrong: 'I live here since 2010.',
          right: 'I *have lived* here since 2010.',
        ),
      ),
      GrammarSection(
        heading: 'since und for',
        paragraphs: [
          '*Since* nennt den Startpunkt (*since Monday*), *for* die Dauer '
              '(*for three years*). Im Deutschen steht für beides „seit“.',
        ],
        examples: [
          GrammarExample(
            'She *has waited for* three years.',
            'Sie wartet seit drei Jahren.',
          ),
        ],
      ),
    ],
  ),
  GrammarRule(
    id: 'comparison',
    title: 'Steigerung von Adjektiven',
    summary: '-er/-est oder more/most',
    level: GrammarLevel.intermediate,
    sections: [
      GrammarSection(
        heading: 'Kurze und lange Adjektive',
        paragraphs: [
          'Einsilbige Adjektive steigerst du mit *-er* und *-est*: *cold*, '
              '*colder*, *the coldest*. Ab drei Silben stehen *more* und '
              '*most* davor: *more expensive*, *the most expensive*.',
          'Ein paar Formen sind unregelmäßig: *good* → *better* → *best*, '
              '*bad* → *worse* → *worst*.',
        ],
        examples: [
          GrammarExample(
            'The night was *colder* than expected.',
            'Die Nacht war kälter als erwartet.',
          ),
          GrammarExample(
            'This is *the most beautiful* station in Spain.',
            'Das ist der schönste Bahnhof Spaniens.',
          ),
        ],
        pitfall: GrammarPitfall(
          wrong: 'She is more tall than me.',
          right: 'She is *taller* than me.',
        ),
      ),
    ],
  ),
  GrammarRule(
    id: 'some-any',
    title: 'some und any',
    summary: 'Mengen in Aussagen, Fragen und Verneinungen',
    level: GrammarLevel.intermediate,
    sections: [
      GrammarSection(
        heading: 'Die Grundregel',
        paragraphs: [
          '*Some* steht in bejahten Sätzen, *any* in Fragen und '
              'Verneinungen. In Angeboten und Bitten bleibt *some*, weil du '
              'ein Ja erwartest: *Would you like some tea?*',
        ],
        examples: [
          GrammarExample(
            'There are *some* tickets left.',
            'Es sind noch ein paar Fahrkarten übrig.',
          ),
          GrammarExample(
            'Nobody had *any* information.',
            'Niemand hatte irgendeine Information.',
          ),
        ],
      ),
    ],
  ),
  GrammarRule(
    id: 'conditionals',
    title: 'Bedingungssätze',
    summary: 'if-Sätze Typ 1, 2 und 3',
    level: GrammarLevel.advanced,
    sections: [
      GrammarSection(
        heading: 'Die drei Typen',
        paragraphs: [
          'Typ 1 (real): *if* + Simple Present, Hauptsatz mit *will*. '
              'Typ 2 (unwahrscheinlich): *if* + Simple Past, Hauptsatz mit '
              '*would*. Typ 3 (verpasst): *if* + Past Perfect, Hauptsatz mit '
              '*would have* + Partizip.',
          'Im if-Satz selbst steht nie *will* oder *would*.',
        ],
        examples: [
          GrammarExample(
            'If the train *is* late, we *will take* a taxi.',
            'Wenn der Zug Verspätung hat, nehmen wir ein Taxi.',
          ),
          GrammarExample(
            'If I *had* more time, I *would read* more.',
            'Wenn ich mehr Zeit hätte, würde ich mehr lesen.',
          ),
          GrammarExample(
            'If she *had left* earlier, she *would have caught* the train.',
            'Wäre sie früher losgegangen, hätte sie den Zug erreicht.',
          ),
        ],
        pitfall: GrammarPitfall(
          wrong: 'If I would have time, I would read more.',
          right: 'If I *had* time, I would read more.',
        ),
      ),
    ],
  ),
  GrammarRule(
    id: 'passive',
    title: 'Passiv',
    summary: 'Wenn die Handlung wichtiger ist als der Handelnde',
    level: GrammarLevel.advanced,
    sections: [
      GrammarSection(
        heading: 'Bildung',
        paragraphs: [
          'Das Passiv bildest du mit einer Form von *be* + Partizip: '
              '*is built*, *was built*, *has been built*. Wer die Handlung '
              'ausführt, folgt bei Bedarf mit *by*.',
          'Achtung: Das deutsche „werden“ entspricht hier *be*, nicht '
              '*will*.',
        ],
        examples: [
          GrammarExample(
            'The station *was built* in 1901.',
            'Der Bahnhof wurde 1901 gebaut.',
          ),
          GrammarExample(
            'The tickets *are checked* by the conductor.',
            'Die Fahrkarten werden vom Schaffner kontrolliert.',
          ),
        ],
        pitfall: GrammarPitfall(
          wrong: 'The bridge will built next year.',
          right: 'The bridge *will be built* next year.',
        ),
      ),
    ],
  ),
  GrammarRule(
    id: 'reported-speech',
    title: 'Indirekte Rede',
    summary: 'Zeitverschiebung nach said und told',
    level: GrammarLevel.advanced,
    sections: [
      GrammarSection(
        heading: 'Die Zeit rückt zurück',
        paragraphs: [
          'Steht das einleitende Verb in der Vergangenheit (*said*, '
              '*told*), rückt die Zeit der wiedergegebenen Aussage meist '
              'einen Schritt zurück: *am* → *was*, *will* → *would*, '
              '*have done* → *had done*. Einen Konjunktiv wie im Deutschen '
              'gibt es nicht.',
        ],
        examples: [
          GrammarExample(
            '"I am tired." → She said she *was* tired.',
            '„Ich bin müde.“ → Sie sagte, sie sei müde.',
          ),
          GrammarExample(
            '"The train will come." → He said the train *would* come.',
            '„Der Zug wird kommen.“ → Er sagte, der Zug werde kommen.',
          ),
        ],
      ),
    ],
  ),
];
