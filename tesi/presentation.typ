#import "@preview/touying:0.6.1": *
#import themes.metropolis: *

#import "@preview/numbly:0.1.0": numbly
#import "@preview/pinit:0.2.2": *
#import "@preview/cetz:0.3.2": canvas, draw, palette
#import "@preview/cetz-plot:0.1.1": chart
#import "@preview/showybox:2.0.4": showybox

#let lang = "it"
#set text(font: "TeX Gyre Termes", lang: lang, size: 1em, region: lang)

#show raw: it => {
  show regex("pin\d"): it => pin(eval(it.text.slice(3)))
  it
}

#show strong: set text(black)

#show: metropolis-theme.with(
  aspect-ratio: "16-9",
  // footer: self => self.info.institution,
  footer-progress: true,
  config-info(
    title: [Design, ingegnerizzazione e realizzazione di un sistema di dialogo basato su LLM nel dominio delle tecnologie assistive],
    subtitle: [Tesi di Laurea Magistrale],
    author: [Relatore: Prof. Alessandro Mazzei\ Co-Relatori: Dott. Pier Felice Balestrucci, Dott. Michael Oliverio\ Candidato: Dott. Stefano Vittorio Porta],
    date: "2 Aprile 2025",
    institution: [Università degli Studi di Torino, Dipartimento di Informatica - Anno Accademico 2023/2024],
    logo: image("media/unito.svg", height: 3.99em),
  ),
  // config-common(datetime-format: "[day] [month] [year]")
  config-common(
    show-bibliography-as-footnote: bibliography("bib.yml"),
    handout: true,
  ),
  header-right: image("media/unito.svg", height: 1.4em),
  /*   config-colors(
    primary: rgb("#c25e00"),
    primary-light: rgb("#d6c6b7"),
    secondary: rgb("#23373b"),
    neutral-lightest: rgb("#fafafa"),
    neutral-dark: rgb("#23373b"),
    neutral-darkest: rgb("#23373b"),
  ), */
)

#set heading(numbering: numbly("{1}.", default: "1.1"))
#show heading: set text(size: 0.95em)

#show table: set text(hyphenate: false)
#set table(
  align: (x, y) => (left + if y == 0 { bottom } else { top }),
  fill: (_, y) => if calc.odd(y) { gray.lighten(50%) },
  stroke: none,
)

#show raw.where(block: true): set text(font: "JetBrains Mono NL")

#show figure.where(kind: "plot"): set figure(supplement: [Grafico])
#show figure.where(kind: "snip"): set figure(supplement: [Snippet])
#show figure.where(kind: "script"): set figure(supplement: [Script])
#show figure.where(kind: "fun"): set figure(supplement: [Funzione])
#show figure.where(kind: "cls"): set figure(supplement: [Classe])
#show figure.where(kind: "query"): set figure(supplement: [Query])
#show figure.where(kind: "diag"): set figure(supplement: [Diagramma])

#set raw(syntaxes: ("sparql.sublime-syntax", "turtle.sublime-syntax"))

#title-slide()

= Contesto

== Motivazioni

Iniziamo ad ambientarci:

- *Lettura di contenuti testuali*: da 30 anni sono disponibili sistemi di sintesi vocale integrati in smartphone e computer.
// #pause
- Essenziali per le persone con *disabilità visive*: consentono di accedere a contenuti testuali in modo autonomo e senza l'ausilio di un lettore umano.

#align(center)[
  #image("media/tts-audio.jpg", height: 8em)
]

---

- Pagine web. I sistemi TTS sono in grado di
  - Leggere il testo
  // #pause
  - Interpretare la struttura del documento
  - Questo permette di seguire il flusso di lettura per fornire un'esperienza di qualità

== Problema!

Tutto funziona, a patto che...
#pause
- La pagina web sia strutturata in modo semantico
#align(center)[
  #image("media/html-sementics-layout.png", height: 10em)
]
#pause
- Le immagini siano accompagnate da un testo alternativo
#align(center)[```html <img alt="...">``` o ```html <img aria-label="...">```]
#pause
// #v(1em)

#align(center)[*Queste due condizioni dipendono da chi prepara il contenuto!*]

---

I sistemi di TTS non sono in grado di interpretare il significato di un'immagine o di un elemento puramente visivo.
#pause
#align(center)[
  #let hq = 7em
  #set image(height: hq)
  #stack(dir: ltr, spacing: 2em)[
    #image("image.png")
  ][
    #image("image-1.png")
  ]
]

// #pause
Se non viene fornita un'alternativa testuale contenente delle informazioni utili, l'utente non potrà comprendere appieno il contenuto della pagina o di uno specifico elemento!

#pause
Una di quattro immagini sul web non ha una descrizione testuale o non è informativa @WebAIM2024.

