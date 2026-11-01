import 'exercise_models.dart';
import 'grammar_models.dart';
import 'home_models.dart';
import 'practice_models.dart';

/// Authored beginner practice and sentence translations, available offline.
class LocalizedPracticeContent {
  const LocalizedPracticeContent({
    required this.texts,
    required this.listening,
    required this.grammar,
    required this.rules,
    required this.translations,
  });

  final List<ExerciseText> texts;
  final List<ChoiceExercise> listening;
  final List<ChoiceExercise> grammar;
  final List<GrammarRule> rules;
  final Map<String, String> translations;
}

final Map<String, LocalizedPracticeContent> localizedPracticeContent = {
  "es": _content(
    texts: [
      _text("es", "es-text-tren", "Un viaje en tren", "Reisen", [
        [
          (
            "Ana {llega|llegar|verb} a la estación con una maleta {pequeña|pequeño|adjective}.",
            "Ana kommt mit einem kleinen Koffer am Bahnhof an.",
          ),
          (
            "Hoy visita a su hermana en otra ciudad.",
            "Heute besucht sie ihre Schwester in einer anderen Stadt.",
          ),
          (
            "En la entrada compra un {billete|billete|noun} y pregunta por el andén.",
            "Am Eingang kauft sie eine Fahrkarte und fragt nach dem Bahnsteig.",
          ),
          (
            "El empleado le muestra un cartel junto a la puerta.",
            "Der Mitarbeiter zeigt ihr ein Schild neben der Tür.",
          ),
        ],
        [
          (
            "Ana {espera|esperar|verb} unos minutos y después sube al tren.",
            "Ana wartet ein paar Minuten und steigt dann in den Zug.",
          ),
          (
            "Encuentra un {asiento|asiento|noun} junto a la ventana.",
            "Sie findet einen Sitzplatz am Fenster.",
          ),
          (
            "El viaje es {tranquilo|tranquilo|adjective} y puede leer su libro.",
            "Die Fahrt ist ruhig und sie kann ihr Buch lesen.",
          ),
          (
            "Su hermana la espera al final del viaje.",
            "Ihre Schwester erwartet sie am Ende der Fahrt.",
          ),
        ],
      ]),
      _text("es", "es-text-mercado", "El mercado del sábado", "Einkaufen", [
        [
          (
            "Luis {va|ir|verb} al mercado con una bolsa {grande|grande|adjective}.",
            "Luis geht mit einer großen Tasche zum Markt.",
          ),
          (
            "Quiere preparar la cena para sus amigos esta noche.",
            "Er möchte heute Abend das Abendessen für seine Freunde zubereiten.",
          ),
          (
            "Primero busca un puesto de {verduras|verdura|noun} cerca de la fuente.",
            "Zuerst sucht er einen Gemüsestand in der Nähe des Brunnens.",
          ),
          (
            "Una señora le enseña tomates y zanahorias de su huerto.",
            "Eine Frau zeigt ihm Tomaten und Karotten aus ihrem Garten.",
          ),
        ],
        [
          (
            "Luis {compra|comprar|verb} seis tomates y un poco de pan.",
            "Luis kauft sechs Tomaten und etwas Brot.",
          ),
          (
            "Las manzanas también parecen {buenas|bueno|adjective}, pero ya tiene fruta en casa.",
            "Die Äpfel sehen auch gut aus, aber er hat schon Obst zu Hause.",
          ),
          (
            "Paga con un {billete|billete|noun} y guarda el cambio.",
            "Er bezahlt mit einem Geldschein und steckt das Wechselgeld ein.",
          ),
          (
            "Después vuelve a casa para cocinar con calma.",
            "Danach geht er nach Hause zurück, um in Ruhe zu kochen.",
          ),
        ],
      ]),
      _text("es", "es-text-dia", "Un día en el barrio", "Alltag", [
        [
          (
            "Por la mañana Elena {abre|abrir|verb} la ventana de su cocina.",
            "Am Morgen öffnet Elena das Fenster ihrer Küche.",
          ),
          (
            "La calle está {tranquila|tranquilo|adjective} y hace un poco de sol.",
            "Die Straße ist ruhig und die Sonne scheint ein wenig.",
          ),
          (
            "Prepara el {desayuno|desayuno|noun} y escucha música en la radio.",
            "Sie bereitet das Frühstück zu und hört Musik im Radio.",
          ),
          (
            "Hoy no trabaja y tiene tiempo para dar un paseo.",
            "Heute arbeitet sie nicht und hat Zeit für einen Spaziergang.",
          ),
        ],
        [
          (
            "Después Elena {sale|salir|verb} de casa y camina hasta el parque.",
            "Danach verlässt Elena das Haus und geht bis zum Park.",
          ),
          (
            "Allí encuentra a una amiga y hablan de sus planes.",
            "Dort trifft sie eine Freundin und sie sprechen über ihre Pläne.",
          ),
          (
            "Las dos se sientan en un {banco|banco|noun} bajo un árbol.",
            "Die beiden setzen sich auf eine Bank unter einem Baum.",
          ),
          (
            "Al mediodía comen en un café {pequeño|pequeño|adjective} del barrio.",
            "Mittags essen sie in einem kleinen Café im Viertel.",
          ),
        ],
      ]),
    ],
    listening: _esListening,
    grammar: _esGrammar,
    rules: _esRules,
  ),
  "it": _content(
    texts: [
      _text("it", "it-text-treno", "In treno da un amico", "Reisen", [
        [
          (
            "Marco {arriva|arrivare|verb} alla stazione con uno zaino {rosso|rosso|adjective}.",
            "Marco kommt mit einem roten Rucksack am Bahnhof an.",
          ),
          (
            "Oggi va a trovare un amico che abita vicino al mare.",
            "Heute besucht er einen Freund, der in der Nähe des Meeres wohnt.",
          ),
          (
            "Compra un {biglietto|biglietto|noun} alla macchina e controlla il binario.",
            "Er kauft am Automaten eine Fahrkarte und prüft das Gleis.",
          ),
          (
            "Sul tabellone vede che il treno parte fra dieci minuti.",
            "Auf der Anzeigetafel sieht er, dass der Zug in zehn Minuten abfährt.",
          ),
        ],
        [
          (
            "Marco {aspetta|aspettare|verb} vicino a una famiglia con due bambini.",
            "Marco wartet in der Nähe einer Familie mit zwei Kindern.",
          ),
          (
            "Quando arriva il treno, cerca un {posto|posto|noun} vicino al finestrino.",
            "Als der Zug ankommt, sucht er einen Platz am Fenster.",
          ),
          (
            "Il viaggio è {breve|breve|adjective} e il paesaggio è molto bello.",
            "Die Fahrt ist kurz und die Landschaft ist sehr schön.",
          ),
          (
            "Il suo amico lo aspetta davanti alla stazione.",
            "Sein Freund wartet vor dem Bahnhof auf ihn.",
          ),
        ],
      ]),
      _text("it", "it-text-mercato", "La spesa al mercato", "Einkaufen", [
        [
          (
            "Giulia {entra|entrare|verb} nel mercato della piazza ogni sabato mattina.",
            "Giulia geht jeden Samstagmorgen auf den Markt auf dem Platz.",
          ),
          (
            "Porta sempre una borsa {grande|grande|adjective} perché compra la spesa per tutta la settimana.",
            "Sie bringt immer eine große Tasche mit, weil sie für die ganze Woche einkauft.",
          ),
          (
            "Oggi cerca delle {mele|mela|noun} e un chilo di patate.",
            "Heute sucht sie Äpfel und ein Kilo Kartoffeln.",
          ),
          (
            "Prima di scegliere guarda i prezzi sui cartelli.",
            "Bevor sie sich entscheidet, schaut sie auf die Preise auf den Schildern.",
          ),
        ],
        [
          (
            "Il venditore le {mostra|mostrare|verb} anche dei pomodori del suo orto.",
            "Der Verkäufer zeigt ihr auch Tomaten aus seinem Garten.",
          ),
          (
            "Sono {maturi|maturo|adjective} e Giulia ne prende quattro per una salsa.",
            "Sie sind reif und Giulia nimmt vier davon für eine Soße.",
          ),
          (
            "Poi compra il {pane|pane|noun} al banco vicino.",
            "Dann kauft sie Brot am Stand nebenan.",
          ),
          (
            "Prima di tornare a casa beve un caffè con sua sorella.",
            "Bevor sie nach Hause zurückkehrt, trinkt sie einen Kaffee mit ihrer Schwester.",
          ),
        ],
      ]),
      _text("it", "it-text-giorno", "Una giornata libera", "Alltag", [
        [
          (
            "La domenica Paolo {prepara|preparare|verb} la colazione per la sua famiglia.",
            "Am Sonntag bereitet Paolo das Frühstück für seine Familie zu.",
          ),
          (
            "Mette sul tavolo il {pane|pane|noun}, il latte e la marmellata.",
            "Er stellt Brot, Milch und Marmelade auf den Tisch.",
          ),
          (
            "La cucina è {luminosa|luminoso|adjective} e tutti mangiano con calma.",
            "Die Küche ist hell und alle essen in Ruhe.",
          ),
          (
            "Dopo colazione i bambini vogliono uscire per giocare al parco.",
            "Nach dem Frühstück möchten die Kinder hinausgehen, um im Park zu spielen.",
          ),
        ],
        [
          (
            "Paolo {prende|prendere|verb} una palla e chiude la porta di casa.",
            "Paolo nimmt einen Ball und schließt die Haustür.",
          ),
          (
            "La famiglia cammina lungo una strada {tranquilla|tranquillo|adjective} fino al parco.",
            "Die Familie geht eine ruhige Straße entlang bis zum Park.",
          ),
          (
            "I bambini giocano mentre i genitori si siedono su una {panchina|panchina|noun}.",
            "Die Kinder spielen, während sich die Eltern auf eine Bank setzen.",
          ),
          (
            "Più tardi tornano a casa per preparare il pranzo insieme.",
            "Später gehen sie nach Hause zurück, um gemeinsam das Mittagessen zuzubereiten.",
          ),
        ],
      ]),
    ],
    listening: _itListening,
    grammar: _itGrammar,
    rules: _itRules,
  ),
  "nb": _content(
    texts: [
      _text("nb", "nb-text-tog", "En tur med toget", "Reisen", [
        [
          (
            "Sara {kommer|komme|verb} til stasjonen med en {liten|liten|adjective} koffert.",
            "Sara kommt mit einem kleinen Koffer zum Bahnhof.",
          ),
          (
            "I dag skal hun besøke en venn i en annen by.",
            "Heute besucht sie einen Freund in einer anderen Stadt.",
          ),
          (
            "Hun kjøper en {billett|billett|noun} i automaten ved inngangen.",
            "Sie kauft am Automaten am Eingang eine Fahrkarte.",
          ),
          (
            "På skjermen ser hun at toget går fra spor tre om ti minutter.",
            "Auf dem Bildschirm sieht sie, dass der Zug in zehn Minuten von Gleis drei abfährt.",
          ),
        ],
        [
          (
            "Sara {venter|vente|verb} på perrongen sammen med flere andre reisende.",
            "Sara wartet mit mehreren anderen Reisenden auf dem Bahnsteig.",
          ),
          (
            "Når toget kommer, finner hun en {plass|plass|noun} ved vinduet.",
            "Als der Zug kommt, findet sie einen Platz am Fenster.",
          ),
          (
            "Vognen er {rolig|rolig|adjective}, så hun kan lese en bok.",
            "Der Wagen ist ruhig, deshalb kann sie ein Buch lesen.",
          ),
          (
            "Vennen hennes møter henne utenfor stasjonen når hun kommer fram.",
            "Ihr Freund trifft sie vor dem Bahnhof, als sie ankommt.",
          ),
        ],
      ]),
      _text("nb", "nb-text-marked", "Lørdag på markedet", "Einkaufen", [
        [
          (
            "Hver lørdag {går|gå|verb} Jonas til markedet på torget i byen.",
            "Jeden Samstag geht Jonas zum Markt auf dem Stadtplatz.",
          ),
          (
            "Han har med seg en {stor|stor|adjective} pose og en kort handleliste.",
            "Er hat eine große Tasche und eine kurze Einkaufsliste dabei.",
          ),
          (
            "Først vil han kjøpe {epler|eple|noun} og poteter til middagen.",
            "Zuerst möchte er Äpfel und Kartoffeln für das Abendessen kaufen.",
          ),
          (
            "Han ser på prisene og snakker litt med en selger.",
            "Er schaut auf die Preise und spricht ein wenig mit einem Verkäufer.",
          ),
        ],
        [
          (
            "Selgeren {viser|vise|verb} ham noen tomater fra en gård i nærheten.",
            "Der Verkäufer zeigt ihm Tomaten von einem Bauernhof in der Nähe.",
          ),
          (
            "Tomatene er {røde|rød|adjective} og lukter godt.",
            "Die Tomaten sind rot und duften gut.",
          ),
          (
            "Jonas kjøper også et {brød|brød|noun} fra bakeriet ved siden av.",
            "Jonas kauft auch ein Brot von der Bäckerei nebenan.",
          ),
          (
            "Etterpå tar han bussen hjem og begynner å lage mat.",
            "Danach fährt er mit dem Bus nach Hause und beginnt zu kochen.",
          ),
        ],
      ]),
      _text("nb", "nb-text-dag", "En fri dag", "Alltag", [
        [
          (
            "Om morgenen {åpner|åpne|verb} Ingrid vinduet og ser ut på gaten.",
            "Am Morgen öffnet Ingrid das Fenster und schaut auf die Straße.",
          ),
          (
            "Det er en {fin|fin|adjective} dag, og solen skinner over husene.",
            "Es ist ein schöner Tag und die Sonne scheint über den Häusern.",
          ),
          (
            "Hun lager {frokost|frokost|noun} og drikker en kopp kaffe ved kjøkkenbordet.",
            "Sie macht Frühstück und trinkt eine Tasse Kaffee am Küchentisch.",
          ),
          (
            "I dag har hun fri og vil gå en tur i parken.",
            "Heute hat sie frei und möchte im Park spazieren gehen.",
          ),
        ],
        [
          (
            "Etter frokost {tar|ta|verb} Ingrid på seg jakken og går ut.",
            "Nach dem Frühstück zieht Ingrid ihre Jacke an und geht hinaus.",
          ),
          (
            "I parken møter hun en venninne som bor i samme gate.",
            "Im Park trifft sie eine Freundin, die in derselben Straße wohnt.",
          ),
          (
            "De setter seg på en {benk|benk|noun} og snakker om helgen.",
            "Sie setzen sich auf eine Bank und sprechen über das Wochenende.",
          ),
          (
            "Senere spiser de lunsj på en {liten|liten|adjective} kafé i nærheten.",
            "Später essen sie in einem kleinen Café in der Nähe zu Mittag.",
          ),
        ],
      ]),
    ],
    listening: _nbListening,
    grammar: _nbGrammar,
    rules: _nbRules,
  ),
  "pt-BR": _content(
    texts: [
      _text("pt-BR", "pt-BR-text-trem", "Uma viagem de trem", "Reisen", [
        [
          (
            "Ana {chega|chegar|verb} à estação com uma mala {pequena|pequeno|adjective}.",
            "Ana kommt mit einem kleinen Koffer am Bahnhof an.",
          ),
          (
            "Hoje ela vai visitar a irmã em outra cidade.",
            "Heute besucht sie ihre Schwester in einer anderen Stadt.",
          ),
          (
            "Na entrada, compra uma {passagem|passagem|noun} e pergunta onde fica a plataforma.",
            "Am Eingang kauft sie eine Fahrkarte und fragt, wo der Bahnsteig ist.",
          ),
          (
            "O funcionário aponta para a escada ao lado da banca de jornais.",
            "Der Mitarbeiter zeigt auf die Treppe neben dem Zeitungskiosk.",
          ),
        ],
        [
          (
            "Ana {espera|esperar|verb} alguns minutos e depois entra no trem.",
            "Ana wartet ein paar Minuten und steigt dann in den Zug.",
          ),
          (
            "Ela encontra um {assento|assento|noun} perto da janela.",
            "Sie findet einen Sitzplatz am Fenster.",
          ),
          (
            "A viagem é {tranquila|tranquilo|adjective} e ela aproveita para ler um livro.",
            "Die Fahrt ist ruhig und sie nutzt die Zeit, um ein Buch zu lesen.",
          ),
          (
            "Sua irmã vai buscá-la na estação quando o trem chegar.",
            "Ihre Schwester holt sie am Bahnhof ab, wenn der Zug ankommt.",
          ),
        ],
      ]),
      _text("pt-BR", "pt-BR-text-feira", "Sábado na feira", "Einkaufen", [
        [
          (
            "Todo sábado, Lucas {vai|ir|verb} à feira perto da sua casa.",
            "Jeden Samstag geht Lucas zum Markt in der Nähe seines Hauses.",
          ),
          (
            "Ele leva uma sacola {grande|grande|adjective} e uma lista de compras.",
            "Er nimmt eine große Einkaufstasche und eine Einkaufsliste mit.",
          ),
          (
            "Hoje precisa de {batatas|batata|noun}, tomates e algumas frutas para a semana.",
            "Heute braucht er Kartoffeln, Tomaten und etwas Obst für die Woche.",
          ),
          (
            "Antes de comprar, olha os preços nas bancas e conversa com os vendedores.",
            "Bevor er einkauft, schaut er auf die Preise an den Ständen und spricht mit den Verkäufern.",
          ),
        ],
        [
          (
            "Uma vendedora {mostra|mostrar|verb} as bananas que chegaram pela manhã.",
            "Eine Verkäuferin zeigt die Bananen, die am Morgen angekommen sind.",
          ),
          (
            "Elas estão {maduras|maduro|adjective} e Lucas compra seis.",
            "Sie sind reif und Lucas kauft sechs.",
          ),
          (
            "Depois ele escolhe um {pão|pão|noun} na banca ao lado.",
            "Danach sucht er sich am Stand nebenan ein Brot aus.",
          ),
          (
            "Na volta, passa na casa da avó para deixar algumas frutas.",
            "Auf dem Rückweg geht er bei seiner Großmutter vorbei, um etwas Obst abzugeben.",
          ),
        ],
      ]),
      _text("pt-BR", "pt-BR-text-dia", "Um dia de folga", "Alltag", [
        [
          (
            "De manhã, Marina {abre|abrir|verb} a janela da cozinha e olha a rua.",
            "Am Morgen öffnet Marina das Küchenfenster und schaut auf die Straße.",
          ),
          (
            "O céu está {azul|azul|adjective} e o sol já ilumina os prédios.",
            "Der Himmel ist blau und die Sonne beleuchtet bereits die Gebäude.",
          ),
          (
            "Ela prepara o {café|café|noun} e coloca pão e queijo na mesa.",
            "Sie bereitet den Kaffee zu und legt Brot und Käse auf den Tisch.",
          ),
          (
            "Hoje é seu dia de folga, então pode tomar o café da manhã com calma.",
            "Heute hat sie frei und kann deshalb in Ruhe frühstücken.",
          ),
        ],
        [
          (
            "Depois Marina {sai|sair|verb} de casa e caminha até o parque.",
            "Danach verlässt Marina das Haus und geht bis zum Park.",
          ),
          (
            "Lá encontra uma amiga que mora no mesmo bairro.",
            "Dort trifft sie eine Freundin, die im selben Viertel wohnt.",
          ),
          (
            "As duas sentam em um {banco|banco|noun} e conversam sobre a semana.",
            "Die beiden setzen sich auf eine Bank und sprechen über die Woche.",
          ),
          (
            "Mais tarde, almoçam em um restaurante {pequeno|pequeno|adjective} perto do parque.",
            "Später essen sie in einem kleinen Restaurant in der Nähe des Parks zu Mittag.",
          ),
        ],
      ]),
    ],
    listening: _ptBRListening,
    grammar: _ptBRGrammar,
    rules: _ptBRRules,
  ),
};

