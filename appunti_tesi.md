# 1. Compilatore programmatico

- Scritto in kotlin
- Utilizza un file contenente l'automa rappresentato col linguaggio graphviz
- Genera un file AIML che contiene tutte le regole e le possibili domande riguardanti l'automa

## Pro e contro

### Pro

- Facilità di utilizzo
- Velocità di esecuzione

### Contro

- Le regole sono molto stringenti sulla forma delle domande che possono essere fatte, e per poter permettere una
  corretta risposta è necessario che l'utente conosca la forma delle domande che può fare, e che le rispetti
- Non è possibile fare domande complesse
- Le risposte sono molto limitate e ripetitive

# 2. Ricerca successiva per migliorare i contro del compilatore

Problemi da risolvere:

1. Le regole sono molto stringenti sulla forma delle domande che possono essere fatte
2. Le risposte sono molto limitate e ripetitive

Finora mi sono concentrato sulla generazione delle regole AIML, ma non ho ancora pensato a come migliorare le risposte.
La direzione che ho preso si basa sulla costruzione di alcuni modelli fondati su reti neurali che permettano di
riconoscere con maggiore flessibilità le domande poste dagli utenti.

Il piano è di dividere la gestione di una domanda (lato riconoscimento) in due step:

1. Riconoscimento dell'argomento della domanda
2. Riconoscimento dei complementi della domanda (se presenti), come il riferimento a nodi o input dell'automa o degli
   archi. Questi saranno poi usati per riempire degli slot.

## 2.1. Ricerca di modelli di reti neurali

Prima dell'utilizzo di modelli di reti neurali ho investigato ancora sulla possibilità di utilizzare dei modelli
statistici costruiti automaticamente. Questo principalmente per la velocità di
esecuzione e la footprint ridotta rispetto a modelli di reti neurali.
Spacy era un'opzione, tuttavia dopo aver scoperto BERT (https://arxiv.org/abs/1810.04805) ho deciso di orientarmi verso
l'utilizzo di modelli di reti neurali basati sui Transformer.

### 2.2 Ricerca di modelli di reti neurali per il riconoscimento di domande

Praticamente subito sono arrivato a BERT, un modello di rete neurale basato sui Transformer sviluppato da Google.
BERT è preaddestrato su un corpus di testo molto grande; esistono diverse versioni che idealmente dovrebbero essere
utilizzate in base alla quantità di risorse disponibili, considerando anche il task che si vuole svolgere.

È stato essenziale un primo periodo di studio e sperimentazione con l'architettura di BERT.
Durante questa prima fase ho utilizzato indicazioni per il fine tuning di modelli presenti su alcuni paper, tra
cui https://arxiv.org/abs/2004.10964