== Anche peggio...

Se per le immagini possiamo utilizzare tecniche di *Computer Vision* o *Reti Neurali* per generare automaticamente un testo alternativo, per le rappresentazioni grafiche di dati (grafici, diagrammi, mappe) non è così semplice.


#pause
#align(center)[
  #let hq = 10em
  #set image(height: hq)
  #stack(dir: ltr, spacing: 2em)[
    #image("image-2.png")
  ][
    #pause
    #image("image-3.png")
  ]
]

== Un aiuto

- Il Progetto NoVAGraphS si propone di rendere più accessibili questi contenuti, mediante la costruzione di sistemi di dialogo (Chatbot).
// #pause

- Con essi è possibile interagire per ottenere informazioni sui dati presenti in grafi o strutture simili, per avere una comprensione *profonda* del contenuto.
// #pause

- Il Progetto originale fa fondamento su AIML @aiml (Artificial Intelligence Markup Language), un linguaggio di markup per la creazione di chatbot.

== Un esempio

#figure(
  ```xml
  <category>
    <pattern>MI CHIAMO *</pattern>
    <template>
      Ciao <star/>, piacere di conoscerti!
    </template>
  </category>



  ```,
  caption: "Esempio di AIML per la gestione di un saluto",
)

== Limitazioni di AIML

- Le strategie di wildcard e pattern matching restano *prevalentemente letterali*: Se una frase si discosta dal pattern previsto, il sistema fallisce il matching
// #pause
// - Sono disponibili ridotte funzionalità per la gestione di _sinonimi_, semplificazione delle _locuzioni_ e _correzione ortografica_
#pause
- La *gestione del contesto* (via `<that>`, `<topic>`, `<star>`, ecc.) è rudimentale
#pause
- L'integrazione (via `<sraix>`) con *basi di conoscenza esterne* (KB, database, API) è possibile implementando funzioni personalizzate, ma è di difficile gestione
#pause
- Le risposte generate sono *statiche e predefinite*, e non possono essere generate dinamicamente in base a dati esterni o a contesti più ampi in modo automatico

== Obiettivi
- Sviluppare un sistema di dialogo che superi le limitazioni di AIML evidenziate
// #pause
- Integrare tecniche di *Natural Language Understanding* (NLU) e *Retrieval-Augmented Generation* (RAG) per migliorare l'esperienza d'uso
// #pause
- Assicurare una elevata facilità di estensione e personalizzazione per diversi domini e applicazioni

= Natural Language Understanding

== Panoramica

Il primo elemento dello stack di NLP rispetto ad AIML che vogliamo migliorare è il riconoscimento delle intenzioni dell'utente.

#pause
- Non useremo più un sistema basato su pattern matching ed espressioni regolari
- Riconosceremo la categoria di interazione affidandoci ad un classificatore basato su LLM
- Le parti variabili della frase (slot) verranno estratte tramite un sistema di Named Entity Recognition (NER)

== Classificazione

- Essendo un task supervisionato, bisogna partire con l'etichettatura dei dati.
- Il dataset utilizzato proviene dalle precedenti pubblicazioni del progetto NoVAGraphS, e contiene 350 interazioni degli utenti prodotte durante precedenti sperimentazioni.
#pause
- L'annotazione dei dati:
  - Inizialmente è stata effettuata automaticamente
  - Successivamente è stata completamente riveduta ed effettutata manualmente
#pause
- Sono usati due livelli di granularità per la classificazione:
  - 7 *classi principali*
  - Sono state introdotte le *classi secondarie* per ogni classe principale, per un totale di 33.

---

