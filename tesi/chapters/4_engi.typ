#let hrule() = align(center, line(length: 60%, stroke: silver))

= Ingegnerizzazione <engi>
Al momento della sua concezione, questa tesi doveva vertere sulla sola ricerca e sviluppo di un «compilatore» che fosse in grado di assemblare una configurazione per un chatbot AIML, partendo dai dati di un automa a stati finiti.\
L'idea era che, una volta sviluppate le basi, il compilatore per NoVAGraphS fosse adattabile con sufficiente facilità ad altri domini non collegati ai FSA.

Fin dalle prime sperimentazioni del prototipo di compilatore tuttavia ci accorgemmo di tre principali problematiche da risolvere, già discusse nella @limiti-aiml:
1. AIML non offre metodi al di fuori del *pattern matching* per identificare la regola di interazione che deve essere attivata. L'unica possibilità in questo caso sarebbe lo studio delle possibili variazioni linguistiche di una certa interazione per determinare una espressione regolare in grado di includere il maggior numero di variazioni possibili.\ È evidente tuttavia come questa opzione sia estremamente dispendiosa e complessa da un punto di vista attuativo e progettuale;
2. Le *risposte fornite* sono circoscritte all'insieme predisposto al momento della progettazione dell chatbot. Dover prevedere ed elencare multiple forme della risposta, per ogni possibile dato richiesto, è un'operazione a dir poco monumentale, se non persino un po' folle e raffigurerebbe l'anti-pattern per eccellenza, condannando il file alla totale impossibilità di manutenzione;
3. *Codificare i dati* di una struttura informativa per poterli poi interrogare non è una funzionalità prevista da AIML. Questo è il motivo per cui la precedente problematica è di difficile risoluzione. Sfortunatamente AIML non predispone modi per interagire con dati esterni; averli permetterebbe di prevedere una sola risposta in grado di reperire i dati richiesti e restituirli all'utente, rimuovendo la necessità di duplicare molteplici volte le stesse risposte con la sola variazione dei dati in output.

Esiste la possibilità di integrare servizi esterni tramite il tag `<sraix>`@aiml; questa opzione tuttavia non dovrebbe essere l'unico modo per poter riconoscere interazioni non previste, o interrogare dati esterni: usarlo per risolvere ogni nostro problema, effettuando chiamate ad API esterne, dimostra come non sia adeguato per gli obiettivi di NoVAGraphS.

A questo punto, una volta determinate le migliorie apportabili, davanti a noi vi erano due vie percorribili:
#enum(numbering: "a.")[
  Estendere uno degli interpreti AIML, come `aiml-high`@aiml-high (implementato in JavaScript ECMAScript 5 e non più manutenuto) o `python-aiml`@python-aiml per aggiungere le funzionalità necessarie per NoVAGraphS;
][
  Sviluppare una nuova soluzione che alla base abbia le tre problematiche come punti saldi da supportare in primo luogo.
]

Considerando l'attuale stato del panorama di AIML open source @aiml-high @python-aiml, e valutando i benefici che l'introduzione di nuove tecniche avrebbero potuto portare, ho deciso di progettare un nuovo sistema in grado di risolvere le problematiche sollevate. In questo modo:
1. Invece del pattern matching si può _anche_ utilizzare un *classificatore neurale* per determinare la classe d'interazione dell'utente. Chiaramente anche in questo caso avremo da raccogliere un certo numero di domande per ogni classe di interazione per poterle riconoscere con adeguata affidabilità. Il vantaggio risiede nel fatto che, una volta determinate le classi di interazione, sarà sufficiente utilizzare un algoritmo di addestramento (fine-tuning se si usa un Transformer) per ottenere un modello pronto all'uso.\ Oltre alla ridotta necessità di lavoro umano al di fuori della classificazione iniziale, è sempre possibile introdurre nuove classi semplicemente usando una tecnica di transfer learning, di cui il fine-tuning fa parte @strangmann2024transferlearningfinetuninglarge;
2. Per le risposte, è possibile continuare ad utilizzare un insieme di frasi pre-costruite (template); alternativamente si può lasciare la composizione della risposta a una LLM usando dei prompt ad-hoc per ogni possibile interazione, così da massimizzare la qualità della risposta generata.
3. L'interazione coi dati (o API esterne) è lasciata a moduli di retrieval estensibili, in modo da poter personalizzare il sistema per soddisfare le necessità del dominio di applicazione.

== Panoramica del sistema
L'intero sistema è diviso in due sezioni: il *compilatore* e il *runner*, che verranno approfonditi nelle sezioni successive. Possiamo definirli nel modo seguente:

