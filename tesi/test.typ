#import "@preview/cetz:0.3.1": canvas, draw
#import "@preview/cetz-plot:0.1.0": plot

#show bibliography: set heading(numbering: "1.")

// Some definitions presupposed by pandoc's typst output.
#let horizontalrule = [
  #line(start: (25%,0%), end: (75%,0%))
]

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]
#show terms: it => {
  it.children
    .map(child => [
      #strong[#child.term]
      #block(inset: (left: 1.5em, top: -0.4em))[#child.description]
      ])
    .join()
}

#set table(
  inset: 6pt,
  stroke: none
)

#show figure.where(
  kind: table
): set figure.caption(position: top)

#show figure.where(
  kind: image
): set figure.caption(position: bottom)

#let content-to-string(content) = {
  if content.has("text") {
    content.text
  } else if content.has("children") {
    content.children.map(content-to-string).join("")
  } else if content.has("body") {
    content-to-string(content.body)
  } else if content == [ ] {
    " "
  }
}
#let conf(
  title: none,
  subtitle: none,
  authors: (),
  keywords: (),
  date: datetime.today().display(),
  abstract: none,
  cols: 1,
  margin: (x: 1.25in, y: 1.25in),
  paper: "a4",
  lang: "it",
  region: "IT",
  font: (),
  fontsize: 11pt,
  sectionnumbering: none,
  doc,
) = {
  set document(
    title: title,
    author: authors.map(author => content-to-string(author.name)),
    keywords: keywords,
  )
  set page(
    paper: paper,
    margin: margin,
    numbering: "1",
  )
  set par(justify: true)
  set text(lang: lang,
           region: region,
           font: font,
           size: fontsize)
  set heading(numbering: sectionnumbering)

  if title != none {
    align(center)[#block(inset: 2em)[
      #text(weight: "bold", size: 1.5em)[#title]
      #(if subtitle != none {
        parbreak()
        text(weight: "bold", size: 1.25em)[#subtitle]
      })
    ]]
  }

  if authors != none and authors != [] {
    let count = authors.len()
    let ncols = calc.min(count, 3)
    grid(
      columns: (1fr,) * ncols,
      row-gutter: 1.5em,
      ..authors.map(author =>
          align(center)[
            #author.name \
            #author.affiliation \
            #author.email
          ]
      )
    )
  }

  if date != none {
    align(center)[#block(inset: 1em)[
      #date
    ]]
  }

  if abstract != none {
    block(inset: 2em)[
    #text(weight: "semibold")[Abstract] #h(1em) #abstract
    ]
  }

  if cols == 1 {
    doc
  } else {
    columns(cols, doc)
  }
}
#show: doc => conf(
  title: "Relazione informale lavoro svolto",
  abstract: "In questo documento cercherò di riassumere tutto il lavoro svolto finora per la tesi, oltre al lavoro che vi propongo di svolgere per poter effettivamente considerare la tesi come conclusa.",
  cols: 1,
  sectionnumbering: "1.",
  doc,
)

= Compilatore programmatico
<compilatore-programmatico>

All'inizio della tesi si era parlato di un compilatore che, forniti i dati dell'automa, fosse in grado di produrre il file AIML per le interazioni.

- Scritto in kotlin
- Utilizza un file contenente l'automa rappresentato col linguaggio graphviz
- Genera un file AIML che contiene tutte le regole e le possibili domande riguardanti l'automa

== Pro e contro
<pro-e-contro>
=== Pro
<pro>
- Facilità di utilizzo
- Velocità di esecuzione
- Linguaggio memory safe

=== Contro
<contro>
- Le regole sono molto stringenti sulla forma delle domande che possono essere fatte, e per poter permettere una corretta risposta è necessario che l'utente conosca la forma delle domande che può fare, e che le rispetti
- Non è possibile fare domande complesse
- Le risposte sono molto limitate e ripetitive

= Ricerca successiva per migliorare i contro del compilatore
<ricerca-successiva-per-migliorare-i-contro-del-compilatore>
Problemi da risolvere:

+ Le regole sono molto stringenti sulla forma delle domande che possono essere fatte
+ Le risposte sono molto limitate e ripetitive

Finora mi sono concentrato sulla generazione delle regole AIML, ma non ho ancora pensato a come migliorare le risposte. La direzione che ho preso si basa sulla costruzione di alcuni modelli fondati su reti neurali che permettano di riconoscere con maggiore flessibilità le domande poste dagli utenti.

Il piano è di dividere la gestione di una domanda (lato riconoscimento) in due step:

+ Riconoscimento dell'argomento della domanda
+ Riconoscimento dei complementi della domanda (se presenti), come il riferimento a nodi o input dell'automa o degli archi. Questi saranno poi usati per riempire degli slot.