#figure(
  table(
    columns: (0.3fr, 1fr, 0.3fr),

    table.header[Classe][Scopo][Numero di Esempi],
    table.hline(),

    [transition], [Domande che riguardano le transizioni tra gli stati], [77],
    [automaton], [Domande che riguardano l'automa in generale], [48],
    [state], [Domande che riguardano gli stati dell'automa], [48],
    [grammar], [Domande che riguardano la grammatica riconosciuta dall'automa], [33],
    [theory], [Domande di teoria generale sugli automi], [15],
    [start], [Domande che avviano l'interazione con il sistema], [6],
    [off\_topic], [Domande non pertinenti al dominio che il sistema deve saper gestire], [2],
  ),
  caption: "Classi principali per la classificazione delle domande",
)

---

#figure(
  table(
    columns: (auto, auto, auto),
    table.header[Sottoclassi][Scopo][Numero di Esempi],
    table.hline(),

    [description], [Descrizioni generali sull'automa], [14],
    [description_brief], [Descrizione generale (breve) sull'automa], [10],
    [directionality], [Domande riguardanti la direzionalità o meno dell'intero automa], [1],
    [list], [Informazioni generali su nodi e archi], [1],
    [pattern], [Presenza di pattern particolari nell'automa], [9],
    [representation], [Rappresentazione spaziale dell'automa], [13],
  ),
  caption: [Classi secondarie per la classe primaria dell'*Automa*],
)

// #align(center)[(esempio)]

== Data Augmentation

- Del dataset originale sono rimasti solo 229 esempi, divisi in classi sbilanciate.
- Per assicurare che il modello abbia buone prestazioni, è stato necessario aumentare il numero di esempi.
- Sono state generate 851 nuove domande, utilizzando LLM alle quali è stato fornito un insieme di quesiti di una certa classe.
- Per le domande off-topc è stato adoperato il dataset SQUAD @squad1

---

#figure(
  {
    let plot_data = (
      ([automaton], 48, 184),
      ([grammar], 33, 223),
      ([off_topic], 6, 106),
      ([start], 2, 19),
      ([state], 41, 151),
      ([theory], 15, 115),
      ([transition], 83, 366),
    )
    canvas({
      draw.set-style(legend: (fill: white), barchart: (bar-width: .8, cluster-gap: 0))
      chart.barchart(
        plot_data,
        mode: "clustered",
        size: (15, 10),
        label-key: 0,
        value-key: (1, 2),
        labels: ([Originale], [Augmented]),
        legend: "inner-north-east",
        // bar-style: palette.new(colors: (aqua, green)),
      )
    })
  },
  caption: "Numero di esempi per classe originale e aumentata",
)

== Fine-tuning

- Partendo LLM pre-addestrate e con una buona padronanza della lingua inglese, l'addestramento è piuttosto rapido e non richiede molte risorse.
- È stato eseguito un fine-tuning per adattare il modello alla classificazione delle domande.
- In questo modo il modello apprende le particolarità e sfumature dello scenario applicativo specifico.
- La metrica massimizzata è stata la *F1 score* (media armonica fra Precision e Recall)
$ "F1" = 2 dot ("Precision" dot "Recall") / ("Precision" + "Recall") $

---

I modelli utilizzati per il fine-tuning sono stati:

- `google-bert/bert-base-uncased`, versione da 110 milioni di parametri @bert-base (Google)
- `distilbert/distilbert-base-uncased` @distilbert-base, versione distillata di BERT, con circa il 40% in meno di parametri @distilbert
- `google/mobilebert-uncased` @mobilebert-uncased con 25 milioni di parametri; per dispositivi mobili
- `google/electra-small-discriminator` @electra-hf, da 14 milioni di parametri

---

#figure(
  {
    let plot_data = (
      ([Main], 173, 91, 119, 42),
      ([Automaton], 40, 23, 26, 9),
      ([Transition], 65, 35, 44, 15),
      ([Grammar], 46, 26, 32, 11),
      ([State], 35, 21, 22, 8),
      ([Theory], 30, 18, 19, 7),
    )
    canvas({
      draw.set-style(legend: (fill: white), barchart: (bar-width: .8, cluster-gap: 0))
      chart.barchart(
        plot_data,
        mode: "clustered",
        size: (15, 10),
        label-key: 0,
        value-key: (1, 2, 3, 4),
        labels: ([bert], [distilbert], [mobilebert], [electra]),
        x-label: "Tempo di addestramento in secondi",
        y-label: "Classe di training",
        legend: "inner-south-east",
        bar-style: palette.new(colors: (red, green, purple, aqua)),
      )
    })
  },
  caption: "Tempo di addestramento per BERT, DistilBERT, MobileBERT ed ELECTRA",
)

---

#figure(
  {
    let plot_data = (
      ([BERT], 0.89711, 0.92, 0.86),
      ([DistilBERT], 0.88114, 0.92, 0.84),
      ([MobileBERT], 0.816, 0.81, 0.73),
      ([ELECTRA], 0.833, 0.80, 0.42),
      ([AIML], 0, 0.33, 0.2),
    )
    canvas({
      draw.set-style(legend: (fill: white), barchart: (bar-width: .8, cluster-gap: 0))
      chart.barchart(
        plot_data,
        mode: "clustered",
        size: (15, 10),
        label-key: 0,
        value-key: (1, 2, 3, 5),
        labels: ([Classe Principale (training)], [Classe Principale (test)], [Classe Secondaria (test)]),
        x-label: "F1 Score",
        y-label: "Modello Utilizzato",
        legend: "inner-south-east",
        // bar-style: palette.new(colors: (green, red, aqua)),
      )
    })
  },
  caption: "Performance su test set bilanciato da 468 ulteriori domande confrontato con AIML",
)

---

#align(
  center,
  {
    // show text:
    table(
      columns: 8,
      table.header(
        // row 1
        table.cell(rowspan: 2)[],
        table.cell(colspan: 3, align: center)[Performance AIML],
        table.cell(colspan: 3, align: center)[Performance BERT],
        table.cell(rowspan: 2)[Esempi],
        // row 2
        [Precision],
        [Recall],
        [F1-score],
        [Precision],
        [Recall],
        [F1-score],
      ),
      table.hline(),
      table.vline(x: 1, start: 0),
      table.vline(x: 4, start: 0),
      table.vline(x: 7, start: 0),

      [Automaton], [0.52], [0.19], [0.27], [0.93], [0.93], [*0.93*], [75],
      [Grammar], [0.90], [0.13], [0.23], [0.78], [0.83], [*0.81*], [70],
      [Off-Topic], [0.26], [0.82], [0.39], [1.00], [0.96], [*0.98*], [100],
      [Start], [1.00], [0.53], [0.69], [1.00], [0.90], [*0.95*], [40],
      [State], [0.17], [0.19], [0.18], [0.96], [1.00], [*0.98*], [43],
      [Theory], [0.00], [0.00], [0.00], [0.57], [0.57], [*0.57*], [30],
      [Transition], [0.67], [0.28], [0.40], [0.97], [0.99], [*0.98*], [110],
      table.hline(),
      [Accuracy], table.cell(colspan: 2)[], [0.35], table.cell(colspan: 2)[], [*0.92*], [468],
      [Macro avg], [0.44], [0.27], [0.27], [0.89], [0.88], [*0.88*], [468],
      [Weighted avg], [0.53], [0.35], [0.33], [0.92], [0.92], [*0.92*], [468],
    )
  },
)

---

#figure(
  grid(
    columns: 2,
    image(
      "../multitask_training/diagrams/aiml/confusion_matrices_aiml_main.svg",
      height: auto,
    ),
    image(
      "../multitask_training/diagrams/BertForSequenceClassification/confusion_matrices_bert_main.svg",
      height: auto,
    ),
  ),
  caption: [Matrici di confusione per le classi principali con AIML e BERT],
)

== Named entity recognition

Dobbiamo poter estrarre le parti variabili delle domande, in modo da capire quali informazioni l'utente sta cercando. È stato usato _Doccano_ per l'annotazione delle frasi.

// ---

#figure(
  image("./media/doccano_screen.png"),
  caption: [Interfaccia di Doccano per l'annotazione dei dati di NER.],
) <doccano-screen>

---

In seguito all'etichettatura sono risultate tre classi di entità:

- `input`: per input o sequenze di simboli.\ #quote[Does it only accept 1s and 0s?] #sym.arrow.double ```json [20,21,"input"],[27,28,"input"]```

- `node`: per i frammenti di testo che contengono nodi o stati dell'automa.\ #quote[Is there a transition between q2 and q0?] #sym.arrow.double ```json [30,32,"node"],[37,39,"node"]```

- `language`: informazioni sulla grammatica accettata dall'automa.\ #quote[Does the automaton accept strings over the alphabet {0,1}?] #sym.arrow.double ```json [53,58,"language"]```

---

#figure(
  image("./media/f1_ner.png", height: 10cm),
  caption: [Performance di F1 del modello di NER durante l'addestramento tramite SPACY @spacy.],
)<f1-ner>

= Retrieval Augmented Generation

== Retrieval

- Per fornire risposte complete e pertinenti, il sistema deve essere in grado di interrogare una base di conoscenza esterna.
#pause
- Esistono diverse tecniche, che dipendono dal tipo di dati e dalla loro rappresentazione:
  - Basi di conoscenza strutturate: SQL, SPARQL, ecc.
  #pause
  - Corpus: ricerca full-text, TF-IDF, embeddings...
  #pause
  - API e servizi esterni: REST, JMESPath

== Retrieval su Database

#figure(
  ```sql
  SELECT customer_name, order_date, total_amount
  FROM orders
  WHERE order_id = :orderId
    AND customer_id = :customerId;



  ```,
  kind: "query",
  caption: "Esempio di query SQL per il recupero di dettagli di un ordine in un sistema e-commerce.",
) <sql-example>

== Retrieval su Knowledgebase

/* ---

#figure(
  ```turtle
  BASE <http://example.org/>
  PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
  PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
  PREFIX foaf: <http://xmlns.com/foaf/0.1/>
  PREFIX rel: <http://www.perceive.net/schemas/relationship/>

  <#green-goblin>
    rel:enemyOf <#spiderman> ;
    a foaf:Person ;
    foaf:name "Green Goblin", "Goblin"@it .

  <#spiderman>
    rel:enemyOf <#green-goblin> ;
    a foaf:Person ;
    foaf:name "Spiderman", "Uomo Ragno"@it .


  ```,
  kind: "snip",
  caption: [Annotazione in formato Turtle di un grafo RDF.],
) <ttl-example> */

// ---

#figure(
  ```sparql
  PREFIX dbo: <http://dbpedia.org/ontology/>
  PREFIX dbr: <http://dbpedia.org/resource/>

  SELECT ?director
   WHERE {
    dbr:The_Incredibles dbo:director ?director .
  }


  ```,
  kind: "query",
  caption: [Query SPARQL per il recupero del regista del film _Gli Incredibili_ (Brad Bird).],
) <incredibles>

// ---

== Cosine Similarity

#figure(
  image("image-4.png"),
  caption: [Illustrazione della cosine similarity.],
)

