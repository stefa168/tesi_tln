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
      title-style: (
        weight: 900,
        sep-thickness: 0pt,
        color: red.darken(40%),
        align: start,
      ),
      frame: (
        title-color: red.lighten(80%),
        border-color: red.darken(40%),
        thickness: (left: 1pt),
        radius: 0pt,
      ),
      title: [Domanda],
    )[Quanto costa la spedizione per l'Italia?],
  ),
  showybox(
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
  )[La spedizione in Italia costa 5 euro e in media impiega 3 giorni lavorativi.],
  showybox(
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
  )[La tariffa di spedizione per l'Italia è di 5 euro, con una consegna stimata in 3 giorni.]
)

In alcuni contesti, la stessa informazione deve essere presentata con stili differenti: più formale o colloquiale, più conciso o descrittivo. Le LLM odierne consentono di riformulare un testo attraverso un prompt mirato:

#grid(
  columns: 2,
  gutter: 0.5cm,
  // align: horizon,
  showybox(
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
    title: [Prompt A],
  )[Riscrivi il seguente paragrafo con uno stile tecnico, mantenendo i contenuti originali e senza introdurre variazioni nei dati: \[...\]],
  showybox(
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
    title: [Prompt B],
  )[Modifica il seguente testo in modo che risulti più colloquiale e breve: \[...\]],
)

Qualora il sistema debba attingere a documenti esterni, articoli o risorse protette, la parafrasi può prevenire problemi di copyright (purché sia garantita la corretta attribuzione delle fonti).
Anziché inserire stringhe letteralmente copiate, il sistema riformula i concetti principali, ottimizzando il flusso del dialogo e riducendo i rischi legali o di duplicazione.

Per implementare la parafrasi, si può sfruttare una LLM appositamente addestrata o semplicemente vincolata attraverso un prompt. Il flusso di lavoro risultante sarà tipicamente diviso in tre fasi:

1. *Recupero dei dati*: il sistema ottiene i contenuti rilevanti dalla knowledge base o da un documento;
2. *Formulazione del prompt*: invece di richiedere semplicemente "Genera una risposta che spieghi X", si invia al modello una richiesta che include il testo da parafrasare e le specifiche sullo stile o la lunghezza desiderata;
3. *Generazione del testo*: la LLM produce una variante testuale dell'input, che può essere arricchita da sfumature stilistiche dipendenti dal contesto.

In base alle esigenze, la parafrasi può essere usata in modo selettivo soltanto in alcuni passaggi della conversazione, ad esempio per differenziare i saluti iniziali o per riformulare un concetto ripetuto. Nella fase di valutazione, come vedremo, è doveroso controllare la coerenza semantica tra testo di partenza e testo riformulato, utilizzando metriche come BLEU, ROUGE o similitudini di embedding.

=== Prompting

