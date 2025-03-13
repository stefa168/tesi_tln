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

Per mostrare le varie componenti del sistema, sarà utilizzata una _configurazione giocattolo_, composta da poche interazioni accettate dal chatbot, usando lo stesso automa visibile nel @fsa_eval della @raccolta-domande. Questo ci permetterà di vedere al meglio tutte le funzionalità attualmente implementate.

== Compilatore

Come già anticipato, il compilatore si occupa della preparazione di tutte le risorse che poi saranno necessarie a tempo di runtime: verifica dei dati di addestramento, costruzione dei modelli neurali e raggruppamento delle risorse locali, principalmente.

Potremmo pensare di lasciare i suddetti compiti direttamente al runner: questo comporterebbe tuttavia un tempo di avvio nettamente maggiore. Non scordiamo infatti che l'addestramento di un modello neurale può richiedere ore, se non giorni; il fine-tuning può ridurre i tempi di attesa, che non saranno comunque immediati (si veda come esempio il @fine-tuning-time della @valutazione_ft).

Questo andrebbe contro il bisogno di essere pronti a rispondere ad un utente il più rapidamente possibile: ad oggi ci si aspetta che i servizi web abbiano tempi di risposta pressochè immediati. Secondo le ricerche di #cite(<webpage-wait-time>, form: "prose"), il tempo di attesa accettato da un utente per il caricamento di una pagina web si aggira intorno ai 2 secondi. Possiamo prevedere aspettative simili anche per il nostro sistema.

=== Pipeline

Dovendoci occupare della preparazione potenzialmente di più modelli per un singolo chatbot, è utile poter formalizzare il processo che il compilatore dovrà seguire:
1. In primo luogo è necessario *caricare i dati per l'addestramento*: questo può richiedere anche la partizione dei dati in funzione del task. Per citare un esempio, la divisione è essenziale nel nostro caso d'uso d'esempio, dove abbiamo sia etichette per la classe principale, sia per la classe secondaria (@nuove-classi).
2. Per ogni modello previsto da compilare, procediamo a effettuare il fine-tuning o il training (se NER).
3. Raggruppiamo tutti i dati in modo da renderli pronti per il Runner.

#figure(
  image("../media/compiler.drawio.png", width: 70%),
  kind: "diag",
  caption: [Flusso semplificato delle operazioni di compilazione.],
)

Come è possibile prevedere, è comunque necessario un file di configurazione. È stato scelto il formato YAML @yaml che, grazie ad una sintassi molto semplice, permette di codificare con grande potenza tutte le informazioni della nostra serie di pipeline:

#figure(
  ```yaml
  models:
    - name: "global_subject_classifier"
      type: classification
      steps:
        - type: load_csv
          name: data
          path: "./multitask_training/data_cleaned_manual_combined.csv"
          label_columns: "Global Subject"
        - type: train_model
          name: training
          dataframe: data.dataframe
          pretrained_model: "google/electra-small-discriminator"
          examples_column: "Question"
          labels_column: "Global Subject"
          train_epochs: 20

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

    - name: "question_entities_recognition"
      type: ner
      steps:
        - type: ner_spacy
          name: ner_training
          language: "en"
          training_data_path: "./ner_training/corpus/ner_labels.jsonl"
          training_device: "gpu"
          resulting_model_name: "ner_trained_model"
  ```,
  kind: "snip",
  caption: [Estratto della configurazione che descrive come devono essere addestrati i modelli del chatbot.],
)<compiler-conf-snip>

Sotto la chiave `models` troviamo una lista di modelli, ciascuno con una *sequenza* di operazioni che devono essere svolte per poter preparare il proprio modello con successo. Nel @compiler_classes è possibile vedere in dettaglio la struttura delle classi e delle proprietà utilizzate per la compilazione.

Osserviamo più nel dettaglio:
- Il modello `global_subject_classifier` svolge due operazioni: `load_csv` e `train_model`.
  1. `load_csv` carica i dati da un file CSV, specificando quali colonne contengono le etichette per poter effettuare delle operazioni di pre-processing volte a preparare i dati per l'addestramento.
  2. `train_model` effettua il fine-tuning di un modello pre-addestrato, specificando quali colonne del dataframe contengono gli esempi e le etichette da usare per l'addestramento, e quanti cicli di addestramento effettuare.