== Prompting

#showybox(
  title-style: (
    weight: 900,
    sep-thickness: 0pt,
    color: green.darken(40%),
    align: start,
  ),
  frame: (
    title-color: green.lighten(80%),
    border-color: green.darken(40%),
    thickness: (left: 1pt),
    radius: 0pt,
  ),
  title: [Prompt],
)[Ecco i dati estratti dal database di e-commerce:
  #list(
    marker: [•],
    [Prezzo dell'articolo: 49,99 euro],
    [Tempi di spedizione: 2 giorni],
    [Colori disponibili: rosso, blu, verde],
  )
  Genera una breve risposta da mostrare al cliente, evitando informazioni non pertinenti e senza inventare nulla.]
#showybox(
  title-style: (
    weight: 900,
    sep-thickness: 0pt,
    color: blue.darken(40%),
    align: start,
  ),
  frame: (
    title-color: blue.lighten(80%),
    border-color: blue.darken(40%),
    thickness: (left: 1pt),
    radius: 0pt,
  ),
  title: [Risposta da GPT-4o],
)[L'articolo è disponibile nei colori rosso, blu e verde al prezzo di 49,99 euro. I tempi di spedizione sono di 2 giorni.]

---

#showybox(
  title-style: (
    weight: 900,
    sep-thickness: 0pt,
    color: green.darken(40%),
    align: start,
  ),
  frame: (
    title-color: green.lighten(80%),
    border-color: green.darken(40%),
    thickness: (left: 1pt),
    radius: 0pt,
  ),
  title: [Prompt],
)[
  Sei un assistente che fornisce informazioni su ordini online. Di seguito trovi una selezione parziale delle interazioni con l'utente:

  *Utente*: “Qual è lo stato di avanzamento del mio ordine?”

  Il sistema ha reperito i seguenti dati:
  #list(
    marker: [•],
    [Ordine n. 1357],
    [Stato: in spedizione],
    [Previsione di consegna: 10/04/2025],
  )

  Ora, rispondi alla domanda dell'utente in modo chiaro e conciso, mantenendo la coerenza con le interazioni precedenti.
]