Il *Compilatore* permette ai botmaster di progettare in modo dichiarativo i modelli necessari per poter interagire con l'utente nel dominio di applicazione.\
Consideriamo come esempio il dominio degli automi a stati finiti: indicativamente dovremo saper rispondere a domande sugli stati dell'automa, e le transizioni che li collegano. Dovranno quindi essere raccolti degli esempi delle interazioni che saranno poi usati per addestrare un modello di classificazione, come discusso nella @classificazione-llm. Allo stesso modo la costruzione di un sistema di NER sarà delegata al compilatore.

In questo modo, le difficoltà maggiori nella preparazione dei modelli (che ho anche personalmente riscontrato durante la ricerca) sono astratte, e permettono ai botmaster di concentrarsi sul design del chatbot.

I dati utilizzati a runtime per i modelli e per il retrieval sono infine raggruppati tutti assieme per permettere un deploy più indolore possibile del *Runner*, che si occupa invece di utilizzare ciò che il compilatore ha preparato in anticipo per gestire le interazioni con gli utenti.

Il modo in cui un certo chatbot funzioni, quindi determinare ad esempio il flusso di decisione dell'interazione, è un compito lasciato al botmaster.\ _Da grandi poteri derivano grandi responsabilità_, potremmo anche dire...

Se le funzionalità del compilatore o del runner non dovessero soddisfare qualche necessità particolare, è sempre lasciata totale libertà di aggiungerne di nuove partendo da quelle di base: per questo motivo, il linguaggio scelto per l'implementazione sarà Python, data la sua diffusione capillare @jetbrains-python e la grande flessibilità e facilità d'uso.

Per mostrare le varie componenti del sistema, sarà utilizzata una _configurazione giocattolo_, composta da poche interazioni accettate dal chatbot, usando lo stesso automa visibile nel @fsa_eval della @raccolta-domande come dati. Questo ci permetterà di vedere al meglio tutte le funzionalità attualmente implementate.

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

Come è possibile prevedere, è comunque necessario un file di configurazione per poter istruire il sistema alla preparazione dei dataset. È stato scelto il formato YAML @yaml che, grazie ad una sintassi molto semplice, permette di codificare con grande potenza tutte le informazioni della nostra serie di pipeline:

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

È essenziale notare come ogni `Model` contenga una lista di `Step`, una *classe astratta*. L'astrazione permette alla @model-compiler (`ModelPilepileCompiler`), che esegue gli `Step` di essere _implementation agnostic_, permettendo quindi l'introduzione di nuove classi riducendo al minimo l'accoppiamento delle funzionalità @code-smells.

#figure(
  image("../media/diags/compiler_classes.svg", height: 14cm),
  kind: "diag",
  caption: [Class Diagram raffigurante le classi e proprietà utilizzate per la compilazione.],
) <compiler_classes>

Osserviamo più nel dettaglio:
- Il modello `global_subject_classifier` richiede due operazioni: `load_csv` e `train_model`.
  1. `load_csv` carica i dati da un file CSV, specificando quali colonne contengono le etichette per poter effettuare delle operazioni di pre-processing volte a preparare i dati per l'addestramento.
  2. `train_model` effettua il fine-tuning di un modello pre-addestrato, specificando quali colonne del dataframe contengono gli esempi e le etichette da usare per l'addestramento, e quanti cicli di addestramento effettuare.
- Il modello `question_intent_classifiers` prevede tre operazioni: `load_csv`, `split_data` e `train_model`.
  1. `load_csv` è analogo a prima.
  2. `split_data` suddivide i dati in base ad una colonna specificata, e per ogni valore unico di quella colonna esegue una ulteriore sequenza di operazioni. In questo caso l'unica operazione prevista è la seguente;
  3. `train_model` è analogo a prima, con l'aggiunta di un parametro `resulting_model_name` che permette di specificare il nome del modello addestrato tramite un template.
- Il modello `question_entities_recognition` ha una sola operazione: `ner_spacy`, che addestra un modello di NER usando il framework Spacy, specificando il percorso del corpus di addestramento e il dispositivo su cui addestrare il modello.

La peculiarità del sistema è la gestione degli step: ogni passaggio può avere un output che può essere usato come input per un altro step, in quello che è stato definito come un _contesto di esecuzione_. Questo permette di creare pipeline dalla grande potenza espressiva, conservando comunque la semplicità di una configurazione YAML.

