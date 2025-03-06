#import "@preview/showybox:2.0.4": showybox
#import "@preview/pinit:0.2.2": *

= Natural Language Generation <nlg>
/*
- *NLG*: tramite prompting o parafrasi (sulle risposte)
  - *LLM per generare delle alternative ad una risposta standard, o per generarla direttamente dai dati tramite prompt*
  - Fornire anche la domanda, quindi considerare il contesto?
  - Contesto più ampio?
  - *Valutazione*
    - ROUGE, ecc.
    - Misure automatiche di valutazione con embeddings
    - Jurafsky: capitolo su valutazione umana delle risposte dei sistemi di dialogo(sequenza di risposte/dialogo) da due possibili fonti
    - Classificazione con confronto con AIML
    - Performance Zero shot con modello baseline non trainato
    - Qualità delle risposte valutate da persone (questionario):
      - Tassonomia Dusek (https://d2t-llm.github.io/) per la valutazione
        Calcolare l'agreement tra valutatori
*/

#let mono(body, font: "JetBrains Mono NL") = {
  text(upper(body), font: font, size: 10pt)
}

#let tdd(date) = {
  [#sym.quote.r.single#date]
}

#let hrule() = align(center, line(length: 60%, stroke: silver))

Nel contesto di un sistema di dialogo, la generazione del linguaggio naturale (NLG) è una delle componenti fondamentali affinchè il sistema possa effettivamente comunicare con gli utilizzatori in modo efficace.

Una volta che abbiamo compreso l'intenzione dell'utente, dobbiamo generare una risposta che sia *coerente con la richiesta* e che *fornisca un qualche valore* all'interlocutore, senza scordare che quest'ultima deve essere comprensibile. Il processo può essere svolto in diversi modi, a seconda delle esigenze e delle capacità del sistema stesso.

La @nlg punterà ad illustrare le tecniche di generazione del linguaggio naturale studiate per lo sviluppo del sistema, mentre la @engi si occuperà di mostrare più nel dettaglio come queste siano rese disponibili per i botmaster nell'implementazione vera e propria.

Nelle sezioni seguenti vedremo che il processo è divisibile in due fasi principali:
1. Il recupero dei dati: senza informazioni, il sistema non può generare risposte significative. Il recupero dei dati è quindi il primo passo per poter generare risposte coerenti e pertinenti.
2. La generazione delle risposte: una volta che il sistema ha a disposizione i dati necessari, può procedere con la generazione del testo che verrà presentato all'utente. Possono essere utilizzate diverse tecniche, tra cui prompting o parafrasi, per generare risposte di qualità.

== Data Retrieval // Spiegazione di cosa è il data retrieval
Vi possono essere casi in cui il sistema non ha bisogno di recuperare dati o dettagli per poter rispondere; in questi casi, la risposta può essere generata direttamente dal sistema stesso, senza bisogno di informazioni aggiuntive. Questa situazione è tipica quando il sistema deve rispondere a domande prestabilite o statiche, come ad esempio quelle relative a informazioni generali o a domande di cortesia.

Possiamo pensare ad esempio a interazioni basilari da inizio conversazione, le cui risposte sono fisse e non necessitano di alcun tipo di elaborazione, come:
- Semplici saluti: "Ciao!", "Potresti aiutarmi?";
- Informazioni generali: "Qual è il tuo nome?", "Come posso contattare il servizio clienti?";
- Interazioni di cortesia: "Grazie!", "A presto!".
In questi casi, è evidente che il sistema non abbia bisogno di recuperare ulteriori dati o dettagli *potenzialmente variabili a seconda del contesto* per poter rispondere, ma che possa generare la risposta direttamente.

Se invece il sistema deve fornire informazioni specifiche o personalizzate, allora è necessario che sia in grado di recuperare i dati necessari per generare la risposta. Questo processo può avvenire in diversi modi, a seconda delle esigenze del sistema, della complessità delle informazioni richieste e del modo in cui queste sono strutturate e salvate.