Come evidenziato da diversi lavori in letteratura (#cite(<kasner-dusek>, form: "prose") #cite(<yuan-faerber-graph2text>, form: "prose")), l'impiego di Large Language Model (LLM) per la generazione di risposte basate su dati si sta rivelando una strategia sempre più diffusa, ma al contempo complessa da controllare.\
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
- *Contestualizzazione*: la LLM deve essere messa nella condizione di “vedere” i dati recuperati in precedenza, per non attingere soltanto a conoscenze latenti nel proprio addestramento.
  Fornire uno snippet del testo rilevante, una lista di fatti chiave, o delle triple di un knowledge graph aumenta la probabilità che il modello usi correttamente i dati.
- *Vincoli e stile*: se si desidera uno stile specifico (ad esempio formale, tecnico o più narrativo), si può precisare il _tone of voice_ all'interno del prompt:
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
  In alcuni studi (#cite(<llm-zeroshot>, form: "prose")), questa strategia riduce il numero di imprecisioni, anche se non le elimina completamente.

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
- *Few-shot*: si includono alcuni esempi di output desiderati all'interno del prompt, in modo da fornire una guida esplicita al modello su come rispondere o formulare un certo tipo di contenuto. Questa modalità risulta efficace per compiti specifici o con particolari regole di stile.
- *Dialogo multi-turno*: in un sistema di dialogo, ogni nuovo turno può arricchire il prompt con un estratto delle interazioni precedenti. In tal modo, la LLM “ricorda” i contesti precedenti e può mantenere la coerenza tematica nel corso della conversazione.
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

    Ora, rispondi alla domanda dell'utente in modo chiaro e conciso, mantenendo la coerenza con le interazioni precedenti:
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
    title: [Risposta della LLM (GPT-4o)],
  )[Il tuo ordine n. 1357 è in spedizione e arriverà indicativamente il 10/04/2025.]

Come mostrato da #cite(<llm-zeroshot>, form: "prose"), un LLM come ChatGPT può generare testi in modo ragionevole anche zero-shot, ossia senza essere specificamente addestrato su un particolare set di dati.
Tuttavia, gli autori mettono in luce come il modello possa omettere parte dei contenuti provenienti dalla base di conoscenza o, al contrario, inserire dati allucinati, soprattutto se il dominio è complesso o i dati non corrispondono a conoscenze di dominio già acquisite dal modello in fase di pretraining.
Questi limiti emergono con maggiore evidenza quando i dati da trasformare in testo appartengono a domini poco noti al modello o, addirittura, sono controfattuali o fittizi, e quindi non rientrano nella conoscenza pregressa del LLM.

Un quadro simile è proposto anche da #cite(<yuan-faerber-graph2text>, form:"prose"), che hanno confrontato GPT-3 e ChatGPT su benchmark di generazione testuale a partire da knowledge graph.
I risultati dimostrano che i modelli di generazione, se impiegati in modalità zero-shot, ottengono buone performance di scorrevolezza, ma faticano a mantenere l'accuratezza semantica, finendo con l'inserire dettagli inventati o non coerenti.\
Inoltre, test su classificatori BERT mostrano come il testo “inventato” dai modelli conservi pattern facilmente riconoscibili rispetto al testo di riferimento umano.
Ciò rafforza l'idea che l'LLM, pur potente, abbia bisogno di prompting e controlli specifici per non produrre contenuti fuorvianti.

== Qualità delle risposte

Durante la mia ricerca, ho deciso di utilizzare diverse LLM per valutare le potenziali variazioni di output e la qualità delle risposte generate. Le valutazioni in questa sezione sono state effettuate su un numero ristretto di modelli e domande dal momento che la disponibilità di annotatori umani è stato un fattore limitante.

Il processo che ho seguito coincide con quello proposto da #cite(<kasner-dusek>, form: "prose"), che possiamo riassumere nei seguenti passaggi.

=== Selezione dei modelli
Ho deciso di utilizzare 5 modelli di LLM, tra cui tre locali (`deepseek-r1:8b`, `gemma2:9b`, `llama3.1:8b`) e due modelli cloud (`gpt-4o`, `o3-mini`). La scelta è stata presa con lo scopo di confrontare modelli di diverse dimensioni e complessità, valutando le differenze di output e la qualità delle risposte tra modelli open source (e open weights) e modelli cloud-based ma closed-source.

// Secondo la FTC #footnote[Federal Trade Commission, uno degli organi degli USA], la disponibilità ampia di modelli fondazionali open source e di open weights è fondamentale per diversi motivi:

La scelta non è casuale: è possibile osservare come la disponibilità di modelli fondazionali open source e open weights giochi un ruolo determinante su più livelli.

In primo luogo, essa consente una maggiore *trasparenza e accountability*: rendendo pubblici i pesi e la struttura dei modelli, si favorisce una comprensione approfondita dei meccanismi decisionali degli algoritmi, permettendo di identificare e correggere eventuali bias o anomalie.
Questo livello di apertura è fondamentale non solo per garantire la sicurezza e l'affidabilità degli strumenti AI, ma anche per promuovere un utilizzo responsabile e conforme agli standard etici emergenti.

In secondo luogo, l'accesso libero ai modelli permette a ricercatori, accademici e sviluppatori di effettuare verifiche indipendenti e test approfonditi.
Tale approccio, incentivando la replicabilità e la validazione esterna, diviene un importante strumento per valutare la robustezza e la resilienza dei modelli, contribuendo a mitigare rischi potenzialmente legati a vulnerabilità o comportamenti imprevisti.
Questo elemento risulta particolarmente significativo in un panorama in cui la rapidità di sviluppo delle tecnologie AI richiede metodologie rigorose di controllo e verifica.

Inoltre, l'adozione di modelli open source stimola l'innovazione e la competizione nel settore: la loro disponibilità abbassa le barriere d'accesso, consentendo a startup e centri di ricerca di sperimentare e sviluppare nuove soluzioni senza dover necessariamente sostenere gli elevati costi associati a tecnologie proprietarie.

Si pensi anche solo a come, in questa tesi, sia stato possibile eseguire modelli di medie dimensioni come llama3 o Deepseek-r1 senza dover ricorrere a servizi cloud o a infrastrutture dedicate, o a come oggi stiano nascendo innumerevoli progetti open source che sfruttano modelli locali per risolvere problemi di vario genere, dalla home automation @hassio ai servizi di assistenza virtuale.\
Tale dinamica favorisce la nascita di un ecosistema più variegato e dinamico, in cui il confronto tra approcci e metodologie diverse arricchisce il progresso tecnologico complessivo.

L'open source promuove l'inclusività e supporta la regolamentazione e la ricerca pubblica @fsfs.
Un accesso ampio e democratico ai modelli AI permette agli enti regolatori e alla comunità scientifica di monitorare l'evoluzione delle tecnologie, identificando tempestivamente criticità e proponendo interventi correttivi che possano tutelare gli utenti e garantire uno sviluppo sostenibile e responsabile @open-source-llm @open-weights-foundational.

Da notare anche come, a seconda dei modelli utilizzati, vi possano essere pattern linguistici preferiti dai modelli stessi, che possono influenzare la qualità delle risposte, e che possono renderli facilmente identificabili da parte degli utenti, come evidenziato da #cite(<idiosyncrasieslargelanguagemodels>, form: "prose") all'inizio di quest'anno.

=== Raccolta delle domande
Ho selezionato un insieme di 15 domande provenienti dal validation set già presentato nella @valutazione_ft. Le domande sono state scelte in modo da includere quelle che ho ritenuto con le maggiori potenzialità di fornire risultati significativi per le analisi.

L'automa utilizzato per le domande è stato il seguente, proveniente dal Corpus prodotto durante la ricerca svolta da #cite(<dataset-nova>, form: "prose") su NoVAGraphS.

#figure(
  image("../../gen_eval/fsa.svg"),
  kind: "diag",
  caption: [Automa a stati finiti per la generazione delle domande. Una rappresentazione in formato Graphviz dell'automa è presente nello @fsa-dot.],
) <fsa_eval>

Le domande scelte sono le seguenti:

- _Would you say that the automaton is directed?_
- _Could you tell me whether the automaton is directed?_
- _Can you describe the automaton's input and output symbols?_
- _Could you identify the grammar or set of symbols that the automaton recognizes?_
- _Could you highlight the primary aspects of state q0?_
- _Can you provide more details about state q0?_
- _Which state or states are considered final?_
- _What are the final states in the automaton?_
- _Does a directed arc exist from q1 to q0?_
- _Is q0 directly connected to q1 by a transition?_
- _Can you spot any transition where the start and end state are identical?_
- _Is there a looping transition from a state back to the same state?_
- _What are the incoming and outgoing transition paths for q1?_
- _What links are present for state q2 in the automaton?_
- _What are the entry and exit transitions for state q2?_

=== Generazione delle risposte
Ho utilizzato i modelli per generare risposte in modo zero-shot, senza ulteriori addestramenti. Ogni domanda è stata inviata a ciascun modello, che ha prodotto una risposta testuale. Le domande non sono state presentate senza alcuna informazione ai modelli, ma utilizzando il seguente prompt:

#figure(
  ```
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
  ```,
  kind: "snip",
  caption: "Prompt utilizzato per la generazione delle risposte.",
)