Durante la compilazione, la classe `ModelPipelineCompiler` presentata nella @model-compiler segue tre passaggi essenziali:
1. Fa verificare allo step attuale che i suoi requisiti per poter portare a termine l'esecuzione siano soddisfatti (`step.resolve_requirements(context)`). In più, la verifica restituisce tutti gli elementi necessari per l'effettiva esecuzione. Un esempio del metodo di risoluzione è presentato nello @resolve-spacy;
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
  caption: [Funzione di risoluzione dei requisiti, estratta dalla classe per l'addestramento con SpaCy],
) <resolve-spacy>

2. Esegue l'effettivo step (`step.execute(retrieved_inputs, context)`): se è un caricamento di dati, li inserisce nel `context`, se è un addestramento, esegue le rispettive funzioni di fine-tuning o training, ecc.
3. Ultimo passo, non meno importante, è la verifica dell'effettivo successo e conclusione dello step (`step.verify_execution(execution_results)`). Un _sanity check_ è molto importante per assicurarci di aver prodotto dati che non possano invalidare l'intera pipeline.

Dopo l'esecuzione del passo 3, i risultati dello step sono salvati nel dizionario `context`, rendendoli così disponibili agli altri step se mai dovessero averne bisogno. Questo è il motivo per cui ogni step di un modello necessita di un nome univoco: il fine-tuning ad esempio, richiedendo un dataframe, potrà specificare di voler utilizzare i dati del passaggio di caricamento da CSV (`dataframe: data.dataframe` dell'esempio nello @compiler-conf-snip).

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

== Runner
Una volta che le preparazioni con la compilazione sono state completate, abbiamo tutto il necessario per effettivamente eseguire il chatbot. Compiler e Runner sono due applicativi separati, ma il file di configurazione resta lo stesso. Assieme al file specifico del chatbot, è fornito al Runner una seconda configurazione che indica dove individuare gli *Artefatti* della compilazione, quali acceleratori di calcolo (GPU) utilizzare, e le potenziali chiavi private per l'interazione con API esterne.

Nel file specifico del chatbot, sotto la chiave `flows` sono definiti i multipli flussi di interazione con l'utente. Al momento dell'avvio del Runner, tutti i flow vengono scanditi per identificare se vi sono errori (sezioni inaccessibili, loop, ecc.), e successivamente vengono anche identificate le risorse effettivamente necessarie per l'esecuzione del chatbot.

=== Resource Dependency Discovery

Questa serie di *preflight checks* sono essenziali per evitare problemi a runtime, cercando di minimizzare il rischio che l'esperienza dell'utente sia interrotta durante le interazioni.

Il processo di *Resource Dependency Discovery* si basa sull'implementazione da parte di ogni `RunnerStep` (che compongono i `flow`) di un `ResourceDiscoveryMixin` (@mixin-interface).\ Un Mixin @mixin è un pattern di programmazione orientata agli oggetti che consente di “mescolare” funzionalità comuni in diverse classi senza dover ricorrere all'ereditarietà classica. In pratica, un mixin è una classe o un modulo che contiene metodi e attributi pensati per essere riutilizzati da altre classi.

Immaginiamo di avere più classi che necessitano di comportamenti simili, ad esempio il logging o la validazione dei dati: invece di ripetere lo stesso codice in ciascuna classe o creare una gerarchia complessa che centralizza tali funzioni, si crea un mixin che implementa questa funzionalità e poi lo si “inserisce” nelle classi interessate. Questo approccio *favorisce la composizione rispetto all'ereditarietà tradizionale*, permettendo una maggiore flessibilità e una migliore riusabilità del codice. Molto spesso è suggerito nel contesto del motto "_prefer composition over inheritance_" #footnote["preferire la composizione all'ereditarietà"] @gof @composition-inheritance-java.

Va notato che l'utilizzo dei mixin richiede cautela: se non gestiti correttamente, possono generare conflitti (ad esempio, metodi con lo stesso nome provenienti da mixin diversi) e rendere il codice meno trasparente. In linguaggi come Python o Ruby, i mixin sono comunemente usati proprio grazie al supporto per l'ereditarietà multipla o ai moduli, che facilitano l'inclusione di funzionalità extra nelle classi.

In questo caso, il Mixin è una interfaccia che impone di implementare un metodo `discover_resources_to_load` che restituisce un dizionario con le risorse necessarie per l'esecuzione dello step.