typedef _AuthoredText = (ExerciseText, Map<String, String>);

_AuthoredText _text(
  String language,
  String id,
  String title,
  String topic,
  List<List<(String, String)>> paragraphs,
) => (
  ExerciseText(
    language: language,
    info: Story(
      id: id,
      title: title,
      topic: topic,
      level: 'A2',
      readingMinutes: 2,
    ),
    paragraphs: [
      for (final paragraph in paragraphs)
        paragraph.map((sentence) => sentence.$1).join(' '),
    ],
  ),
  {
    for (final paragraph in paragraphs)
      for (final sentence in paragraph) _plain(sentence.$1): sentence.$2,
  },
);

String _plain(String markup) => markup.replaceAllMapped(
  RegExp(r'\{([^|}]+)\|[^|}]+\|\w+\}'),
  (match) => match[1]!,
);

LocalizedPracticeContent _content({
  required List<_AuthoredText> texts,
  required List<ChoiceExercise> listening,
  required List<ChoiceExercise> grammar,
  required List<GrammarRule> rules,
}) => LocalizedPracticeContent(
  texts: List.unmodifiable(texts.map((text) => text.$1)),
  listening: listening,
  grammar: grammar,
  rules: rules,
  translations: Map.unmodifiable({for (final text in texts) ...text.$2}),
);