Mentre `{question}` è stata sostituita con la domanda corrente, `{data}` è rimasto lo stesso per tutti i prompt, e contiene la rappresentazione in formato `Graphviz` dell'automa a stati finiti mostrato nel @fsa_eval:

#figure(
  ```dot
  digraph FSA {
      rankdir=LR;
      node [shape = circle];
      q0 [shape = doublecircle];
      q1; q2; q3; q4;

      start [shape=none, label=""];  // Invisible start indicator
      start -> q0;                  // Start arrow pointing to starting state

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

In questo modo, i modelli sono anche stati valutati verificando la capacità di estrarre informazioni rilevanti dai dati forniti. Nel contesto del sistema che verrà illustrato nella @engi, il prompt sarà molto più specifico, offrendo alle LLM informazioni aggiuntive che possono ulteriormente guidare la generazione delle risposte. Consideriamo questa fase come baseline per valutare le capacità di generazione dei modelli.

=== Annotazione manuale
Il passaggio successivo è stato la valutazione delle risposte generate. Come sistema di valutazione, è stato utilizzato lo stesso di #cite(<kasner-dusek>, form: "author"), che prevede la collaborazione di annotatori umani su un applicativo da loro sviluppato, Factgenie @factgenie @kasner2024factgenie.

Il software è una piattaforma web che permette di valutare la qualità delle risposte generate da modelli di LLM, fornendo un'interfaccia intuitiva per gli annotatori:

#figure(
  image("../media/factgenie_UI.png"),
  caption: "Interfaccia di Factgenie per la valutazione delle risposte generate da LLM.",
)

Gli annotatori, dopo aver ricevuto una breve formazione sull'uso dell'applicativo, sono liberi di evidenziare nelle risposte frammenti problematici semplicemente selezionandoli. Sono stati definiti quattro generi di errori:
/*
    Incorrect: The fact in the text contradicts the data.
    Not checkable: The fact in the text cannot be checked given the data.
    Misleading: The fact in the text is misleading in the given context.
    Other: The text is problematic for another reason, e.g. grammatically or stylistically incorrect, irrelevant, or repetitive.
*/
#let gold = rgb("#c9ab40")
#let incorrect() = [*#text(fill: red)[#underline[INCORRECT]#super[I]]*]
#let not_checkable() = [*#text(fill: purple)[#underline[NOT_CHECKABLE]#super[NC]]*]
#let misleading() = [*#text(fill: gold)[#underline[MISLEADING]#super[M]]*]
#let other() = [*#text(fill: rgb("#858585"))[#underline[OTHER]#super[O]]*]

- #incorrect(): la risposta contiene informazioni che contraddicono i dati forniti o che sono chiaramente sbagliate.
- #not_checkable(): la risposta contiene informazioni che non possono essere verificate con i dati forniti.
- #misleading(): la risposta contiene informazioni fuorvianti o che possono essere interpretate in modo errato.
- #other(): la risposta contiene errori grammaticali, stilistici o di altro tipo.

Oltre ad evidenziare parti problematiche delle risposte, è stato richiesto agli annotatori anche di fornire delle valutazioni qualitative su alcune metriche:

- *Accuratezza della risposta*: da selezionare quando la risposta è corretta al 100% e non contiene errori sui dati;
- *Assenza o incompletezza di informazioni*: da selezionare quando la risposta non contiene tutte le informazioni rilevanti;
- *Totale incongruenza della risposta*: da selezionare quando la risposta appare completamente scorrelata o non pertinente alla domanda;
- *Chiarezza della risposta*: se è comprensibile e ben strutturata;
- *Lunghezza della risposta*: se la comprensione della risposta è facilitata dalla sua lunghezza (o brevità);
- *Utilità percepita della risposta*: se la risposta è utile e fornisce informazioni rilevanti;
- *Apprezzamento generale*: se la risposta è apprezzata o gradita.

In totale, 12 annotatori hanno partecipato alla valutazione delle risposte generate dai modelli. Ogni volontario ha valutato un sottoinsieme delle risposte, garantendo comunque un overlap sulle 75 risposte totali. Per identificarli in questa tesi è stato definito un $epsilon_"hum"$, che rappresenta le informazioni risultante dalle annotazioni umane.

=== Annotazione automatica

In modo simile alle annotazioni prodotte dai volontari, sono state adoperati due modelli di LLM commerciali per valutare in modo automatico la qualità delle risposte generate. Mi sono basato sulla peculiarità di questi modelli di essere facilmente personalizzabili per vari compiti senza particolari necessità di addestramento.

Ho utilizzato i successori di GPT-4, indicati come più aderenti alle specifiche fornite in un certo task (#cite(<gpt-good-eval-wang>, form: "prose"), #cite(<sottana-etal-2023-evaluation>, form: "prose"), #cite(<kocmi-federmann-2023-gemba>, form: "prose")); in particolare, ho utilizzato `GPT-o3-mini` (indicato come particolarmente in grado di effettuare ragionamenti tramite chain-of-thought @chain-of-thought) e `GPT-4.5`, successore attualmente in sviluppo di `GPT-4`.

In particolare, per la valutazione automatica sono stati definiti $epsilon_"o3"$ e $epsilon_"4"$ (uno per modello), che in seguito alle istruzioni sulla task, hanno prodotto una serie di span da loro identificati come problematici. Nello specifico, è stato richiesto ai modelli di produrre una struttura dati JSON contenente le seguenti informazioni:

#figure(
  ```json
  {
    "errors": [{
      "reason": [REASON],
      "text": [TEXT_SPAN],
      "type": [ERROR_CATEGORY]
    }]
  }
  ```,
  kind: "snip",
  caption: "Struttura dati JSON prodotta dai modelli per la valutazione automatica delle risposte.",
)

È di particolare importanza l'ordine con cui le proprietà degli oggetti che popolano la lista `errors` sono state riportate: è prima richiesto di generare la motivazione dell'errore in quanto risulta che i modelli tendano a produrre output di precisione più elevata @kasner-dusek.

=== Risultati
Iniziamo a verificare l'accuratezza dell'output dei vari modelli. Considereremo come baseline i modelli closed source di OpenAI.

Una prima valutazione, disponibile nella @percentages-results, ci rivela che, a seconda del modello, tra il 18.6% e l'83% delle risposte contengono almeno un errore, secondo $epsilon_"hum"$. $epsilon_"4.5"$ ha individuato almeno un errore nel 6.6-33% delle risposte, mentre $epsilon_"o3"$ indica un errore nel 6-13% degli output.
Considerati questi range, saranno presentati i risultati solo per $epsilon_"hum"$ e $epsilon_"4.5"$, in quanto $epsilon_"o3"$ ha fornito risultati simili a $epsilon_"4.5"$.

`Deepseek-r1:8b` e `Gemma2:9b` sono i modelli open che presentano il minor numero di errori, con una percentuale di risposte corrette rispettivamente del 26.7% e del 33.3%.

#figure(
  {
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
      [Deepseek], [*20%*], [*13.3%*], [6.67%], [*0%*], [*26.7%*], [6.7%], [66.7%], [*0%*], [83%], [*33.3%*],
      [Gemma2], [26.7%], [26.7%], [*0%*], [*0%*], [33.3%], [*0%*], [*20%*], [6.7%], [*30.6%*], [*33.3%*],
      [Llama3.1], [33.3%], [33.3%], [6.67%], [*0%*], [*26.7%*], [6.7%], [46.7%], [*0%*], [67.3%], [53.3%],
      table.hline(stroke: (dash: "dashed")),
      [GPT-4o], [20%], [*6.7%*], [13.3%], [*0%*], [20%], [*0%*], [40%], [*0%*], [36%], [*6.6%*],
      [GPT-o3-mini], [*0%*], [13.3%], [*0%*], [*0%*], [*13.3%*], [*0%*], [*20%*], [*0%*], [*18.6%*], [20%],
    )
  },
  caption: [Percentuali di _risposte contenenti almeno un errore_, secondo le annotazioni umane ($epsilon_"hum"$) e le valutazioni automatiche ($epsilon_"4.5"$). Più basso è il valore, migliore è la qualità delle risposte.],
) <percentages-results>

L'errore più comune è #other(), indicando che i modelli tendono a produrre risposte grammaticalmente scorrette, stilisticamente inadeguate o ripetitive.
In particolare, `Deepseek-r1` è il modello che produce più errori di questo tipo, con una percentuale del 66.6% secondo i valutatori umani.

Possiamo anche vedere come in media, tutti i modelli tendano a produrre almeno un errore #incorrect() per 10 risposte, ad eccezione di `gpt-o3-mini`. Questo potrebbe dovuto sia al fatto che il modello abbia accesso ad ampie risorse di esecuzione, sia al fatto che si tratti di un modello chain-of-thought. Questo genere di modelli, dei quali fa parte anche `Deepseek-r1`, richiedono più tempo per eseguire, ma tendono a produrre output di maggiore qualità in seguito ad una fase di "ragionamento".

Questa ipotesi è supportata dai dati: `Deepseek-r1`, nella sua versione da 8 miliardi di parametri utilizzata in questa valutazione, produce meno errori di `GPT-4o` (1.26 - 1.46) , modello (stimato) da 200 miliardi di parametri @abacha2025medecbenchmarkmedicalerror.
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
    [Deepseek-r1:8b], [*1.26*], [*2.66*], [0.73], [*0*], [1], [0.66], [5.3], [*0*], [8.3], [*3.33*],
    [Gemma2:9b], [1.66], [*2.66*], [*0*], [*0*], [*0.66*], [*0*], [*0.73*], [0.66], [*3.06*], [*3.33*],
    [Llama3.1:8b], [2.93], [4.66], [0.06], [*0*], [*0.66*], [0.66], [3.06], [*0*], [6.73], [5.33],
    table.hline(stroke: (dash: "dashed")),
    [GPT-4o], [1.46], [*0.66*], [1], [*0*], [0.2], [*0*], [*0.93*], [*0*], [3.6], [*0.66*],
    [GPT-o3-mini], [*0*], [2], [*0*], [*0*], [*0.13*], [*0*], [1.73], [*0*], [*1.86*], [2],
  ),
  caption: [Numero medio di _errori ogni 10 output, per ogni categoria di errore_ e in totale, secondo le annotazioni umane ($epsilon_"hum"$) e le valutazioni automatiche ($epsilon_"4.5"$). Più basso è il valore (evidenziato per ogni colonna), migliore è la qualità delle risposte.],
)

/*
clearness distribution per LLM
[gpt-o3-mini],[92.66666666666666],[7.333333333333333],[0.0]
[gpt-4o],[86.0],[8.666666666666668],[5.333333333333334]
[deepseek-r1-8b],[69.33333333333334],[30.0],[0.6666666666666667]
[llama3-1-8b],[63.33333333333333],[19.333333333333332],[17.333333333333336]
[gemma2-9b],[56.00000000000001],[28.000000000000004],[16.0]

length distribution per LLM
[gpt-o3-mini],[96.0],[2.0],[2.0],
[gpt-4o],[89.33333333333333],[8.666666666666668],[2.0],
[llama3-1-8b],[78.0],[8.666666666666668],[13.333333333333334],
[deepseek-r1-8b],[71.33333333333334],[24.666666666666668],[4.0],
[gemma2-9b],[49.333333333333336],[0.0],[50.66666666666667]

usefulness distribution per LLM
[gpt-o3-mini],[2.0],[98.0],[0.0]
[gpt-4o],[4.666666666666667],[90.0],[5.333333333333334]
[deepseek-r1-8b],[12.666666666666668],[82.0],[5.333333333333334]
[llama3-1-8b],[12.0],[68.0],[20.0]
[gemma2-9b],[17.333333333333336],[58.666666666666664],[24.0]

like distribution per LLM
[gpt-o3-mini],[4.666666666666667],[95.33333333333334]
[gpt-4o],[13.333333333333334],[86.66666666666667]
[deepseek-r1-8b],[32.0],[68.0]
[llama3-1-8b],[42.0],[57.99999999999999]
[gemma2-9b],[63.33333333333333],[36.666666666666664]

answer 100% accurate, missing information, completely off topic
deepseek-r1-8b,70.0,9.333333333333334,0.0
gemma2-9b,66.0,27.333333333333332,2.0
gpt-4o,90.0,4.666666666666667,1.3333333333333335
gpt-o3-mini,98.66666666666667,0.6666666666666667,0.0
llama3-1-8b,71.33333333333334,10.666666666666668,2.0
*/

In termini di chiarezza (cioè quanto la risposta risulti pienamente comprensibile), `GPT-o3-mini` produce la percentuale più alta di risposte completamente chiare (oltre il 90%), seguito a breve distanza da `GPT-4o` (86%).
Viceversa, i modelli open source mostrano tassi di chiarezza inferiore: `Deepseek-r1:8b` e `Llama3.1:8b` spaziano tra il 60% e il 70%, mentre `Gemma2:9b` si ferma al 56%, con il 16% di risposte ritenute non sufficientemente chiare. Questo indica che, per quanto riguarda la formulazione dei contenuti, i modelli `GPT-o3-mini` e `GPT-4o` riescono a generare frasi più fluide e comprensibili.

#figure(
  table(
    columns: 4,
    table.header(
      table.cell(rowspan: 1, align: center + horizon)[Modello],
      // table.cell(colspan: 3, align: center)[*Clearness*],
      [Completely Clear],
      [Mostly Clear],
      [Unclear],
    ),
    table.hline(),
    [GPT-o3-mini], [*92.66%*], [7.33%], [0%],
    [GPT-4o], [*86%*], [8.66%], [5.33%],
    [Deepseek-r1:8b], [*69.33%*], [30%], [0.66%],
    [llama3.1:8b], [*63.33%*], [19.33%], [17.33%],
    [Gemma2:9b], [*56%*], [28%], [16%]
  ),
  caption: [Distribuzione della _chiarezza percepita nelle risposte_ per ogni modello.],
)

Un dato che appare strettamente collegato alla chiarezza è la lunghezza percepita delle risposte.
Anche qui `GPT-o3-mini` produce quasi sempre risposte lunghe il giusto secondo i valutatori (96% dei casi) e solo in rarissime occasioni troppo estese o troppo sintetiche.
`GPT-4o` mantiene numeri simili (89,33%), mentre i modelli open source, in particolare `Deepseek-r1:8b` e `Gemma2:9b`, peccano rispettivamente di risposte talvolta troppo lunghe e troppo brevi. 

`Gemma2:9b` produce risposte troppo brevi addirittura nel 50% circa delle interazioni.
Andando a verificare la lunghezza effettiva, spesso le risposte di `Gemma2:9b` marcate come troppo brevi sono composte da una sola parola, che evidentemente non fornisce informazioni sufficienti agli annotatori.

#figure(
  table(
    columns: 4,
    table.header(
      table.cell(rowspan: 1, align: center + horizon)[Modello],
      // table.cell(colspan: 3, align: center)[*Clearness*],
      [Long Enough],
      [Too Long],
      [Too short],
    ),
    table.hline(),
    [GPT-o3-mini], [*96%*], [2%], [2%],
    [GPT-4o], [*89.33%*], [8.66%], [2%],
    [llama3.1:8b], [*78%*], [8.66%], [13.33%],
    [Deepseek-r1:8b], [*71.33%*], [24.66%], [4%],
    [Gemma2:9b], [49.33%], [0%], [*50.66%*]
  ),
  caption: [Distribuzione della _lunghezza percepita delle risposte_ per ogni modello.],
)

Guardando all'utilità percepita dagli annotatori (intesa come quanto una risposta sia ritenuta utile nel contesto della domanda associata), `GPT-o3-mini` si distingue nettamente: quasi il 98% delle sue risposte è ritenuta utile, con una minima quota di risposte "né utili né inutili" e nessuna considerata del tutto priva di valore.
`GPT-4o` mantiene un livello molto alto di utilità (90%), pur avendo un 5% di risposte ritenute di utilità nulla. 
I modelli open source mostrano differenze notevoli: `Deepseek-r1:8b` produce un ottimo risultato con l'82% di risposte utili, `Llama3.1:8b` scende al 68%, mentre `Gemma2:9b` si ferma al 58.66%, con quasi un quarto delle risposte reputate come prive di utilità per la comprensione dell'automa.

#figure(
  table(
    columns: 4,
    table.header(
      table.cell(rowspan: 1, align: center)[Modello],
      // table.cell(colspan: 3, align: center)[*Clearness*],
      [Useful],
      [Neither Useful\ nor Useless],
      [Useless],
    ),
    table.hline(),
    [GPT-o3-mini], [*98%*], [2%], [0%],
    [GPT-4o], [*90%*], [4.66%], [5.33%],
    [Deepseek-r1:8b], [*82%*], [12.66%], [5.33%],
    [llama3.1:8b], [*68%*], [12%], [20%],
    [Gemma2:9b], [*58.66%*], [17.33%], [24%],
  ),
  caption: [Distribuzione del' _utilità percepita delle risposte_ per ogni modello.],
)

Il gradimento generale conferma sostanzialmente queste tendenze.
`GPT-o3-mini` è apprezzato in oltre il 95% delle risposte, `GPT-4o` nell'86.66%.
I modelli open source registrano un calo, con `Deepseek-r1:8b` apprezzato nel 68% dei casi, `Llama3.1:8b` al 58% e `Gemma2:9b` sotto il 40%. Anche in questo caso, dunque, `GPT-o3-mini` e `GPT-4o` dimostrano di generare testi più convincenti e graditi dagli annotatori.

#figure(
  table(
    columns: 3,
    table.header(
      table.cell(rowspan: 1, align: center + horizon)[Modello],
      [Not Appreciated],
      [Appreciated],
    ),
    table.hline(),
    [GPT-o3-mini], [4.66%], [*95.33%*],
    [GPT-4o], [13.33%], [*86.66%*],
    [Deepseek-r1:8b], [32%], [*68%*],
    [llama3.1:8b], [42%], [*57.99%*],
    [Gemma2:9b], [*63.33%*], [36.66%],
  ),
  caption: [Distribuzione dell'_apprezzamento delle risposte_ per ogni modello.],
)

Infine, è interessante vedere il tasso di completezza e accuratezza delle risposte ("100% accurate", "informazioni mancanti", "totalmente off-topic").
`GPT-o3-mini` domina chiaramente, con quasi il 99% di risposte completamente corrette rispetto ai dati forniti, e solo lo 0,66% che omette dettagli essenziali.
`GPT-4o` si attesta su un 90% di risposte precise, evidenziando però un minimo margine di errore maggiore.

Sul fronte open source, `Deepseek-r1:8b` e `Llama3.1:8b` viaggiano intorno al 70% di risposte pienamente accurate; `Gemma2:9b`, pur avendo una discreta fetta di risposte corrette (66%), nel 27% delle risposte tende ad omettere delle informazioni, evidenziando un problema di incompletezza più marcato.

#figure(
  table(
    columns: 4,
    table.header(
      table.cell(rowspan: 1, align: center + horizon)[Modello],
      [100% Accurate],
      [Missing Info],
      [Completely Off Topic],
    ),
    table.hline(),
    [Deepseek-r1:8b], [70%], [9.33%], [*0%*],
    [Gemma2:9b], [66%], [27.33%], [2%],
    [GPT-4o], [90%], [4.66%], [1.33%],
    [GPT-o3-mini], [*98.66%*], [*0.66%*], [*0%*],
    [llama3.1:8b], [71.33%], [10.66%], [2%],
  ),
  caption: [Distribuzione della _qualità delle risposte_ per ogni modello.],
)

Per le ultime osservazioni, può essere utile osservare la correlazione tra le varie metriche di valutazione delle risposte per ogni modello. Questo ci permette di capire se esistono relazioni significative tra le diverse dimensioni di valutazione, e se i modelli tendono a produrre output coerenti o meno.

#figure(
  image("../../gen_eval/diagrams/correlation_metrics.svg", width: 85%),
  caption: "Correlazione tra le metriche di valutazione delle risposte per ogni modello.",
)

Dalla matrice di correlazione (calcolata col coefficiente di correlazione di Pearson) si nota innanzitutto che tutte le variabili sono positivamente correlate tra loro; ciò suggerisce che, all'aumentare di una determinata caratteristica (ad esempio la chiarezza percepita), tendono a crescere anche le altre (come l'utilità o il gradimento). Tuttavia, l'intensità di queste relazioni varia sensibilmente:

- *Usefulness e accuracy*: la correlazione più forte è fra utilità percepita e accuratezza (\~0.77). In altre parole, le risposte ritenute corrette rispetto ai dati tendono anche a essere giudicate utili per l'utente. È possibile concludere che, se un contenuto è preciso, venga anche percepito come maggiormente informativo o prezioso.

- *Clearness e usefulness*: la seconda correlazione più elevata (\~0.69) lega la chiarezza alla percezione d'utilità. Ciò indica che le risposte ben strutturate e comprensibili risultano, agli occhi dell'utente, più utili rispetto a risposte meno nitide. Non sorprende che la fruibilità dipenda molto da quanto il testo sia chiaro e diretto.

- *Clearness e accuracy*: esiste inoltre una correlazione moderata (\~0.59) tra chiarezza e accuratezza. Anche se si tratta di due concetti distinti (una risposta può essere formalmente ineccepibile ma “opaca”, oppure chiara eppure carente di dettagli), nel complesso risposte chiare hanno spesso contenuti più precisi — e viceversa. In un sistema di dialogo, ciò può riflettere la tendenza di un buon modello a esprimere in modo ordinato e coerente i dati estratti, evitando di generare confusione (che si tradurrebbe in errori informativi).

- *Correlazioni con l'apprezzabilità*: la percezione positiva da parte dell'utente cresce in parallelo con quasi tutti i parametri, mostrando coefficienti medio-alti. È particolarmente interessante la correlazione con la usefulness (\~0.63) e con la clearness (\~0.57). Ciò non sorprende: è ragionevole immaginare che l'esperienza di un utente sia complessivamente migliore quando un sistema produce risposte utili, chiare e ragionevolmente precise.

- Da notare anche la correlazione con la *lunghezza* (\~0.54): sembrerebbe che una risposta ritenuta “abbastanza lunga” (ma non eccessivamente prolissa) favorisca un giudizio positivo (possiamo immaginare perché fornisca il giusto livello di dettaglio senza risultare ridondante o generica).

- Ruolo della *lunghezza*: la lunghezza percepita delle risposte ha la correlazione più modesta con l'accuratezza (\~0.26) e con l'utilità (\~0.31), ma mostra un legame più consistente con il gradimento. Questo ci può far ipotizzare che, se da un lato un testo più lungo non necessariamente garantisca risposte più esatte o più utili, dall'altro esiste una tendenza per cui gli utenti apprezzano leggermente di più risposte che non siano troppo sintetiche. La lunghezza potrebbe dunque fungere da “cuscinetto” per includere informazioni e dimostrare padronanza dell'argomento, purché non diventi prolissa.

Sono state escluse dalla matrice di correlazione le metriche attribuite alle risposte parziali ("missing") o completamente scorrelate ("off-topic"), in quanto non sono stati ottenuti abbastanza dati per poter stabilire relazioni significative.

=== Conclusioni

In questa sezione abbiamo visto come la generazione automatica di testo all'interno di un sistema di dialogo richieda l'integrazione di molteplici aspetti: dall'estrazione dei dati — tramite basi di conoscenza, corpora testuali o API esterne — alla costruzione di prompt ben progettati, fino alla valutazione qualitativa e quantitativa delle risposte generate.
È emerso che l'impiego di modelli di grandi dimensioni (come GPT) consenta di ottenere risultati particolarmente convincenti in termini di chiarezza, utilità e accuratezza.
In effetti, modelli come `GPT-o3-mini` hanno saputo mantenere alta la qualità delle risposte, dimostrandosi generalmente più "affidabili" e apprezzati dagli utenti rispetto a diverse alternative open source.

Ciononostante, gli esperimenti svolti evidenziano come anche i modelli open source — pur offrendo prestazioni mediamente inferiori — presentino importanti vantaggi che rendono la loro adozione strategica in numerosi contesti.

Un primo aspetto rilevante è la *privacy dei dati*: l'uso di un modello “locale” consente di elaborare internamente *informazioni sensibili* (ad esempio relative a ordini, utenti o contenuti proprietari), evitando che esse vengano esposte a servizi remoti #footnote[Specialmente considerando i rischi che comporta la condivisione di dati sensibili a terzi. È di vitale importanza considerare i rischi associati, e non dimenticare che ci sono casi di falsificazione dei risultati delle LLM, come mostrato in #cite(<rig-performance>, form: "full")].
A questo si lega la possibilità di *controllare e personalizzare il flusso di elaborazione*; chiunque disponga di conoscenze tecniche adeguate può *ispezionare*, *modificare* o *integrare* il codice sorgente e i pesi del modello, adattandolo a domini verticali o ottimizzandolo per esigenze specifiche (ad esempio effettuando operazioni di fine-tuning su un corpus interno).

Un ulteriore vantaggio riguarda la *trasparenza e la replicabilità*: con i modelli open source è più facile realizzare un'audit trail dell'architettura e del comportamento di generazione, analizzando i meccanismi che portano a un certo output.
Questo non solo facilita la verifica e la riduzione dei bias, ma incentiva anche una ricerca aperta e collaborativa che stimola l'innovazione e la creazione di community attive.
In alcune applicazioni critiche, come quelle mediche o finanziarie, poter dimostrare con esattezza come il sistema produce le risposte è un requisito essenziale per adeguarsi a normative e standard di conformità.

Infine, dal punto di vista delle licenze e della sostenibilità nel lungo periodo, le soluzioni open offrono una maggiore flessibilità d'uso e spesso non impongono canoni basati sul volume di richieste.
Ciò *abbatte potenzialmente i costi operativi*, permettendo di sperimentare e adottare la tecnologia su larga scala senza vincoli commerciali stringenti.

Considerati insieme, questi elementi fanno sì che, pur non potendo ancora competere con GPT in termini di prestazioni pure, i modelli open source incarnino un'opzione sempre più solida per chi cerca indipendenza, controllo e trasparenza, costituendo una componente essenziale dell'ecosistema NLG moderno.

Nella prossima sezione vedremo come tutte le componenti finora presentate sono state integrate in un sistema di dialogo completo.