import 'package:flutter/cupertino.dart';

import 'home_models.dart';
import 'story_models.dart';

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