const _esListening = [
  ChoiceExercise(
    id: "es-listen-1",
    kind: PracticeKind.listening,
    title: "Abfahrt verstehen",
    summary: 'Hör zu und wähle die passende Antwort.',
    topic: "Reisen",
    level: 1,
    targetLanguage: "es",
    prompt: "Wann fährt der Zug ab?",
    audioText: "El tren sale a las nueve.",
    audioDuration: Duration(seconds: 5),
    options: ["Um acht Uhr", "Um neun Uhr", "Um zehn Uhr"],
    answer: "Um neun Uhr",
    explanation: "*A las nueve* bedeutet „um neun Uhr“.",
  ),
  ChoiceExercise(
    id: "es-listen-2",
    kind: PracticeKind.listening,
    title: "Beim Einkaufen",
    summary: 'Hör zu und wähle die passende Antwort.',
    topic: "Einkaufen",
    level: 1,
    targetLanguage: "es",
    prompt: "Wie viele Kilo Äpfel möchte die Person?",
    audioText: "Quiero dos kilos de manzanas, por favor.",
    audioDuration: Duration(seconds: 5),
    options: ["Ein Kilo", "Zwei Kilo", "Drei Kilo"],
    answer: "Zwei Kilo",
    explanation: "*Dos kilos de manzanas* bedeutet „zwei Kilo Äpfel“.",
  ),
  ChoiceExercise(
    id: "es-listen-3",
    kind: PracticeKind.listening,
    title: "Orte finden",
    summary: 'Hör zu und wähle die passende Antwort.',
    topic: "Alltag",
    level: 1,
    targetLanguage: "es",
    prompt: "Wo ist die Bibliothek?",
    audioText: "La biblioteca está al lado del parque.",
    audioDuration: Duration(seconds: 5),
    options: ["Neben dem Park", "Gegenüber dem Bahnhof", "Hinter dem Markt"],
    answer: "Neben dem Park",
    explanation: "*Al lado del parque* bedeutet „neben dem Park“.",
  ),
];

