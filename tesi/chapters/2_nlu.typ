#import "@preview/cetz:0.3.2": canvas, draw, palette
#import "@preview/cetz-plot:0.1.1": chart
#import draw: rect, content

#let mono(body, font: "JetBrains Mono NL") = {
  text(upper(body), font: font, size: 10pt)
}

#let tdd(date) = {
  [#sym.quote.r.single#date]
}

#let hrule() = align(center, line(length: 60%, stroke: silver))

= Natural Language Understanding // Spiegazione di cosa si tratta

(introduzione all'argomento)

== Come AIML gestisce la comprensione // Collegamento a come AIML gestisce la comprensione

Negli anni #tdd(90) iniziò a guadagnare popolarità il Loebner Prize @loebner, una competizione ispirata al Test di Turing @imitation_game.\
Nella competizione, chatbot e sistemi conversazionali cercavano di "ingannare" giudici umani, facendo credere loro di essere persone reali.
Molti sistemi presentati alla competizione erano basati su pattern matching e rule-based, a volte integrando euristiche per la gestione di sinonimi o correzione ortografica.

Tra questi, uno dei più celebri è _ALICE_ (Artificial Linguistic Internet Computer Entity), sviluppato da Richard Wallace utilizzando il linguaggio di markup AIML (Artificial Intelligence Markup Language) da lui introdotto @aiml @alice.\
ALICE vinse per la prima volta il Loebner Prize nel 2000, e in seguito vinse altre due edizioni, nel 2001 e 2004.

=== Struttura di un chatbot AIML

Basato sull'XML @aiml, di base l'AIML fornisce una struttura formale per definire regole di conversazione attraverso *categorie* di _pattern_ e _template_:
- `<pattern>`: la frase (o le frasi) attese in input a cui il chatbot deve reagire;
- `<template>`: la risposta (testuale o con elementi dinamici) che il chatbot fornisce quando si verifica il match del pattern.

La forma più semplice di categoria è:
#figure(
  ```xml
  <category>
    <pattern>CIAO</pattern>
    <template>Ciao! Come posso aiutarti oggi?</template>
  </category>
  ```,
  kind: "snip",
  caption: [Esempio basilare di una categoria AIML.],
)

In questo caso, se l'utente scrive "Ciao" #footnote[Caratteri maiuscoli e minuscoli sono considerati uguali dal motore di riconoscimento.], il sistema restituisce la risposta associata nella sezione del `<template>`.\ \
Naturalmente questa è una regola basilare: AIML permette di definire pattern molto più complessi.\
Un primo passo verso la creazione di regole più flessibili è l'uso di wildcard: associando simboli quali #sym.ast e #sym.dash.en a elementi di personalizzazione (`<star/>`), il motore che esegue la configurazione AIML può gestire un certo grado di variabilità linguistica.

In particolare, il simbolo `*` corrisponde a una wildcard che cattura qualsiasi sequenza di parole in input tra i due pattern specificati.\
In questo caso, se l'utente digita "Mi chiamo Andrea", il sistema sostituisce `<star/>` con "Andrea", e risponde di conseguenza.

#figure(
  ```xml
  <category>
    <pattern>MI CHIAMO *</pattern>
    <template>
      Ciao <star/>, piacere di conoscerti!
    </template>
  </category>
  ```,
  kind: "snip",
  caption: [Esempio di utilizzo di wildcard in AIML.],
)

#hrule()

Spesso è necessario memorizzare informazioni fornite dall'utente per utilizzarle successivamente. A questo scopo, AIML offre i tag `<set>` e `<get>` che, rispettivamente, memorizzano e recuperano valori da variabili di contesto:

#figure(
  ```xml
  <category>
    <pattern>IL MIO COLORE PREFERITO È *</pattern>
    <template>
      <think>
        <set name="colore"><star/></set>
      </think>
      Ok, ricorderò che il tuo colore preferito è <star/>.
    </template>
  </category>

  <category>
    <pattern>QUAL È IL MIO COLORE PREFERITO</pattern>
    <template>
      Il tuo colore preferito è <get name="colore"/>.
    </template>
  </category>
  ```,
  kind: "snip",
  caption: [Esempio di utilizzo dei tag `<set>` e `<get>` in AIML.],
)

Nella prima `<category>`, il tag `<think>` fa sì che l'operazione di memorizzazione non produca output testuale per l'utente, ma aggiorni internamente la variabile `colore`.\
Nel secondo blocco, si utilizza `<get name="colore"/>` per restituire all'utente il valore memorizzato.

#hrule()

Il tag `<condition>` permette di definire regole condizionali in base a variabili di contesto.\

Se la variabile stagione (presumibilmente impostata altrove con un `<set>`) ha valore `inverno`, verrà restituito “Fa piuttosto freddo...”. Un risultato simile si ottiene per `estate`, mentre per altri valori o mancanza di valore si restituisce l'ultimo _list item_.

#figure(
  ```xml
  <category>
    <pattern>CHE TEMPO FA</pattern>
    <template>
      <condition name="stagione">
        <li value="inverno">Fa piuttosto freddo, in questa stagione.</li>
        <li value="estate">Fa molto caldo, bevi tanta acqua!</li>
        <li>Non saprei, forse è primavera o autunno?</li>
      </condition>
    </template>
  </category>
  ```,
  kind: "snip",
  caption: [Esempio di utilizzo del tag `<condition>` in AIML.],
)

// #hrule()

Il tag `<topic>` permette di raggruppare categorie che appartengono a un medesimo ambito di conversazione, per _facilitare la lettura_ delle regole:

#figure(
  ```xml
  <topic name="saluti">
    <category>
      <pattern>CIAO</pattern>
      <template>
        Ciao, piacere di vederti!
      </template>
    </category>

    <category>
      <pattern>COME STAI</pattern>
      <template>
        Sto bene, grazie! E tu come stai?
      </template>
    </category>
  </topic>
  ```,
  kind: "snip",
  caption: [Esempio di utilizzo del tag `<topic>` in AIML.],
)

In questo modo le regole legate ai saluti sono tutte contenute all'interno di un blocco `<topic>` chiamato `saluti`.

#hrule()

Il tag `<srai>`#footnote[Stimulus-Response Artificial Intelligence @aiml] permette di reindirizzare l'input ad un'altra regola, che verrà processata come se fosse stata digitata dall'utente. È molto utile per riutilizzare risposte o logiche già definite:

#figure(
  ```xml
  <topic name="saluti">
    <category>
      <pattern>SALUTA *</pattern>
      <template>
        <srai>CIAO</srai>
      </template>
    </category>
  </topic>
  ```,
  kind: "snip",
  caption: [Esempio di utilizzo del tag `<srai>` in AIML.],
)

Se l'utente scrive "Saluta Andrea", la regola cattura "SALUTA \*" e reindirizza il contenuto (in questo caso “CIAO”) a un'altra categoria.
Se esiste una categoria che gestisce il pattern “CIAO”, verrà attivata la relativa risposta.

Esiste anche una versione contratta di `<srai>` chiamata `<sr>`, che è stata prevista come scorciatoia quando è necessario matchare un solo pattern. Secondo la documentazione, il tag corrisponde a `<srai><star/></srai>`.

#hrule()

Abbiamo già visto `<think>` in azione per evitare che il contenuto venga mostrato all'utente.
In generale, `<think>` è utile quando vogliamo impostare o manipolare variabili senza generare output visibile, ad esempio:

#figure(
  ```xml
  <category>
    <pattern>ADESSO È *</pattern>
    <template>
      <think><set name="stagione"><star/></set></think>
      Grazie, ora so che la stagione attuale è <star/>!
    </template>
  </category>
  ```,
  kind: "snip",
  caption: [Esempio di utilizzo del tag `<think>` in AIML.],
)

// #hrule()

Il tag `<that>` permette di scrivere pattern che dipendono dalla risposta precedentemente fornita dal chatbot. È particolarmente utile per gestire contesti conversazionali più complessi:

#figure(
  ```xml
  <category>
    <pattern>SI</pattern>
    <that>VA TUTTO BENE</that>
    <template>Felice di averti aiutato!</template>
  </category>
  ```,
  kind: "snip",
  caption: [Esempio di utilizzo del tag `<that>` in AIML.],
)

In questo caso la regola sarà attivata se la risposta precedente del bot era “VA TUTTO BENE” e l'utente risponde in modo affermativo.


#hrule()

Per rendere la conversazione più naturale, AIML 2.0 fornisce `<random>`, che permette di restituire una risposta fra più alternative:

#figure(
  ```xml
  <category>
    <pattern>COME VA</pattern>
    <template>
      <random>
        <li>Benissimo, grazie!</li>
        <li>Abbastanza bene, e tu?</li>
        <li>Non c'è male, e tu come stai?</li>
      </random>
    </template>
  </category>
  ```,
  kind: "snip",
  caption: [Esempio di utilizzo del tag `<random>` in AIML.],
)

Ogni volta che l'utente scrive “Come va”, il bot sceglierà casualmente una delle tre risposte elencate.

#hrule()

Alcune versioni di AIML supportano `<learn>`, che consente al bot di aggiungere nuove categorie “al volo” durante l'esecuzione:

#{
  show figure.where(kind: "snip"): set block(breakable: true)
  figure(
    ```xml
    <category>
      <pattern>TI INSEGNO *</pattern>
      <template>
        <think>
          <learn>
            <![CDATA[
              <category>
                <pattern><star/></pattern>
                <template>Ho imparato a rispondere a "<star/>"!</template>
              </category>
            ]]>
          </learn>
        </think>
        Ho imparato una nuova regola!
      </template>
    </category>
    ```,
    kind: "snip",
    caption: [Esempio di utilizzo del tag `<learn>` in AIML.],
  )
}

=== Criticità e limiti di AIML

Grazie ai tag previsti dallo schema, AIML riesce a gestire conversazioni piuttosto complesse. Ciononostante, presenta comunque alcune limitazioni:

- Le strategie di wildcard e pattern matching restano prevalentemente letterali, con limitata capacità di interpretare varianti linguistiche non codificate nelle regole.\
  Se una frase si discosta dal pattern previsto, il sistema fallisce il matching.
  Sono disponibili comunque alcune funzionalità per la gestione di sinonimi, semplificazione delle locuzioni e correzione ortografica (da comporre e aggiornare manualmente) che possono mitigare alcuni di questi problemi.
- La gestione del contesto (via `<that>, <topic>`, `<star>`, ecc.) è rudimentale, soprattutto se paragonata a sistemi moderni di NLU con modelli neurali che apprendono contesti ampi e riescono a tenere traccia di dettagli dal passato della conversazione.
- L'integrazione con basi di conoscenza esterne (KB, database, API) richiede estensioni o script sviluppati ad-hoc, poiché AIML di per sé non offre costrutti semantici o query integrate, e non permette di integrare script internamente alle regole @aiml.
- Le risposte generate sono statiche e predefinite, e non possono essere generate dinamicamente in base a dati esterni o a contesti più ampi in modo automatico (come invece avviene con LLM e modelli di generazione di linguaggio).