== Generazione delle risposte

- Dobbiamo assicurarci che il sistema sia in grado di rispondere in modo non solo coerente e pertinente, ma anche efficace alle domande degli utenti.

- Per effettuare le valutazioni sono stati utilizzati diversi LLM
- Una volta generate tutte le risposte con i vari modelli, sono state tutte annotate
- I risultati delle annotazioni hanno fornito dettagli essenziali per la scelta del modello finale

---

Sono state scelte delle LLM open-weights dati i multipli vantaggi che offrono:

- Trasparenza e accountability
  - Accesso ai pesi e alla struttura dei modelli per identificare bias e anomalie.
  - Maggiore controllo sulla sicurezza e affidabilità dell'AI.
#pause
- Verifiche indipendenti e replicabilità per ricercatori e sviluppatori. Maggiore fiducia.
#pause
- Innovazione e competizione
  - Riduzione delle barriere d'ingresso per startup e centri di ricerca.
  - Non sono necessarie per forza grandi risorse hardware
  - Protezione della privacy e riduzione dei costi operativi.
#pause
- Supporto a uno sviluppo sostenibile e responsabile dell'AI.

---

```md
You are a helpful assistant expert in finite state automata.
Answer the question given by the user using the retrieved data, using plain text only.
Avoid referring to the data directly; there is no need to provide any additional information.
Keep the answer concise and short, and avoid using any additional information not provided.

The system has retrieved the following data:
` ` `
{data}
` ` `

The user has asked the following question:
` ` `
{question}
` ` `
```

---

Per la generazione delle risposte è stato selezionato un sottinsieme di domande che richiedono informazioni riguardo questo specifico automa a stati finiti:

#figure(image("../gen_eval/fsa.svg")) <fsa_eval>

#pause