#figure(
  ```python
  class ResourceDiscoveryMixin(ABC):
      @abstractmethod
      def discover_resources_to_load(self) -> set[Resource]:
          """
          An abstract method to discover resources to load.
          Different classes can implement this method based on their specific logic.
          """
          pass
  ```,
  kind: "cls",
  caption: [Mixin per la scoperta delle risorse necessarie per l'esecuzione di uno step.],
) <mixin-interface>

Nelle risorse possono anche essere specificati file da caricare, modelli da inizializzare, e così via. Questo permette al Runner di caricare in memoria tutte le risorse necessarie per l'esecuzione del chatbot, e di poterle passare agli step in modo trasparente e immediato.

=== Flow

Un `Flow` è una sequenza di `RunnerStep` che rappresenta un percorso di interazione con l'utente. Possono essere utilizzati come analoghi dei `Topic` di AIML @aiml, o come sequenze di interazioni che l'utente può intraprendere con il chatbot.

Ogni `RunnerStep` rappresenta un'azione che il chatbot o l'utente deve intraprendere per poter procedere con l'interazione. Ad esempio, un `RunnerStep` potrebbe essere un'interazione con un modello di classificazione per determinare la classe di una domanda, o un'interazione con un modello di NER per estrarre le entità da una domanda.

Nell'esempio del @flow-example, possiamo vedere come un `Flow` possa essere composto da più `RunnerStep`, ognuno con un compito specifico.

#figure(
  image("../media/diags/simple_chatbot.svg"),
  kind: "diag",
  caption: [Diagramma semplificato di un chatbot in grado di fornire informazioni basilari riguardo un automa a stati finiti.],
) <flow-example>

Come vediamo, sono presenti tre `Flow` distinti:
- Il primo, denominato "Intent Principale", si occupa di:
  1. Lasciare il controllo all'utente che dovrà inviare un messaggio;
  2. Determinare la classe d'interazione generale dell messaggio utente;
  3. Estrarre le entità presenti nella domanda.
  Una volta effettuate queste tre azioni, l'ultima decisione è un analogo allo `switch` dei linguaggi di programmazione, che permette di determinare quale `Flow` eseguire successivamente valutando una condizione o effettuando pattern matching. È anche predisposto un `Fallback Flow` che si occupa di gestire le interazioni non previste.
- Il secondo `Flow`, "Transition Flow", si preoccupa prima di determinare la classe d'interazione specifica che l'utente ha inviato; successivamente instrada l'esecuzione verso una delle due query possibili, in base alla classe d'interazione. Le due query utilizzano uno `RunnerStep` personalizzato che permette di interrogare il grafo rappresentante l'automa sfruttando le API di NetworkX.
  Recuperate le informazioni, il flow comporrà la risposta all'utente con un prompt dedicato; questo sarà inviato ad una LLM (locale o remota) e infine inoltrato all'utente.
- In modo simile al precedente `Flow`, "State Flow" si occupa di determinare la classe d'interazione specifica dell'utente, e di interrogare il grafo per recuperare le informazioni richieste riguardo gli stati dell'automa. La particolarità in questo caso è che nel caso della verifica dell'esistenza di uno stato: la risposta non sarà generata da una LLM ma verrà estratta da un insieme predefinito.

In ogni caso, alla fine di un flow, se non è specificato dove proseguire ulteriormente, il controllo viene restituito al flow iniziale.
Ogni `Flow` deve specificare uno `start_step`, che rappresenta il primo step da eseguire all'avvio del flow.

Ogni step invece, può specificare uno `next_step` e uno `next_flow` che rappresentano rispettivamente il prossimo step da eseguire e il prossimo flow da eseguire. Queste due opzioni sono utili per implementare il controllo del flusso di esecuzione, e permettono di creare interazioni complesse con l'utente. 
Se non viene specificato il prossimo step, o il prossimo flow, il controllo viene restituito al flow iniziale. La logica di branching effettuata è mostrata nelllo @flow-execution.

#figure(
  ```python
  starting_flow = flows.get("main")

  current_flow = starting_flow
  current_step = starting_flow.steps.get(current_flow.start_step)

  context = {}

  while current_step is not None:
    next_step, next_flow = current_step.execute(context)

    if next_flow is not None:
        current_flow = config.flows[next_flow]

        if next_step is not None:
            current_step = current_flow.steps[next_step]
        else:
            current_step = current_flow.steps.get(current_flow.start_step)
    else:
        if next_step is not None:
            current_step = current_flow.steps[next_step]
        else:
            current_step = current_flow.steps.get(current_flow.start_step)
  ```,
  kind: "snip",
  caption: [Ciclo di esecuzione dei `Flow` nel Runner.],
)<flow-execution>

