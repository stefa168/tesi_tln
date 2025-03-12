= Ingegnerizzazione <engi>
Al momento della sua concezione, questa tesi doveva vertere sulla sola ricerca e sviluppo di un "compilatore" che fosse in grado di assemblare una configurazione per un chatbot AIML, partendo dai dati di un automa a stati finiti.\
L'idea era che, una volta sviluppate le basi, il compilatore per NoVAGraphS fosse adattabile con sufficiente facilità ad altri domini non collegati ai FSA.

Fin dalle prime sperimentazioni del prototipo di compilatore tuttavia ci accorgemmo di tre principali problematiche da risolvere:
1. AIML non offre metodi al di fuori del *pattern matching* per identificare la regola di interazione che deve essere attivata. L'unica possibilità in questo caso sarebbe lo studio delle possibili variazioni linguistiche di una certa interazione per determinare una espressione regolare in grado di includere il maggior numero di variazioni possibili.\ È evidente tuttavia come questa opzione sia estremamente dispendiosa e complessa da un punto di vista attuativo e progettuale;
2. Le *risposte fornite* sono circoscritte all'insieme predisposto al momento della progettazione dell chatbot. Dover prevedere ed elencare multiple forme della risposta, per ogni possibile dato richiesto, è un'operazione a dir poco monumentale, se non persino un po' folle e raffigurerebbe l'anti-pattern per eccellenza, condannando il file alla totale impossibilità di manutenzione;
3. *Codificare i dati* di una struttura informativa per poterli poi interrogare non è una funzionalità prevista da AIML. Questo è il motivo per cui la precedente problematica è di difficile risoluzione: AIML non predispone modi per interagire con dati esterni, ma soltanto funzionalità per reagire a interazioni degli utenti.

Esiste la possibilità di integrare servizi esterni tramite il tag `<sraix>`@aiml. Questa opzione tuttavia non dovrebbe essere l'unico modo per poter riconoscere interazioni non previste, o interrogare dati esterni: usarlo per risolvere ogni nostro problema, effettuando chiamate ad API esterne, dimostra come non sia adeguato per gli obiettivi di NoVAGraphS.

A questo punto, una volta determinate le migliorie apportabili, davanti a noi vi erano due vie percorribili:
#enum(numbering: "a.")[
  Estendere uno degli interpreti AIML, come `aiml-high`@aiml-high (implementato in JavaScript ECMAScript 5 e non più manutenuto) o `python-aiml`@python-aiml per aggiungere le funzionalità necessarie per NoVAGraphS;
][
  Sviluppare una nuova soluzione che alla base abbia le tre problematiche come punti saldi da supportare in primo luogo.
]

Considerando l'attuale stato del panorama di AIML open source @aiml-high @python-aiml, e valutando i benefici che l'introduzione di nuove tecniche avrebbero potuto portare, ho deciso di progettare un nuovo sistema in grado di risolvere le problematiche sollevate. In questo modo:
1. Invece del pattern matching si può _anche_ utilizzare un *classificatore neurale* per determinare la classe d'interazione dell'utente. Chiaramente anche in questo caso avremo da raccogliere un certo numero di domande per ogni classe di interazione per poterle riconoscere con adeguata affidabilità; il vantaggio risiede nel fatto che, una volta determinate le classi di interazione, sarà sufficiente utilizzare un algoritmo di addestramento (fine-tuning se si usa un Transformer) per ottenere un modello pronto all'uso.\ Oltre alla ridotta necessità di lavoro umano al di fuori della classificazione iniziale, è sempre possibile introdurre nuove classi semplicemente usando una tecnica di transfer learning @strangmann2024transferlearningfinetuninglarge (di cui il fine-tuning fa parte);
2. Per le risposte, è possibile continuare ad utilizzare un insieme di frasi pre-costruite (template); alternativamente si può lasciare la composizione della risposta a una LLM usando dei prompt ad-hoc per ogni possibile interazione, così da massimizzare la qualità della risposta generata.
3. L'interazione coi dati (o API esterne) è lasciata a moduli di retrieval estensibili, in modo da poter personalizzare il sistema per soddisfare le necessità del dominio di applicazione.

== Panoramica del sistema
L'intero sistema è diviso in due sezioni: il *compilatore* e il *runner*, che verranno approfonditi nelle sezioni successive. Possiamo definirli nel modo seguente:

Il *Compilatore* permette ai botmaster di progettare in modo dichiarativo i modelli necessari per poter interagire con l'utente nel dominio di applicazione.\
Consideriamo come esempio il dominio degli automi a stati finiti: indicativamente dovremo saper rispondere a domande sugli stati dell'automa, e le transizioni che li collegano. Dovranno quindi essere raccolti degli esempi delle interazioni che saranno poi usati per addestrare un modello di classificazione, come discusso nella @classificazione-llm. Allo stesso modo la costruzione di un sistema di NER sarà delegata al compilatore.

In questo modo, le difficoltà maggiori nella preparazione dei modelli (che ho anche personalmente riscontrato durante la ricerca) sono astratte, e permettono ai botmaster di concentrarsi sul design del chatbot.

I dati utilizzati a runtime per i modelli e per il retrieval sono infine raggruppati tutti assieme per permettere un deploy più indolore possibile: il *Runner* si occupa invece di utilizzare ciò che il compilatore ha preparato in anticipo per gestire le interazioni con gli utenti.

Il modo in cui un certo chatbot funzioni, quindi determinare ad esempio il flusso di decisione dell'interazione, è un compito lasciato al botmaster.\ _Da grandi poteri derivano grandi responsabilità_, potremmo anche dire...

Se le funzionalità del compilatore o del runner non dovessero soddisfare qualche necessità particolare, è sempre lasciata totale libertà di aggiungerne di nuove partendo da quelle di base: per questo motivo, il linguaggio scelto per l'implementazione sarà Python, data la sua diffusione capillare @jetbrains-python e la grande flessibilità e facilità d'uso.

== Compilatore

#figure(
  image("../media/compiler.drawio.png", width: 70%),
  kind: "diag",
  caption: [Flusso semplificato delle operazioni di compilazione.],
)

=== Pipeline

== Runner