Se il tema della domanda è riguardante le _transizioni uscenti da un nodo_, prima di generare la risposta, il sistema recupera le i dettagli utili e li presenta al modello.

#align(center)[
  ```md
  The transitions exiting from the node are the following:
  - From qo to q1, with label '1'
  ```
]

---
#figure(
  ```dot
  digraph FSA {
      rankdir=LR;
      node [shape = circle];
      q0 [shape = doublecircle];
      q1; q2; q3; q4;

      start [shape=none, label=""];
      start -> q0;

      q0 -> q1 [label = "1"];
      q1 -> q2 [label = "1"];
      q2 -> q3 [label = "1"];
      q3 -> q4 [label = "0"];
      q4 -> q0 [label = "0"];
  }
  ```,
  kind: "snip",
  caption: "Rappresentazione in formato Graphviz dell'automa a stati finiti utilizzato come input per le domande.",
) <fsa-dot>

== Annotazione

- È necessario annotare le risposte per valutare le performance degli LLM candidati
- Basato sulle ricerche di Z. Kasner e O. Dušek @kasner-dusek
- Verrà utilizzato il software Factgenie @factgenie da loro sviluppato per le annotazioni

---

Gli annotatori sono liberi di evidenziare nelle risposte frammenti problematici semplicemente selezionandoli. Sono stati definiti quattro generi di errori:

#let gold = rgb("#c9ab40")
#let incorrect() = [*#text(fill: red)[#underline[INCORRECT]#super[I]]*]
#let not_checkable() = [*#text(fill: purple)[#underline[NOT_CHECKABLE]#super[NC]]*]
#let misleading() = [*#text(fill: gold)[#underline[MISLEADING]#super[M]]*]
#let other() = [*#text(fill: rgb("#858585"))[#underline[OTHER]#super[O]]*]

- #incorrect(): la risposta contiene informazioni che contraddicono i dati forniti o che sono chiaramente sbagliate.
- #not_checkable(): la risposta contiene informazioni che non possono essere verificate con i dati forniti.
- #misleading(): la risposta contiene informazioni fuorvianti o che possono essere interpretate in modo errato.
- #other(): la risposta contiene errori grammaticali, stilistici o di altro tipo.

---

#figure(
  image("./media/factgenie_UI.png"),
  caption: "Interfaccia di Factgenie",
) <factgenie-ui>

---

Oltre ad evidenziare parti problematiche delle risposte, è stato richiesto agli annotatori anche di fornire delle valutazioni qualitative su alcune metriche:

- *Accuratezza della risposta*: da selezionare quando la risposta è corretta al 100% e non contiene errori sui dati;
- *Assenza o incompletezza di informazioni*: da selezionare quando la risposta non contiene tutte le informazioni rilevanti;
- *Totale incongruenza della risposta*: da selezionare quando la risposta appare completamente scorrelata o non pertinente alla domanda;
- *Chiarezza della risposta*: se è comprensibile e ben strutturata;
- *Lunghezza della risposta*: se la comprensione della risposta è facilitata dalla sua lunghezza (o brevità);
- *Utilità percepita della risposta*: se la risposta è utile e fornisce informazioni rilevanti;
- *Apprezzamento generale*: se la risposta è apprezzata o gradita.

---

In totale, 12 annotatori hanno partecipato alla valutazione delle risposte generate dai modelli.
Riguardo gli annotatori:
- 8 su 12 sono studenti del Dipartimento di Informatica;
- 2 hanno un background ingegneristico;
- I rimanenti 2 provengono dal Dipartimento di Storia e Biologia.

L'età media è di 28 anni, con un range tra i 21 e i 68 anni.

Ogni volontario ha valutato un sottoinsieme delle risposte, garantendo comunque un overlap sulle 75 risposte totali.

Oltre agli annotatori umani, sono stati utilizzati anche due modelli di LLM (`GPT-o3-mini` e `GPT-4.5`) per svolgere automaticamente una valutazione simile a quella dei volontari ($epsilon_"hum"$).

== Risultati