Nonostante questi limiti, AIML ha rappresentato un passo importante nell'evoluzione dei chatbot, offrendo un framework standardizzato e relativamente user-friendly per la creazione di agenti rule-based @alice.\
In alcuni ambiti ristretti (FAQ, conversazioni scriptate, assistenti vocali), costituisce ancora una soluzione valida e immediata.
In domini più complessi, in cui la varietà del linguaggio e l'integrazione con dati dinamici sono essenziali, diventa indispensabile affiancare o sostituire AIML con tecniche di Natural Language Understanding basate su machine learning e deep learning.

Nelle sezioni successive sarà mostrato il percorso seguito per cercare di migliorare la comprensione degli input dell'utente, integrando tecniche di NLU basate su modelli di linguaggio neurali, e valutando le performance ottenute rispetto ad AIML.

== Classificazione con LLM // Introduzione alla classificazione di intenti

Come detto poco sopra, uno dei limiti di AIML è la gestione limitata di varianti linguistiche e contesti conversazionali.

Per permettere all'AIML di generalizzare sulle richieste degli utenti, il botmaster #footnote[Lo sviluppatore delle regole AIML per un certo progetto] deve dichiarare delle generalizzazioni esplicite, ad esempio utilizzando wildcard o pattern che catturano più varianti di una stessa richiesta.
Questo processo richiede tempo e competenze linguistiche, oltre ad una grande attenzione per evitare ambiguità o sovrapposizioni tra regole.

Durante il mio percorso di ricerca ho deciso di seguire una strada simile a quella di AIML, ma facendo un passo indietro e ponendomi la domanda:

#quote()[
  Invece che cercare dei pattern nelle possibili richieste degli utenti, perchè non trovare un modello che possa generalizzare su queste richieste in modo automatico?
]

Il percorso per arrivare al modello di classificazione di intenti ha richiesto i suoi tempi, ma alla fine ho ottenuto dei risultati che ritengo soddisfacenti.

I problemi principali da risolvere per poter classificare gli intenti sono due: la *raccolta di dati* etichettati e la *scelta del modello* di classificazione.

=== Dataset di training // Come ho raccolto i dati etichettati per addestrare il modello

Di base, nel mondo dell'apprendimento automatico supervisionato, per addestrare un modello di classificazione è necessario un dataset di *esempi etichettati*, cioè coppie di input e output su cui il modello deve imparare a generalizzare.

Per la classificazione di intenti, i dataset più comuni sono quelli di chatbot e assistenti vocali, che contengono domande e richieste etichettate con l'intento che l'utente vuole esprimere.

Il dataset originario fornitomi è stato composto in seguito a una campagna di raccolta dati manuale, in cui diversi collaboratori hanno interagito con un prototipo di chatbot AIML, ponendo domande e richieste di vario tipo.

Il dataset è una collezione di circa 700 singole interazioni "botta e risposta" prodotte dagli utenti durante la prima fase di sperimentazione.
Metà sono domande, l'altra metà coincide con ciò che il chatbot ha risposto.
Sono anche presenti ulteriori metriche e valutazioni qualitative delle interazioni, che però non sono state utilizzate per l'addestramento del modello di classificazione.

==== Estrazione dei dati

Dovendo addestrare un modello di classificazione, ho provveduto innanzitutto ad estrarre i dati effettivamente a noi necessari. Un piccolo script python che adopera la libreria `pandas`@pandas è stato sufficiente:

#figure(
  ```python
  import pandas as pd
  from dotenv import load_dotenv

  load_dotenv()

  df_o = pd.read_excel('corpus/interaction-corpus.xlsx')

  # Filter only the rows that have "Participant" as 'U'
  df = df_o[df_o['Participant'] == 'U']
  df = df[['Text']]
  df = df.drop_duplicates()
  df = df[df['Text'].apply(lambda x: isinstance(x, str))]
  df['Text'] = df['Text'].str.strip()  # Remove trailing whitespace
  texts = df['Text'].dropna()

  df.to_csv("./filtered_data.csv")
  ```,
  kind: "script",
  caption: [Estrazione dei dati dal dataset di interazione.],
)

Estratte le domande, ho potuto procedere con l'etichettatura.

In un primo step, ho considerato la possibilità di lasciare il compito di etichettatura delle domande ad un sistema che svolgesse il compito in automatico.\
Questo permetterebbe di avere un dataset decorato, senza dover ricorrere a un'etichettatura manuale che sarebbe stata molto dispendiosa in termini di tempo e risorse, specialmente in ottica di un incremento dei dati del dataset in seguito a nuove interazioni con il chatbot.

Per fare ciò, ho rivolto la mia attenzione ai modelli di linguaggio neurali, in particolare ai Large Language Models (LLM), dal momento che sono in grado di generalizzare su una vasta gamma di task linguistici, inclusa la classificazione di intenti.

Con l'enorme disponibilità attuale di modelli pre-addestrati e API che permettono di interagire con essi, ho potuto sperimentare diverse soluzioni per l'etichettatura automatica delle domande.\
In particolare, ho deciso di sperimentare con modelli di LLM open-source, dal momento che sono eseguibili localmente e permettono di mantenere i dati sensibili all'interno dell'ambiente di lavoro, senza doverli condividere con servizi esterni.\
Per utilizzarli, si sono rivelate fondamentali le API fornite da Ollama @ollama, un sistema per hostare localmente modelli di LLM open source (e in certi casi anche _open-weights_).

=== Etichettatura automatica del dataset
<etichettatura-automatica-delle-domande>
Per poter automatizzare l'etichettatura usando una LLM, prima di tutto ho identificato l'insieme delle possibili etichette:
#figure(
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
  ```,
  kind: "snip",
  caption: [Etichette possibili per le domande del dataset.],
)

In questa mappa, ad ogni etichetta è associata una descrizione che indica alla LLM un contesto in cui collocarla, con lo scopo di assistere la LLM ad etichettare correttamente le domande togliendo il più possibile le ambiguità.\
Questo genere di task è del tipo *zero shot*, in cui il modello non ha mai visto i dati di training e deve etichettare le domande esclusivamente in base a un contesto fornito.

Con lo scopo di assicurare un'etichettatura corretta e affidabile, ho deciso di utilizzare due modelli di LLM differenti, in modo da poter fare un majority voting tra le etichette prodotte dai due modelli:

- _Gemma 2_, sviluppato da Google Deep Mind @gemma;
- _llama 3.1_, sviluppato da Meta AI @llama3.

I modelli sono stati utilizzati nelle loro varianti da 9 miliardi di parametri per Gemma 2 (dimensione intermedia) e 8 miliardi per llama 3.1 (il più piccolo dei modelli forniti), basandomi sulle sperimentazioni che hanno mostrato un buon compromesso tra performance (intese come qualità dei risultati prodotti in seguito al prompting) e tempo di esecuzione @gemma @llama3.

Un ulteriore modello, Qwen @qwen, prodotto da Alibaba, è stato utilizzato durante le sperimentazioni, ma i risultati non sono stati sufficientemente soddisfacenti da permettere un utilizzo all'interno del progetto.

Ho effettuato il prompting delle domande con i modelli di LLM utilizzando le risorse dell'hardware a mia disposizione, composto da:
- CPU AMD Ryzen 7 5800x (4.7GHz, 8 core, 16 thread, 32MB L3 cache)
- 64GB RAM DDR4 \@3200MHz
- GPU Nvidia RTX 3070 Ti (8GB GDDR6, 6144 CUDA cores \@1.77GHz)

Ad ogni modello è richiesto di etichettare ogni domanda.
Il prompt utilizzato è stato progettato in modo da fornire un contesto chiaro e preciso, in modo da guidare la LLM verso l'etichetta corretta.\
In particolare, ne sono stati utilizzati due per ogni modello, in modo da fornire un contesto più vario e permettere ai modelli di generalizzare meglio sulle domande.
Ogni prompt risulta diverso dal punto di vista della composizione della richiesta, ma l'intento finale a livello semantico è lo stesso.

I prompt sono stati scelti in modo da fornire informazioni utili ai modelli per etichettare le domande, insieme ad un contesto che effettivamente faccia comprendere alla LLM quale sia l'argomento della domanda:

#figure(
  ```python
  prompts = [
    # First prompt
    """You are going to be provided a series of interactions from a user regarding questions about finite state automatons.
    Each message has to be labelled, according to the following labels:

    {labels}

    You only need to answer with the corresponding label you've identified.
    Do not explain the reasoning, do not use different terms from the labels you've received now.
    Interaction:
    {text}
    Label:
    """,

    # Second prompt
    """You are an AI assistant trained to classify questions into the following categories:

    {labels}

    Please classify the following question:
    {text}
    Category:
    """
  ]
  ```,
  kind: "snip",
  caption: [Prompt utilizzati per l'etichettatura delle domande.],
)

Si notino le differenze tra i due prompt: il primo è più dettagliato e fornisce una spiegazione più approfondita delle etichette, mentre il secondo è più conciso e diretto.

I tag tra parentesi graffe vengono sostituiti con i valori attualmente in uso, in modo da rendere il prompt generico e riutilizzabile.

Segue un estratto di codice python che mostra come è stato effettuato il prompting.
Viene importata una classe `Chat`, da me sviluppata, che permette di interagire con i modelli di LLM in modo più semplice, astraendo le API di ollama.

#figure(
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
  ```,
  kind: "script",
  caption: [Prompting delle domande con i modelli di LLM.],
)

Ecco un esempio dei risultati dell'etichettatura del bronze dataset, in seguito al prompting con i modelli di LLM:

#figure(
  align(center)[
    #show table.cell.where(y: 0): strong
    #set text(size: 10pt)
    #table(
      columns: (0.3fr, 1fr, 1fr, 1fr, 1fr),
      align: (auto, auto, auto, auto, auto),
      table.header([ID], [gemma2:9b], [gemma2:9b], [llama3.1:8b], [llama3.1:8b]),
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
    )],
  kind: table,
  caption: [Esempio di etichettatura delle domande del bronze dataset.],
) <bronze-etichettatura>

Come è possibile notare, i modelli hanno etichettato le domande in modo coerente tra di loro, ma non sempre con le etichette corrette.\
In certi casi, le etichette sono state completamente sbagliate, e in altre occorrenze sono state prodotte risposte che o non sono presenti nel set di etichette fornito, o hanno ignorato il prompt fornito, fornendo risposte completamente estranee.

Come accennato, è stato adoperato un sistema di majority voting per combinare i risultati delle due LLM, in modo da ottenere un'etichettatura più affidabile:\

#figure(
  ```python
  from collections import Counter

  def majority_vote(row: pd.Series):
      label_counts = Counter(row)
      majority_label = label_counts.most_common(1)[0][0]
      return majority_label
  ```,
  kind: "snip",
  caption: [Funzione di majority voting per combinare le etichette.],
)

Tuttavia, in seguito ad una prima fase di fine tuning, ho verificato che nonostante un'etichettatura valida, le classi identificate erano troppo sbilanciate, con alcune classi che contenevano un numero troppo esiguo di esempi, portando a una classificazione poco affidabile.
In più, ho realizzato che le classi scelte erano troppo generiche: questo problema non avrebbe permesso di identificare con precisione l'argomento della domanda.

Per questo motivo ho proceduto con una revisione delle etichette, e una successiva etichettatura manuale delle domande.