Un ultimo punto da considerare è la gestione del contesto. Il contesto è contenuto in un dizionario che raccoglie tutte le informazioni necessarie per l'esecuzione del chatbot, e viene passato ad ogni step durante l'esecuzione. Questo permette di mantenere lo stato dell'interazione con l'utente, e di condividere informazioni tra i vari step, che possono effettuare manipolazioni sui dati.

Per lasciare la massima libertà possibile, è stato deciso di utilizzare la libreria `Asteval` @asteval, che permette di eseguire codice Python fornito all'interno di stringhe. La libreria è estremamente flessibile e permette di eseguire codice Python in modo sicuro, evitando l'esecuzione di codice dannoso o erroneo.

Attraverso questa libreria, è possibile definire delle espressioni che verranno valutate a runtime, ad esempio per effettuare branching con la classificazione di una domanda, per interagire con i dati estratti da un modello di NER, o per interrogare una libreria esterna.

== Osservazioni e sviluppi futuri

Nonostante il sistema sia stato progettato per essere il più flessibile possibile, permettendo l'implementazione di `Step` personalizzati, e astraendo allo stesso tempo le complessità maggiori quali l'utilizzo di modelli di classificazione, vi sono alcune limitazioni che il sistema comunque presenta, e che potranno essere oggetto di futuri sviluppi.

In primo luogo, l'utilizzo di `Asteval` per l'esecuzione di codice Python a runtime è molto potente, ma allo stesso tempo molto pericoloso. La libreria permette di eseguire qualsiasi codice Python fornito, e non fornisce alcun tipo di protezione contro codice dannoso o malevolo.

Una possibile soluzione potrebbe essere l'utilizzo di un sistema di sandboxing, che permetta di eseguire il codice in un ambiente controllato. Asteval supporta già diversi generi di controlli e limitazioni configurabili, ma in alcuni casi potrebbe essere necessario implementare verifiche più stringenti attualmente non presenti.

#hrule()

Bisogna anche aggiungere come, nonostante il formato YAML per la configurazione sia molto potente, durante lo sviluppo esso sia stato spinto al limite delle sue capacità. Per flow semplici, il formato è molto chiaro e leggibile, ma se si inizia a dover lavorare con espressioni python lunghe o con strutture complesse, il formato può diventare ostico e difficile da mantenere, rendendo problematica anche la comprensione del flusso di esecuzione.

Una possibile soluzione potrebbe essere l'utilizzo di un DSL (Domain Specific Language) che permetta di definire le configurazioni in modo più chiaro e conciso, e che permetta di eseguire controlli di validità in fase di scrittura. Questa opzione è stata considerata durante lo sviluppo, ma è stata scartata per motivi di complessità e ridondanza considerando altre alternative.

Un'opzione più favorevole sarebbe la conversione del sistema in una libreria Python pura, che permetta di definire le configurazioni direttamente in codice Python, sfruttando le capacità di introspezione e validazione del linguaggio. In questo modo sarebbe sufficiente implementare delle funzioni che rappresentano flow e step, abbassando la barriera all'ingresso per nuovi sviluppatori già esperti in Python. 

D'altra parte, questa soluzione potrebbe rendere più complesso lo sviluppo per utenti non esperti, motivo per cui comunque il supporto al formato YAML potrebbe dover essere mantenuto.
Bisogna tenere comunque a mente che già la scrittura di chatbot in AIML non richiede conoscenze indifferenti, anche se non si tratta direttamente di programmazione, ma comunque di una forma di scripting che implica la comprensione di concetti come la programmazione logica, la gestione di variabili e la sintassi di XML.

Una migrazione a Python puro renderebbe anche più veloce l'implementazione e, soprattutto, il testing di nuove integrazioni, aumentando la comodità per gli sviluppatori e riducendo il tempo complessivamente necessario per sviluppare nuove funzionalità.

Naturalmente la conversione del sistema in una libreria Python pura potrebbe risolvere anche il problema dell'utilizzo della libreria `ASTEVAL`, lasciando invece la libertà di fare fondamento sulle capacità di introspezione del linguaggio per eseguire controlli di validità sul codice fornito.

Inoltre, la vasta disponibilità di IDE avanzati con sistemi di completamento già largamente diffusi a livello professionale, come _PyCharm_ di JetBrains o _Visual Studio Code_ di Microsoft, permetterebbe di ridurre gli errori di sintassi e di semantica, e di velocizzare lo sviluppo di nuove funzionalità, senza dover implementare nuovi strumenti per la validazione delle configurazioni.