Tuttavia in seguito ho deciso di utilizzare la libreria `Transformers` di
HuggingFace (https://arxiv.org/abs/1910.03771), che permette di utilizzare modelli preaddestrati e fornisce ottime API
per l'addestramento, il fine tuning e in generale per l'interazione con modelli di reti neurali basati sui Transformer.

Oltre a BERT "base" ho anche utilizzato DistilBERT (https://arxiv.org/abs/1910.01108), una versione distillata di BERT
che riesce a mantenere buone
performance con una footprint ridotta.

Durante il lavoro di ricerca mi sono concentrato sul perfezionamento anche dei parametri di fine-tuning; per questo
oltre a una serie di tentativi sperimentali in autonomia, ho usato come base di partenza il lavoro di altri
ricercatori (https://arxiv.org/abs/2006.04884) che hanno perfezionato i parametri di fine-tuning di BERT per la
classificazione di testo, per evitare problemi di overfitting e/o vanishing/exploding gradient.

### 2.3 Fine tuning di BERT

BERT è un modello preaddestrato e supervisionato, quindi per poter effettuare il fine tuning è necessario avere un
dataset etichettato.

Sono partito dalle circa 200 domande prodotte durante i vari test con gli utenti svolti in precedenza.

#### 2.3.1 Preparazione del dataset

I dati iniziali sono una collezione delle interazioni degli utenti con il sistema quando le interazioni erano state
costruite a mano.
Per poter utilizzare questi dati per il fine tuning di BERT è stato necessario:

1. Estrarre tutte le domande escludendo le risposte del sistema
2. Etichettare le domande con l'argomento a cui si riferiscono

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
Inizialmente ho pensato di etichettare automaticamente le domande utilizzando un modello di LLM locale.

#### 2.3.2 Etichettatura automatica delle domande

Per poter automatizzare l'etichettatura usando una LLM, prima di tutto ho identificato l'insieme delle possibili
etichette.

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

Ogni etichetta è associata a una descrizione che aiuta a capire a cosa si riferisce, specialmente per permettere alla
LLM di etichettare correttamente le domande togliendo il più possibile le ambiguità.

Per avere una maggiore sicurezza nella correttezza delle etichette, ho preferito utilizzare più modelli di LLM:

- Gemma 2 (https://arxiv.org/abs/2408.00118), sviluppato da Google
- llama 3.1 (https://arxiv.org/abs/2407.21783), sviluppato da Meta

Ogni modello ha ricevuto più prompt diversi con le stesse domande, in modo da poter poi effettuare un majority voting
per stabilire l'etichetta finale.

I modelli sono stati utilizzati nelle loro varianti da 9 miliardi di parametri per gemma (intermedio) e 8 miliardi per
llama3.1 (più piccolo), in seguito ad alcune veloci sperimentazioni che hanno mostrato un buon compromesso tra
performance (intese come qualità dei risultati prodotti in seguito al prompting) e tempo di esecuzione.

Ho ulteriormente provato ulteriore modello, Qwen (https://arxiv.org/abs/2309.16609), prodotto da Alibaba, ma i risultati
non sono stati soddisfacenti.

Utilizzando le risorse hardware a disposizione, ho effettuato il prompting delle domande con i modelli di LLM. Segue un
esempio di codice python che mostra come è stato effettuato il prompting.
È inclusa una classe `Chat`, da me sviluppata, che permette di interagire con i modelli di LLM in modo più semplice,
astraendo le API di ollama.

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
        progress_bar = tqdm(total=dataset_size, desc=f"Asking {model} with prompt {p_i}", unit="rows")

        for r_i, row in df.iterrows():
            text = row["Text"]

            prompt = prompts[0].replace("{text}", text)

            inferred_label = chat.interact(prompt, stream=True, print_output=False, use_in_context=False)
            inferred_label = inferred_label.strip().replace("'", "")

            res_df.at[r_i, f"{model} {p_i}"] = inferred_label
            progress_bar.update()

        print(progress_bar.format_dict["elapsed"])
        progress_bar.close()
```

Ecco un esempio dei risultati dell'etichettatura del bronze dataset:

| index | gemma2:9b 0                                     | gemma2:9b 1    | llama3.1:8b 0  | llama3.1:8b 1  |
|-------|-------------------------------------------------|----------------|----------------|----------------|
| 0     | START                                           | START          | START          | START          |
| 1     | GEN_INFO                                        | GEN_INFO       | GEN_INFO       | GEN_INFO       |
| 2     | SPEC_TRANS                                      | SPEC_TRANS     | TRANS_BETWEEN  | TRANS_BETWEEN  |
| 3     | SPEC_TRANS                                      | SPEC_TRANS     | TRANS_BETWEEN  | TRANS_BETWEEN  |
| 4     | Please provide the interaction.  \nLABEL: START | START          | START          | START          |
| ...   | ...                                             | ...            | ...            | ...            |
| 285   | OPT_REP                                         | OPT_REP        | OPT_REP        | OPT_REP        |
| 286   | GRAMMAR                                         | GRAMMAR        | GRAMMAR        | GRAMMAR        |
| 287   | REPETITIVE_PAT                                  | REPETITIVE_PAT | REPETITIVE_PAT | REPETITIVE_PAT |
| 288   | TRANS_DETAIL                                    | TRANS_DETAIL   | TRANS_DETAIL   | GEN_INFO       |
| 289   | GRAMMAR                                         | GRAMMAR        | FINAL_STATE    | FINAL_STATE    |

Combinare i risultati tramite majority voting è stato essenziale, in quanto i modelli di LLM non sono perfetti e alcune
volte sono state prodotte risposte completamente estranee rispetto alle etichette fornite.

```python
from collections import Counter


def majority_vote(row: pd.Series):
    label_counts = Counter(row)
    majority_label = label_counts.most_common(1)[0][0]
    return majority_label
```

In seguito ad una prima fase di fine tuning tuttavia, ho verificato che nonostante un'etichettatura valida, le classi
identificate erano troppo sbilanciate, con alcune classi che contenevano pochissimi esempi. In più, le etichette erano
troppo generiche e non permettevano di identificare con precisione l'argomento della domanda.

Per questo motivo ho proceduto con una revisione delle etichette, e una successiva etichettatura manuale delle domande.

#### 2.3.3 Nuove classi e etichettatura manuale

Prima di tutto ho effettuato una ulteriore passata di revisione delle domande, escludendo quelle non pertinenti o
incomprensibili.
Durante questa fase ho compreso che non sarebbe stato sufficiente utilizzare un solo "livello" di etichette, ma che
sarebbe stato necessario utilizzare un sistema di etichettatura gerarchico, in modo da poter identificare con maggiore
precisione l'argomento della domanda, riducendo il numero di classi principali.

Le classi principali, che rappresentano l'argomento generale della domanda, sono state ridotte a 7:

| Classe         | Descrizione                                                         | Numero di Esempi |
|----------------|---------------------------------------------------------------------|------------------|
| **transition** | Domande che riguardano le transizioni tra gli stati                 | 77               |
| **automaton**  | Domande che riguardano l'automa in generale                         | 48               |
| **state**      | Domande che riguardano gli stati dell'automa                        | 48               |
| **grammar**    | Domande che riguardano la grammatica riconosciuta dall'automa       | 33               |
| **theory**     | Domande di teoria generale sugli automi                             | 15               |
| **start**      | Domande che avviano l'interazione con il sistema                    | 6                |
| **off_topic**  | Domande non pertinenti al dominio che il sistema deve saper gestire | 2                |

Le classi secondarie, che rappresentano l'argomento specifico della domanda dipendono dalla classe principale. Per
questo motivo il loro numero è variabile, ma in totale si tratta di 33 classi (**count**: 29,**existence_from**: 18,
**list**: 17,**description**: 16,**accepted**: 14,**representation**: 13,**existence_between**: 12,**transitions**: 12,
**description_brief**: 10,**pattern**: 10,**existence_directed**: 9,**start**: 8,**final**: 8,**symbols**: 7,**off_topic
**: 6,**cycles**: 4,**label**: 4,**example_input**: 4,**final_list**: 3,**states**: 3,**generic**: 3,**variation**: 2,
**greet**: 2,**final_count**: 2,**validity**: 2,**simulation**: 2,**regex**: 2,**definition**: 2,**input**: 1,
**existence_into**: 1,**directionality**: 1,**details**: 1,**self_loop**: 1).

Dal momento che le classi secondarie sono dipendenti dalle classi principali, ho deciso di etichettare prima le classi
principali e poi le classi secondarie.

Dal momento che il numero di esempi è piuttosto ridotto (229), e inoltre le classi sono sbilanciate, ho deciso di
arricchire i dati con ulteriori domande generate automaticamente e manualmente. Ho aggiunto un totale di 525 domande,
con la seguente distribuzione:

| Classe         | Numero di Esempi aggiuntivi |
|----------------|-----------------------------|
| **transition** | 148                         |
| **automaton**  | 93                          |
| **state**      | 56                          |
| **grammar**    | 111                         |
| **theory**     | 100                         |
| **start**      | 17                          |

Le domande off-topic aggiuntive sono state estratte dal dataset Squad (Stanford Question Answering Dataset) v2
(https://aclanthology.org/D16-1264/, https://aclanthology.org/P18-2124/), per avere una sufficiente varietà di domande
non pertinenti.

# Proposte

Il compilatore inizialmente doveva produrre soltanto un file AIML, con le interazioni e i dati già previsti e fissati
nella pietra. Tuttavia, a parer mio, questo genere di approccio risulta poco flessibile e prono a produrre grosse
quantità di dati. Sì che è possibile anche utilizzare regole annidate e simili, ma in un mondo dove oggi siamo in grado
di interagire con una LLM, credo che bisogni cercare di puntare a proporre un "AIML" più adatto a quello che oggi ci si
aspetta da un motore di chat e interrogazioni.

Per questo motivo inizialmente ho dedicato tutto il tempo alla ricerca delle tecniche più efficaci per il riconoscimento
dei quesiti dell'utente, finito con l'utilizzo di BERT dopo fine-tuning. Allo stesso modo, per identificare i soggetti
di una domanda, il NER dovrebbe essere sufficiente.

Detto questo, proporrei un nuovo genere di sistema, di cui il compilatore è solo una parte.
Nello specifico, si tratta di una pipeline che integra diversi step, partendo da un compilatore e finendo in un motore
di esecuzione per il question answering su topic ristretti e specifici.

## Cosa fa il compilatore

Il compilatore invece di dover costruire un file AIML in output, lavora su più stadi, e necessita di una configurazione
più approfondita.

Nello specifico, richiede i seguenti dati:

1. Per ogni genere (classe) di domanda possibile nel dominio da analizzare, devono essere forniti dei piccoli dataset di
   domande che possano essere usati per comporre i dati con cui viene effettuato il fine-tuning di BERT.
2. Come per le classi di domande, ogni genere di Named Entity potenzialmente richiesta deve essere compresa in un
   dataset
   taggato per addestrare un modello che si occupi di NER.
3. Infine, non possono mancare anche i dati effettivi sui quali deve essere costruita una piccola knowledge base. Dato
   che ogni classe può richiedere informazioni diverse dalla knowledge base, possono essere utili delle regole per
   recuperare i dati relativi alla domanda appena posta. La regola può essere espressa in JSONPath o JMESPath o un altro
   linguaggio di query da decidere (un'opzione decisamente più complessa può essere ad esempio SPARQL, proventiente dal
   dominio del web semantico)