=== Nuove classi e etichettatura manuale
Prima di proseguire con l'etichettatura, ho provveduto a ripulire il dataset da domande non pertinenti o duplicate.
Una volta fatto, ho deciso di ridurre il numero di classi, in modo da poter avere un dataset più bilanciato e con classi più specifiche.\
Avendone ridotto il numero, per ottenere un livello di granularità maggiore, ho deciso di utilizzare un sistema di etichettatura gerarchico, in modo da poter identificare con maggiore precisione l'argomento della domanda.
Il risultato è stato un dataset con due livelli di classi: le _classi principali_ e le _classi secondarie_, che ci permetteranno di classificare le domande come se ci trovassimo in un albero decisionale @hierarchical.
\
Ne sono risultati sono due livelli di classi:
- Le _classi principali_ (o _question intent_, si veda la @classi-principali), che rappresentano l'argomento generale della domanda, per un totale di 7 classi;
- Le _classi secondarie_, che rappresentano l'argomento specifico della domanda, dipendono dalla classe principale e sono 33 in totale. A seconda della classe principale, il numero di classi secondarie varia.

[TODO: Inserire albero con le classi principali e secondarie]

Il numero ristretto di classi di domande ha permesso di creare una suddivisione più bilanciata tra le classi, e di ottenere un dataset generalmente più equilibrato.

#figure(caption: [Classi principali del dataset.])[
  #show table.cell.where(y: 0): strong
  #show table.cell.where(x: 0): strong
  #table(
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
  )] <classi-principali>

Come è possibile notare dalle tabelle che seguono, alcune classi secondarie contengono un numero esiguo di esempi, non sufficiente per una classificazione affidabile.

#figure(caption: [Le 6 classi secondarie del dataset per la classe primaria dell'*automa*.])[
  #show table.cell.where(y: 0): strong
  #show table.cell.where(x: 0): strong
  #table(
    columns: (auto, auto, auto),
    table.header[Sottoclassi][Scopo][Numero di Esempi],
    table.hline(),

    [description], [Descrizioni generali sull'automa], [14],
    [description_brief], [Descrizione generale (breve) sull'automa], [10],
    [directionality], [Domande riguardanti la direzionalità o meno dell'intero automa], [1],
    [list], [Informazioni generali su nodi e archi], [1],
    [pattern], [Presenza di pattern particolari nell'automa], [9],
    [representation], [Rappresentazione spaziale dell'automa], [13],
  )
]

#figure(caption: [Le 11 classi secondarie del dataset per la classe primaria delle *transizioni*.])[
  #show table.cell.where(y: 0): strong
  #show table.cell.where(x: 0): strong
  #table(
    columns: (auto, auto, auto),
    table.header[Sottoclassi][Scopo][Numero di Esempi],
    table.hline(),

    [count], [Numero di transizioni], [10],
    [cycles], [Domande riguardo anelli tra nodi], [4],
    [description], [Descrizioni generali sugli archi], [2],
    [existence_between], [Esistenza di un arco tra due nodi], [12],
    [existence_directed], [Esistenza di un arco da un nodo a un altro], [9],
    [existence_from], [Esistenza di un arco uscente da un nodo], [18],
    [existence_into], [Esistenza di un arco entrante in un nodo], [1],
    [input], [Ricezione di un input da parte di un nodo], [1],
    [label], [Indicazione di quali archi hanno una certa etichetta], [4],
    [list], [Elenco generico degli archi], [15],
    [self_loop], [Esistenza di self-cycles], [1],
  )
]

#figure(caption: [Le 8 classi secondarie del dataset per la classe primaria degli *stati*.])[
  #show table.cell.where(y: 0): strong
  #show table.cell.where(x: 0): strong
  #table(
    columns: (auto, auto, auto),
    table.header[Sottoclassi][Scopo][Numero di Esempi],
    table.hline(),

    [count], [Numero di stati], [19],
    [details], [Dettagli specifici su uno stato], [1],
    [list], [Elenco generale degli stati], [1],
    [start], [Qual è lo stato iniziale], [8],
    [final], [Esistenza di uno stato finale], [7],
    [final_count], [Numero di stati finali], [2],
    [final_list], [Elenco degli stati finali], [3],
    [transitions], [Connessioni tra gli stati], [8],
  )
]

#figure(caption: [Le 7 classi secondarie del dataset per la classe primaria della *grammatica*.])[
  #show table.cell.where(y: 0): strong
  #show table.cell.where(x: 0): strong
  #table(
    columns: (auto, auto, auto),
    table.header[Sottoclassi][Scopo][Numero di Esempi],
    table.hline(),

    [accepted], [Grammatica accettata dall'automa], [14],
    [example_input], [Input di esempio accettato dall'automa], [4],
    [regex], [Regular expression corrispondente all'automa], [2],
    [simulation], [Simulazione dell'automa con input dell'utente], [8],
    [symbols], [Simboli accettati dalla grammatica], [7],
    [validity], [Validità di un input fornito], [2],
    [variation], [Richiesta di simulazione su un automa modificato], [2],
  )
]

#pagebreak(weak: true)

=== Data Augmentation

Come evidenziato nella sezione precedente, diverse classi secondarie contengono un numero esiguo di esempi, non sufficiente per una buona classificazione in seguito al fine-tuning.

Avendo solo 229 esempi, ho arricchito i dati con ulteriori domande scritte manualmente e anche generate artificialmente.

Le domande artificiali sono state prodotte in grandi quantità adoperando diversi modelli disponibili online e locali, tra cui:
- ChatGPT `4o`, `o1` e `o3-mini` @openai-llm;
- Llama3.1 @llama3;
- DeepSeek R1 @deepseek-r1 @deepseek-technical.

Ad ogni modello è stato presentato un insieme di domande con lo stesso topic principale o secondario, assieme al contesto in cui vengono poste e ad una richiesta di produzione di ulteriori domande simili semanticamente.
Per maggiore convenienza, è stato richiesto ai modelli di rispondere fornendo le nuove domande formattate in markdown @markdown.

Dato il grosso volume di risposte, per verificare l'adesione dei modelli alle richieste è stato effettuato un controllo a campione, che non ha evidenziato particolari problematiche nella precisione di nessuno dei modelli.

In totale sono stati aggiunti 851 nuovi quesiti, con la seguente distribuzione:

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
        size: (10, auto),
        label-key: 0,
        value-key: (1, 2),
        labels: ([Originale], [Augmented]),
        legend: "inner-north-east",
        // bar-style: palette.new(colors: (aqua, green)),
      )
    })
  },
  kind: "plot",
  caption: [Distribuzione delle domande originali e generate artificialmente per ogni classe principale.],
) <augmented-distribution-primary>

Le domande off-topic aggiuntive sono state estratte dal dataset SQUAD #footnote[Stanford Question Answering Dataset] v2 @squad1 @squad2, per avere una sufficiente varietà di domande non pertinenti.

Anche le classi secondarie hanno ricevuto alcune migliorie alla distribuzione, che rimane comunque ancora sbilanciata, com'è possibile vedere nel #ref(<augmented-distribution-secondary>):

#figure(
  {
    let plot_data = (
      ([accepted], 14.0, 67),
      ([count], 29.0, 60),
      ([cycles], 4.0, 22),
      ([dead], 0.0, 3),
      ([definition], 2.0, 16),
      ([description], 14.0, 74),
      ([description_brief], 10.0, 16),
      ([details], 2.0, 22),
      ([deterministic], 0.0, 5),
      ([directionality], 1.0, 15),
      ([example_input], 4.0, 21),
      ([existence_between], 12.0, 35),
      ([existence_directed], 9.0, 31),
      ([existence_from], 18.0, 52),
      ([existence_into], 1.0, 38),
      ([final], 8.0, 30),
      ([final_count], 0.0, 8),
      ([final_list], 5.0, 16),
      ([generic], 3.0, 50),
      ([greet], 2.0, 19),
      ([image], 0.0, 2),
      ([input], 0.0, 12),
      ([label], 4.0, 57),
      ([list], 1.0, 48),
      // ([off_topic], 6.0, 106),
      ([optimization], 0.0, 6),
      ([overview], 17.0, 7),
      ([pattern], 10.0, 37),
      ([reachability], 0.0, 5),
      ([regex], 2.0, 19),
      ([representation], 13.0, 29),
      ([self_loop], 1.0, 32),
      ([simulation], 4.0, 30),
      ([start], 8.0, 25),
      ([start_final], 0.0, 3),
      ([state_connections], 7.0, 21),
      ([states], 3.0, 21),
      ([symbols], 7.0, 24),
      ([transitions], 5.0, 37),
      ([validity], 0.0, 14),
      ([variation], 2.0, 29),
    )
    canvas({
      draw.set-style(legend: (fill: white), barchart: (bar-width: .8, cluster-gap: 0))
      chart.barchart(
        plot_data,
        mode: "clustered",
        size: (9, 18),
        label-key: 0,
        value-key: (1, 2),
        labels: ([Originale], [Augmented]),
        legend: "inner-south-east",
      )
    })
  },
  kind: "plot",
  caption: [Distribuzione delle domande originali e generate artificialmente per ogni classe secondaria.],
) <augmented-distribution-secondary>

Nonostante lo sbilanciamento, è stato possibile ottenere dei buoni risultati in seguito al fine-tuning.

L'utilizzo del dataset SQUAD ha anche introdotto un'ulteriore incremento delle performance, portando a una diminuzione dell'erronea classificazione di esempi off-topic come domande lecite. In particolare, le metriche di entropia e confidenza durante il fine tuning sono migliorate rispettivamente del 17% e del 7%.

=== Fine-tuning <fine-tuning> // Cosa ho usato delle LLM per fare classificazione

Per poter utilizzare i Large Language Models (LLM) per la classificazione di intenti, ho dovuto seguire un processo di fine-tuning.

Il fine-tuning avviene verso la fine della preparazione di un modello di machine learning.
In particolare, è la fase in cui si prende un modello pre-addestrato su un compito generale (o su una grande quantità di dati non etichettati) e lo si “specializza” su un compito specifico, come la classificazione di intenti, l'analisi del sentiment o il riconoscimento di entità nominate.\
Si parte quindi da un modello che possiede già una buona conoscenza linguistica di base (perché allenato, ad esempio, su quantità imponenti di testo come Wikipedia, libri o pubblicazioni) e lo si addestra ulteriormente su un dataset mirato, così da fargli apprendere le particolarità e le sfumature del nuovo scenario applicativo, senza dover ripartire da zero.

Sul piano tecnico, il processo di fine-tuning si fonda sugli stessi principi del _learning by example_: si forniscono al modello coppie di input e output (nel caso di una classificazione, l'output è la classe corretta), e si calcola la loss (ad esempio la cross-entropy tra le probabilità previste dal modello e quelle desiderate).\
Tramite la _backpropagation_ dell'errore, i pesi del modello vengono aggiornati iterativamente, così da allineare le predizioni alle etichette reali.
Il risultato è che, dopo un numero sufficiente di iterazioni (o epoche), il modello impara a predire con buona approssimazione la classe corretta anche per esempi non ancora visti.

#figure(
  image("../media/pretraining-finetuning-transformer-models-2-1.png"),
  caption: [Processo di fine-tuning di un modello di LLM. *IMMAGINE DA SOSTITUIRE*],
)