#figure(
  {
    show strong: set text(fill: black)
    show table.cell: set text(fill: black)
    show table: set text(size: 0.93em)
    table(
      columns: 11,
      table.header(
        table.cell(rowspan: 2, align: center + horizon)[Modello],
        table.cell(colspan: 2, align: center)[*Incorrect*],
        table.cell(colspan: 2, align: center)[*Not Checkable*],
        table.cell(colspan: 2, align: center)[*Misleading*],
        table.cell(colspan: 2, align: center)[*Other*],
        table.cell(colspan: 2, align: center)[*Globale*],
        [$epsilon_"hum"$],
        [$epsilon_"4.5"$],
        [$epsilon_"hum"$],
        [$epsilon_"4.5"$],
        [$epsilon_"hum"$],
        [$epsilon_"4.5"$],
        [$epsilon_"hum"$],
        [$epsilon_"4.5"$],
        [$epsilon_"hum"$],
        [$epsilon_"4.5"$],
      ),
      table.hline(),
      [Deepseek], [*20.0%*], [*13.3%*], [6.67%], [*0.0%*], [*26.7%*], [6.7%], [66.7%], [*0.0%*], [83.0%], [*33.3%*],
      [Gemma2], [26.7%], [26.7%], [*0.0%*], [*0.0%*], [33.3%], [*0.0%*], [*20.0%*], [6.7%], [*30.6%*], [*33.3%*],
      [Llama3.1], [33.3%], [33.3%], [6.67%], [*0.0%*], [*26.7%*], [6.7%], [46.7%], [*0.0%*], [67.3%], [53.3%],
      table.hline(stroke: (dash: "dashed")),
      [GPT-4o], [20.0%], [*6.67%*], [13.3%], [*0.0%*], [20.0%], [*0.0%*], [40.0%], [*0.0%*], [36.0%], [*6.67%*],
      [GPT-o3-mini], [*0.0%*], [13.3%], [*0.0%*], [*0.0%*], [*13.3%*], [*0.0%*], [*20.0%*], [*0.0%*], [*18.6%*], [20.0%],
    )
  },
  caption: [Percentuali di _risposte contenenti almeno un errore_, secondo le annotazioni umane ($epsilon_"hum"$) e le valutazioni automatiche ($epsilon_"4.5"$). Più basso è il valore, migliore è la qualità delle risposte.],
) <percentages-results>

/* ---

#figure(
  table(
    columns: 11,
    table.header(
      table.cell(rowspan: 2, align: center + horizon)[Modello],
      table.cell(colspan: 2, align: center)[*Incorrect*],
      table.cell(colspan: 2, align: center)[*Not Checkable*],
      table.cell(colspan: 2, align: center)[*Misleading*],
      table.cell(colspan: 2, align: center)[*Other*],
      table.cell(colspan: 2, align: center)[*Globale*],
      [$epsilon_"hum"$],
      [$epsilon_"4.5"$],
      [$epsilon_"hum"$],
      [$epsilon_"4.5"$],
      [$epsilon_"hum"$],
      [$epsilon_"4.5"$],
      [$epsilon_"hum"$],
      [$epsilon_"4.5"$],
      [$epsilon_"hum"$],
      [$epsilon_"4.5"$],
    ),
    table.hline(),
    [Deepseek-r1:8b], [*0.13*], [*0.26*], [0.07], [*0*], [0.1], [0.06], [0.53], [*0*], [0.83], [*0.33*],
    [Gemma2:9b], [0.16], [*0.26*], [*0*], [*0*], [*0.06*], [*0*], [*0.07*], [0.06], [*0.31*], [*0.33*],
    [Llama3.1:8b], [0.29], [0.47], [*0*], [*0*], [*0.07*], [0.07], [0.31], [*0*], [0.67], [0.53],
    table.hline(stroke: (dash: "dashed")),
    [GPT-4o], [0.15], [*0.07*], [0.1], [*0*], [0.02], [*0*], [*0.09*], [*0*], [0.36], [*0.07*],
    [GPT-o3-mini], [*0*], [0.2], [*0*], [*0*], [*0.01*], [*0*], [0.17], [*0*], [*0.19*], [0.2],
  ),
  caption: [Numero medio di _errori per output, per ogni categoria di errore_ e in totale, secondo le annotazioni umane ($epsilon_"hum"$) e le valutazioni automatiche ($epsilon_"4.5"$). Più basso è il valore, migliore è la qualità delle risposte.],
) <err-num-llm> */

---

#figure(
  table(
    columns: 5,
    table.header(
      [Metrica],
      table.cell(colspan: 2, align: center + horizon)[LLM Commerciale],
      table.cell(colspan: 2, align: center + horizon)[LLM Open-Weights],
    ),
    table.hline(),
    [Chiarezza], [GPT-o3-mini #h(1em)], [93%], [Deepseek-r1:8b#h(1em)], [69%],
    [Lunghezza], [GPT-o3-mini], [96%], [Deepseek-r1:8b], [78%],
    [Utilità], [GPT-o3-mini], [98%], [Deepseek-r1:8b], [82%],
    [Apprezzamento], [GPT-o3-mini], [95%], [Deepseek-r1:8b], [68%],
  ),
  caption: [Percentuali di valutazione delle risposte generate dai modelli LLM commerciali e open-weights.],
)

---

#figure(
  image("../gen_eval/diagrams/correlation_metrics.svg"),
  kind: "diag",
  caption: "Correlazione tra le metriche di valutazione delle risposte per ogni modello.",
) <corr-matrix>