const _itListening = [
  ChoiceExercise(
    id: "it-listen-1",
    kind: PracticeKind.listening,
    title: "Abfahrt verstehen",
    summary: 'Hör zu und wähle die passende Antwort.',
    topic: "Reisen",
    level: 1,
    targetLanguage: "it",
    prompt: "Wann fährt der Zug ab?",
    audioText: "Il treno parte alle dieci.",
    audioDuration: Duration(seconds: 5),
    options: ["Um neun Uhr", "Um zehn Uhr", "Um elf Uhr"],
    answer: "Um zehn Uhr",
    explanation: "*Alle dieci* bedeutet „um zehn Uhr“.",
  ),
  ChoiceExercise(
    id: "it-listen-2",
    kind: PracticeKind.listening,
    title: "Beim Einkaufen",
    summary: 'Hör zu und wähle die passende Antwort.',
    topic: "Einkaufen",
    level: 1,
    targetLanguage: "it",
    prompt: "Was möchte die Person?",
    audioText: "Vorrei tre mele, per favore.",
    audioDuration: Duration(seconds: 5),
    options: ["Zwei Birnen", "Drei Äpfel", "Vier Orangen"],
    answer: "Drei Äpfel",
    explanation: "*Tre mele* bedeutet „drei Äpfel“.",
  ),
  ChoiceExercise(
    id: "it-listen-3",
    kind: PracticeKind.listening,
    title: "Orte finden",
    summary: 'Hör zu und wähle die passende Antwort.',
    topic: "Alltag",
    level: 1,
    targetLanguage: "it",
    prompt: "Wo ist die Apotheke?",
    audioText: "La farmacia è davanti alla stazione.",
    audioDuration: Duration(seconds: 5),
    options: ["Vor dem Bahnhof", "Neben dem Park", "Hinter dem Café"],
    answer: "Vor dem Bahnhof",
    explanation: "*Davanti alla stazione* bedeutet „vor dem Bahnhof“.",
  ),
];