L'elemento distintivo del fine-tuning rispetto a un addestramento “da zero” (o from scratch) sta nel fatto che la maggior parte dei pesi del modello non parte da valori iniziali casuali, bensì da un punto in cui il modello ha già “appreso” molte regole e pattern del linguaggio.
Se nel pre-addestramento ha appreso, ad esempio, la nozione di contesto, la correlazione fra parole vicine e la loro valenza semantica, durante il fine-tuning deve semplicemente specializzarsi nel riconoscere come queste informazioni si combinano per risolvere il compito target.
Questo riduce drasticamente la quantità di dati e di risorse computazionali necessarie a raggiungere buone prestazioni.

Nel caso di una classificazione testuale multi-classe, si aggiunge in genere un piccolo strato di output (o head) in cima al modello pre-addestrato.
La testa è una semplice rete feed-forward, spesso costituita da uno o due livelli di neuroni, che produce un vettore di dimensione pari al numero di possibili etichette.
Il resto del modello rimane pressoché invariato: l'architettura interna, come i vari encoder o layer del Transformer, resta la stessa, ma i loro pesi continuano ad aggiornarsi durante il training, almeno in un contesto standard (è anche possibile, in alcuni scenari, “congelare” i primi strati e addestrare solo quelli finali, in base a considerazioni di efficienza e dimensione del dataset).

#figure(
  image("../media/llm_classifier2.png"),
  caption: [Struttura di un modello di classificazione basato su LLM. *IMMAGINE DA SOSTITUIRE*],
)

=== BERT

Prima di illustrare più nel dettaglio il fine-tuning, è utile introdurre BERT #footnote[Bidirectional Encoder Representations from Transformers] @bert, progenitore della famiglia di modelli da me utilizzati per la sperimentazione, nonchè uno dei modelli più noti e influenti degli ultimi anni nell'ambito del Natural Language Processing.

BERT è stato proposto nel 2018 da #cite(<bert>, form: "prose") come un sistema capace di apprendere rappresentazioni contestuali del testo in modo bidirezionale, basandosi sull'architettura Transformer introdotta in precedenza da #cite(<vaswani2023attentionneed>, form: "prose").

L'idea portante di BERT è quella di addestrare un modello neurale a predire, data una sequenza testuale, le parole mascherate (ovvero rimosse o sostituite) e la relazione tra frasi adiacenti.
Queste due tecniche di pre-addestramento vengono rispettivamente chiamate Masked Language Modeling e Next Sentence Prediction.

Nel Masked Language Modeling, BERT maschera casualmente alcune parole del testo in input e chiede al modello di indovinare quali fossero, costringendolo così a sviluppare una comprensione profonda del contesto circostante.\

Nel Next Sentence Prediction, invece, il modello riceve in ingresso due frasi (A e B) e impara a classificare se B segue effettivamente A o se le due frasi appartengono a contesti disgiunti.
Addestrando in parallelo su questi due compiti, BERT acquisisce rappresentazioni interne che colgono sfumature sintattiche, semantiche e relazionali del linguaggio @bert.

Una volta pre-addestrato su grandi corpora di testo (come Wikipedia ed estrazioni di libri), BERT può essere facilmente “specializzato” per vari task supervisionati, tra cui la classificazione di testi, l'analisi del sentiment, il question answering e, in generale, tutto ciò che riguarda la comprensione del linguaggio naturale, essendo un modello encoder.
La peculiarità di BERT è che, essendo già addestrato a livello linguistico di base, necessita di meno esempi per ottenere risultati spesso notevoli su compiti altamente specializzati.

Esistono diverse varianti del modello, in termini di dimensioni e capacità. Le versioni più comuni sono `BERT-base` e `BERT-large`, differenziate per numero di livelli (encoder) e di parametri totali.\
In generale, la versione `base` è più rapida e ha requisiti meno elevati in termini di memoria, mentre la versione large offre performance maggiori a fronte di tempi di calcolo e requisiti hardware superiori.

Nella libreria di Huggingface `transformers` @huggingface_transformers, BERT è messo a disposizione come un modello pretrained, pronto per essere caricato e ulteriormente addestrato.
In un contesto di classificazione di intenti, ad esempio, si può utilizzare `AutoModelForSequenceClassification` specificando il checkpoint “bert-base-uncased” (o simili).

Un esempio di codice di inizializzazione è il seguente:

#figure(
  ```python
  from transformers import AutoModelForSequenceClassification, AutoTokenizer

  model_name = "bert-base-uncased"
  tokenizer = AutoTokenizer.from_pretrained(model_name)
  model = AutoModelForSequenceClassification.from_pretrained(model_name, num_labels=num_classes)
  ```,
  kind: "snip",
  caption: [Inizializzazione di un modello BERT per la classificazione di intenti.],
)

`model` è in grado di elaborare sequenze di token generate dal tokenizer e, una volta fine-tuned, produce come output le probabilità di appartenere alle varie classi (o intenti) da classificare. Questa è la base su cui mi sono appoggiato per la classificazione delle domande del dataset.

=== Implementazione

In questa sezione sarà presentata la procedura di fine-tuning che ho implementato per addestrare un modello di classificazione di intenti basato su architetture Transformer.\
L'intero processo sfrutta principalmente la libreria `transformers` di Huggingface @huggingface_transformers, in combinazione con altri strumenti sempre dell'ecosistema FOSS #footnote[Free and Open Source Software, cioè Software *Libero* e Open Source @gplv3 @fsfs] di Huggingface, come `datasets`.

L'utilizzo di queste librerie permette di semplificare notevolmente il processo di fine-tuning, fornendo API intuitive e funzionalità di alto livello per la gestione dei dati, la creazione dei modelli e la valutazione delle performance.
In questo modo è possibile addestrare un modello di classificazione di intenti in poche righe di codice, senza dover scrivere manualmente i loop di training e validation, o implementare da zero la logica di salvataggio e caricamento dei modelli, nonostante questa via sia sempre possibile.

L'obiettivo è utilizzare un modello pre-addestrato (ad esempio BERT, DistilBERT o qualsiasi altro compatibile con `AutoModelForSequenceClassification`) con lo scopo di specializzarlo nel riconoscimento di specifiche categorie di intenti, e successivamente salvarlo per l'uso nel chatbot.

==== Preparazione dei dati

Un primo punto cruciale è la preparazione del dataset, gestita dalla funzione `prepare_dataset`.
Qui effettuo la suddivisione stratificata tra train e validation, tokenizzo i testi tramite un `AutoTokenizer` e converto le etichette da stringhe a interi, in accordo con la mappatura definita nella classe `LabelInfo` #footnote[Si veda l'appendice per la completa definizione.].

#figure(
  ```python
  def prepare_dataset(df: DataFrame,
                    tokenizer: PreTrainedTokenizer,
                    label_info: LabelInfo,
                    examples_column: str,
                    labels_column: str) -> tuple[Dataset, Dataset]:
    """
    Prepares the dataset for training and evaluation by tokenizing the text
    and encoding the labels.
    """
    def tokenize_and_label(example: dict) -> BatchEncoding:
        question = example[examples_column]
        encodings = tokenizer(question, padding="max_length", truncation=True, max_length=128)
        label = label_info.get_id(example[labels_column])
        encodings.update({'labels': label})
        return encodings

    split = StratifiedShuffleSplit(n_splits=1, test_size=0.2, random_state=42)
    train_index, val_index = next(split.split(df, df[labels_column]))
    strat_train_set = df.iloc[train_index].reset_index(drop=True)
    strat_val_set = df.iloc[val_index].reset_index(drop=True)

    train_dataset = Dataset.from_pandas(strat_train_set)
    eval_dataset = Dataset.from_pandas(strat_val_set)

    train_dataset = train_dataset.map(tokenize_and_label, remove_columns=train_dataset.column_names)
    eval_dataset = eval_dataset.map(tokenize_and_label, remove_columns=eval_dataset.column_names)

    return train_dataset, eval_dataset
  ```,
  kind: "fun",
  caption: [Funzione per la preparazione del dataset.],
)

In questo modo, ottengo due oggetti di tipo `Dataset` che rappresentano il training set e il validation set.
Ciascun esempio è stato trasformato in una struttura pronta per essere gestita dal `Trainer` di Huggingface, con un campo `labels` che indica la classe corretta da apprendere.

Una volta create e preparate queste componenti (funzione di metriche, funzioni di training, dataset tokenizzato), eseguo il fine-tuning chiamando `run_fine_tuning` (presentata poco più avanti).

==== Metriche di valutazione <metriche_bert>

Per prima cosa, ho definito una funzione in grado di calcolare le metriche di valutazione, che permetteranno di valutare le performance del modello in fase di fine-tuning in modo automatico.

Ho scelto di considerare *accuratezza*, *precision*, *recall* e *F1* come indicatori classici di performance; in aggiunta, calcolo anche l'*entropia media* e la *confidenza media*, allo scopo di misurare rispettivamente il grado di incertezza delle previsioni e la probabilità media associata alla classe predetta.
Lo snippet seguente mostra la funzione `compute_metrics`:

#figure(
  ```python
  def compute_metrics(eval_pred):
    """
    Compute evaluation metrics for the model predictions.
    """
    predictions, labels = eval_pred
    probabilities = np.exp(predictions) / np.sum(np.exp(predictions), axis=1, keepdims=True)
    preds = np.argmax(probabilities, axis=1)

    acc = accuracy_score(labels, preds)
    precision, recall, f1, _ = precision_recall_fscore_support(labels, preds, average='weighted', zero_division=0)

    entropies = entropy(probabilities.T)
    avg_entropy = np.mean(entropies)
    avg_confidence = np.mean(np.max(probabilities, axis=1))

    metrics = {
        'accuracy': acc,
        'precision': precision,
        'recall': recall,
        'f1': f1,
        'avg_entropy': avg_entropy,
        'avg_confidence': avg_confidence,
    }
    return metrics
  ```,
  kind: "fun",
  caption: [Funzione per il calcolo delle metriche di valutazione.],
)

Può essere utile soffermarci un momento a spiegare le metriche scelte:

L'*accuratezza* (o tasso di classificazione corretta) misura la proporzione di esempi classificati correttamente, senza distinzione tra le varie classi. Formalmente: $ "Accuracy" = 1/N sum ^N _(i=1){hat(y)_i = y_i} $ dove ${hat(y)_i = y_i}$ vale 1 se la previsione è corretta, 0 altrimenti. Più il valore è vicino a 1, migliore è la performance complessiva del modello.

#hrule()

Quando si lavora con problemi di classificazione con etichette binarie, o si valuta ciascuna classe indipendentemente, esistono alcuni conteggi che possono essere utili per valutare la qualità delle previsioni:
- i *true positives* (TP) indicano i casi in cui il modello ha predetto correttamente la classe positiva;
- i *false positives* (FP) indicano i casi previsti come positivi dal modello, ma che in realtà sono negativi;
- i *false negatives* (FN) i casi previsti negativi ma in realtà positivi.
Sulla base di queste definizioni, si introducono due metriche fondamentali:
$
  "Precision" = "TP" / ("TP" + "FP")
$ che indica la percentuale di esempi classificati come positivi che erano effettivamente positivi.
$ "Recall" = "TP" / ("TP" + "FN") $
stima la quota di esempi positivi che sono stati effettivamente riconosciuti come tali dal modello.

#hrule()