=== Basi di conoscenza strutturate
Le basi di conoscenza costituiscono una delle fonti più affidabili da cui un sistema di dialogo può attingere informazioni. La loro natura ordinata, con tabelle, relazioni e campi ben definiti, assicura una gestione dei dati che riduce la possibilità di incongruenze o duplicazioni. Allo stesso tempo, la costruzione e la manutenzione di uno schema ben progettato richiedono un certo impegno iniziale, poiché bisogna prevedere in anticipo quali tipi di informazioni saranno necessari all'interno del sistema.

In uno scenario di dialogo, il processo di risposta idealmente seguirebbe due passi. Consideriamo ad esempio la domanda "Vorrei informazioni sul mio ordine numero 25565":
1. Prima di tutto il sistema riconoscerebbe il genere di richiesta posta dall'utente. Ipotizzando una classificazione simile a quella discussa nella @classificazione-llm (quindi con uno o più livelli di classificazione dell'intent), riusciremmo a comprendere che la richiesta è legata al recupero di informazioni su un ordine.\

2. Una volta identificato l'intent, mediante un modello di NER, il sistema estrarrebbe il valore di `orderId` dalla frase dell'utente, per poi interrogare una base di dati, tramite un prepared statement SQL @owasp-injection, per recuperare i dettagli dell'ordine richiesto. Un esempio di query per il recupero di dettagli di un ordine in un sistema e-commerce potrebbe essere il seguente:

  #figure(
    ```sql
    SELECT customer_name, order_date, total_amount
    FROM orders
    WHERE order_id = :orderId
      # Aggiungiamo un vincolo per evitare accessi non autorizzati
      AND customer_id = :customerId;
    ```,
    kind: "query",
    caption: "Esempio di query SQL per il recupero di dettagli di un ordine in un sistema e-commerce.",
  )

L'esecuzione di questa interrogazione restituisce al modulo di generazione del linguaggio naturale i dettagli necessari a comporre una risposta personalizzata.\
Un ulteriore vantaggio di questo approccio risiede nella possibilità di definire in anticipo diversi vincoli e relazioni che facilitano la coerenza dei dati.