const _nbListening = [
  ChoiceExercise(
    id: "nb-listen-1",
    kind: PracticeKind.listening,
    title: "Abfahrt verstehen",
    summary: 'Hör zu und wähle die passende Antwort.',
    topic: "Reisen",
    level: 1,
    targetLanguage: "nb",
    prompt: "Wann fährt der Zug ab?",
    audioText: "Toget går klokka åtte.",
    audioDuration: Duration(seconds: 5),
    options: ["Um sieben Uhr", "Um acht Uhr", "Um neun Uhr"],
    answer: "Um acht Uhr",
    explanation: "*Klokka åtte* bedeutet „um acht Uhr“.",
  ),
  ChoiceExercise(
    id: "nb-listen-2",
    kind: PracticeKind.listening,
    title: "Beim Einkaufen",
    summary: 'Hör zu und wähle die passende Antwort.',
    topic: "Einkaufen",
    level: 1,
    targetLanguage: "nb",
    prompt: "Was möchte die Person?",
    audioText: "Jeg vil gjerne ha to brød.",
    audioDuration: Duration(seconds: 5),
    options: ["Ein Brot", "Zwei Brote", "Drei Äpfel"],
    answer: "Zwei Brote",
    explanation: "*To brød* bedeutet „zwei Brote“; *brød* bleibt hier im Plural unverändert.",
  ),
  ChoiceExercise(
    id: "nb-listen-3",
    kind: PracticeKind.listening,
    title: "Orte finden",
    summary: 'Hör zu und wähle die passende Antwort.',
    topic: "Alltag",
    level: 1,
    targetLanguage: "nb",
    prompt: "Wo ist die Bibliothek?",
    audioText: "Biblioteket ligger ved siden av skolen.",
    audioDuration: Duration(seconds: 5),
    options: ["Neben der Schule", "Vor dem Markt", "Hinter dem Bahnhof"],
    answer: "Neben der Schule",
    explanation: "*Ved siden av skolen* bedeutet „neben der Schule“.",
  ),
];