L'*F1-score* @Opitz_2024 fornisce una media armonica fra Precision e Recall, combinando entrambe le metriche in un singolo indice: $ "F1" = 2 dot ("Precision" dot "Recall") / ("Precision" + "Recall") $
Un F1 score alto richiede che entrambe le metriche siano elevate; se una delle due è bassa, il valore di F1 tende drasticamente a ridursi.
Questo lo rende particolarmente utile in casi di class imbalance o quando è importante non trascurare né la precisione né la capacità di recuperare tutti i positivi.

#hrule()

L'*entropia* è una misura della disordine o incertezza di un sistema, in questo caso delle previsioni del modello.

Per un singolo esempio, se il modello produce una distribuzione di probabilità $bold(p)_i = (p_(i,1), dots, p_(i,k))$ sulle $k$ classi, è possibile calcolare l'entropia dell'esempio come $ "H" (bold(p)_i) = - sum ^k _(j=1) p_(i,j) log (p_(i,j)) $

Tale quantità esprime quanto “incerte” sono le previsioni del modello: se il modello assegna un'alta probabilità a una sola classe e bassa probabilità alle altre, l'entropia tende a essere prossima a zero (predizione più "sicura"); se distribuisce le probabilità in modo pressoché uniforme, l'entropia aumenta (maggiore incertezza).

L'entropia media su tutto il set di validazione di dimensione $N$ è: $ "Average Entropy" = 1/N sum ^N_(i=1)H(p_i) $
Un valore basso di entropia media indica che, in media, le previsioni del modello sono piuttosto concentrate su una specifica classe; un valore più alto suggerisce che il modello sia spesso incerto.

#hrule()

Sempre definita a partire dalla distribuzione $bold(p)_i$, la confidenza per il singolo esempio $i$ può essere definita come la probabilità associata alla classe di output che ha la confidenza massima:$ C(bold(p)_i) = max_j p_(i,j) $

Maggiore è il valore di $C(bold(p)_i)$, più il modello risulta "sicuro" di quella predizione. Analogamente, la confidenza media sul dataset si calcola come: $ "Average Confidence" = 1/N sum ^N _(i=1) max_j p_(i,j) $

Un valore prossimo a 1 indica che, spesso, il modello prende decisioni molto nette; un valore più basso può rivelare maggiore cautela o incertezza.

Usata congiuntamente all'entropia media, la confidenza media può fornire indicazioni interessanti su come il modello pesa le varie classi e quanto tende a "sbilanciarsi" sulle previsioni.

==== Addestramento <addestramento>

Per effettuare l'addestramento vero e proprio, ho definito anche la funzione `run_fine_tuning`, che si fa carico di gestire i parametri di training (come numero di epoche, learning rate, batch size), di configurare gli strumenti di logging e salvataggio, e di lanciare effettivamente il training tramite la classe `Trainer` della libreria `transformers`.

La classe `Trainer` semplifica notevolmente la gestione di molteplici aspetti, come la schedulazione del learning rate o la stratificazione della validazione.

Il metodo espone diversi parametri significativi:
- `load_best_model_at_end=True` consente di caricare automaticamente al termine dell'addestramento i pesi del modello con il miglior valore di F1 (impostato in metric_for_best_model='f1');
- `warmup_ratio=0.1` configura un periodo iniziale di warm-up, durante il quale il learning rate cresce gradualmente prima di stabilizzarsi nella fase successiva.
  Questo contribuisce a rendere l'ottimizzazione più stabile ed evitare picchi di aggiornamento eccessivi nelle primissime iterazioni.\
  La configurazione del warmup, assieme alla learning rate sono state scelte basandomi sull'utilissimo paper di #cite(<bert_fine_tuning>, form: "prose") che fornisce una guida pratica per il fine-tuning di BERT.
- `metric_for_best_model='f1'` indica che il modello migliore sarà scelto in base al valore di F1, calcolato dalla funzione `compute_metrics`. F1 torna utile in quanto è in grado di bilanciare le due metriche di precision e recall, fornendo un'indicazione complessiva delle performance del modello.

Un'ultima considerazione molto importante riguarda il parametro `report_to`, che consente di specificare a quali servizi di logging inviare i risultati del training.\
Nel mio caso, ho scelto di fare affidamento a *Weights and Biases* #footnote[Weights and Biases, abbreviato `Wandb`, è un servizio di monitoraggio e logging per l'addestramento di modelli di machine learning] in modalità online, in modo da poter monitorare in tempo reale le performance del modello durante il fine-tuning.

#figure(
  ```python
  def run_fine_tuning(model: AutoModelForSequenceClassification,
                    tokenizer: AutoTokenizer,
                    train_dataset: Dataset,
                    eval_dataset: Dataset,
                    wandb_mode: str,
                    num_train_epochs=20) -> Trainer:
    """
    Fine-tunes a pre-trained model on the provided training dataset and evaluates it
    on the evaluation dataset.
    """
    report_to = ["wandb"] if wandb_mode == "online" else None

    training_args = TrainingArguments(
        output_dir='./temp',  # Directory to save the model and other outputs
        num_train_epochs=num_train_epochs,  # Number of training epochs
        learning_rate=2e-5,  # Learning rate for the optimizer
        warmup_ratio=0.1,  # Warmup for the first 10% of steps
        lr_scheduler_type='linear',  # Linear scheduler
        per_device_train_batch_size=16,  # Batch size for training
        per_device_eval_batch_size=16,  # Batch size for evaluation
        save_strategy='epoch',  # Save the model at the end of each epoch
        logging_strategy='epoch',  # Log metrics at the end of each epoch
        eval_strategy='epoch',  # Evaluate the model at the end of each epoch
        logging_dir='./temp/logs',  # Directory to save the logs
        load_best_model_at_end=True,  # Load the best model at the end by evaluation metric
        metric_for_best_model='f1',  # Use subtopic F1-score to determine the best model
        greater_is_better=True,  # Higher metric indicates a better model
        save_total_limit=1,  # Limit the total number of saved models
        save_only_model=True,  # Save only the model weights
        report_to=report_to,  # Report logs to Wandb if mode is "online"
    )

    trainer = Trainer(
        model=model,  # The model to be trained
        args=training_args,  # Training arguments
        train_dataset=train_dataset,  # Training dataset
        eval_dataset=eval_dataset,  # Evaluation dataset
        processing_class=tokenizer,  # Tokenizer for processing the data
        compute_metrics=compute_metrics  # Function to compute evaluation metrics
    )

    print(f"Trainer is using device: {trainer.args.device}")

    trainer.train()  # Start the training process

    return trainer
  ```,
  kind: "fun",
  caption: [Funzione per l'addestramento del modello.],
)

La quasi totalità dei dati mostrati in questo documento sono stati raccolti tramite Wandb, riducendo enormemente il tempo necessario per l'analisi e la visualizzazione dei risultati: il salvataggio automatico ad ogni run e la possibilità di confrontare run diversi in un'unica dashboard sono state funzionalità fondamentali per la mia sperimentazione.

==== Modelli e architettura utilizzate

Tutti i modelli che ho utilizzato per la sperimentazione sono basati su BERT, o ELECTRA @electra, entrambi fondati sull'architettura encoder @bert.

In particolare, dal repository di Huggingface dedicato ai modelli di classificazione ho deciso di utilizzare:
- `google-bert/bert-base-uncased`, versione da 110 milioni di parametri @bert-base. Si tratta del modello originale di BERT ideato da Google @bert;
- `distilbert/distilbert-base-uncased` @distilbert-base, versione distillata @hinton-distillation di BERT, con circa il 40% in meno di parametri @distilbert. Il modello è il risultato di una operazione dove si addestra un modello più piccolo ad imitare al meglio l'originale;
- `google/mobilebert-uncased` @mobilebert-uncased, versione di BERT ingegnerizzata con lo scopo di essere eseguibile su dispositivi mobili. Ha un totale di 25 milioni di parametri @mobilebert.
- `google/electra-small-discriminator` @electra-hf, da 14 milioni di parametri. Questo modello è stato addestrato utilizzando tecniche simili a quelle utilizzate per addestrare le GAN #footnote[Generative Adversarial Networks, modelli addestrati in coppia, dove uno impara a svolgere un certo compito generativo, e l'altro a riconoscere se un certo esempio presentato è generato o meno.] @adversarial-nets @electra

Tutti i modelli utilizzati sono direttamente adoperabili per i nostri scopi essendo modelli encoder: dato un certo input produrranno una rappresentazione vettoriale o matriciale.
Il risultato è successivamente classificabile da una rete feed-forward, restituendo così come risultato la classe più probabile (si veda la #ref(<fine-tuning>)).

#hrule()

Sono state effettuate anche delle sperimentazioni con una variante della normale architettura, dove su un unico encoder vengono addestrati due modelli separati di classificazione, per riconoscere con un'unica esecuzione del modello entrambe le classi della domanda presentata.

L'idea, già utilizzata anche in altri ambiti per il Transfer Learning @multitask o direttamente su BERT @multitask-bert1 @multitask-bert2 può permettere di ridurre notevolmente il costo e i tempi di addestramento, oltre ai requisiti di memoria.
Infatti, avendo la quasi totalità dei pesi concentrati nei layer del transformer, lo strato finale di classificazione risulta molto "sottile", e richiede una percentuale minima rispetto al resto del modello.

Nel mio caso sfortunatamente l'architettura a doppia testa di classificazione non si è rivelato migliore, con performance in media inferiori del 20% rispetto al miglior modello addestrato finora.
Nonostante le performance peggiori, l'utilizzo di un modello del genere può essere considerato in contesti soggetti da forti limiti hardware, come su dispositivi mobili, edge o low-end.

L'intera implementazione fa nuovamente fondamento sull'enorme flessibilità della libreria `transformers`. È stato sufficiente infatti soltanto aggiungere le due classification heads ed estendere il metodo `forward` che si occupa della predizione:

#figure(
  ```python
  from torch import nn as nn
  from transformers import BertPreTrainedModel, BertModel


  class BertForHierarchicalClassification(BertPreTrainedModel):
      def __init__(self, config, num_main_topics, num_subtopics):
          super().__init__(config)
          self.bert = BertModel(config)
          self.classifier_main = nn.Linear(config.hidden_size, num_main_topics)
          self.classifier_sub = nn.Linear(config.hidden_size, num_subtopics)
          self.init_weights()

      def forward(self, input_ids, attention_mask, labels_main=None, labels_sub=None):
          outputs = self.bert(input_ids=input_ids, attention_mask=attention_mask)
          pooled_output = outputs.pooler_output
          logits_main = self.classifier_main(pooled_output)
          logits_sub = self.classifier_sub(pooled_output)

          loss = None
          if labels_main is not None and labels_sub is not None:
              loss_fct = nn.CrossEntropyLoss()
              loss_main = loss_fct(logits_main, labels_main)
              loss_sub = loss_fct(logits_sub, labels_sub)
              loss = loss_main + loss_sub  # Adjust weighting if needed

          return {'loss': loss, 'logits_main': logits_main, 'logits_sub': logits_sub}
  ```,
  kind: "cls",
  caption: [Estensione di un modello BERT per la classificazione gerarchica in-model.],
)

=== Valutazione e performance <valutazione_ft> // Spiegazione di come ho valutato i risultati dei classificatori

Come spiegato a #ref(<metriche_bert>, form: "page"), per compiere l'addestramento dei modelli è stato essenziale sfruttare metriche di valutazione adeguate, in grado di fornire un quadro completo delle performance del modello.