== Modelli di reti neurali per il riconoscimento di domande
<ricerca-di-modelli-di-reti-neurali>
Prima dell'utilizzo di modelli di reti neurali ho investigato ancora sulla possibilità di utilizzare dei modelli statistici costruiti automaticamente. Questo principalmente per la velocità di esecuzione e la footprint ridotta rispetto a modelli di reti neurali. Spacy era un'opzione che ho effettivamente esplorato per un po' di tempo, tuttavia dopo aver scoperto BERT @bert ho deciso di orientarmi verso l'utilizzo di modelli di reti neurali basati sui Transformer, basandomi sulla loro promessa di prestazioni migliori rispetto ai modelli classici.

BERT è preaddestrato su un corpus di testo molto grande; esistono diverse versioni che idealmente dovrebbero essere utilizzate in base alla quantità di risorse disponibili, considerando anche il task che si vuole svolgere.

È stato essenziale un primo periodo di studio e sperimentazione con l'architettura di BERT. Durante questa prima fase ho utilizzato indicazioni per il fine tuning di modelli presenti su alcuni paper, tra cui #cite(<dont_stop_pretraining>, form: "prose")

Tuttavia in seguito ho deciso di utilizzare la libreria `Transformers` di HuggingFace @huggingface_transformers, che permette di utilizzare modelli preaddestrati e fornisce ottime API per l'addestramento, il fine tuning e in generale per l'interazione con modelli di reti neurali basati sui Transformer.

Oltre a BERT "base" ho anche utilizzato DistilBERT @distilbert, una versione distillata di BERT che riesce a mantenere buone performance con una footprint ridotta.

Durante il lavoro di ricerca mi sono concentrato sul perfezionamento anche dei parametri di fine-tuning; per questo oltre a una serie di tentativi sperimentali in autonomia, ho usato come base di partenza il lavoro di altri ricercatori @bert_fine_tuning che hanno perfezionato i parametri di fine-tuning di BERT per la classificazione di testo, per evitare problemi di overfitting e/o vanishing/exploding gradient che portano potenzialmente a catastrophic forgetting

=== Fine tuning di BERT
<fine-tuning-di-bert>
BERT è un modello preaddestrato e supervisionato, quindi per poter effettuare il fine tuning è necessario avere un dataset etichettato.

Sono partito dalle circa 200 domande prodotte durante i vari test con gli utenti svolti in precedenza.

==== Preparazione del dataset
<preparazione-del-dataset>
I dati iniziali sono una collezione delle interazioni degli utenti con il sistema quando le interazioni erano state costruite a mano. Per poter utilizzare questi dati per il fine tuning di BERT è stato necessario:

+ Estrarre tutte le domande escludendo le risposte del sistema
+ Etichettare le domande con l'argomento a cui si riferiscono

L'estrazione è stata piuttosto rapida, dopo aver scritto un semplice script python che usa pandas.

```python
import pandas as pd
from dotenv import load_dotenv

load_dotenv()

df_o = pd.read_excel('corpus/interaction-corpus.xlsx')

# filter only the rows that have "Participant" as 'U'
df = df_o[df_o['Participant'] == 'U']
df = df[['Text']]
df = df.drop_duplicates()
df = df[df['Text'].apply(lambda x: isinstance(x, str))]
df['Text'] = df['Text'].str.strip()  # Remove trailing whitespace
texts = df['Text'].dropna()

df.to_csv("./filtered_data.csv")
```

Estratte le domande, ho proceduto con l'etichettatura.

Inizialmente ho pensato di etichettare automaticamente le domande utilizzando un modello di LLM locale. Ho individuato le utilissime API fornite da Ollama @ollama, un sistema per hostare localmente modelli di LLM open.

==== Etichettatura automatica delle domande
<etichettatura-automatica-delle-domande>
Per poter automatizzare l'etichettatura usando una LLM, prima di tutto ho identificato l'insieme delle possibili etichette.

```python
LABELS: dict[str, str] = {
  "START": "Initial greetings or meta-questions, such as 'hi' or 'hello'.",
  "GEN_INFO": "General questions about the automaton that don't focus on specific components or functionalities.",
  "STATE_COUNT": "Questions asking about the number of states in the automaton.",
  "FINAL_STATE": "Questions about final states of the automaton.",
  "STATE_ID": "Questions about the identity of a particular state.",
  "TRANS_DETAIL": "General questions about the transitions within the automaton.",
  "SPEC_TRANS": "Specific questions about particular transitions or arcs between states.",
  "TRANS_BETWEEN": "Specific question about a transition between two states",
  "LOOPS": "Questions about loops or self-referencing transitions within the automaton.",
  "GRAMMAR": "Questions about the language or grammar recognized by the automaton.",
  "INPUT_QUERY": "Questions about the input or simulation of the automaton.",
  "OUTPUT_QUERY": "Questions specifically asking about the output of the automaton.",
  "IO_EXAMPLES": "Questions asking for examples of inputs and outputs.",
  "SHAPE_AUT": "Questions about the spatial or graphical representation of the automaton.",
  "OTHER": "Questions not related to the automaton or off-topic questions.",
  "ERROR_STATE": "Questions related to error states or failure conditions within the automaton.",
  "START_END_STATE": "Questions about the initial or final states of the automaton.",
  "PATTERN_RECOG": "Questions that aim to identify patterns in the automaton's structure or behavior.",
  "REPETITIVE_PAT": "Questions focusing on repetitive patterns, especially in transitions.",
  "OPT_REP": "Questions about the optimal spatial or minimal representation of the automaton.",
  "EFFICIENCY": "Questions about the efficiency or minimal representation of the automaton."
}
```