const _ptBRListening = [
  ChoiceExercise(
    id: "pt-BR-listen-1",
    kind: PracticeKind.listening,
    title: "Abfahrt verstehen",
    summary: 'Hör zu und wähle die passende Antwort.',
    topic: "Reisen",
    level: 1,
    targetLanguage: "pt-BR",
    prompt: "Wann fährt der Zug ab?",
    audioText: "O trem sai às oito horas.",
    audioDuration: Duration(seconds: 5),
    options: ["Um sieben Uhr", "Um acht Uhr", "Um neun Uhr"],
    answer: "Um acht Uhr",
    explanation: "*Às oito horas* bedeutet „um acht Uhr“.",
  ),
  ChoiceExercise(
    id: "pt-BR-listen-2",
    kind: PracticeKind.listening,
    title: "Beim Einkaufen",
    summary: 'Hör zu und wähle die passende Antwort.',
    topic: "Einkaufen",
    level: 1,
    targetLanguage: "pt-BR",
    prompt: "Was möchte die Person?",
    audioText: "Eu quero duas garrafas de água, por favor.",
    audioDuration: Duration(seconds: 5),
    options: [
      "Zwei Flaschen Wasser",
      "Drei Flaschen Wasser",
      "Eine Flasche Saft",
    ],
    answer: "Zwei Flaschen Wasser",
    explanation: "*Duas garrafas de água* bedeutet „zwei Flaschen Wasser“.",
  ),
  ChoiceExercise(
    id: "pt-BR-listen-3",
    kind: PracticeKind.listening,
    title: "Orte finden",
    summary: 'Hör zu und wähle die passende Antwort.',
    topic: "Alltag",
    level: 1,
    targetLanguage: "pt-BR",
    prompt: "Wo ist der Markt?",
    audioText: "O mercado fica ao lado da escola.",
    audioDuration: Duration(seconds: 5),
    options: ["Neben der Schule", "Vor dem Park", "Hinter dem Bahnhof"],
    answer: "Neben der Schule",
    explanation: "*Ao lado da escola* bedeutet „neben der Schule“.",
  ),
];

const _esGrammar = [
  ChoiceExercise(
    id: "es-grammar-1",
    kind: PracticeKind.grammar,
    title: "Präsens mit yo",
    summary: 'Wähle die Form, die in die Lücke passt.',
    topic: "Verben",
    level: 1,
    targetLanguage: "es",
    prompt: "Yo ___ español cada día.",
    options: ["hablo", "hablas", "hablan"],
    answer: "hablo",
    explanation: "Bei regelmäßigen Verben auf *-ar* endet die Form mit *yo* auf *-o*: *hablar → hablo*.",
  ),
  ChoiceExercise(
    id: "es-grammar-2",
    kind: PracticeKind.grammar,
    title: "Adjektive im Plural",
    summary: 'Wähle die Form, die in die Lücke passt.',
    topic: "Adjektive",
    level: 1,
    targetLanguage: "es",
    prompt: "Las casas son ___.",
    options: ["blanco", "blanca", "blancas"],
    answer: "blancas",
    explanation: "*Casas* ist weiblich und steht im Plural. Das Adjektiv passt sich an: *blancas*.",
  ),
  ChoiceExercise(
    id: "es-grammar-3",
    kind: PracticeKind.grammar,
    title: "ser im Präsens",
    summary: 'Wähle die Form, die in die Lücke passt.',
    topic: "Verben",
    level: 1,
    targetLanguage: "es",
    prompt: "Nosotros ___ estudiantes.",
    options: ["soy", "somos", "son"],
    answer: "somos",
    explanation: "Zu *nosotros* gehört die Form *somos* von *ser*: *Nosotros somos estudiantes*.",
  ),
];