Iniziamo quindi valutando i risultati dell'addestramento sulla classe principale del dataset:

#figure(
  image("../media/f1_final.png"),
  kind: "plot",
  caption: [Confronto delle performance di F1 tra i modelli addestrati.],
)

Come possiamo osservare, le performance crescono man mano che procediamo con il processo di fine tuning, ma si stabilizzano dopo aver visto circa i tre quarti del dataset. I modelli `bert` e `distilbert` terminano l'addestramento con performance pressochè identiche (la differenza è dello 0.01%), mentre i modelli `mobilebert` e `electra` differiscono di circa l'8% rispetto a `bert`.

Le differenze di performance sono sempre da confrontare considerando anche il tempo di addestramento e la complessità del modello: `electra` ad esempio, pur avendo performance leggermente inferiori, è stato addestrato in meno della metà del tempo rispetto a `bert`.

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
        size: (10, 5.5),
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
  kind: "plot",
  caption: [Confronto dei tempi di addestramento per ciascuna classe di training.],
)

Questo salto nei tempi di addestramento così brusco in realtà porta dei peggioramenti: le sue performance su un test separato mostra risultati peggiori ridotte rispetto agli altri modelli, come possiamo constatare nel @performance_f1_test_training. Questo ci ricorda come la scelta del modello non debba essere fatta solo in base alle performance ottenute durante l'addestramento, ma che queste devono essere sempre confermate verificando con un test set separato.

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
        size: (10, 6),
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
  kind: "plot",
  caption: [Confronto delle performance di F1 tra i modelli addestrati.\ È anche mostrato il valore di F1 per la classe principale ottenuto durante il fine-tuning dei modelli.],
) <performance_f1_test_training>

Tutte le valutazioni sono effettuate utilizzando un ulteriore dataset di test, separato dal dataset di training e di validazione, per evitare overfitting e garantire una valutazione imparziale.
È composto da 468 ulteriori domande, distribuite in modo da assicurare una verifica sufficiente su tutte le classi di intenti secondarie, cruciali per la corretta classificazione e per fornire effettivamente risposte utili agli utenti.

Utilizzeremo le performance di AIML come baseline di riferimento per il confronto con gli altri modelli neurali. In seguito alla comparazione delle performance mediante la metrica F1 tra i vari modelli vista in @performance_f1_test_training, d'ora in avanti ci concentreremo sulle metriche ottenute con `bert-base-uncased`, il modello più performante tra quelli addestrati.

Per poterlo fare, sfrutteremo le matrici di confusione per valutare le performance dei modelli, in particolare per osservare come si comportano in presenza di classi sbilanciate o di domande ambigue. #footnote[Una matrice di confusione è una tabella che mostra il numero di predizioni corrette e incorrette fatte dal modello, confrontando le predizioni con le etichette reali.]
Siamo interessati a capire se il modello riesce a classificare correttamente domande mai viste; con la matrice di confusione ci aspetteremo di vedere una diagonale principale molto più marcata rispetto agli altri elementi, indicando che il modello è in grado di classificare correttamente la maggior parte delle domande.

Saranno anche presentate le tabelle di valutazione per ciascuna classe, in modo da poter osservare le performance di ciascun modello in modo più dettagliato.

Le metriche presentate nelle tabelle seguenti sono state prodotte utilizzando la funzione `classification_report` della libreria `scikit-learn` @scikit-learn, che calcola precision, recall e F1 score per ciascuna classe, oltre all'accuracy complessiva.

Il modello AIML, nonostante sia costituito da un numero non indifferente di regole e pattern (103), ha performance mediamente basse, con un F1 score medio del 33% rispetto al 92% di BERT (@valutazione_aiml_main).

#figure(
  caption: [Risultati delle metriche principali di valutazione per la classificazione\
    del main intent, sia con AIML che con BERT.],
)[
  #show table.cell.where(y: 0): strong
  #show table.cell.where(x: 0): strong
  #table(
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

    [Automaton], [0.52], [0.19], [0.27], [0.93], [0.93], [0.93], [75],
    [Grammar], [0.90], [0.13], [0.23], [0.78], [0.83], [0.81], [70],
    [Off-Topic], [0.26], [0.82], [0.39], [1.00], [0.96], [0.98], [100],
    [Start], [1.00], [0.53], [0.69], [1.00], [0.90], [0.95], [40],
    [State], [0.17], [0.19], [0.18], [0.96], [1.00], [0.98], [43],
    [Theory], [0.00], [0.00], [0.00], [0.57], [0.57], [0.57], [30],
    [Transition], [0.67], [0.28], [0.40], [0.97], [0.99], [0.98], [110],
    table.hline(),
    [Accuracy], table.cell(colspan: 2)[], [0.35], table.cell(colspan: 2)[], [0.92], [468],
    [Macro avg], [0.44], [0.27], [0.27], [0.89], [0.88], [0.88], [468],
    [Weighted avg], [0.53], [0.35], [0.33], [0.92], [0.92], [0.92], [468],
  )
] <valutazione_aiml_main>

Possiamo anche vedere come, dove questo non sia in grado di classificare una certa domanda, finisca col classificarla come off-topic, indicando una certa difficoltà nel riconoscere domande in realtà valide per il nostro dominio (@conf_aiml_main).

#figure(
  grid(
    rows: 2,
    image(
      "../../multitask_training/diagrams/aiml/confusion_matrices_aiml_main.svg",
      height: 8cm,
    ),
    image(
      "../../multitask_training/diagrams/BertForSequenceClassification/confusion_matrices_bert_main.svg",
      height: 8cm,
    ),
  ),
  kind: "plot",
  caption: [Matrici di confusione per la classe principale classificata con AIML (sopra) e BERT (sotto).\ Seguendo una certa riga (classe) possiamo vedere per ogni colonna (classe predetta) quanti esempi sono stati classificati correttamente e quanti no. La diagonale invece indica il numero di esempi classificati senza errori.],
) <conf_aiml_main>

Le stesse osservazioni sono applicabili anche alle classi di intenti secondarie (@valutazione_aiml_bert_sub), dove AIML mostra un F1 score medio del 20%, rispetto all'86% di BERT.

Le matrici di confusione confermano le tendenze già presentate dai due modelli per la classe principale, con BERT che mostra una diagonale principale molto marcata (@conf_aiml_sub). AIML effettivamente riesce a classificare correttamente pochi elementi delle varie classi, mentre BERT mostra una maggiore capacità di generalizzazione.

#page(margin: (right: 2cm, left: 2cm, top: 2cm, bottom: 2cm))[
  #figure(
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
        table.cell(align: center)[F1],
        [Precision],
        [Recall],
        table.cell(align: center)[F1],
      ),
      table.hline(),
      table.vline(x: 1, start: 0),
      table.vline(x: 4, start: 0),
      table.vline(x: 7, start: 0),

      [ACCEPTED], [0.40], [0.40], [0.40], [0.83], [1.00], [0.91], [10],
      [COUNT], [0.75], [0.15], [0.25], [0.95], [1.00], [0.98], [20],
      [CYCLES], [0.00], [0.00], [0.00], [1.00], [1.00], [1.00], [10],
      [DEFINITION], [0.00], [0.00], [0.00], [0.00], [0.00], [0.00], [4],
      [DESCRIPTION], [0.18], [0.09], [0.12], [0.51], [0.78], [0.62], [23],
      [DESCRIPTION_BRIEF], [0.00], [0.00], [0.00], [0.60], [0.25], [0.35], [12],
      [DETAILS], [0.00], [0.00], [0.00], [1.00], [1.00], [1.00], [10],
      [DIRECTIONALITY], [0.00], [0.00], [0.00], [1.00], [0.80], [0.89], [10],
      [EXAMPLE_INPUT], [0.00], [0.00], [0.00], [1.00], [1.00], [1.00], [10],
      [EXISTENCE_BETWEEN], [0.19], [0.80], [0.30], [0.67], [0.60], [0.63], [10],
      [EXISTENCE_DIRECTED], [0.00], [0.00], [0.00], [0.75], [0.60], [0.67], [10],
      [EXISTENCE_FROM], [0.00], [0.00], [0.00], [0.80], [0.80], [0.80], [10],
      [EXISTENCE_INTO], [0.00], [0.00], [0.00], [0.82], [1.00], [0.90], [9],
      [FINAL], [0.00], [0.00], [0.00], [1.00], [0.83], [0.91], [6],
      [FINAL_LIST], [0.00], [0.00], [0.00], [0.75], [0.86], [0.80], [7],
      [GENERIC], [0.00], [0.00], [0.00], [0.00], [0.00], [0.00], [2],
      [LABEL], [0.00], [0.00], [0.00], [0.00], [0.00], [0.00], [9],
      [LIST], [0.00], [0.00], [0.00], [1.00], [1.00], [1.00], [10],
      [OFF_TOPIC], [0.26], [0.82], [0.39], [1.00], [0.96], [0.98], [100],
      [OVERVIEW], [0.00], [0.00], [0.00], [0.50], [0.67], [0.57], [3],
      [PATTERN], [0.75], [0.90], [0.82], [1.00], [1.00], [1.00], [10],
      [REGEX], [0.00], [0.00], [0.00], [1.00], [1.00], [1.00], [10],
      [REPRESENTATION], [0.33], [0.10], [0.15], [1.00], [0.70], [0.82], [10],
      [SELF_LOOP], [0.00], [0.00], [0.00], [0.90], [1.00], [0.95], [9],
      [SIMULATION], [0.00], [0.00], [0.00], [0.91], [1.00], [0.95], [10],
      [START], [1.00], [0.42], [0.59], [0.98], [0.92], [0.95], [50],
      [STATES], [0.00], [0.00], [0.00], [0.00], [0.00], [0.00], [1],
      [STATE_CONNECTIONS], [0.00], [0.00], [0.00], [1.00], [1.00], [1.00], [30],
      [SYMBOLS], [0.00], [0.00], [0.00], [0.70], [0.70], [0.70], [10],
      [THEORY], [0.00], [0.00], [0.00], [0.57], [0.57], [0.57], [30],
      [TRANSITIONS], [0.00], [0.00], [0.00], [0.00], [0.00], [0.00], [3],
      [VARIATION], [0.00], [0.00], [0.00], [0.91], [1.00], [0.95], [10],
      table.hline(),
      [Accuracy], table.cell(colspan: 2)[], [0.28], table.cell(colspan: 2)[], [0.86], [468],
      [Macro avg], [0.11], [0.11], [0.09], [0.73], [0.73], [0.72], [468],
      [Weighted avg], [0.24], [0.28], [0.20], [0.87], [0.86], [0.86], [468],
    ),
    caption: [Risultati delle metriche di valutazione per la classificazione delle classi secondarie con AIML e BERT.],
  ) <valutazione_aiml_bert_sub>
]

#page(margin: (right: 3cm, left: 3.5cm, top: 2cm, bottom: 2cm))[
  #figure(
    grid(
      rows: 2,
      image("../../multitask_training/diagrams/aiml/confusion_matrices_aiml_sub.svg", height: 12.5cm),
      image(
        "../../multitask_training/diagrams/BertForSequenceClassification/confusion_matrices_bert_sub.svg",
        height: 12.5cm,
      )
    ),
    caption: [Matrici di confusione per le classi secondarie classificate con AIML (sopra) e BERT (sotto).],
  ) <conf_aiml_sub>
]