= Ingegnerizzazione del sistema

== Funzionalità equivalenti

Il nuovo sistema deve offrire funzionalità equivalenti a quelle di AIML, ma con un'architettura più moderna e flessibile:

#pause

1. Riconoscimento del topic:
  - Classificazione neurale
  - NER
#pause
2. Recupero delle informazioni:
  - Script
  - Database
  - API
#pause
3. Generazione delle risposte:
  - LLM locale/remota
  - Template

== Compilatore

- Dal momento che dobbiamo lavorare con dei LLM, è necessario un sistema che effettui fine-tuning per ogni insieme di interazioni. Potremmo lasciare il fine-tuning a runtime, ma prepararlo in anticipo permette di risparmiare tempo e risorse.
- È sufficiente descrivere in modo sequenziale (pipeline) le operazioni da eseguire, e il "compilatore" si occuperà di preparere tutto il necessario

---

#figure(```json
- name: "question_intent_classifiers"
      type: classification
      steps:
        - type: load_csv
          name: data
          path: "./multitask_training/data_cleaned_manual_combined.csv"
          label_columns: ["Global Subject", "Question Intent"]
        - type: split_data
          name: split
          dataframe: data.dataframe
          on_column: "Global Subject"
          for_each:
            - type: train_model
              name: training
              dataframe: split.dataframe
              pretrained_model: "google/electra-small-discriminator"
              examples_column: "Question"
              labels_column: "Question Intent"
              resulting_model_name: "question_intent_{on_column}"
```)

---

#figure(
  image("./media/diags/compiler_classes_horiz.svg"),
  kind: "diag",
  caption: [Class Diagram raffigurante le classi e proprietà utilizzate per la compilazione.],
) <compiler_classes>

== Runner

Come per AIML, è necessario un motore di esecuzione del chatbot, che si occupi di seguire il flusso di esecuzione delle interazioni e di gestire le domande degli utenti.
#pause
- Il motore di esecuzione è un automa a stati finiti
- Il percorso di interazione è un grafo: ogni nodo codifica un'azione che il motore deve svolgere:
  - Lasciare la parola all'utente
  - Recuperare informazioni da risorse (DB, API, ecc.)
  - Generare una risposta (LLM, template, default, ecc.)
- Un insieme di nodi è definito come un _flusso_ di interazione (flow), che può essere richiamato in qualsiasi momento.
---

== Esempio di chatbot

#image("image-5.png")

---

#align(center)[
  #grid(
    columns: 2,
    image("image-6.png"), image("image-8.png"),
  )
]

= Conclusioni

== Confronto

- *Riconoscimento Intenzioni*: AIML si basa solo su pattern matching, il sistema proposto supporta sia classificatori neurali che basati su regole.
- *Gestione Contesto*: AIML usa `<topic>` in modo rigido, il nuovo sistema adotta un meccanismo di Flow più articolato, con un contesto di esecuzione completo.
- *Dati Esterni*: AIML ricorre a `<sraix>` in modo periferico, il nuovo sistema integra nativamente moduli di retrieval come componente centrale.
- *Controllo del Flusso*: AIML utilizza `<condition>` e `<srai>` in modo semplice, il nuovo sistema offre branching condizionale e passaggio dinamico tra flussi.

---

- *Approccio ibrido*: Combina dichiarativo (AIML) con la flessibilità di Python e reti neurali.
- *Scalabilità e adattabilità*: Ideale per chatbot complessi, riduce sforzo di progettazione e manutenzione.
- *Controllo totale*: Definire con precisione l'ordine delle interazioni evita limiti tipici dei LLM, come explainability ridotta, allucinazioni e jailbreaking.

== Sviluppi futuri

L'utilizzo degli step permette di avere la massima flessibilità, astraendo comunque il sistema da dettagli implementativi.

- Libreria di valutazione delle espressioni (Asteval) che consente di eseguire codice Python a runtime, garantendo grande flessibilità
- Assenza di protezioni predefinite contro codice malevolo rende necessaria una sandbox
- Servono controlli più stringenti per garantire sicurezza e stabilità

---
- YAML spinto al limite: ottimo per flow semplici, ma diventa complesso per espressioni avanzate
- Possibilità di introdurre un DSL dedicato per maggiore chiarezza e validazione

---

- Definire le configurazioni direttamente in Python abbasserebbe la barriera di ingresso per sviluppatori
- Supporto IDE (PyCharm, VS Code) migliorerebbe validazione e velocità di sviluppo
- Mantenere compatibilità YAML per utenti meno esperti

#focus-slide[
  Grazie per l'attenzione!\
  Domande?
]