- Il modello `question_intent_classifiers` ha tre operazioni: `load_csv`, `split_data` e `train_model`.
  1. `load_csv` è analogo a prima.
  2. `split_data` suddivide i dati in base ad una colonna specificata, e per ogni valore unico di quella colonna effettua un addestramento separato.
  3. `train_model` è analogo a prima, con l'aggiunta di un parametro `resulting_model_name` che permette di specificare il nome del modello addestrato tramite un template.
- Il modello `question_entities_recognition` ha una sola operazione: `ner_spacy`, che addestra un modello di NER usando il framework Spacy, specificando il percorso del corpus di addestramento e il dispositivo su cui addestrare il modello.

#figure(
  image("../media/diags/compiler_classes.svg"),
  kind: "diag",
  caption: [Class Diagram raffigurante le classi e proprietà utilizzate per la compilazione.],
) <compiler_classes>

La peculiarità del sistema è la gestione degli step: ogni passaggio può avere un output che può essere usato come input per un altro step, in quello che è stato definito come un _contesto di esecuzione_. Questo permette di creare pipeline dalla grande potenza espressiva, conservando comunque la semplicità di una configurazione YAML.

Durante la compilazione, la classe `ModelPipelineCompiler` presentata nella @model-compiler segue tre passaggi essenziali:
1. Fa verificare allo step attuale che i suoi requisiti per poter portare a termine l'esecuzione siano soddisfatti (`step.resolve_requirements(context)`). In più, la verifica restituisce tutti gli elementi necessari per l'effettiva esecuzione;
#figure(
  ```python
    def resolve_requirements(self, context: dict[str, dict[str, Any]]) -> dict[str, Any]:
        context = super().resolve_requirements(context)

        init_spacy_device(self.training_device)

        if not self.training_data_path.exists():
            raise StepExecutionError(f"Training data missing at '{self.training_data_path}'")

        return context
  ```,
  kind: "snip",
  caption: [Funzione di risoluzione dei requisiti per l'addestramento con SpaCy],
)

2. Esegue l'effettivo step (`step.execute(retrieved_inputs, context)`): se è un caricamento di dati, li inserisce nel `context`, se è un addestramento, esegue le rispettive funzioni di fine-tuning o training, ecc.
3. Ultimo passo, non meno importante, è la verifica dell'effettivo successo e conclusione dello step (`step.verify_execution(execution_results)`). Un _sanity check_ è molto importante per assicurarci di aver prodotto dati che non possano invalidare l'intera pipeline.

#figure(
  ```python
  class ModelPipelineCompiler:
      def __init__(self, model: Model, config: CompilerConfigV2):
          """
          Initialize the runner with a validated pipeline configuration.
          """
          self.model = model
          self.config = config

      def run(self, config_path: Path, artifacts_dir: Path):
          """
          Run the pipeline, executing its steps in sequence.
          """

          if self.model.disabled:
              print(f"Skipping disabled model '{self.model.name}'")
              return

          print(f"Running pipeline '{self.model.name}'")

          # Shared context for intermediate outputs
          context: dict[str, dict[str, object]] = {
              'model_metadata': self.model.model_dump(exclude={'steps'}),
              "config": self.config.model_dump(exclude={'models'}),
              "config_path": config_path,
              "artifacts_dir": artifacts_dir,
              "compilation_start_time": datetime.now().strftime('%Y-%m-%d %H:%M:%S')
          }

          step: Step
          for step in self.model.steps:
              try:
                  retrieved_inputs = step.resolve_requirements(context)
                  execution_results = step.execute(retrieved_inputs, context)
                  checked_outputs = step.verify_execution(execution_results)

                  context[step.name] = checked_outputs
              except StepExecutionError as e:
                  print(f"Error executing step '{step.name}': {e}")
                  raise
  ```,
  kind: "cls",
  caption: [La classe adibita alla gestione del context durante la compilazione di ogni modello.],
) <model-compiler>

Dopo l'esecuzione del passo 3, i risultati dello step sono salvati nel dizionario `context`, rendendoli così disponibili agli altri step se mai dovessero averne bisogno. Questo è il motivo per cui ogni step di un modello necessita di un nome univoco: il fine-tuning ad esempio, richiedendo un dataframe, potrà specificare di voler utilizzare i dati del passaggio di caricamento da CSV (`dataframe: data.dataframe` dell'esempio nello @compiler-conf-snip).

== Runner
Una volta che le preparazioni con la compilazione sono state completate, abbiamo tutto il necessario per effettivamente eseguire il chatbot. Compiler e Runner sono due applicativi separati, ma il file di configurazione resta lo stesso.

== Sviluppi futuri