Per finire, vediamo anche alcuni esempi del test set etichettati da AIML e Bert. Questi esempi sono stati scelti in modo da mostrare come i due modelli si comportano in un'ipotetica situazione reale:

#figure(
  table(
    columns: 7,
    table.header(
      table.cell(rowspan: 2)[Domanda],
      table.cell(colspan: 2, align: center)[Ground Truth],
      table.cell(colspan: 2, align: center)[AIML],
      table.cell(colspan: 2, align: center)[BERT],
      [Main],
      [Sub],
      [Main],
      [Sub],
      [Main],
      [Sub],
    ),
    table.hline(),
    [Would you display a full list of all components, including nodes and transitions, in the finite state automaton?], [AUT], [LST], [OT], [OT], [*AUT*], [*LST*],
    [Could you summarize the automaton for me?], [AUT], [DB], [OT], [OT], [*AUT*], [*DB*],
    [Could you give me a brief summary of the automaton?], [AUT], [DB], [OT], [OT], [*AUT*], [*DB*],
    [Can you point out the start state in this automaton?], [STT], [STRT], [OT], [OT], [*STT*], [*STRT*],
    [Is a systematic pattern evident in the automata arcs?], [AUT], [PTT], [*AUT*], [*PTT*], [*AUT*], [*PTT*],
    [Can you point out a repetitive pattern among the arcs?], [AUT], [PTT], [*AUT*], [*PTT*], [*AUT*], [*PTT*],
    // I’d like to hear an explanation of how this automaton’s states are formed and related.,AUTOMATON,DESCRIPTION,OFF_TOPIC,OFF_TOPIC,AUTOMATON,REPRESENTATION
    [I’d like to hear an explanation of how this automaton’s states are formed and related.], [AUT], [DESC], [OT], [OT], [AUT], [REP],
    // Would you mind describing the automaton’s configuration and links?,AUTOMATON,DESCRIPTION,OFF_TOPIC,OFF_TOPIC,AUTOMATON,REPRESENTATION
    [Would you mind describing the automaton’s configuration and links?], [AUT], [DESC], [OT], [OT], [AUT], [REP],
  ),
)

In generale, i risultati ottenuti con BERT sono molto soddisfacenti, con performance nettamente superiori rispetto ad AIML. Questo conferma l'efficacia dei modelli neurali per la classificazione di intenti in un contesto di chatbot, e dimostra come l'uso di modelli pre-addestrati come BERT possa portare a risultati molto migliori rispetto a soluzioni rule-based. Non mancano tuttavia degli esempi in cui BERT non riesce a classificare correttamente la domanda, ma in generale il modello mostra una capacità di generalizzazione molto più elevata rispetto ad AIML.

== Riconoscimento delle entità

Negli anni Novanta, parallelamente agli studi sull'Intelligenza Artificiale per la realizzazione di sistemi conversazionali rule-based come AIML, si sviluppavano anche nuovi compiti di Natural Language Processing (NLP) orientati all'estrazione di informazioni dal testo in modo più strutturato. Uno dei compiti chiave in questo processo è il Named Entity Recognition (NER), o riconoscimento delle entità nominate.

Nato inizialmente nell'ambito di competizioni e conferenze come le *Message Understanding Conferences* @muc-history, il NER si propose come task cruciale per identificare all'interno di un testo i riferimenti a persone, organizzazioni, luoghi, date e altre categorie, assegnando a ciascuna entità un'etichetta appropriata. Se AIML, per certi versi, si concentra su _che cosa l'utente vuole_ (*intent classification*), il NER si focalizza su _chi o che cosa è menzionato_ all'interno di un messaggio o di un documento.

Un semplice esempio può essere la frase "Mario Rossi ieri è stato a Roma per un incontro con Telecom Italia.". Un sistema NER ideale dovrebbe riconoscere:
- Mario Rossi come una *persona* (`PERSON`);
- Roma come un *luogo* (`LOC`);
- Telecom Italia come un'*organizzazione* (`ORG`).

In un chatbot avanzato, questa funzionalità è particolarmente importante perché consente di trasformare testi destrutturati (come messaggi, email o query di ricerca) in informazioni utilizzabili da moduli di analisi successivi.

Consideriamo la possibilità che l'utente chieda a un chatbot che si occupa di automi a stati finiti "Qual è la differenza tra un *automa deterministico* e un *automa non deterministico*?": la NER dovrebbe individuare correttamente "automa deterministico" e "automa non deterministico" come entità rilevanti (anche se meno “classiche” rispetto a persona/luogo/organizzazione).\ In questo modo, il chatbot sa di dover recuperare informazioni specifiche su queste due tipologie di automi, assegnandole poi al modulo incaricato di rispondere alla domanda.

=== Approcci e metodologie nel NER

La ricerca sul riconoscimento delle entità (Named Entity Recognition) ha attraversato diverse fasi, ognuna caratterizzata da metodologie specifiche e da un livello di “intelligenza” sempre crescente @munnangi2024briefhistorynamedentity. Inizialmente, i sistemi si basavano su regole statiche o elenchi di entità predefiniti, mentre negli ultimi anni si è passati a tecniche di machine learning via via più complesse, fino ad arrivare ai più recenti modelli neurali basati su architetture di tipo Transformer.

==== Metodi rule-based o a dizionario
Nella prima fase, molti sistemi NER si affidavano a liste di entità note (chiamate “gazetteer”) e a regole linguistiche (pattern o espressioni regolari) per individuare nomi di persone, luoghi, organizzazioni e così via. L'idea di fondo era piuttosto semplice: se una parola compariva in un elenco di nomi propri oppure coincideva con un pattern di stringa (ad esempio iniziale maiuscola, presenza di determinati suffissi), allora veniva etichettata come entità.

Questi approcci erano relativamente facili da implementare e sufficientemente efficaci in un contesto ben definito, purché gli elenchi fossero tenuti costantemente aggiornati. Tuttavia, mostravano rapidamente i loro limiti nel momento in cui si presentavano nomi o entità nuove non inclusi nei dizionari, oppure quando si operava in un dominio estremamente vasto (es. social media) o molto specialistico. In tali casi, l'aggiornamento continuo dei gazetteer e la gestione manuale delle regole si rivelavano complessi e poco scalabili.

==== Metodi statistici (CRF, HMM, SVM)
Successivamente, con la diffusione del machine learning, si sono affermati approcci statistici in grado di automatizzare gran parte del processo di individuazione e classificazione delle entità. Tra i metodi più noti, spiccano i Conditional Random Fields @crf-base, gli Hidden Markov Models @hmm e le Support Vector Machines @svm. Questi algoritmi imparano a riconoscere le entità partendo da un dataset annotato, ossia un corpus di testi in cui ogni parola è già etichettata come “entità” o “non entità” (con eventuali sotto-categorie quali PERSON, LOCATION, ORGANIZATION, ecc.).

Il vantaggio principale di questo approccio è che i modelli statistici non dipendono più soltanto da elenchi o regole scritte dall'uomo: essi apprendono le regolarità linguistiche e i pattern lessicali (per esempio, la probabilità che un termine che inizia con la maiuscola sia un nome proprio di persona) direttamente dai dati. Per molti anni, questi metodi hanno rappresentato lo stato dell'arte del NER, garantendo performance elevate a fronte di un'adeguata disponibilità di dati annotati.

==== Modelli neurali
Negli ultimi anni, la scena del NER è stata rivoluzionata dall'avvento di reti neurali, inizialmente di tipo ricorrente (come RNN @rnn_intro o LSTM @lstm @colah) e, più di recente, di tipo Transformer @vaswani2023attentionneed (ad es. BERT @bert, RoBERTa, GPT). L'adozione di embedding per le parole e di meccanismi di attenzione (self-attention) ha permesso di superare molte limitazioni dei metodi precedenti, poiché queste architetture sono in grado di:

- gestire contesti testuali più lunghi in modo efficace;
- catturare la struttura sintattica e il significato semantico delle frasi;
- fornire rappresentazioni linguistiche approfondite in grado di distinguere omonimi e contesti diversi.

In questo modo, anche in domini molto specifici (come quello degli automi a stati finiti, in cui esistono entità specialistiche come "automa deterministico" o "automa non deterministico"), i modelli neurali si sono dimostrati capaci di riconoscere e catalogare con maggiore accuratezza le entità rilevanti @Polignano2021818. Questa evoluzione ha portato a un vero e proprio salto di qualità nelle prestazioni del NER, consentendo al sistema di operare su testi complessi e ricchi di sfumature senza richiedere il continuo intervento di programmatori o linguisti per aggiornare le regole manuali.

=== Slot Filling

Mentre il NER si concentra su dove compaiono le entità nel testo e su che tipo di entità si tratti (persona, luogo, organizzazione, ecc.), lo slot-filling rappresenta un'operazione più specifica e spesso orientata al dominio @Schank1975ScriptsPA @slot2. In altre parole:

- Il NER produce una segmentazione e un'etichettatura generica:\ Mario Rossi #sym.arrow `PERSON`, Roma #sym.arrow `LOC`, Telecom Italia #sym.arrow `ORG`.
- Lo slot-filling prende queste entità (o altre componenti di testo) e le associa a ruoli predefiniti, tipici di una determinata applicazione. Ad esempio, per un chatbot di viaggi potremmo avere:
  - città_di_partenza = "Milano"
  - città_di_arrivo = "Roma"
  - data_viaggio = "2025-03-07"

In alcuni sistemi, il compito di “trovare gli slot” e “riempirli” è integrato in un singolo modello (joint model di intent classification e slot-filling @ner-slot-joint). In altri casi, come in pipeline più complesse, si preferisce separare il passaggio di NER dal passaggio di mapping di dominio (slot-filling).

Facciamo un esempio di conversazione per un assistente virtuale di prenotazione ristoranti:

1. L'utente scrive: “Voglio prenotare un tavolo per stasera da Gianni”.
2. Il NER riconosce nel testo:
  - “Gianni” come entità di tipo `PER` (potrebbe essere ambiguo, ma in contesto gastronomico potrebbe anche essere un `LOC` se “Da Gianni” è il nome del ristorante).
  - “stasera” come `TIME`.
3. Lo slot-filling contestualizza:
  - nome_ristorante = "Da Gianni"
  - data_prenotazione = "2025-03-02 20:00" (se "stasera" è mappato a una data specifica e magari un orario predefinito)
  - richiesta_utente = "prenotazione"

Da un punto di vista implementativo, potremmo anche definire uno slot “ristorante” e uno slot “orario”, che vengono riempiti con i valori estratti. Il NER fornisce la base per capire dove si trovano le informazioni nel testo, mentre lo slot-filling si assicura di collocarle correttamente nei campi del database o nei parametri del servizio di prenotazione.

=== Annotazione dei dati con Doccano

Prima di procedere all'addestramento del modello di Named Entity Recognition, è stato necessario produrre un dataset adeguatamente etichettato. A questo scopo, ho impiegato Doccano @doccano, uno strumento web open-source pensato per facilitare il processo di annotazione di testi. L'interfaccia di Doccano consente di selezionare frammenti di testo (ad esempio, termini rilevanti in un dominio specifico) e assegnare loro delle etichette, generando in output un file JSONL pronto per la fase di training.

