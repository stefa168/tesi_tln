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

Negli anni #tdd(90) iniziò a guadagnare popolarità il Loebner Prize, una competizione ispirata al Test di Turing @imitation_game.\
Nella competizione, chatbot e sistemi conversazionali cercavano di "ingannare" giudici umani, facendo credere loro di essere persone reali.
Molti sistemi presentati alla competizione erano basati su pattern matching e rule-based, a volte integrando euristiche per la gestione di sinonimi o correzione ortografica.

Tra questi, uno dei più celebri è _ALICE_ (Artificial Linguistic Internet Computer Entity), sviluppato da Richard Wallace utilizzando il linguaggio di markup AIML (Artificial Intelligence Markup Language) da lui introdotto @aiml @alice.\
ALICE vinse per la prima volta il Loebner Prize nel 2000, e in seguito vinse altre due edizioni, nel 2001 e 2004.

=== Struttura di un chatbot AIML

Basato sull'XML @aiml, di base l'AIML fornisce una struttura formale per definire regole di conversazione attraverso *categorie* di _pattern_ e _template_:
- `<pattern>`: la frase (o le frasi) attese in input a cui il chatbot deve reagire;
- `<template>`: la risposta (testuale o con elementi dinamici) che il chatbot fornisce quando si verifica il match del pattern.

La forma più semplice di categoria è:
#align(center)[
```xml
<category>
  <pattern>CIAO</pattern>
  <template>Ciao! Come posso aiutarti oggi?</template>
</category>
```
]

Qui, se l'utente scrive "Ciao" #footnote[Caratteri maiuscoli e minuscoli sono considerati uguali dal motore di riconoscimento.], il sistema restituisce la risposta associata nella sezione del `<template>`.\ \ 
Naturalmente questa è una regola basilare; AIML permette di definire pattern molto più complessi.\
Un primo passo verso la creazione di regole più flessibili è l'uso di wildcard: associando simboli quali #sym.ast e #sym.dash.en a elementi di personalizzazione (`<star/>`), il motore che esegue la configurazione AIML può gestire un certo grado di variabilità linguistica:

#pagebreak(weak: true)

#align(center)[
```xml
<category>
  <pattern>MI CHIAMO *</pattern>
  <template>
    Ciao <star/>, piacere di conoscerti!
  </template>
</category>
```
]

In particolare, il simbolo `*` corrisponde a una wildcard che cattura qualsiasi sequenza di parole in input tra i due pattern specificati.\
In questo caso, se l'utente digita "Mi chiamo Andrea", il sistema sostituisce `<star/>` con "Andrea", e risponde di conseguenza.

#hrule()

Spesso è necessario memorizzare informazioni fornite dall'utente per utilizzarle successivamente. A questo scopo, AIML offre i tag `<set>` e `<get>` che, rispettivamente, memorizzano e recuperano valori da variabili di contesto:

#align(center)[
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
```
]

Nella prima `<category>`, il tag `<think>` fa sì che l'operazione di memorizzazione non produca output testuale per l'utente, ma aggiorni internamente la variabile `colore`.\
Nel secondo blocco, si utilizza `<get name="colore"/>` per restituire all'utente il valore memorizzato.

#hrule()

Il tag `<condition>` permette di definire regole condizionali in base a variabili di contesto.\

Se la variabile stagione (presumibilmente impostata altrove con un `<set>`) ha valore `inverno`, verrà restituito “Fa piuttosto freddo...”. Un risultato simile si ottiene per `estate`, mentre per altri valori o mancanza di valore si restituisce l'ultimo _list item_.

#align(center)[
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
```
]

#hrule()

Il tag `<topic>` permette di raggruppare categorie che appartengono a un medesimo ambito di conversazione, per facilitare la lettura delle regole:

#align(center)[
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
```
]

In questo modo le regole legate ai saluti sono tutte contenute all'interno di un blocco `<topic>` chiamato `saluti`.

#hrule()

Il tag `<srai>`#footnote[Stimulus-Response Artificial Intelligence @aiml] permette di reindirizzare l'input ad un'altra regola, che verrà processata come se fosse stata digitata dall'utente. È molto utile per riutilizzare risposte o logiche già definite:

#align(center)[
```xml
<topic name="saluti">
  <category>
    <pattern>SALUTA *</pattern>
    <template>
      <srai>CIAO</srai>
    </template>
  </category>
