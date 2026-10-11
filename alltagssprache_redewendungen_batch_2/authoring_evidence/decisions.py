import json
from pathlib import Path
P=Path(__file__).parent
bind=json.loads((P/'bindings.json').read_text());new={};ov={}
def mapping(text):
 for line in text.strip().splitlines():
  w,s=line.split(' ',1);bind[w]=s
def ns(lemma,pos,key,gloss,definition,*surfaces):
 r=lemma+'/'+pos+'|'+key;new[r]=dict(ref=r,lemma=lemma+'/'+pos,sense_key=key,gloss_de=gloss,definition_de=definition)
 for w in surfaces or (lemma.lower(),):bind[w]=r
 return r
def o(w,s,r,occ=None):ov[(w,s,occ)]=r
mapping('''
plans plan/NOUN|plan#vorhaben
plan plan/NOUN|plan#vorhaben
rent rent/NOUN|rent#miete
best good/ADJ|good#gut
bigger big/ADJ|big#gross
letters letter/NOUN|letter#brief
friendly friendly/ADJ|friendly#freundlich
club club/NOUN|club#verein
completely completely/ADV|completely#voellig
calling call/VERB|call#anrufen
coats coat/NOUN|coat#mantel
deadlines deadline/NOUN|deadline#abgabefrist
did do/AUX|do#hilfsverb
hear hear/VERB|hear#erfahren
healthy healthy/ADJ|healthy#gesund
join join/VERB|join#beitreten
laughed laugh/VERB|laugh#lachen
love love/VERB|love#liebt
refused refuse/VERB|refuse#ablehnen
retiring retire/VERB|retire#in-rente-gehen
ruin ruin/VERB|ruin#verderben
smiling smile/VERB|smile#laechelt
twins twin/NOUN|twin#zwilling
welcome welcome/ADJ|welcome#willkommen
has have/AUX|have#hilfsverb
have have/AUX|have#hilfsverb
me I/PRON|i#mich
more more/DET|more#mehr-menge
less less/DET|less#weniger-menge
keys key/NOUN|key#schluessel
dry dry/ADJ|dry#trocken
minutes minute/NOUN|minute#minuten
leaves leave/VERB|leave#abfahren
sleep sleep/NOUN|sleep#schlaf
rest rest/NOUN|rest#rest
test test/NOUN|test#test
just just/ADV|just#nur
only only/ADJ|only#einzig
bad bad/ADJ|bad#schlimm
closing close/VERB|close#betrieb-einstellen
free free/ADJ|free#frei
leave leave/VERB|leave#verlassen
walking walk/NOUN|walk#gehen
walk walk/NOUN|walk#spaziergang
could could/AUX|could#konnten
left leave/VERB|leave#in-zustand-hinterlassen
made make/VERB|make#veranlassen
blaming blame/VERB|blame#die-schuld-geben
keeps keep/VERB|keep#fortsetzen
asking ask/VERB|ask#fragen
offer offer/NOUN|offer#angebot
got get/VERB|get#gelangen
before before/ADP|before#vor
since since/ADP|since#seit_praeposition
grew grow/VERB|grow#aufwachsen
up up/PART|up#aufwachsen
meeting meeting/NOUN|meeting#treffen
interrupted interrupt/VERB|interrupt#unterbrechen
''')
ns('courage','NOUN','courage#mut','Mut','Die innere Kraft, trotz Angst oder Unsicherheit zu handeln.')
ns('end','VERB','end#beenden','beenden','Eine Beziehung, Tätigkeit oder einen Vorgang zum Abschluss bringen.','ended')
ns('enjoyable','ADJ','enjoyable#angenehm','angenehm; erfreulich','Freude bereitend und als angenehm erlebt.')
ns('forever','ADV','forever#ewig','ewig','Für immer oder über eine als endlos empfundene Zeit.')
ns('fuss','NOUN','fuss#umstaende','Umstände; Aufhebens','Unnötiger Aufwand oder aufgeregtes Verhalten wegen einer Sache.')
ns('innocent','ADJ','innocent#harmlos','harmlos; ohne böse Absicht','Ohne schädliche Absicht, etwa von einem unbeabsichtigten Versehen.')
ns('late','ADJ','late#neueste','neueste','Im Superlativ latest: zeitlich am jüngsten; zuletzt geschehen oder erschienen.','latest')
ns('lie','NOUN','lie#luege','Lüge','Eine bewusst unwahre Aussage.')
ns('owner','NOUN','owner#besitzer','Besitzer','Eine Person, der etwas gehört.')
ns('paperwork','NOUN','paperwork#papierkram','Papierkram','Schriftliche Verwaltungsarbeiten wie Formulare und Dokumente.')
ns('salesman','NOUN','salesman#verkaeufer','Verkäufer','Ein Mann, der beruflich Waren verkauft.')
ns('stare','VERB','stare#starren','starren','Lange und mit festem Blick auf jemanden oder etwas schauen.','stared')
ns('term','NOUN','term#fachbegriff','Fachbegriff','Ein Wort oder Ausdruck mit einer bestimmten, oft fachlichen Bedeutung.','terms')
ns('unexpected','ADJ','unexpected#unerwartet','unerwartet','Nicht vorhergesehen oder erwartet.')
ns('unfairly','ADV','unfairly#ungerecht','ungerecht; zu Unrecht','Auf eine ungerechte oder unberechtigte Weise.')
ns('unfriendly','ADJ','unfriendly#unfreundlich','unfreundlich','Anderen gegenüber nicht freundlich oder zugewandt.')
ns('unsafe','ADJ','unsafe#unsicher','unsicher; gefährlich','Nicht sicher, weil eine Gefahr für Menschen besteht.')
ns('judge','NOUN','judge#juror','Juror','Eine Person, die bei einem Wettbewerb die Leistungen bewertet.')
ns('risk','VERB','risk#riskieren','riskieren','Etwas einer möglichen Gefahr oder einem Verlust aussetzen.')
ns('search','NOUN','search#suche','Suche','Das Bemühen, eine Person, Sache oder Gelegenheit zu finden.')
ns('poor','ADJ','poor#schlecht','schlecht','Von geringer Qualität oder hinter dem angemessenen Standard zurückbleibend.')
ns('get','VERB','get#befoerdern','bekommen; befördern','Etwas mit Mühe an einen bestimmten Ort oder durch eine Öffnung bewegen.','getting')
ns('go','VERB','go#ablaufen','laufen; verlaufen','Von einer Tätigkeit oder Situation: sich auf eine bestimmte Weise entwickeln.','going')
ns('miss','VERB','miss#frist-versaeumen','versäumen','Eine Frist nicht einhalten.','UNUSED_MISS_DEADLINE')
ns('miss','VERB','miss#vermissen','vermissen','Die Abwesenheit einer Person oder Sache bedauern.','UNUSED_MISS_PERSON')
ns('keep','VERB','keep#zustand-aufrechterhalten','halten; dafür sorgen','Bewirken, dass jemand in einem Zustand bleibt oder eine Tätigkeit fortsetzt.','UNUSED_KEEP_CAUSE')
ns('favour','NOUN','favour#bevorzugung','Bevorzugung; Gunst','In in favour of: eine Person oder Gruppe gegenüber anderen bevorzugen.')
ns('side','NOUN','side#partei','Seite; Partei','Eine der gegensätzlichen Positionen oder Gruppen in einer Auseinandersetzung.')
ns('for','ADP','for#preis','für','Den Geldbetrag als Gegenleistung für einen Verkauf angeben.','UNUSED_FOR_PRICE')
ns('through','ADV','through#hindurch','hindurch','Durch eine Öffnung oder an einem Hindernis vorbei, ohne folgendes Präpositionalobjekt.')
ns('to','ADP','to#zustimmung','zu','Nach agree: den Vorschlag oder Plan nennen, dem zugestimmt wird.','UNUSED_TO_AGREE')
# Decisions apply to this exact sentence only, without editing inherited rows.
o('apparently','is','be/AUX|be#hilfsverb')
o('my mistake','on','on/ADP|on#an_zeitlich')
o('get straight to the point','have','have/VERB|have#besitzen')
o('disbelief','in','in/ADP|in#zustand');o('disbelief','at','at/ADP|at#richtung')
o('that is to say','is','be/AUX|be#hilfsverb',1)
o('go with the flow','have','have/VERB|have#besitzen')
o('paint a picture','of','of/ADP|of#ueber_bezug')
o('banter','kept','keep/VERB|keep#zustand-aufrechterhalten')
o('arguably','this','this/PRON|this#dies_stellvertretend')
o('go the extra mile','help','help/VERB|help#helfen')
o('biased','in','in/ADP|in#zustand');o('biased','of','of/ADP|of#ueber_bezug')
o("don't take it personally",'to','to/ADP|to#gegenueber-dativ')
o('the last straw','their','their/PRON|their#ihr')
o('supportive','for','for/ADP|for#nach')
o('on edge','for','for/ADP|for#erwartetes')
o('what went wrong','time','time/NOUN|time#mal')
o('add insult to injury','at','at/ADP|at#richtung')
o('fancy seeing you here','so','so/ADV|so#so_sehr')
o('eat humble pie','after','after/SCONJ|after#nach-hier-vor-einer-ing-form');o('eat humble pie','her','her/PRON|her#sie_objekt');o('eat humble pie','had','have/VERB|have#muessen')
o('are you serious','for','for/ADP|for#preis');o('are you serious','that','that/ADV|that#so')
o('predicament','in','in/ADP|in#zustand')
o("I'm here for you",'in','in/ADP|in#in_zeitlich');o("I'm here for you",'of','of/ADP|of#teil_menge')
o('just in case','take','take/VERB|take#mitnehmen')
o('on thin ice','missed','miss/VERB|miss#frist-versaeumen')
o('pushy','kept','keep/VERB|keep#fortsetzen');o('pushy','after','after/SCONJ|after#nachdem')
o('in the first place','to','to/ADP|to#zustimmung')
o('inconsiderate','leaving','leave/VERB|leave#hinterliess')
o("I wouldn't say that",'rather','rather/ADV|rather#rather-than-statt');o("I wouldn't say that",'than','than/ADP|than#alternative-eigenschaft')
o('see red','to','to/ADP|to#gegenueber-dativ')
o('deliberate','that','that/PRON|that#das')
o('good for you','took','take/VERB|take#erfordern')
o('make way','get','get/VERB|get#gelangen')
o('credible','for','for/ADP|for#fuer')
o('fingers crossed','for','for/ADP|for#geplanter-zeitpunkt')
o('now or never','in','in/ADP|in#in_zeitlich')
o('no offence','little','little/ADV|little#etwas')
o("can't complain",'is','be/AUX|be#hilfsverb',0);o("can't complain",'at','at/ADP|at#zu-in-at-home')
o('easier said than done','that','that/PRON|that#das')
o('keep the ball rolling','plan','plan/VERB|plan#planen')
o('take care','have','have/VERB|have#einnehmen')
o('if memory serves','first','first/ADV|first#zuerst')
o('what a bother','left','leave/VERB|leave#liess-liegen')
o("let's keep it that way",'for','for/ADP|for#seit_lang_dauer');o("let's keep it that way",'of','of/ADP|of#teil_menge')
o('welcome back','missed','miss/VERB|miss#vermissen')
bind['office']='office/NOUN|office#buero'
o('the last straw','their','they/PRON|they#ihr_plural')
o('tricky','through','through/ADP|through#durch')
o('where was I','before','before/SCONJ|before#bevor')
o('thank goodness','home','home/ADV|home#nach-hause')
o('take care','home','home/ADV|home#nach-hause')
o('what a relief','home','home/ADV|home#zu-hause')
o('that is to say','room','room/NOUN|room#raum')
ns('why','ADV','why#warum-frage','warum','Fragt in einer direkten oder indirekten Frage nach dem Grund.')