Una serie di record del file JSONL prodotto da Doccano potrebbe avere il seguente formato:
#figure(
  ```json
  [{
      "id": 632,
      "text": "What is the output when the automaton processes '1010'?",
      "label": [[49,53,"input"]]
  },
  {
      "id": 634,
      "text": "Does the automaton accept strings where the number of '0's equals the number of '1's?",
      "label": [[55,56,"input"], [81,82,"input"]]
  },
  {
      "id": 635,
      "text": "What is the effect on the accepted language if we remove state q1?",
      "label": [[63,65,"node"]]
  }]
  ```,

  kind: "snip",
  caption: [Esempio di record JSONL prodotto da Doccano per l'annotazione dei dati di NER.],
)

Nel dettaglio, vediamo che:
- Il campo `text` contiene la stringa completa del messaggio o della domanda.
- Il campo `label` indica le etichette come tuple, ciascuna composta da:
  1. La posizione iniziale del frammento etichettato (inclusa).
  2. La posizione finale del frammento etichettato (esclusa).
  3. L'etichetta stessa (ad esempio, `input` o `node`).

La fase di annotazione è stata svolta manualmente, con particolare attenzione alla coerenza e alla completezza delle etichette. Doccano ha permesso di semplificare il lavoro, consentendo di visualizzare i testi e le etichette in modo chiaro e di aggiungere nuove annotazioni con pochi clic, senza la necessità di scrivere codice o utilizzare strumenti esterni.

In seguito all'etichettatura sono risultate tre classi di entità:
- `input`: per i frammenti di testo che contengono input o sequenze di simboli. Ad esempio, nella frase
  #quote[Does it only accept 1s and 0s?] ci aspetteremmo di individuare due entità di tipo `input`: `[20,21,"input"],[27,28,"input"]`;
- `node`: per i frammenti di testo che contengono nodi o stati dell'automa. Ad esempio, nella frase
  #quote[Is there a transition between q2 and q0?] ci aspetteremmo di individuare due entità di tipo `node`: `[30,32,"node"],[37,39,"node"]`.
- `language`: per i frammenti di testo che contengono informazioni sulla lingua accettata dall'automa. Ad esempio, nella frase
  #quote[Does the automaton accept strings over the alphabet {0,1}?] ci aspetteremmo di individuare un'entità di tipo `language`: `[53,58,"language"]`.

=== Implementazione con spaCy // Come ho implementato la parte di NER con spacy
spaCy è una libreria open-source in Python progettata per l'elaborazione del linguaggio naturale. Offre una serie di strumenti avanzati per l'analisi e la comprensione di testi, tra cui tokenizzazione, lemmatizzazione, part-of-speech tagging e, essenziale per il nostro progetto, la Named Entity Recognition, per la quale ha un motore altamente performante.

Un tipico flusso di lavoro con spaCy prevede la creazione di un “modello” (o il caricamento di un modello pre-addestrato) corrispondente a una determinata lingua, il passaggio di testo a questo modello per il processamento (tokenizzazione, tagging, ecc.) e, se necessario, la personalizzazione o l'addestramento ulteriore delle varie componenti. Proprio quest'ultimo aspetto - l'addestramento di un modello di Named Entity Recognition - è al centro di questa sezione.

==== Caricamento dati in formato Doccano JSONL
La prima componente fondamentale è la classe `NERData`, che si occupa di caricare e rappresentare i dati etichettati in formato Doccano JSONL. Doccano produce un file in cui ogni riga corrisponde a un esempio di testo con le relative annotazioni (indici di inizio/fine e nome dell'etichetta). Bisogna notare come il file non sia un vero e proprio JSON, ma una sequenza di righe JSON, ciascuna contenente un singolo esempio.

Per questo motivo al momento dell'importazione è essenziale leggere il file riga per riga e caricare ogni esempio separatamente:

#figure(
  ```python
  class NERData:
      """
      A class to represent NER data in Doccano JSONL format.
      """

      def __init__(self, line: str):
          data = json.loads(line.strip())

          self.text: str = data['text']
          self.labels: list[SpacyEntity] = data.get('label', [])  # (start, end, label)
          self.entity_labels = list({label for (_, _, label) in self.labels})

      @staticmethod
      def load_jsonl_data(file_path: Path) -> list['NERData']:
          """
          Convert Doccano JSONL format to spaCy training data format.
          """
          with file_path.open('r', encoding='utf-8') as f:
              return [NERData(line) for line in f]

      def make_example(self, nlp):
          doc = nlp.make_doc(self.text)
          annotations = {"entities": self.labels}
          return Example.from_dict(doc, annotations)
  ```,
  kind: "cls",
  caption: [La classe `NERData` permette di gestire in modo semplice i dati etichettati in formato Doccano JSONL.],
)

L'idea alla base segue design pattern comuni per la gestione dei dati:
- La classe si occupa di rappresentare un singolo esempio, con il testo e le relative annotazioni;
- Il metodo `load_jsonl_data` si occupa di caricare tutti gli esempi da un file JSONL e restituirli come una lista di oggetti `NERData`. Per poterlo fare, viene sfruttato il costruttore della classe in modo da rendere il codice più modulare e manutenibile possibile;
- Il metodo d'istanza `make_example` converte un esempio in un formato compatibile con spaCy @spacy @honnibal_spacy_2015, in modo da poter essere utilizzato per l'addestramento del modello.

==== Pre-elaborazione dei dati

Una volta caricati i dati, il passo successivo consiste nell’analisi delle etichette e nella suddivisione in train set e validation set. Per questo scopo, si utilizzano due funzioni:

#figure(
  ```python
    def prepare_multilabel_data(entities: list[NERData]) -> tuple[ndarray, list[str]]:
      """
      Prepare multilabel data for NER entities, converting them into
      a binary matrix format using MultiLabelBinarizer.
      """
      binarizer = MultiLabelBinarizer()
      all_labels = [e.entity_labels for e in entities]
      binarizer.fit(all_labels)

      label_matrix = binarizer.transform(all_labels)
      return label_matrix, binarizer.classes_
  ```,
  kind: "fun",
  caption: [La funzione `prepare_multilabel_data` si occupa di preparare i dati etichettati per l'addestramento del modello NER.],
)

Qui si sfrutta un `MultiLabelBinarizer` dal modulo `sklearn.preprocessing` per convertire le etichette multiclasse in un formato binario, in modo da poterle utilizzare per l'addestramento di un modello di classificazione. Questo passaggio è essenziale per poter addestrare un modello di NER, che deve essere in grado di riconoscere più entità contemporaneamente.

#figure(
  ```python
    def stratified_split(entities: list[NERData],
                       label_matrix,
                       val_size=0.2,
                       random_state=42) -> tuple[list[NERData], list[NERData]]:
      """
      Perform a stratified split on multilabel data using
      MultilabelStratifiedShuffleSplit.
      """
      msss = MultilabelStratifiedShuffleSplit(n_splits=1,
                                              test_size=val_size,
                                              random_state=random_state)

      train_indices, test_indices = next(msss.split(np.zeros(len(label_matrix)), label_matrix))

      train_data = [entities[i] for i in train_indices]
      test_data = [entities[i] for i in test_indices]

      return train_data, test_data
  ```,
  kind: "fun",
  caption: [La funzione `stratified_split` si occupa di dividere i dati in training set e validation set in modo stratificato.],
)

Grazie a `MultilabelStratifiedShuffleSplit` dal modulo di estensione di scikit-learn `iterstrat.ml_stratifiers`, è possibile dividere i dati in modo stratificato, garantendo che le proporzioni delle etichette siano mantenute sia nel training set che nel validation set. Questo è particolarmente importante quando si lavora con dataset multiclasse, in cui alcune etichette possono essere sottorappresentate e rischierebbero di non essere presenti in uno dei due set.

==== Addestramento del modello

Vediamo ora a step come la funzione `train_spacy` è implementata. Questa funzione si occupa di addestrare un modello di Named Entity Recognition con spaCy, partendo dai dati preparati e suddivisi in precedenza.

1. Creazione del modello spaCy a partire da zero: definiamo una nuova pipeline vuota, a cui viene aggiunto esclusivamente il componente per la NER. Registriamo anche tutte le etichette possibili nella pipeline:
  #align(center)[
    ```python
    nlp = spacy.blank(language)
    ner = nlp.add_pipe('ner', last=True)

    for label in label_list:
      ner.add_label(label)
    ```
  ]
  Normalmente, nel caso in cui si dovesse addestrare una pipeline più complessa, spaCy offre la possibilità di descriverla in un file di configurazione. Dal momento che la NER sarà preparata per un sistema più grande, è preferibile cercare di ridurre al minimo i file intermedi di configurazione proprio per permettere un controllo più centralizzato.
2. Training loop. Per ogni iterazione:
  1. Si mescola il training set che viene poi diviso in piccoli batch:
    #align(center)[
      ```python
      random.shuffle(train_data)
      batches = minibatch(items=train_data,size=compounding(4.0, 32.0, 1.001))
      ```
    ]
    Il parametro del compounding permette di incrementare gradualmente la dimensione dei batch, partendo da un valore minimo fino a un valore massimo, in modo da bilanciare la varianza e la stabilità dell'addestramento
  2. Si itera sui batch e si aggiorna il modello. Usando la funzione `make_example` definita in precedenza, si convertono gli esempi in un formato compatibile con spaCy e si aggiornano i pesi del modello tramite la funzione `update` (che userà internamente la discesa del gradiente):
    #align(center)[
      ```python
      for batch in batches:
        examples = [el.make_example(nlp) for el in batch]
        nlp.update(examples, drop=0.5, sgd=optimizer, losses=losses)
      ```
    ]
3. Valutazione. Alla fine di ogni epoca, si valuta il modello sul validation set e si calcolano le metriche di interesse (precision, recall, F1 score):
  #align(center)[
    ```python
    with nlp.use_params(optimizer.averages):
      examples = [el.make_example(nlp) for el in val_data]
      scores = nlp.evaluate(examples)
    ```
  ]

Come si può notare, l'addestramento di un modello di NER con spaCy richiede poche righe di codice, grazie alla semplicità e alla flessibilità della libreria. Inoltre, la modularità delle componenti (tra cui `NERData`, `prepare_multilabel_data`, `stratified_split`) permette di mantenere il codice pulito e facilmente estendibile, adattandolo a nuovi dataset o a nuove esigenze.

=== Valutazione e performance

#figure(
  image("../media/f1_ner.png"),
  kind: "plot",
  caption: [Performance di F1 del modello di NER durante l'addestramento.],
)

Anche nel caso della Named Entity Recognition la metrica di riferimento è l'F1 score, che tiene conto sia della precisione che del recall del modello. Nel grafico sopra, possiamo vedere come l'F1 score del modello si stabilisca quasi fin dall'inizio oltre il 90%, confermando la bontà del training set e la capacità del modello di generalizzare correttamente le entità riconosciute.

Prese singolarmente, le tre tipologie di entità del training set (`input`, `node`, `language`) mostrano performance molto simili, con un F1 score medio intorno al 92%. Questo indica che il modello è in grado di riconoscere con precisione e recall elevati le entità di interesse, indipendentemente dalla loro categoria.