Ad ogni etichetta è associata una descrizione che aiuta a capire a cosa si riferisce, specialmente per permettere alla LLM di etichettare correttamente le domande togliendo il più possibile le ambiguità.

Per avere una maggiore sicurezza nella correttezza delle etichette, ho preferito utilizzare più modelli di LLM:

- Gemma 2 @gemma, sviluppato da Google Deep Mind
- llama 3.1 @llama3, sviluppato da Meta AI

Ogni modello ha ricevuto più prompt diversi con le stesse domande, in modo da poter poi effettuare un majority voting per stabilire l'etichetta finale.

I modelli sono stati utilizzati nelle loro varianti da 9 miliardi di parametri per gemma (intermedio) e 8 miliardi per llama3.1 (più piccolo), in seguito ad alcune veloci sperimentazioni che hanno mostrato un buon compromesso tra performance (intese come qualità dei risultati prodotti in seguito al prompting) e tempo di esecuzione.

Ho provato un ulteriore modello, Qwen @qwen, prodotto da Alibaba, ma i risultati non sono stati soddisfacenti.

Utilizzando le risorse hardware a disposizione, ho effettuato il prompting delle domande con i modelli di LLM. Segue un esempio di codice python che mostra come è stato effettuato il prompting. È inclusa una classe `Chat`, da me sviluppata, che permette di interagire con i modelli di LLM in modo più semplice, astraendo le API di ollama.

```python
from tqdm import tqdm
from chat_helper import Chat
import pandas as pd

# ollama_models = ["llama3.1:8b", "gemma:7b", "qwen:7b"]
ollama_models = ["gemma2:9b", "llama3.1:8b"]

# We are initializing a new dataframe with the same index as the original one
res_df = pd.DataFrame(index=df.index)

for model in ollama_models:
    chat = Chat(model=model)

    dataset_size = len(df)

    for p_i, prompt_version in enumerate(prompts):
        progress_bar = tqdm(
          total=dataset_size, 
          desc=f"Asking {model} with prompt {p_i}", unit="rows"
        )

        for r_i, row in df.iterrows():
            text = row["Text"]

            prompt = prompts[0].replace("{text}", text)

            inferred_label = chat.interact(
              prompt, 
              stream=True, 
              print_output=False, 
              use_in_context=False
            )
            inferred_label = inferred_label.strip().replace("'", "")

            res_df.at[r_i, f"{model} {p_i}"] = inferred_label
            progress_bar.update()

        print(progress_bar.format_dict["elapsed"])
        progress_bar.close()
```

Ecco un esempio dei risultati dell'etichettatura del bronze dataset:

#figure(
  align(center)[#table(
    columns: (0.2fr, 1fr, 1fr, 1fr, 1fr),
    align: (auto,auto,auto,auto,auto,),
    table.header([ID], [gemma2:9b], [gemma2:9b], [llama3.1:8b], [llama3.1:8b],),
    table.hline(),
    [0], [START], [START], [START], [START],
    [1], [GEN\_INFO], [GEN\_INFO], [GEN\_INFO], [GEN\_INFO],
    [2], [SPEC\_TRANS], [SPEC\_TRANS], [TRANS\_BETWEEN], [TRANS\_BETWEEN],
    [3], [SPEC\_TRANS], [SPEC\_TRANS], [TRANS\_BETWEEN], [TRANS\_BETWEEN],
    [4], [Please provide the interaction. : START], [START], [START], [START],
    […], […], […], […], […],
    [285], [OPT\_REP], [OPT\_REP], [OPT\_REP], [OPT\_REP],
    [286], [GRAMMAR], [GRAMMAR], [GRAMMAR], [GRAMMAR],
    [287], [REPETITIVE\_PAT], [REPETITIVE\_PAT], [REPETITIVE\_PAT], [REPETITIVE\_PAT],
    [288], [TRANS\_DETAIL], [TRANS\_DETAIL], [TRANS\_DETAIL], [GEN\_INFO],
    [289], [GRAMMAR], [GRAMMAR], [FINAL\_STATE], [FINAL\_STATE],
  )]
  , kind: table
  )

Combinare i risultati tramite majority voting è stato essenziale, in quanto i modelli di LLM non sono perfetti e alcune volte sono state prodotte risposte completamente estranee rispetto alle etichette fornite:

```python
from collections import Counter

def majority_vote(row: pd.Series):
    label_counts = Counter(row)
    majority_label = label_counts.most_common(1)[0][0]
    return majority_label
```

In seguito ad una prima fase di fine tuning tuttavia, ho verificato che nonostante un'etichettatura valida, le classi identificate erano troppo sbilanciate, con alcune classi che contenevano pochissimi esempi. In più, le etichette erano troppo generiche e non permettevano di identificare con precisione l'argomento della domanda.