const _itGrammar = [
  ChoiceExercise(
    id: "it-grammar-1",
    kind: PracticeKind.grammar,
    title: "Präsens mit io",
    summary: 'Wähle die Form, die in die Lücke passt.',
    topic: "Verben",
    level: 1,
    targetLanguage: "it",
    prompt: "Io ___ italiano ogni giorno.",
    options: ["parlo", "parli", "parlano"],
    answer: "parlo",
    explanation: "Bei regelmäßigen Verben auf *-are* endet die Form mit *io* auf *-o*: *parlare → parlo*.",
  ),
  ChoiceExercise(
    id: "it-grammar-2",
    kind: PracticeKind.grammar,
    title: "Adjektive im Plural",
    summary: 'Wähle die Form, die in die Lücke passt.',
    topic: "Adjektive",
    level: 1,
    targetLanguage: "it",
    prompt: "Le borse sono ___.",
    options: ["rosso", "rossa", "rosse"],
    answer: "rosse",
    explanation: "*Borse* ist weiblich und steht im Plural. Aus *rossa* wird deshalb *rosse*.",
  ),
  ChoiceExercise(
    id: "it-grammar-3",
    kind: PracticeKind.grammar,
    title: "essere im Präsens",
    summary: 'Wähle die Form, die in die Lücke passt.',
    topic: "Verben",
    level: 1,
    targetLanguage: "it",
    prompt: "Noi ___ studenti.",
    options: ["sono", "siamo", "siete"],
    answer: "siamo",
    explanation:
        "Zu *noi* gehört die Form *siamo* von *essere*: *Noi siamo studenti*.",
  ),
];

const _nbGrammar = [
  ChoiceExercise(
    id: "nb-grammar-1",
    kind: PracticeKind.grammar,
    title: "Präsens",
    summary: 'Wähle die Form, die in die Lücke passt.',
    topic: "Verben",
    level: 1,
    targetLanguage: "nb",
    prompt: "Hun ___ norsk hver dag.",
    options: ["snakker", "snakke", "snakket"],
    answer: "snakker",
    explanation: "Das Präsens von *å snakke* lautet *snakker*. Diese Form gilt für alle Personen.",
  ),
  ChoiceExercise(
    id: "nb-grammar-2",
    kind: PracticeKind.grammar,
    title: "Adjektive im Plural",
    summary: 'Wähle die Form, die in die Lücke passt.',
    topic: "Adjektive",
    level: 1,
    targetLanguage: "nb",
    prompt: "Husene er ___.",
    options: ["rød", "rødt", "røde"],
    answer: "røde",
    explanation: "Im Plural bekommt *rød* die Endung *-e*: *Husene er røde*.",
  ),
  ChoiceExercise(
    id: "nb-grammar-3",
    kind: PracticeKind.grammar,
    title: "Verb an zweiter Stelle",
    summary: 'Wähle die Form, die in die Lücke passt.',
    topic: "Satzbau",
    level: 1,
    targetLanguage: "nb",
    prompt: "I dag ___ jeg på skolen.",
    options: ["er", "å være", "være"],
    answer: "er",
    explanation: "Im Aussagesatz steht das gebeugte Verb an zweiter Satzgliedposition: *I dag er jeg på skolen*.",
  ),
];

const _ptBRGrammar = [
  ChoiceExercise(
    id: "pt-BR-grammar-1",
    kind: PracticeKind.grammar,
    title: "Präsens mit eu",
    summary: 'Wähle die Form, die in die Lücke passt.',
    topic: "Verben",
    level: 1,
    targetLanguage: "pt-BR",
    prompt: "Eu ___ português todos os dias.",
    options: ["falo", "fala", "falam"],
    answer: "falo",
    explanation: "Bei regelmäßigen Verben auf *-ar* endet die Form mit *eu* auf *-o*: *falar → falo*.",
  ),
  ChoiceExercise(
    id: "pt-BR-grammar-2",
    kind: PracticeKind.grammar,
    title: "Adjektive im Plural",
    summary: 'Wähle die Form, die in die Lücke passt.',
    topic: "Adjektive",
    level: 1,
    targetLanguage: "pt-BR",
    prompt: "As casas são ___.",
    options: ["branco", "branca", "brancas"],
    answer: "brancas",
    explanation: "*Casas* ist weiblich und steht im Plural. Das Adjektiv passt sich an: *brancas*.",
  ),
  ChoiceExercise(
    id: "pt-BR-grammar-3",
    kind: PracticeKind.grammar,
    title: "ser im Präsens",
    summary: 'Wähle die Form, die in die Lücke passt.',
    topic: "Verben",
    level: 1,
    targetLanguage: "pt-BR",
    prompt: "Nós ___ estudantes.",
    options: ["sou", "somos", "são"],
    answer: "somos",
    explanation:
        "Zu *nós* gehört die Form *somos* von *ser*: *Nós somos estudantes*.",
  ),
];

const _esRules = [
  GrammarRule(
    id: "es-rule-1",
    title: "Präsens regelmäßiger Verben auf -ar",
    summary: "Über den Alltag sprechen",
    level: GrammarLevel.beginner,
    targetLanguage: "es",
    sections: [
      GrammarSection(
        heading: 'Bildung und Verwendung',
        paragraphs: [
          "Die Endung zeigt die Person: *yo hablo*, *tú hablas*, *él/ella habla*, *nosotros hablamos*, *vosotros habláis*, *ellos/ellas hablan*. Das Subjektpronomen kann oft entfallen, wenn die Person klar ist.",
        ],
        examples: [
          GrammarExample("Yo *hablo* español.", "Ich spreche Spanisch."),
        ],
      ),
    ],
  ),
  GrammarRule(
    id: "es-rule-2",
    title: "Adjektive passen sich an",
    summary: "Geschlecht und Zahl beachten",
    level: GrammarLevel.beginner,
    targetLanguage: "es",
    sections: [
      GrammarSection(
        heading: 'Bildung und Verwendung',
        paragraphs: [
          "Viele Adjektive passen ihre Endung an das Nomen an: *el bolso rojo*, *la bolsa roja*, *los bolsos rojos*, *las bolsas rojas*. Adjektive auf *-e* haben oft dieselbe Form für beide Geschlechter: *grande*.",
        ],
        examples: [
          GrammarExample("Las casas son *blancas*.", "Die Häuser sind weiß."),
        ],
      ),
    ],
  ),
];