In alternativa alla struttura difficilmente variabile (una sfida comunque superabile!#footnote[https://softwareengineering.stackexchange.com/questions/235785/how-to-handle-unexpected-schema-changes-to-production-database]) in produzione di un database relazionale, un database NoSQL può risultare altrettanto efficace. Nel dominio della _Knowledge Representation_ sono stati definiti alcuni linguaggi il cui scopo è permettere di rappresentare conoscenze strutturate e complesse, dalle quali è anche possibile inferire nuove informazioni.

Alla base vi è RDF (Resource Description Framework), un modello di dati che permette di rappresentare informazioni in forma di triple `<soggetto, predicato, oggetto>`, e il suo linguaggio di interrogazione SPARQL @sparql.

Le annotazioni in formato Turtle ad esempio ci permettono di rappresentare un Grafo RDF testualmente (rendendolo molto facilmente intellegibile da un lettore), come nel seguente esempio:

#figure(
  ```turtle
  BASE <http://example.org/>
  # Definiamo degli IRI, ovvero identificatori di risorse che abbreviano URL più lunghi
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
  kind: "query",
  caption: "Esempio di annotazione in formato Turtle per il film d'animazione _Gli Incredibili_ e il suo regista.",
)

Questo modello è alla base di molte knowledge base, come DBpedia @dbpedia e Wikidata @wikidata, che raccolgono informazioni strutturate su una vasta gamma di argomenti. Le basi di conoscenza sono normalmente codificate su file, in formati come RDF-XML @rdf-syntax-grammar o Turtle @rdf-turtle.

Anche in questo caso, dovendo rispondere a una richiesta come "Chi ha diretto il film d'animazione _Gli Incredibili_? #footnote[http://dbpedia.org/resource/The_Incredibles]", una volta determinato l'intent ed estratta la named entity del film, possiamo recuperare in modo preciso le informazioni necessarie con una veloce query:

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
  caption: "Esempio di query SPARQL per il recupero del regista del film Inception.",
)

Ricevuta la risposta (`dbr:Brad_Bird`#footnote[https://dbpedia.org/page/Brad_Bird]), interagendo coi campi `dbp:name` e `dbo:thumbnail` dell'entità, il sistema potrà rapidamente comporre una risposta completa (se usassimo un template, ne risulterebbe "Il film Gli Incredibili è stato diretto da Brad Bird") e arricchirla con un'immagine del regista.

=== Corpora non testuali
A differenza delle knowledgebase strutturate, i corpora testuali non strutturati offrono la possibilità di attingere a un bacino molto più ampio e flessibile di informazioni, ma richiedono tecniche di recupero dati più complesse per poter restituire risultati pertinenti. Questi corpora possono includere documenti di varia natura, come articoli, pagine web, FAQ, manuali e qualsiasi altro contenuto scritto che non segua uno schema predeterminato.

I metodi tradizionali di Information Retrieval si basano solitamente su indici inversi o modelli a spazio vettoriale, come TF-IDF #footnote[Term Frequency-Inverse Document Frequency] @Rajaraman_Ullman_2011 o BM25 @okapi-bm25, che confrontano la query dell'utente con i termini presenti nel corpus. Sebbene questi approcci siano ancora efficaci in molti scenari, con l'evoluzione dei modelli neurali è possibile sfruttare reti specializzate che codificano frasi e documenti in uno spazio di embedding semantico. Un esempio diffuso è l'utilizzo di Sentence-BERT @sentence-bert, che permette di generare vettori numerici rappresentativi del significato di un testo e, di conseguenza, di calcolare la similarità fra query e documenti in modo più accurato rispetto alle semplici corrispondenze di parole chiave.

Per illustrare questo principio, si consideri il seguente snippet di codice Python che usa la libreria sentence-transformers:

#figure(
  ```python
  from sentence_transformers import SentenceTransformer, util

  # Carichiamo un modello pre-addestrato
  model = SentenceTransformer('all-MiniLM-L6-v2')

  # Supponiamo di avere un piccolo corpus di documenti
  corpus = [
      "Questo è un documento sul funzionamento dei sistemi di dialogo.",
      "Ecco un articolo sui vantaggi dei knowledge graph.",
      "Una breve introduzione all'Information Retrieval."
  ]
  corpus_embeddings = model.encode(corpus, convert_to_tensor=True)

  # Definiamo la query dell'utente
  query = "Cosa sono i sistemi di dialogo?"
  query_embedding = model.encode(query, convert_to_tensor=True)

  # Calcoliamo la similarità tra la query e i documenti
  scores = util.pytorch_cos_sim(query_embedding, corpus_embeddings)[0]
  best_score_idx = scores.argmax().item()

  print("Testo più simile:", corpus[best_score_idx])
  ```,
  kind: "script",
  caption: "Esempio di utilizzo di Sentence-BERT per trovare il documento più simile a una query.",
)

In questo esempio, dopo aver calcolato gli embeddings #footnote[Strutture che codificano il testo numericamente per permettere di effettuare operazioni matematiche, come la *cosine similarity*] dei documenti del corpus e della query utente, calcoliamo la *cosine similarity* tra di essi e identifichiamo l'indice del documento più affine dal punto di vista semantico. La differenza sostanziale rispetto a metodi tradizionali consiste nel fatto che l'uso di embeddings semantici permette di riconoscere relazioni di significato *anche quando il lessico non coincide esattamente*.

Integrando un simile modulo di retrieval in un sistema di dialogo, è possibile estendere la copertura informativa ben oltre i limiti di una base di dati strutturata, sebbene ciò comporti un aumento della complessità. Le performance dipendono, infatti, dalla qualità del modello neurale e dalla quantità di risorse computazionali disponibili per l'indicizzazione e la ricerca.

Il ricorso a corpora testuali non strutturati è particolarmente utile nei sistemi open-domain, dove l'utente potrebbe porre quesiti su una gamma di argomenti molto ampia. L'ampiezza della base informativa fornisce un potenziale enorme, a condizione di implementare strategie di filtraggio e ranking dei risultati che riducano il rischio di rumore o di risposte poco rilevanti. In tal senso, molte pipeline di retrieval prevedono una fase di re-ranking @wang-etal-2021-retrieval, nella quale uno o più modelli ricalcolano la pertinenza dei documenti più promettenti prima di fornire la risposta definitiva all'utente.

=== API e servizi esterni
L'accesso a dati provenienti da fonti esterne in tempo reale rappresenta un altro tassello fondamentale per i sistemi di dialogo moderni. Integrare API e servizi di terze parti permette, ad esempio, di fornire aggiornamenti meteorologici, visualizzare informazioni sul traffico, ottenere prezzi di mercato o eseguire prenotazioni, arricchendo notevolmente le capacità del sistema.

A differenza delle basi di dati documentali o dei corpora statici, le API espongono endpoint che possono variare da semplici chiamate REST, fino a interfacce più complesse che richiedono autenticazione e parametri di configurazione.

Tipicamente il motore di dialogo intercetta la domanda dell'utente e, riconoscendo la necessità di dati esterni, effettuerà una chiamata API verso il servizio più appropriato.
Nel caso di servizi che restituiscono risposte JSON, si può utilizzare un linguaggio di query come JMESPath @jmespath per filtrare i risultati e isolare solo i campi più rilevanti.

#hrule()

JMESPath è un linguaggio espressivo e leggero, progettato per filtrare, cercare e trasformare dati in formato JSON.
A differenza di query tradizionali con linguaggi come SQL, JMESPath è progettato per operare esclusivamente su strutture JSON e consente di navigare in maniera semplice all'interno di oggetti annidati, liste e chiavi complesse. Grazie alla sua sintassi intuitiva, risulta particolarmente utile quando si devono gestire risposte provenienti da API REST, servizi esterni o qualunque altra fonte che fornisca dati in formato JSON.

Supponendo di avere una struttura JSON come la seguente:

#figure(
  ```json
    "items": [
      {"title": "Primo articolo", "category": "tech"},
      {"title": "Secondo articolo", "category": "sport"},
      {"title": "Terzo articolo", "category": "tech"}
    ]
  ```,
  kind: "snip",
  caption: "Esempio di struttura JSON restituita da un'API di news.",
)

Potrebbe essere necessario filtrare solo gli articoli che trattano di tecnologia. Utilizzando JMESPath, possiamo scrivere una query come la seguente:

#figure(
  ```python
  items[?category == 'tech'].title
  ```,
  kind: "snip",
  caption: "Esempio di espressione JMESPath per estrarre i titoli degli articoli di tecnologia.",
)

Questa espressione:
1. Filtra la lista di articoli usando il predicato `?category == 'tech'`
2. Estrae solo il campo `title` di ciascun articolo

Il risultato è una lista che viene popolata in un solo passaggio con tutti i titoli degli articoli. Il sistema di dialogo può quindi usare queste informazioni per formulare una risposta, magari raggruppando i titoli più rilevanti o generando una breve sintesi.

Oltre a restituire dati in forma di testo, alcune API consentono di eseguire azioni che hanno un effetto sul mondo esterno, come prenotare un ristorante o inviare un ordine.\
Ciò comporta un aumento delle responsabilità da parte del sistema, il quale deve gestire correttamente eventuali errori o limiti di utilizzo, come soglie massime di richieste al minuto o specifiche politiche di caching.\
Al tempo stesso, la capacità di interagire dinamicamente con risorse esterne rende il sistema di dialogo molto più potente e utile, in particolare in contesti in cui la tempestività dell'informazione è fondamentale.

== Generazione di risposte tramite LLM

L'adozione di Large Language Model (LLM) per la generazione di risposte all'interno dei sistemi di dialogo rappresenta uno dei progressi più significativi degli ultimi anni nel campo della Natural Language Generation.
Se in passato la creazione di output testuale avveniva in modo per lo più rigido (ad esempio tramite template o frasi predefinite), le recenti architetture neurali basate su transformer—come GPT, T5 o BERT-family—hanno permesso di comporre risposte molto più variegate e contestuali, adattandosi con flessibilità alle esigenze dell'utente.

In un sistema di dialogo, però, la sfida non si limita a “generare testo corretto dal punto di vista linguistico”.
È altresì fondamentale garantire che la risposta risulti coerente con la domanda, contestualmente appropriata e, soprattutto, informativa.
Da un lato, si può pensare all'impiego di un modello come componente centrale, in cui l'utente fornisce direttamente l'input (ad esempio una domanda) e il modello produce l'output (la risposta).
Dall'altro, si può utilizzare lo stesso LLM per operazioni più specifiche, come la parafrasi di risposte già esistenti o l'introduzione di variazioni stilistiche.
Una delle strategie più comuni e potenti per interfacciarsi con i LLM è il prompting, vale a dire l'idea di “istruire” il modello riguardo al contesto, al tono e al formato di output desiderato, mediante prompt testuali che forniscono esempi e regole su come generare il testo.

L'uso di LLM diventa ancor più significativo quando si parla di sistemi di dialogo data-driven.
In questi casi, la generazione non può basarsi esclusivamente sulle conoscenze latenti del modello, ma deve attingere ai dati recuperati nei passaggi precedenti (tramite query, script o retrieval neurale).
In tal modo, il modello produce risposte aggiornate e specifiche, riducendo il rischio di informazioni obsolete o imprecise.

Nelle sottosezioni seguenti verranno illustrati due aspetti fondamentali dell'uso dei LLM nella generazione di risposte.
La *Parafrasi* offre la possibilità di riscrivere o variare un testo in modo più o meno profondo, fornendo un valido strumento per evitare ripetizioni pedisseque o allineare lo stile del sistema alle esigenze del contesto.
Il *Prompting* rappresenta invece la chiave di volta per guidare la produzione linguistica del modello verso gli obiettivi del sistema di dialogo, in termini sia di contenuto che di stile comunicativo.
Vedremo quindi come un'efficace combinazione di tecniche di parafrasi e di prompt engineering possa sostenere la generazione di risposte coerenti, comprensibili e flessibili, migliorando sensibilmente l'esperienza dell'utente.

=== Parafrasi

La parafrasi svolge una funzione cruciale nei sistemi di dialogo data-driven: permette infatti di riformulare, con scelte lessicali e strutturali diverse, una risposta che attinge dagli stessi contenuti di base, che rimarranno inalterati.

In un sistema di dialogo che riceve domande simili in momenti diversi, rispondere sempre con la medesima formulazione testuale può trasmettere un senso di rigidità.
L'utente potrebbe percepire il sistema come meccanico o “ripetitivo”.
Integrando un modulo di parafrasi basato su LLM si possono introdurre piccole ma significative variazioni stilistiche, pur mantenendo inalterate le informazioni fondamentali:

#grid(
  columns: 2, rows: 2, gutter: 0.5cm, //align: horizon,
  grid.cell(
    colspan: 2,
    align: center,
    showybox(
      width: 50%,
      title-style: (boxed-style: (:)),
      title: "Domanda",
    )[Quanto costa la spedizione per l'Italia?],
  ),
  showybox(
    title-style: (boxed-style: (:)),
    title: "Alternativa 1",
  )[La spedizione in Italia costa 5 euro e dal moduloimpiega 3 giorni lavorativi.],
  showybox(
    title-style: (boxed-style: (:)),
    title: "Alternativa 2",
  )[La tariffa di spedizione per l'Italia è di 5 euro, con una consegna stimata in 3 giorni.]
)

In alcuni contesti, la stessa informazione deve essere presentata con stili differenti: più formale, più colloquiale, più conciso o più descrittivo. Le LLM odierne consentono di riformulare un testo attraverso un prompt mirato:

#grid(
  columns: 2,
  gutter: 0.5cm,
  // align: horizon,
  showybox(
    title-style: (boxed-style: (:)),
    title: "Prompt A",
  )[Riscrivi il seguente paragrafo con uno stile tecnico, mantenendo i contenuti originali e senza introdurre variazioni nei dati: \[...\]],
  showybox(
    title-style: (boxed-style: (:)),
    title: "Prompt B",
  )[Modifica il seguente testo in modo che risulti più colloquiale e breve: \[...\]],
)

Qualora il sistema debba attingere a documenti esterni, articoli o risorse protette, la parafrasi può prevenire problemi di copyright (purché sia garantita la corretta attribuzione delle fonti).
Anziché inserire stringhe letteralmente copiate, il sistema riformula i concetti principali, ottimizzando il flusso del dialogo e riducendo i rischi legali o di duplicazione.

Per implementare la parafrasi, si può sfruttare una LLM appositamente addestrata o semplicemente vincolata attraverso un prompt. Il flusso di lavoro risultante sarà tipicamente diviso in tre fasi:

1. Recupero dei dati: il sistema ottiene i contenuti rilevanti dalla knowledge base o da un documento;
2. Formulazione del prompt: invece di richiedere semplicemente "Genera una risposta che spieghi X", si invia al modello una richiesta che include il testo da parafrasare e le specifiche sullo stile o la lunghezza desiderata;
3. Generazione del testo: la LLM produce una variante testuale dell'input, che può essere arricchita da sfumature stilistiche dipendenti dal contesto.

In base alle esigenze, la parafrasi può essere usata in modo selettivo soltanto in alcuni passaggi della conversazione, ad esempio per differenziare i saluti iniziali o per riformulare un concetto ripetuto. Nella fase di valutazione, come vedremo, è doveroso controllare la coerenza semantica tra testo di partenza e testo riformulato, utilizzando metriche come BLEU, ROUGE o similitudini di embedding.

=== Prompting

Come evidenziato da diversi lavori in letteratura (#cite(<kasner-dusek>, form: "prose") #cite(<yuan-faerber-graph2text>, form: "prose")) , l'impiego di Large Language Model (LLM) per la generazione di risposte basate su dati si sta rivelando una strategia sempre più diffusa, ma al contempo complessa da controllare.\
Da un lato, i modelli di grandi dimensioni forniscono una notevole fluidità e flessibilità testuale, dall'altro espongono il sistema al rischio di introdurre *allucinazioni*, omissioni o errori semantici.

Il termine _allucinazioni_, nel contesto delle LLM, si riferisce a risposte generate dal modello che non sono supportate dai dati forniti nel prompt o che sono incoerenti con il contesto della conversazione.
Possono anche contenere informazioni "inventate" o totalmente errate.
È una delle sfide principali nella generazione di testo con LLM, specialmente in contesti data-driven.

All'interno di questo generi di sistemi di dialogo, il prompting acquisisce ulteriore rilevanza, poiché occorre integrare nel prompt non solo il contesto della conversazione e l'intenzione dell'utente, ma anche i dati recuperati nella fase di retrieval.

Per costruire un prompt efficace, è buon uso considerare i seguenti aspetti:

- *Chiarezza dell'istruzione*: è importante esplicitare in modo chiaro cosa si vuole che il modello faccia.
  Richieste seguite da contesto e vincoli specifici possono orientare molto meglio la generazione rispetto a richieste vaghe o incomplete:

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
  #align(center)[
    #set text(size: 15pt)
    #set par(spacing: 0pt)
    #sym.arrow.b
  ]
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
    title: [LLM],
  )[L'articolo è disponibile nei colori rosso, blu e verde al prezzo di 49,99 euro. I tempi di spedizione sono di 2 giorni.]
- *Contestualizzazione*: la LLM deve essere messa nella condizione di “vedere” i dati recuperati in precedenza, per non attingere soltanto a conoscenze latenti nel proprio addestramento.
  Fornire uno snippet del testo rilevante, una lista di fatti chiave, o delle triple di un knowledge graph aumenta la probabilità che il modello usi correttamente i dati.
- *Vincoli e stile*: se si desidera uno stile specifico (ad esempio formale, tecnico o più narrativo), si può precisare il _tone of voice_ all'interno del prompt.
  #showybox(
    title-style: (
      weight: 900,
      sep-thickness: 0pt,
      color: purple.darken(40%),
      align: start,
    ),
    frame: (
      title-color: purple.lighten(80%),
      border-color: purple.darken(40%),
      thickness: (left: 1pt),
      radius: 0pt,
    ),
    title: [Aggiunta al Prompt],
  )[Spiega questi dati come se stessi illustrandoli a un bambino di 10 anni, utilizzando un linguaggio semplice e frasi brevi.]
  Anche la lunghezza desiderata della risposta, l'utilizzo di determinate parole chiave o la struttura desiderata possono essere indicati come vincolo:
  #showybox(
    title-style: (
      weight: 900,
      sep-thickness: 0pt,
      color: purple.darken(40%),
      align: start,
    ),
    frame: (
      title-color: purple.lighten(80%),
      border-color: purple.darken(40%),
      thickness: (left: 1pt),
      radius: 0pt,
    ),
    title: [Aggiunta al Prompt],
  )[
    Usa i dati forniti per creare una tabella in linguaggio Markdown con due colonne: ‘Caratteristica' e ‘Valore'. Non aggiungere ulteriori colonne.
  ]
- *Protezione dalle allucinazioni*: Per limitare la tendenza dei modelli a “inventare” fatti non inclusi nei dati, si possono inserire frasi di avvertenza, come:
  #showybox(
    title-style: (
      weight: 900,
      sep-thickness: 0pt,
      color: purple.darken(40%),
      align: start,
    ),
    frame: (
      title-color: purple.lighten(80%),
      border-color: purple.darken(40%),
      thickness: (left: 1pt),
      radius: 0pt,
    ),
    title: [Aggiunta al Prompt],
  )[
    Se non trovi nei dati un'informazione necessaria, dichiara che non è disponibile. Non introdurre informazioni che non siano presenti nell'elenco qui sotto.
  ]

Un esempio di prompt generico che segue le indicazioni presentate potrebbe essere il seguente:

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
)[Ecco i dati rilevanti estratti dal database: `[lista_json]`.\ Tenendo conto di questi dati e della domanda dell'utente `[domanda_utente]`, genera una risposta chiara e completa. Scrivi in modo formale e non superare i 100 token nella risposta.]

È essenziale tuttavia valutare la complessità del compito, in quanto un'istruzione troppo dettagliata potrebbe confondere il modello, mentre una troppo vaga potrebbe portare a risposte poco pertinenti.
Con questo fine, è possibile adottare diverse strategie di prompting:

- *Zero-shot*: si formula l'istruzione senza fornire esempi di input-output. Il modello, grazie alle conoscenze apprese durante il pre-addestramento, tenterà di interpretare correttamente la richiesta.
- *Few-shot*: si includono alcuni esempi di input e output desiderati all'interno del prompt, in modo da fornire una guida esplicita al modello su come rispondere o formulare un certo tipo di contenuto. Questa modalità risulta efficace per compiti specifici o con particolari regole di stile.
- *Dialogo multi-turno*: in un sistema di dialogo, ogni nuovo turno può arricchire il prompt con un estratto delle interazioni precedenti. In tal modo, la LLM “ricorda” i contesti precedenti e può mantenere la coerenza tematica nel corso della conversazione.

Come mostrato da #cite(<llm-zeroshot>, form: "prose"), un LLM come ChatGPT può generare testi in modo ragionevole anche zero-shot, ossia senza essere specificamente addestrato su un particolare set di dati.
Tuttavia, gli autori mettono in luce come il modello possa omettere parte dei contenuti provenienti dalla base di conoscenza o, al contrario, integrare dati inesatti (“hallucinated”), soprattutto se il dominio è complesso o i dati non corrispondono a conoscenze di dominio già acquisite dal modello in fase di pretraining.
Questi limiti emergono con maggiore evidenza quando i dati da trasformare in testo appartengono a domini poco noti al modello o, addirittura, sono controfattuali o fittizi, e quindi non rientrano nella conoscenza pregressa del LLM.

Un quadro simile è proposto anche da #cite(<yuan-faerber-graph2text>, form:"prose"), che hanno confrontato GPT-3 e ChatGPT su benchmark di generazione testuale a partire da knowledge graph.
I risultati dimostrano che i modelli di generazione, se impiegati in modalità zero-shot, ottengono buone performance di scorrevolezza, ma faticano a mantenere l'accuratezza semantica, finendo con l'inserire dettagli inventati o non coerenti.\
Inoltre, test su classificatori BERT mostrano come il testo “inventato” dai modelli conservi pattern facilmente riconoscibili rispetto al testo di riferimento umano.
Ciò rafforza l'idea che l'LLM, pur potente, abbia bisogno di prompting e controlli specifici per non produrre contenuti fuorvianti.

/* Integrare i dati di retrieval

Il cuore di un sistema data-driven risiede nella capacità di combinare il prompt con i dati recuperati dallo step di retrieval. Un tipico flusso di lavoro potrebbe essere:

Utente chiede: “Che cos'è la teoria della relatività di Einstein?”
Sistema recupera: un passaggio testuale da un corpus, ad esempio un estratto da Wikipedia con informazioni fondamentali.
Formulazione del prompt:
Riassunto delle precedenti interazioni (se rilevante).
Testo recuperato: “Teoria della relatività di Einstein… spiegazioneaestrattispiegazioneaestratti…”
Istruzione per la LLM: “Spiega in modo semplice e chiaro la teoria della relatività facendo riferimento solo ai dati qui forniti.”
Risposta della LLM: usando i dati presenti nel prompt, il modello genera una sintesi o una spiegazione adeguata.

In questo modo, la LLM non si affida soltanto alle informazioni memorizzate nei suoi pesi durante il training, ma attinge al contenuto estratto in tempo reale. Questo approccio, spesso definito Retrieval-Augmented Generation, migliora la pertinenza della risposta e riduce il rischio che la LLM fornisca contenuti datati o inesatti, specialmente in domini soggetti a rapidi cambiamenti.
Sfide e considerazioni

Hallucination e incertezza: anche se il modello riceve dati contestuali, potrebbe comunque generare parti di testo non rispondenti alla realtà. È consigliabile mettere nel prompt istruzioni per “attieniti strettamente ai dati forniti” e implementare meccanismi di verifica (ad esempio un post-processing che confronti la risposta con i contenuti originali).
Lunghezza del prompt: i modelli di grandi dimensioni hanno un limite di token che possono gestire in un singolo prompt. In conversazioni molto lunghe o con dati estesi, diventa necessario un meccanismo di summarization o chunking.
Formattazione della risposta: se il risultato deve essere presentato all'utente in modo strutturato (ad esempio in un elenco puntato o in linguaggio Markdown), è opportuno specificarlo chiaramente nel prompt. */

== Qualità delle risposte

=== Valutazione automatica

=== Valutazione umana

// - Qualità delle risposte valutate da persone (questionario):
//   - Tassonomia Dusek (https://d2t-llm.github.io/) per la valutazione