</topic>
```
]

Se l'utente scrive "Saluta Andrea", la regola cattura "SALUTA \*" e reindirizza il contenuto (in questo caso “CIAO”) a un'altra categoria.
Se esiste una categoria che gestisce il pattern “CIAO”, verrà attivata la relativa risposta.

Esiste anche una versione contratta di `<srai>` chiamata `<sr>`, che è stata prevista come scorciatoia quando è necessario matchare un solo pattern. Secondo la documentazione, il tag corrisponde a `<srai><star/></srai>`.

#hrule()

Abbiamo già visto `<think>` in azione per evitare che il contenuto venga mostrato all'utente.
In generale, `<think>` è utile quando vogliamo impostare o manipolare variabili senza generare output visibile, ad esempio:

#align(center)[
```xml
<category>
  <pattern>ADESSO È *</pattern>
  <template>
    <think><set name="stagione"><star/></set></think>
    Grazie, ora so che la stagione attuale è <star/>!
  </template>
</category>
```
]

#hrule()

Il tag `<that>` permette di scrivere pattern che dipendono dalla risposta precedentemente fornita dal chatbot. È particolarmente utile per gestire contesti conversazionali più complessi:

#align(center)[
```xml
<category>
  <pattern>GRAZIE</pattern>
  <that>VA TUTTO BENE</that>
  <template>Felice di averti aiutato!</template>
</category>
```
]

In questo caso la regola sarà attivata se la risposta precedente del bot era “VA TUTTO BENE” e l'utente scrive “Grazie”.


#hrule()

Per rendere la conversazione più naturale, AIML 2.0 fornisce `<random>`, che permette di restituire una risposta fra più alternative:

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
```

Ogni volta che l'utente scrive “Come va”, il bot sceglierà casualmente una delle tre risposte elencate.

#hrule()