const _itRules = [
  GrammarRule(
    id: "it-rule-1",
    title: "Präsens regelmäßiger Verben auf -are",
    summary: "Über Gewohnheiten sprechen",
    level: GrammarLevel.beginner,
    targetLanguage: "it",
    sections: [
      GrammarSection(
        heading: 'Bildung und Verwendung',
        paragraphs: [
          "Bei *parlare* lauten die Präsensformen *parlo*, *parli*, *parla*, *parliamo*, *parlate*, *parlano*. Die Endung zeigt die Person. Deshalb lässt man *io*, *tu* und andere Subjektpronomen oft weg.",
        ],
        examples: [
          GrammarExample(
            "Noi *parliamo* italiano.",
            "Wir sprechen Italienisch.",
          ),
        ],
      ),
    ],
  ),
  GrammarRule(
    id: "it-rule-2",
    title: "Adjektive auf -o",
    summary: "Vier häufige Endungen",
    level: GrammarLevel.beginner,
    targetLanguage: "it",
    sections: [
      GrammarSection(
        heading: 'Bildung und Verwendung',
        paragraphs: [
          "Adjektive auf *-o* passen sich an Geschlecht und Zahl an: *rosso* (männlich, Einzahl), *rossa* (weiblich, Einzahl), *rossi* (männlich, Mehrzahl), *rosse* (weiblich, Mehrzahl).",
        ],
        examples: [
          GrammarExample("Le borse sono *rosse*.", "Die Taschen sind rot."),
        ],
      ),
    ],
  ),
];

const _nbRules = [
  GrammarRule(
    id: "nb-rule-1",
    title: "Präsens ohne Personenendung",
    summary: "Eine Form für alle Personen",
    level: GrammarLevel.beginner,
    targetLanguage: "nb",
    sections: [
      GrammarSection(
        heading: 'Bildung und Verwendung',
        paragraphs: [
          "Viele Verben bilden das Präsens mit *-r*: *å snakke → snakker*. Die Verbform bleibt bei allen Personen gleich: *jeg snakker*, *du snakker*, *vi snakker*. Häufige unregelmäßige Formen sind *er* von *å være* und *går* von *å gå*.",
        ],
        examples: [
          GrammarExample("Hun *snakker* norsk.", "Sie spricht Norwegisch."),
        ],
      ),
    ],
  ),
  GrammarRule(
    id: "nb-rule-2",
    title: "Verb an zweiter Stelle",
    summary: "Satzbau im Aussagesatz",
    level: GrammarLevel.beginner,
    targetLanguage: "nb",
    sections: [
      GrammarSection(
        heading: 'Bildung und Verwendung',
        paragraphs: [
          "Im norwegischen Aussagesatz steht das gebeugte Verb an zweiter Satzgliedposition. Beginnt der Satz mit einer Zeitangabe, folgt das Subjekt nach dem Verb: *I dag går jeg hjem*. Die Zeitangabe kann aus mehreren Wörtern bestehen.",
        ],
        examples: [
          GrammarExample("I dag *er* jeg hjemme.", "Heute bin ich zu Hause."),
        ],
      ),
    ],
  ),
];

const _ptBRRules = [
  GrammarRule(
    id: "pt-BR-rule-1",
    title: "Präsens regelmäßiger Verben auf -ar",
    summary: "Alltag und Gewohnheiten ausdrücken",
    level: GrammarLevel.beginner,
    targetLanguage: "pt-BR",
    sections: [
      GrammarSection(
        heading: 'Bildung und Verwendung',
        paragraphs: [
          "Bei *falar* lauten häufige Formen *eu falo*, *você fala*, *nós falamos*, *vocês falam*. Auch *ele/ela* steht mit *fala*, *eles/elas* mit *falam*. Im brasilianischen Alltag ist *você* eine häufige Anrede für eine Person.",
        ],
        examples: [
          GrammarExample("Eu *falo* português.", "Ich spreche Portugiesisch."),
        ],
      ),
    ],
  ),
  GrammarRule(
    id: "pt-BR-rule-2",
    title: "Adjektive passen sich an",
    summary: "Geschlecht und Zahl beachten",
    level: GrammarLevel.beginner,
    targetLanguage: "pt-BR",
    sections: [
      GrammarSection(
        heading: 'Bildung und Verwendung',
        paragraphs: [
          "Viele Adjektive passen sich an das Nomen an: *o carro branco*, *a casa branca*, *os carros brancos*, *as casas brancas*. Die Endung *-s* kennzeichnet hier die Mehrzahl.",
        ],
        examples: [
          GrammarExample("As casas são *brancas*.", "Die Häuser sind weiß."),
        ],
      ),
    ],
  ),
];