Per questo motivo ho proceduto con una revisione delle etichette, e una successiva etichettatura manuale delle domande.

==== Nuove classi e etichettatura manuale
<nuove-classi-e-etichettatura-manuale>
Prima di tutto ho effettuato una ulteriore passata di revisione delle domande, escludendo quelle non pertinenti o incomprensibili. Durante questa fase ho compreso che non sarebbe stato sufficiente utilizzare un solo "livello" di etichette, ma che sarebbe stato più efficace utilizzare un sistema di etichettatura gerarchico, in modo da poter identificare con maggiore precisione l'argomento della domanda, riducendo il numero di classi da distinguere.

Le classi principali, che rappresentano l'argomento generale della domanda, sono state ridotte a 7:

#figure(
  align(center)[#table(
    columns: (0.3fr, 1fr, 0.4fr),
    align: (auto,auto,auto,),
    table.header([Classe], [Descrizione], [Numero di Esempi],),
    table.hline(),
    [#strong[transition];], [Domande che riguardano le transizioni tra gli stati], [77],
    [#strong[automaton];], [Domande che riguardano l'automa in generale], [48],
    [#strong[state];], [Domande che riguardano gli stati dell'automa], [48],
    [#strong[grammar];], [Domande che riguardano la grammatica riconosciuta dall'automa], [33],
    [#strong[theory];], [Domande di teoria generale sugli automi], [15],
    [#strong[start];], [Domande che avviano l'interazione con il sistema], [6],
    [#strong[off\_topic];], [Domande non pertinenti al dominio che il sistema deve saper gestire], [2],
  )]
  , kind: table
  )

Avendo solo 7 classi principali di domande, considerato il numero ristretto di esempi, è stato possibile suddividerli senza ottenere un numero enorme di classi che si dividono tra di loro pochi esempi.

Le classi secondarie, che rappresentano l'argomento specifico della domanda dipendono dalla classe principale. Per questo motivo il loro numero è variabile, ma in totale si tratta di 33 classi
(#{
  let classes = (
    ("count", 29),
    ("existence_from", 18),
    ("list", 17),
    ("description", 16),
    ("accepted", 14),
    ("representation", 13),
    ("existence_between", 12),
    ("transitions", 12),
    ("description_brief", 10),
    ("pattern", 10),
    ("existence_directed", 9),
    ("start", 8),
    ("final", 8),
    ("symbols", 7),
    ("off_topic", 6),
    ("cycles", 4),
    ("label", 4),
    ("example_input", 4),
    ("final_list", 3),
    ("states", 3),
    ("generic", 3),
    ("variation", 2),
    ("greet", 2),
    ("final_count", 2),
    ("validity", 2),
    ("simulation", 2),
    ("regex", 2),
    ("definition", 2),
    ("input", 1),
    ("existence_into", 1),
    ("directionality", 1),
    ("details", 1),
    ("self_loop", 1),
  )

  [#classes.map(c => [#text(hyphenate: false)[#strong[#c.at(0)];: #c.at(1)]]).join([, ])]
}).

Dal momento che le classi secondarie sono dipendenti dalle classi principali, ho deciso di etichettare prima le classi principali e poi le classi secondarie.

Dal momento che il numero di esempi è piuttosto ridotto (229), e inoltre le classi sono sbilanciate, ho deciso di arricchire i dati con ulteriori domande generate automaticamente e manualmente. Ho aggiunto un totale di 525 domande, con la seguente distribuzione:

#figure(
  align(center)[#table(
    columns: 2,
    align: (auto,auto),
    table.header([Classe], [Numero di esempi aggiuntivi],),
    table.hline(),
    [#strong[transition]], [148],
    [#strong[automaton]], [93],
    [#strong[state]], [56],
    [#strong[grammar]], [111],
    [#strong[theory]], [100],
    [#strong[start]], [17],
  )], kind: table
)

Le domande off-topic aggiuntive (un centinaio) sono state estratte dal dataset SQUAD #footnote[Stanford Question Answering Dataset] v2 @squad1 @squad2, per avere una sufficiente varietà di domande non pertinenti.

Anche le classi secondarie hanno ricevuto alcune migliorie alla distribuzione, che tuttavia è ancora da migliorare: 
(#{
  let classes = (
    ("description",74),
    ("accepted",57),
    ("existence_from",42),
    ("count",40),
    ("generic",39),
    ("list",38),
    ("label",36),
    ("transitions",34),
    ("pattern",27),
    ("existence_between",25),
    ("existence_directed",21),
    ("final",21),
    ("simulation",20),
    ("variation",19),
    ("greet",19),
    ("representation",19),
    ("states",18),
    ("existence_into",17),
    ("definition",16),
    ("description_brief",16),
    ("start",15),
    ("symbols",14),
    ("validity",14),
    ("cycles",12),
    ("details",12),
    ("input",12),
    ("self_loop",11),
    ("example_input",11),
    ("regex",9),
    ("final_count",8),
    ("off_topic",6),
    ("final_list",6),
    ("optimization",6),
    ("deterministic",5),
    ("reachability",5),
    ("start_final",3),
    ("dead",3),
    ("directionality",2),
    ("image",2)
  )

  [#classes.map(c => [#text(hyphenate: false)[#strong[#c.at(0)];: #c.at(1)]]).join([, ])]
}).

Con la nuova distribuzione, più uniforme, è possibile ottenere dei buoni risultati nel training.

L'utilizzo del dataset SQUAD ha anche introdotto un'ulteriore incremento delle performance, portando a una drastica diminuzione della classificazione di esempi OT come domande lecite.

==== Training

Senza addentrarmi troppo nei dettagli per il momento, ho provato due metodi per effettuare il fine-tuning, dal momento che non si tratta di una semplice classificazione multiclasse:
- *multitask training* @multitask, dove invece di avere un solo layer finale di classificazione posto in cima al transformer pre-trainato di BERT ne sono presenti due posizionati in parallelo
- *hierarchical training* @hierarchical, dove si utilizza una tecnica (di tante varianti possibili) in cui si procede nella classificazione delle etichette "a step".

==== Risultati

In seguito al training, è risultato che il modello gerarchico permette di ottenere un maggiore F1-Score, che misura la precisione e il recall del modello. Il modello multitask ha ottenuto un F1-Score dell'86.9% sul topic primario e del 64.1% sul topic secondario, mentre il modello gerarchico ha ottenuto un F1-Score del 90.6% per il topic primario e una media del 75.1% per il topic secondario.

#figure(
  canvas({
    import draw: *

    let f1_main = csv("media/csv/f1_main.csv")
    let data = f1_main.slice(1).map(el => (int(el.at(1))/2, float(el.at(4))))

    plot.plot(
      size: (12,8), 
      x-tick-step: 1, y-tick-step: 0.1, 
      y-max:1, 
      x-label: "Training Epoch", 
      y-label: "F1 Score",{
      plot.add(data)
    })
  }),
  caption: [F1 Score sul topic primario],
  kind: "plot",
  supplement: [Grafico]
)

#figure(
  canvas({
    import draw: *

    let f1_main = csv("media/csv/f1_sub.csv")
    let data = f1_main.slice(1).map(el => (int(el.at(1))/2, float(el.at(4))))

    plot.plot(
      size: (12,8), 
      x-tick-step: 1, y-tick-step: 0.1, 
      y-max:1, 
      x-label: "Training Epoch", 
      y-label: "F1 Score",{
      plot.add(data)
    })
  }),
  caption: [F1 Score sul topic secondario],
  kind: "plot",
  supplement: [Grafico]
)

#figure(
  canvas({
    import draw: *

    let f1_main = csv("media/csv/f1_hierarchical.csv")
    let data = f1_main.slice(1).map(el => (int(el.at(1))/2, float(el.at(4))))

    plot.plot(
      size: (12,8), 
      x-tick-step: 1, y-tick-step: 0.1, 
      y-max:1, 
      x-label: "Training Epoch", 
      y-label: "F1 Score",{
      plot.add(data)
    })
  }),
  caption: [F1 Score sul modello gerarchico],
  kind: "plot",
  supplement: [Grafico]
)

È possibile che il modello gerarchico sia più performante perchè isola i soli esempi che riguardano il topic secondario, permettendo di ottenere una maggiore precisione e recall.

=== Ulteriori ricerche da effettuare

Attualmente ho parlato con un mio amico del Politecnico, che mi ha suggerito di esplorare anche la via della classificazione mediante l'uso diretto degli embeddings prodotti da BERT, senza dover effettuare il fine-tuning. Questo potrebbe essere un'opzione interessante da esplorare, dal momento che permetterebbe di ottenere delle risposte più veloci e con il vantaggio di poter utilizzare anche un modello più grosso (con un numero maggiore di parametri) per ottenere una maggiore accuratezza, senza doverne effettuare il fine-tuning.

== Riconoscimento dei complementi della domanda

Per alcuni dei generi di domande sono presenti anche degli elementi che dobbiamo saper estrarre per poter effettivamente rispondere ai quesiti degli utenti. Naturalmente possono essere di vario tipo, come ad esempio il riferimento a nodi o input dell'automa o degli archi.

Ho quindi effettuato ricerche per il training di modelli per la NER. Esistono modelli addestrabili basati sui transformers anche in questo caso, ma Spacy si è rivelata particolarmente efficace per questo task.

Ho etichettato manualmente le domande con Doccano @doccano, un tool open source per l'annotazione di testo. In seguito ho utilizzato Spacy per effettuare il training del modello NER.

Le performance sono soddisfacenti ed effettivamente il modello riesce a riconoscere con una buona precisione le entità di interesse.

= Proposte
<proposte>
Il compilatore inizialmente doveva produrre soltanto un file AIML, con le interazioni e i dati già previsti e fissati nella pietra. Tuttavia, a parer mio, questo genere di approccio risulta poco flessibile e prono a produrre grosse quantità di dati ridondanti. Naturalmente è possibile anche utilizzare regole annidate e simili per mitigare queste problematiche, ma in un mondo dove oggi siamo in grado di interagire con una LLM, credo che bisogni cercare di puntare a proporre un "AIML" più adatto a quello che oggi ci si aspetta da un motore di chat e interrogazioni.

In più, utilizzare le regole in modo ricorsivo può portare a maggiore confusione e difficoltà nella comprensione di come le regole sono correlate tra di loro.

La difficoltà di ideare, mantenere e aggiornare le regole probabilmente in assoluto è il punto più problematico e importante da risolvere.

Integrare i dati nel file AIML si potrebbe anche rivelare problematico, dovendo introdurre variazioni non indifferenti alla struttura del formato.

Per questo motivo inizialmente ho dedicato tutto il tempo alla ricerca di tecniche efficaci per il riconoscimento dei quesiti dell'utente, finito con l'utilizzo di BERT dopo fine-tuning. Allo stesso modo, per identificare i soggetti di una domanda, il NER dovrebbe essere sufficiente.

Detto questo, vorrei proporre un nuovo genere di sistema, di cui il compilatore è solo una parte. Nello specifico, si tratta di una pipeline che integra diversi step, partendo da un compilatore e finendo in un motore di esecuzione per il question answering su topic ristretti e specifici.

== Cosa fa il compilatore
<cosa-fa-il-compilatore>
Il compilatore invece di dover costruire un file AIML in output, lavora su più stadi, e necessita di una configurazione più approfondita.

Nello specifico, richiede i seguenti dati:

+ Per ogni genere (classe) di domanda possibile nel dominio da analizzare, devono essere forniti i dataset di domande che possano essere usati per comporre i dati con cui viene effettuato il fine-tuning di BERT.
+ Come per le classi di domande, ogni genere di Named Entity potenzialmente richiesta deve essere compresa in un dataset taggato per addestrare un modello che si occupi di NER.
+ Infine, non possono mancare anche i dati effettivi sui quali deve essere costruita una piccola knowledge base. Dato che ogni classe può richiedere informazioni diverse dalla knowledge base, possono essere utili delle regole per recuperare i dati relativi alla domanda appena posta. La regola può essere espressa in JSONPath @jsonpath o JMESPath @jmespath o un altro linguaggio di query da decidere (un'opzione decisamente più complessa può essere ad esempio SPARQL @sparql, proveniente dal dominio del web semantico). Questo potrebbe anche lasciare spazio alla possibilità di interrogare risorse esterne per ottenere informazioni aggiornate.

Non tutto deve essere per forza implementato nel corso di questa parte della tesi (specialmente quello che riguarda la flessibilità per interrogazioni della KB che esulano dal dominio degli automi), tuttavia vorrei comunque lasciare sufficiente flessibilità e estensibilità nel sistema da permettere aggiunte indolori.

Il risultato è un insieme di file che contengono tutto il necessario per permettere al motore di interrogazione di reagire alle domande degli utenti, e di estrarre le informazioni necessarie per rispondere.

=== Componenti della configurazione

Il file di configurazione JSON deve contenere le seguenti informazioni:

+ Una sezione riguardante il training, che include:
  - I dati relativi all'automa, che verranno estratti per costruire la knowledge base. Ipoteticamente i dati possono essere forniti in vari formati; dovrebbe essere piuttosto facile supportare formati come Graphviz  Dot @graphviz, JSON o XML.
  - Il/I dataset di interazioni, che contengono le domande che l'utente può fare, già etichettati per classe di domanda. Possono essere presenti gerarchie di classi di domande, in modo da poter avere una maggiore flessibilità.
  - Il/I dataset di NER, che contengono le domande etichettate con le entità che si vogliono poter estrarre.
  ```json
  "training": {
    "domain_data": {
      "type": "automaton",
      "data": "path_to_automaton.dot"
    },
    "interactions": {
      "type": "dataset",
      "data": "path_to_interactions_dataset.csv"
    },
    "ner": {
      "type": "dataset",
      "data": "path_to_ner_dataset.csv"
    },
  }
  ```
+ Le classi di interazione, che contengono le regole per rispondere alle domande.\ 
  Ogni possibile interazione deve indicare:
    - Una descrizione (utile a fini di documentazione): `description`
    - Un'etichetta per la classe dei dati usati nel training che riguardano l'interazione: `label`
    - Una lista di possibili slot da riempire: `slots`. Ogni slot ha alcuni dettagli:
      - Un nome: `name`. Questo corrisponde al nome dell'entità che si vuole estrarre dalla domanda basandoci sul modello di NER addestrato
      - Una descrizione: `description`
      - Un'indicazione se è opzionale: `optional`
    - Una lista di possibili risposte, che possono contenere dei placeholder per i dati estratti: `answers`.\
      Queste risposte possono essere scritte in un linguaggio di templating, come ad esempio Handlebars @handlebars, oppure possono essere indicate anche delle configurazioni più complesse che permettono di fornire il necessario ad una LLM per generare una risposta più complessa usando i dati estratti (o anche da una memoria interna).
    - Una query per estrarre i dati dalla knowledge base che verranno usati per la risposta: `query`.\
      Questa query può essere espressa in JSONPath o JMESPath (o altri linguaggi che potrebbero essere identificati come più adatti).
    - Una lista di sottoclassi, `subclasses`, che contengono le stesse informazioni di una classe di interazione. Questo permette di creare una gerarchia di classi di interazione, in modo da poter avere una maggiore flessibilità.\
      Se una classe contiene delle sottoclassi, questa non può avere una query associata, e le risposte devono essere generate dalle sottoclassi. Ipoteticamente si potrebbe pensare anche di avere più risposte da più sottoclassi se queste matchano, oppure informare l'utente che il sistema ha compreso la domanda ma che non è in grado di rispondere (e magari suggerire delle domande più specifiche).
  Ecco come potrebbe essere strutturata la sezione delle classi di interazione, per lasciare un esempio concreto: 
  ```json
  "interaction_classes": {
    "InizioConversazione": {
      "label": "start",
      "description": "Gestisce i saluti iniziali dell'utente.",
      "answer": [
        "Ciao! Come posso aiutarti oggi?",
        "Salve! Sono qui per rispondere alle tue domande."
      ]
    },
    "DomandaStatoAutoma": {
      "label": "state",
      "description": "Richieste di informazioni riguardo gli stati dell'automa",
      "subclasses": {
        "StatoStart": {
          "label": "start",
          "description": "Dettagli sugli stati di start",
          "slots": [
            {
              "optional": true
              "name": "state"
            }
          ],
          "query": "$.automaton.states[?(@.type=='start')]",
          "answers": [
            "L'automa ha ${res.length} stati di start: ${res.map(s => s.name).join(', ')}",
            "Gli stati di start dell'automa sono: ${res.map(s => s.name).join(', ')}"
          ]
        },
        "InformazioniOrdine": {
          "descrizione": "Domande riguardanti lo stato di un ordine.",
          "sottoclassi": {},
          "slot": ["numero_ordine"],
          "query": "$.ordini[?(@.numero=='${numero_ordine}')]",
          "risposte": [
            "Lo stato del tuo ordine ${numero_ordine} è: ${risultato.stato}",
            "L'ordine ${numero_ordine} è attualmente: ${risultato.stato}"
          ]
        }
      }
    }
  }
  ```

Naturalmente questa è solo una proposta, e il formato del file di configurazione può essere modificato in base alle esigenze. Per iniziare a costruire il sistema, si potrebbe partire con un formato più semplice e poi aggiungere funzionalità più complesse in funzione di quello che vediamo che è necessario per lavorare nel dominio degli automi.

== Cosa fa il motore di interrogazione

Il motore di interrogazione è il componente che si occupa di ricevere le domande degli utenti e di rispondere in base alle regole definite nel file di configurazione.

Dovrebbe tenere traccia dello stato della conversazione, come AIML già fa utilizzando la memoria e comandi come `<think>`.

Verrebbe costruito in python, avendo bisogno di interagire con il modello di BERT per il riconoscimento delle domande e con Spacy per il riconoscimento delle entità.

L'idea sarebbe di implementarlo come una serie di moduli o una libreria, in modo da poterlo poi integrare separatamente in tanti potenziali sistemi diversi (come ad esempio un bot Telegram, un'interfaccia web, un'applicazione mobile, ecc.).

Per il nostro caso, ad esempio potrebbe essere integrato in una API scritta con FastAPI @fastapi, che permette di costruire API RESTful in modo molto semplice e veloce.

Ritengo che spostarci da AIML a qualcosa di costruito apposta permetterebbe di ottenere un sistema più flessibile e più adatto ai tempi attuali, e darebbe anche una risposta ad alcuni dubbi che erano sorti durante le varie volte che ci siamo confrontati in riunione, come l'integrazione delle LLM, la flessibilità delle regole, la gestione delle variabili quali la conoscenza e le competenze dell'utente o la memoria del sistema.

#pagebreak(weak: true)

/*

Appunti per ragionare su come costruire l'indice della tesi.
Il progetto con cui ho lavorato (NovaGraphS) del Dipartimento di Informatica puntava a produrre un sistema assistivo per permettere l'interrogazione di automi finiti. Il progetto puntava ad utilizzare l'AIML, un linguaggio di markup per la costruzione di chatbot.

Il mio lavoro inizialmente è consistito nel ricercare la possibilità di costruire un "compilatore" che, a partire dai dati dell'automa, fosse in grado di produrre un file AIML che permettesse di rispondere alle domande degli utenti.

In seguito ad una prima implementazione, sono venute alla luce alcune criticità, che hanno evidenziato come AIML potesse limitare la flessibilità del sistema:
- Ogni interazione prevista deve essere codificata tramite regole, che possono diventare molto complesse, specialmente se si vuole costruire un sistema sufficientemente flessibile nel riconoscimento delle domande (che possono essere poste in modi diversi)
- La manutenzione delle regole può rapidamente diventare molto complessa, specialmente se non si adottano sufficienti buone pratiche per la loro scrittura e organizzazione
- Integrare i dati con le regole può essere problematico, specialmente se si vuole costruire un sistema che possa essere interrogato su diversi automi. Dover costruire regole per ogni possibile automa può diventare molto complesso e ridondante. Inoltre, AIML non permette di interrogare direttamente una knowledge base, ma richiede di costruire regole per ogni possibile interrogazione.

Dopo aver riconosciuto le criticità, abbiamo ragionato su come avremmo potuto mitigarle, migliorando il sistema rendendolo più flessibile e adatto ai tempi attuali.

Il mio lavoro si è quindi spostato verso la ricerca sul Natural Language Understanding.

Inizialmente abbiamo supposto di estendere AIML con un sistema di NLU: si sarebbe basato potenzialmente su uno tra:
- Spacy
  - Pattern Sintattici su alberi (documentazione spacy)
  - DRS per semantica (articolo Bos)
- ExpReg Estese
  - Distanza tra la stringa in input e l'espressione regolare (cercare documentazione).
- BertScore

Durante lo studio ho anche individuato Bert come opzione; vedendo che era possibile effettuare il fine-tuning di un modello di Bert per la classificazione di domande, ho deciso di provare questa strada.
Nel mentre, valutando come estendere il sistema per integrare una knowledge base, ho visto che AIML forniva effettivamente alcuni tag per interagire con sistemi esterni, ma il lavoro sarebbe stato doppio:
non solo avremmo dovuto prima scrivere le regole per individuare la domanda, ma poi avremmo dovuto preparare un sistema aggiuntivo in grado di recuperare i dati dalla knowledge base basandoci su quello che ci viene chiesto (non banale) e poi integrare i dati nella risposta.

Quindi ho iniziato ad investigare possibili vie alternative, e ho deciso di progettare un sistema alternativo all'AIML, con un linguaggio di configurazione più "moderno" che permetta di compiere le stesse operazioni in modo più flessibile e meno ridondante.

Ho effettuato ricerche sulle tecniche di NLU, vedendo cosa attualmente è più utilizzato (maggiore supporto e in genere un maggiore sviluppo nel tempo), tenendo in considerazione anche i limiti hardware a disposizione (potenzialmente in futuro la parte di sistema utilizzata dall'utente potrebbe essere fatta girare in locale).

Dopo aver sperimentato con diverse librerie che assistono nell'addestramento di modelli neurali (più flessibili rispetto alle espressioni regolari o simili) mi sono soffermato su
- Modelli di LLM basati su transformers, in particolare BERT
- Modelli di NER, addestrati utilizzando la libreria Spacy, perfetta per questo genere di task

Idealmente tuttavia il sistema dovrebbe essere sufficientemente flessibile da permettere di integrare diversi modelli di NLU, in modo da poter sfruttare le potenzialità di ognuno.

Naturalmente è sempre presente un file di configurazione, che però descrive come è strutturata la parte di costruzione dei modelli poi utilizzati per la NLU.

Quindi il sistema è composto da due parti:
- un compilatore, che addestra il necessario per la NLU, prepara risorse, ecc.
- un "runner" che effettivamente si occupa di ricevere le domande e rispondere in base alle regole definite nel file di configurazione

Una volta preparate tutte le risorse, il "pacchetto" di risorse viene passato al runner.
Il runner si basa anche lui su una sequenza annidata di nodi che utilizzano i modelli addestrati come classificatori per identificare le categorie delle domande, e man mano che si procede in profondità si estraggono le entità necessarie per rispondere alla domanda.
La struttura è come quella di un albero di decisione, dove però ogni nodo è un classificatore (neurale, tradizionale, espressione regolare, ecc), mentre le foglie sono oggetti che descrivono come costruire le risposte.
In particolare, queste possono essere predefinite, possono avere slot (riempiti in seguito ad uno step di estrazione delle entità), possono richiedere l'estrazione di dati da una knowledge base, ecc.
Le risposte sono anche generabili utilizzando servizi di LLM (Question Answering) o simili, in modo da poter ottenere risposte più complesse e flessibili, sempre solo basandoci sui dati estratti.

Le regole servono proprio perchè così riduciamo al minimo il rischio che il sistema possa rispondere in modo errato (se invece avessimo utilizzato direttamente una LLM a cui sono stati dati in pasto tutti i dati dell'automa, per esempio, portando ad allucinazioni del modello).
In questo modo possiamo avere pieno controllo su cosa il chatbot può rispondere (rimane così on-topic), e possiamo anche permettere all'utente di fare domande più complesse, che richiedono l'estrazione di più entità e la generazione di risposte più complesse.

*/

= Introduzione tesi post 

#pagebreak(weak: true)

#bibliography("bib.yml", full: true)