Alcune versioni di AIML supportano `<learn>`, che consente al bot di aggiungere nuove categorie “al volo” durante l'esecuzione:

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
```

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

Per permettere all'AIML di generalizzare sulle richieste degli utenti, il botmaster deve dichiarare delle generalizzazioni esplicite, ad esempio utilizzando wildcard o pattern che catturano più varianti di una stessa richiesta.
Questo processo richiede tempo e competenze linguistiche, oltre ad una grande attenzione per evitare ambiguità o sovrapposizioni tra regole.

Durante il mio percorso di ricerca ho deciso di seguire una strada simile a quella di AIML, ma facendo un passo indietro e ponendomi la domanda:

#quote()[
  Invece che cercare dei pattern nelle possibili richieste degli utenti, perchè non trovare un modello che possa generalizzare su queste richieste in modo automatico?
]

Il percorso per arrivare al modello di classificazione di intenti ha richiesto i suoi tempi, ma alla fine ho ottenuto dei risultati che ritengo soddisfacenti.

I problemi principali da risolvere per poter classificare gli intenti sono due: la raccolta di dati etichettati e la scelta del modello di classificazione.

=== Dataset di training // Come ho raccolto i dati etichettati per addestrare il modello

Di base, nel mondo dell'apprendimento automatico supervisionato, per addestrare un modello di classificazione è necessario un dataset di esempi etichettati, cioè coppie di input e output che il modello deve apprendere a generalizzare.

Per la classificazione di intenti, i dataset più comuni sono quelli di chatbot e assistenti vocali, che contengono domande e richieste etichettate con l'intento che l'utente vuole esprimere.

Il dataset originario fornitomi è stato composto in seguito a una campagna di raccolta dati manuale, in cui diversi collaboratori hanno interagito con un prototipo di chatbot AIML, ponendo domande e richieste di vario tipo.

Il dataset è una collezione di circa 700 singole interazioni, metà sotto forma di domande degli utenti durante la prima fase di sperimentazione, e l'altra che coincide con ciò che il chatbot ha risposto.

==== Estrazione dei dati

Dovendo addestrare un modello di classificazione, ho proceduto innanzitutto con l'estrazione dei dati effettivamente a noi necessari. Un piccolo script python che adopera la libreria `pandas`@pandas è stato sufficiente:

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
  caption: [Estrazione dei dati dal dataset di interazione.]
)

Estratte le domande, si è potuto procedere con l'etichettatura.

In un primo step, ho considerato la possibilità di lasciare il compito di etichettatura delle domande ad un sistema che svolgesse il compito in automatico.\
Questo permetterebbe di avere un dataset decorato, senza dover ricorrere a un'etichettatura manuale che sarebbe stata molto dispendiosa in termini di tempo e risorse, specialmente in ottica di un incremento dei dati del dataset in seguito a nuove interazioni con il chatbot.

Per fare ciò, ho rivolto la mia attenzione ai modelli di linguaggio neurali, in particolare alle Large Language Models (LLM), dal momento che sono in grado di generalizzare su una vasta gamma di task linguistici, inclusa la classificazione di intenti.

Con l'estrema disponibilità attuale di modelli pre-addestrati e API che permettono di interagire con essi, ho potuto sperimentare diverse soluzioni per l'etichettatura automatica delle domande.\
In particolare, ho deciso di sperimentare con modelli di LLM open-source, dal momento che sono eseguibili localmente e permettono di mantenere i dati sensibili all'interno dell'ambiente di lavoro, senza doverli condividere con servizi esterni.\
Per utilizzarli, si sono rivelate fondamentali le API fornite da Ollama @ollama, un sistema per hostare localmente modelli di LLM open source (e in certi casi anche _open-weights_).

==== Etichettatura automatica delle domande
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
  caption: [Etichette possibili per le domande del dataset.]
)

In questa mappa, ad ogni etichetta è associata una descrizione che indica alla LLM un contesto in cui collocarla, con lo scopo di assistere la LLM ad etichettare correttamente le domande togliendo il più possibile le ambiguità.\
Questo genere di task è del tipo zero shot, in cui il modello non ha mai visto i dati di training e deve etichettare le domande esclusivamente in base a un contesto fornito.

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
  caption: [Prompt utilizzati per l'etichettatura delle domande.]
)

Si notino le differenze tra i due prompt: il primo è più dettagliato e fornisce una spiegazione più approfondita delle etichette, mentre il secondo è più conciso e diretto.

I tag tra parentesi graffe vengono sostituiti con i valori attualmente in uso, in modo da rendere il prompt più generico e riutilizzabile.

Segue un estratto di codice python che mostra come è stato effettuato il prompting.
È inclusa una classe `Chat`, da me sviluppata, che permette di interagire con i modelli di LLM in modo più semplice, astraendo le API di ollama.

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
  caption: [Prompting delle domande con i modelli di LLM.]
)

Ecco un esempio dei risultati dell'etichettatura del bronze dataset, in seguito al prompting con i modelli di LLM:

#figure(
  align(center)[
    #show table.cell.where(y: 0): strong
    #set text(size: 10pt)
    #table(
    columns: (0.3fr, 1fr, 1fr, 1fr, 1fr),
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
  )], 
  kind: table,
  caption: [Esempio di etichettatura delle domande del bronze dataset.]
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
  caption: [Funzione di majority voting per combinare le etichette.]
)

Tuttavia, in seguito ad una prima fase di fine tuning, ho verificato che nonostante un'etichettatura valida, le classi identificate erano troppo sbilanciate, con alcune classi che contenevano un numero troppo esiguo di esempi.
In più, ho realizzato che le classi scelte erano troppo generiche; questo non avrebbe permesso di identificare con precisione l'argomento della domanda.

Per questo motivo ho proceduto con una revisione delle etichette, e una successiva etichettatura manuale delle domande.

==== Nuove classi e etichettatura manuale
Prima di proseguire con l'etichettatura, ho provveduto a ripulire il dataset da domande non pertinenti o duplicate.
Una volta fatto, ho deciso di ridurre il numero di classi, in modo da poter avere un dataset più bilanciato e con classi più specifiche.\
Avendone ridotto il numero, per ottenere un livello di granularità maggiore, ho deciso di utilizzare un sistema di etichettatura gerarchico, in modo da poter identificare con maggiore precisione l'argomento della domanda.
\
Ne sono risultati sono due livelli di classi:
- Le _classi principali_ (o _question intent_, si veda la @classi-principali), che rappresentano l'argomento generale della domanda, per un totale di 7 classi;
- Le _classi secondarie_, che rappresentano l'argomento specifico della domanda, dipendono dalla classe principale e sono 33 in totale. A seconda della classe principale, il numero di classi secondarie varia.

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

#figure(
  caption: [Le 6 classi secondarie del dataset per la classe primaria dell'*automa*.]
)[
  #show table.cell.where(y: 0): strong
  #show table.cell.where(x: 0): strong
  #table(
    columns: (auto, auto, auto),
    table.header[Sottoclassi][Scopo][Numero di Esempi],
    table.hline(),

    [description], [Descrizioni generali sull'automa],[14],
    [description_brief], [Descrizione generale (breve) sull'automa],[10],
    [directionality], [Domande riguardanti la direzionalità o meno dell'intero automa],[1],
    [list], [Informazioni generali su nodi e archi],[1],
    [pattern], [Presenza di pattern particolari nell'automa],[9],
    [representation], [Rappresentazione spaziale dell'automa] ,[13],
  )
]

#figure(
  caption: [Le 11 classi secondarie del dataset per la classe primaria delle *transizioni*.]
)[
  #show table.cell.where(y: 0): strong
  #show table.cell.where(x: 0): strong
  #table(
    columns: (auto, auto, auto),
    table.header[Sottoclassi][Scopo][Numero di Esempi],
    table.hline(),
    
    [count],[Numero di transizioni], [10],
    [cycles],[Domande riguardo anelli tra nodi],[4],
    [description], [Descrizioni generali sugli archi],[2],
    [existence_between], [Esistenza di un arco tra due nodi],[12],
    [existence_directed], [Esistenza di un arco da un nodo a un altro],[9],
    [existence_from],[Esistenza di un arco uscente da un nodo],[18],
    [existence_into],[Esistenza di un arco entrante in un nodo],[1],
    [input],[Ricezione di un input da parte di un nodo],[1],
    [label],[Indicazione di quali archi hanno una certa etichetta],[4],
    [list], [Elenco generico degli archi],[15],
    [self_loop], [Esistenza di self-cycles],[1],
  )
]

#figure(
  caption: [Le 8 classi secondarie del dataset per la classe primaria degli *stati*.]
)[
  #show table.cell.where(y: 0): strong
  #show table.cell.where(x: 0): strong
  #table(
    columns: (auto, auto, auto),
    table.header[Sottoclassi][Scopo][Numero di Esempi],
    table.hline(),

    [count], [Numero di stati],[19],
    [details],[Dettagli specifici su uno stato],[1],
    [list],[Elenco generale degli stati],[1],
    [start], [Qual è lo stato iniziale],[8],
    [final], [Esistenza di uno stato finale], [7],
    [final_count], [Numero di stati finali], [2],
    [final_list], [Elenco degli stati finali], [3],
    [transitions], [Connessioni tra gli stati],[8],
  )
]

#figure(
  caption: [Le 7 classi secondarie del dataset per la classe primaria della *grammatica*.]
)[
  #show table.cell.where(y: 0): strong
  #show table.cell.where(x: 0): strong
  #table(
    columns: (auto, auto, auto),
    table.header[Sottoclassi][Scopo][Numero di Esempi],
    table.hline(),

    [accepted], [Grammatica accettata dall'automa],[14],
    [example_input],[Input di esempio accettato dall'automa],[4],
    [regex],[Regular expression corrispondente all'automa],[2],
    [simulation], [Simulazione dell'automa con input dell'utente],[8],
    [symbols], [Simboli accettati dalla grammatica], [7],
    [validity], [Validità di un input fornito], [2],
    [variation], [Richiesta di simulazione su un automa modificato], [2],
  )
]

==== Data Augmentation

Come evidenziato nella sezione precedente, diverse classi secondarie contengono un numero esiguo di esempi, non sufficiente per una buona classificazione in seguito al fine-tuning.

Avendo solo 229 esempi, ho arricchito i dati con ulteriori domande generate automaticamente e manualmente.
Ho aggiunto un totale di 525 domande, con la seguente distribuzione:

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
    [#strong[off\_topic]], [100],
  )], kind: table
)

Le domande off-topic aggiuntive sono state estratte dal dataset SQUAD #footnote[Stanford Question Answering Dataset] v2 @squad1 @squad2, per avere una sufficiente varietà di domande non pertinenti.

Anche le classi secondarie hanno ricevuto alcune migliorie alla distribuzione, che rimane comunque ancora sbilanciata: 
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

Nonostante lo sbilanciamento, è stato possibile ottenere dei buoni risultati in seguito al fine-tuning.

L'utilizzo del dataset SQUAD ha anche introdotto un'ulteriore incremento delle performance, portando a una diminuzione dell'erronea classificazione di esempi off-topic come domande lecite. In particolare, le metriche di entropia e confidenza durante il fine tuning sono migliorate rispettivamente del 17 e del 7%.

=== Fine-tuning // Cosa ho usato delle LLM per fare classificazione

Senza addentrarmi troppo nei dettagli per il momento, ho provato due metodi per effettuare il fine-tuning, dal momento che non si tratta di una semplice classificazione multiclasse:
- *multitask training* @multitask, dove invece di avere un solo layer finale di classificazione posto in cima al transformer pre-trainato di BERT ne sono presenti due posizionati in parallelo
- *hierarchical training* @hierarchical, dove si utilizza una tecnica (di tante varianti possibili) in cui si procede nella classificazione delle etichette "a step".

// - Addestramento di un modello di classificazione tramite Bert
//   - Spiegazione di BERT con puntatore all'appendice sui transformer
//   - Paper di riferimento per gli iperparametri
//   - Utilizzo delle librerie di Hugging Face, con snippet di codice

=== Valutazione e performance // Spiegazione di come ho valutato i risultati dei classificatori

== Riconoscimento delle entità

=== NER e Slot-filling // Spiegazione di cosa sono 

=== Spacy // Come ho implementato la parte di NER con spacy

=== Valutazione e performance

// Metriche di valutazione (F1 con CoNLL, ACE, MUC https://www.davidsbatista.net/blog/2018/05/09/Named_Entity_Evaluation/)

== Dataset <dataset> // Data augmentation con LLM, prompt e valutazione manuale

=== Etichettatura automatica // Classificazione automatica con LLM + snippet estesi nell'appendice

=== Data augmentation 

=== Etichettatura manuale