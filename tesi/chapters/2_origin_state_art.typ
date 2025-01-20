#import "@preview/diagraph:0.3.1": render, raw-render

= Origini e Stato dell'Arte

In questo capitolo verrà fornita una panoramica sui principali approcci per la realizzazione di chatbot e sistemi di interrogazione automatica basati sul linguaggio naturale. 
Si partirà dall'analisi dei sistemi *rule-based*, che hanno segnato le prime tappe nella ricerca nel campo degli agenti conversazionali, per poi passare ai moderni approcci basati sull'apprendimento automatico con le reti neurali, prestando particolare attenzione ai modelli basati sull'architettura dei transformer.

Il Natural Language Understanding è un campo di ricerca in continua evoluzione, con tecniche e algoritmi costantemente aggiornati e nuovi modelli che vengono proposti e testati.

== Chatbot rule-based

Fin dalle origini dello studio dell'elaborazione del linguaggio naturale, i cosiddetti chatbot _rule-based_ (basati su regole) hanno costituito il primo approccio per simulare un interlocutore con cui gli utenti possano interagire col linguaggio naturale.\
In questi sistemi le risposte del chatbot sono generate sulla base di pattern di input definiti in modo esplicito e di regole o template codificati dall'autore del programma. 
Tutte le possibili ramificazioni delle conversazioni sono previste e scelte in anticipo, al momento della progettazione.\
Nonostante le moderne tecniche di apprendimento automatico abbiano guadagnato terreno, i chatbot rule-based mantengono un ruolo significativo, soprattutto quando è cruciale avere un controllo totale sulle risposte, mantenendo il flusso logico esplicito e operando in un dominio ristretto.

// Bisogna spiegare anche cosa sono le regole e come funzionano, magari con un esempio

=== Le Origini con ELIZA

Uno dei primi e più noti esempi di chatbot rule-based è ELIZA, sviluppato da Joseph Weizenbaum al MIT nel 1966 @eliza @eliza_history.\
ELIZA simulava le risposte di uno psicoterapeuta rogersiano #footnote[Carl Rogers è stato uno psicologo statunitense, noto per gli studi sul counseling e fondatore della "psicoterapia incentrata sulla persona". Questo approccio portava alla costruzione di una relazione collaborativa e di fiducia tra terapista e paziente (per Rogers "cliente" dal momento che secondo lui non aveva un ruolo passivo ma attivo nella guarigione), basata sull'empatia, ritenuta essenziale per poter raggiungere il benessere psicologico @rogers.], basandosi su un semplice algoritmo di riscrittura (rewrite) delle frasi in input.\
L'effetto era sorprendentemente convincente in alcuni casi, poichè ELIZA trasformava abilmente le frasi dell'utente in domande di ritorno, mantenendo un'apparenza di comprensione.

#let mono(body, font: "JetBrains Mono NL") = {
  text(upper(body), font: font, size: 10pt)
}

#let tdd(date) = {
  [#sym.quote.r.single#date]
}

// Esempio conversazione con ELIZA
// todo modificare lo stile dell'elenco per renderlo più simile a quello di un messaggio di chat
#figure({
    set align(left)
    quote(block: true)[
      Gli uomini sono tutti uguali.\
      #mono[in che modo]\
      Ci infastidiscono sempre di una cosa o dell'altra.\
      #mono[PUOI PENSARE A UN ESEMPIO SPECIFICO?]\
      Beh, il mio ragazzo mi ha fatta venire qui.\
      #mono[IL TUO RAGAZZO TI HA FATTA VENIRE QUI.]\
      Mi dice sono depressa molto spesso.
      #mono[MI DISPIACE CHE TU SIA DEPRESSA.]
    ]
    v(0.25em)
  },
  caption: [Un esempio di conversazione con ELIZA da #cite(<eliza>, form: "prose")], 
  kind: "listing", 
  supplement: [Listato]
) <eliza_example>

==== Composizione
ELIZA si basava su *script di regole* scritte originariamente in SLIP (un dialetto di Lisp, un linguaggio basato sulla manipolazione dei simboli @ABRAHAMS196951), organizzate in una serie di *pattern* (decomposition rules) e *risposte template* (reassembly rules).\
L'idea fondamentale era che ogni regola si attivasse se l'input dell'utente conteneva una certa parola chiave (keyword); ad ogni keyword era associato un insieme di “trasformazioni” più o meno generali, che permettevano di riformulare la frase dell'utente.

#{
// show figure: set block(breakable: true)
figure(caption: [Un frammento delle regole che compongono ELIZA da #cite(<eliza>, form: "prose")])[
```eliza
(HOW DO YOU 00. PLEASETELL ME YOUR PROBLEM)
START
(SORRY ( ( 0 ) (PLEASE DON'T A P O L I G I Z E )
(APOLOGIES ARE NOT NECESSARY) (WHAT FEELINGS
DO YOU HAVE WHEN YOU APOLOGIZE) ( l I V E TOLD YOU
THAT APOLOGIES ARE NOT REQUIRED)))
(DONT = DON'T)
(CANT = CAN'T)
(WONT = WON'T)
(REMEMBER S
( ( 0 YOU REMEMBER O) (DO YOU OFTEN THINK OF 4)
(DOES THINKING OF ~ BRING ANYTHING ELSE TO MINO)
(WHAT ELSE OO YOU REMEMBER)
(WHY DO YOU REMEMBER 4 JUST NOW)
(WHAT IN THE PRESENT SITUATION REMINDS YOU OF ~)
(WHAT IS THE CONNECTION BETWEEN ME AND ~))
((0 DO I REMEMBER 0) (DID YOU THINK I WOULD FORGET 5)
(WHY DO YOU THINK I SHOULD RECALL S NOW)
(WHAT ABOUT 5) (=WHAT) (YOU MENTIONED S))
((0) (NEWKEY)))
```
]
}

===== Parole chiave e priorità

Le regole di ELIZA erano raggruppate attorno a delle keyword, che definivano l'argomento o l'elemento su cui il sistema doveva focalizzare l'attenzione. 
Ad esempio, se la keyword era “REMEMBER”, tutte le regole associate si occupavano di reinterpretare le frasi in cui l'utente accennava a un ricordo.

- Ogni keyword poteva avere una priorità numerica, indicando quanto fosse importante rispetto alle altre. In caso di input multiple che attivassero più keyword, veniva scelta quella con la priorità più alta.
- Se l'utente menzionava “IO NON RICORDO” (“I DON'T REMEMBER”), ELIZA cercava innanzitutto la keyword “REMEMBER” per attivare le regole di corrispondenza più specifiche.

===== Decomposition Rules

Ogni keyword era legata a una serie di decomposition rules che descrivevano come scomporre la frase dell'utente in componenti rilevanti.
Questo avveniva tramite pattern contenenti placeholder e occasionalmente wildcard.
Ad esempio, una decomposition rule per la keyword “REMEMBER” poteva apparire così (in forma semplificata)
#align(center)[`( 0 YOU REMEMBER 0 )`]

Qui, il simbolo 0 rappresenta dei placeholder che potevano catturare qualunque parte del testo.
Se la frase dell'utente era "I think *you remember* when I was a child", il sistema isolava le porzioni di testo prima e dopo la stringa “YOU REMEMBER”.

Queste regole permettevano a ELIZA di individuare la struttura della frase e di memorizzare le parti variabili (ad esempio, tutto ciò che seguiva “YOU REMEMBER”).

===== Reassembly Rules

Una volta trovato un pattern corrispondente, ELIZA applicava una corrispondente reassembly rule, ovvero un template che generava la risposta.
Proseguendo con l'esempio della keyword “REMEMBER”, se la decomposition rule catturava una parte di frase dopo “YOU REMEMBER”, la reassembly rule selezionata poteva essere una delle seguenti: 

#align(center)[
```
(DO YOU OFTEN THINK OF 4?)
(WHY DO YOU REMEMBER 4 JUST NOW?)
```
]

e il sistema rispondeva sostituendo dinamicamente il placeholder con la parte di testo catturata.

Così, se l'utente diceva "Io penso che tu ricordi il mio compleanno", ELIZA poteva rispondere "Perché pensi che io ricordi il tuo compleanno proprio ora?"

===== Regole di Fallback

Se nessuna keyword né pattern specifico viene attivato, ELIZA passava a una serie di regole di fallback, spesso domande generiche come:

#align(center)[
```
(TELL ME MORE)
(WHY DO YOU SAY THAT?)
```
]

Queste tornano utili a mantenere viva la conversazione anche quando non vi è corrispondenza con le regole definite, evitando il silenzio o un evidente messaggio di errore.

==== Conclusioni

È evidente comunque come ELIZA non fosse realmente in grado di comprendere il significato delle frasi: si limitava a riconoscere e riformulare le frasi usando parole chiave ottenute dalla conversazione.
Un utente che ne è consapevole può potenzialmente "ingannare" il sistema con frasi prive di senso, ottenendo comunque risposte coerenti.

#figure({
    set align(left)
    quote(block: true)[
      Il mio gatto è morto.\
      #mono[MI DISPIACE PER IL TUO GATTO.]\
      Ora che è morto non so cosa fare.\
      #mono[COSA TI FA PENSARE DI NON SAPERE COSA FARE?]\
    ]
    v(0.25em)
  },
  caption: [Un listato dal poco senso. (Povero gatto)], 
  kind: "listing", 
  supplement: [Listato]
) <eliza_example_broken>

Ad ogni modo Weizenbaum riportò (con non poca preoccupazione per ciò che potesse implicare) che diversi utenti iniziarono a fare riferimento al programma umanizzandolo, attribuendogli sentimenti e personalità.\
Una personalità che era, se non proprio di un terapeuta, perlomeno di un interlocutore percepito come utile.

Esiste un episodio celeberrimo che dimostra l'efficacia del sistema: anche la segretaria di Weizenbaum aveva iniziato ad interagire con esso. In un'occasione, gli chiese al ricercatore di lasciarla sola nella stanza per poter terminare privatamente la propria consulenza con ELIZA @eliza_history.

=== AIML

Negli anni #tdd(90) iniziò a guadagnare popolarità il Loebner Prize, una competizione ispirata al Test di Turing @imitation_game.\
Nella competizione, chatbot e sistemi conversazionali cercavano di "ingannare" giudici umani, facendo credere loro di essere persone reali.
Molti sistemi presentati alla competizione erano basati su pattern matching e rule-based, a volte integrando euristiche per la gestione di sinonimi o correzione ortografica.

Tra questi, uno dei più celebri è ALICE (Artificial Linguistic Internet Computer Entity), sviluppato da Richard Wallace utilizzando il linguaggio di markup AIML (Artificial Intelligence Markup Language) da lui introdotto @aiml @alice. ALICE vinse per la prima volta il Loebner Prize nel 2000, e in seguito vinse altre due edizioni, nel 2001 e 2004.

==== Struttura di un chatbot AIML

Basato sull'XML, di base l'AIML fornisce una struttura formale per definire regole di conversazione attraverso “categorie” di pattern e template:
- `<pattern>`: la frase (o le frasi) a cui il chatbot deve reagire.
- `<template>`: la risposta (testuale o con elementi dinamici) che il chatbot fornisce quando si verifica il match del pattern.

Considerando ad esempio la seguente configurazione:
#align(center)[
```xml
<category>
  <pattern>CIAO</pattern>
  <template>Ciao! Come posso aiutarti oggi?</template>
</category>
```
]

se l'utente scrivesse "Ciao" #footnote[Caratteri maiuscoli e minuscoli sono considerati uguali dal motore di riconoscimento.], il sistema risponderebbe con "Ciao! Come posso aiutarti oggi?".

Grazie all'uso di wildcard (#sym.ast, #sym.dash.en) e a elementi di personalizzazione (`<star/>`), AIML può gestire un certo grado di variabilità linguistica:

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

In questo caso, se l'utente scrivesse "Mi chiamo Andrea", il sistema risponderebbe con "Ciao Andrea, piacere di conoscerti!".

Esistono anche tag per permettere di memorizzare informazioni e utilizzarle in seguito, come `<set>` e `<get>`, e per gestire la conversazione in modo più dinamico, come `<think>` e `<condition>`:

#align(center)[
```xml
<category>
  <pattern>CHE TEMPO FA</pattern>
  <template>
    <condition name="stagione">
      <li value="inverno">Fa piuttosto freddo, in questa stagione.</li>
      <li value="estate">Fa molto caldo, bevi tanta acqua!</li>
    </condition>
  </template>
</category>
```
]

È inoltre possibile raggruppare categorie simili con il tag `<topic>`, e riindirizzare la conversazione verso un argomento specifico con il tag `<srai>`:

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

==== Conclusioni su AIML

Grazie ai tag previsti dallo schema, AIML riesce a gestire conversazioni piuttosto complesse. Ciononostante, presenta comunque alcune limitazioni:

- Le strategie di wildcard e pattern matching restano prevalentemente letterali, con limitata capacità di interpretare varianti linguistiche non codificate nelle regole. Se una frase si discosta dal pattern previsto, il sistema fallisce il matching. Sono disponibili comunque alcune funzionalità per la gestione di sinonimi, semplificazione delle locuzioni e correzione ortografica, che devono essere costruite manualmente.
- La gestione del contesto (via `<that>, <topic>`, ecc.) è rudimentale, soprattutto se paragonata a sistemi moderni di NLU con modelli neurali che apprendono contesti ampi.
- L'integrazione con basi di conoscenza esterne (KB, database, API) richiede estensioni proprietarie o script custom, poiché AIML di per sé non offre costrutti semantici o query integrate, e non permette di integrare script internamente alle regole.

Nonostante questi limiti, AIML ha rappresentato un passo importante nell'evoluzione dei chatbot, offrendo un framework standardizzato e relativamente user-friendly per la creazione di agenti rule-based.\
In alcuni ambiti ristretti (FAQ ripetitive, conversazioni scriptate), costituisce ancora una soluzione valida e immediata. 
In domini più complessi, in cui la varietà del linguaggio e l'integrazione con dati dinamici sono essenziali, diventa indispensabile affiancare o sostituire AIML con tecniche di Natural Language Understanding basate su machine learning e deep learning.

#pagebreak(weak: true)

== Natural Language Understanding e Stato dell'Arte

Con *Natural Language Understanding* (NLU) si fa riferimento a un insieme di tecniche e modelli che mirano a comprendere il testo in ingresso a un livello più semantico, superando la semplice analisi di pattern o keyword.
Negli ultimi anni, la ricerca si è orientata verso modelli di machine learning, e in particolare di deep learning, capaci di catturare caratteristiche sintattiche, semantiche e contestuali.

La transizione dai sistemi rule-based verso metodi data-driven nel Natural Language Processing (NLP) è stata inizialmente guidata dall'impiego di Reti Neurali Ricorrenti (RNN), e solo recentemente è stata rivoluzionata dall'introduzione dei Transformer.

Queste architetture hanno permesso di passare da un'analisi del linguaggio ancorata a pattern e regole scritte a mano a un'interpretazione basata su features apprese automaticamente dai dati, in grado di cogliere sfumature sintattiche e semantiche molto più complesse.

=== Recurrent Neural Networks

Le reti neurali ricorrenti (RNN) sono un tipo di architettura di rete neurale progettata per analizzare sequenze di dati. 
Questa caratteristica le rende particolarmente adatte per compiti come modellazione del linguaggio, riconoscimento vocale, descrizione di immagini e tagging video.
Introdotte negli anni #tdd(80), le RNN hanno rivoluzionato l'elaborazione sequenziale, superando i limiti delle reti feedforward: mentre una FFN trasporta informazioni solo in avanti attraverso la rete, le RNN funzionano a cicli, e passano le informazioni di nuovo a se stesse ad ogni step @rnn_intro.

==== Intuizione di base

La principale differenza tra le RNN e le reti neurali tradizionali feedforward è la capacità delle prime di mantenere uno "stato" interno che rappresenta il contesto storico.
Questo stato viene aggiornato in ogni passo temporale $t$, consentendo alla rete di considerare input precedenti ($bold(X)_(0 dots t-1)$) quando elabora quello corrente $bold(X)_t$.

In termini pratici, le RNN sono progettate per "ricordare" informazioni rilevanti nel tempo, modellando così dipendenze sequenziali. Questo è rappresentato matematicamente come:

$ bold(H)_t = phi.alt_h (bold(X)_t bold(W)_(x h)+bold(H)_(t-1) bold(W)_(h h) + bold(b)_h) $

Dove:
- $bold(H)_t in bb(R)^(n times h) $ è lo stato nascosto al tempo $t$, che rappresenta un sommario dell'input corrente e della storia precedente.
- $ bold(X)_t in bb(R)^(n times d)$ è l'input al tempo $t$.
- $bold(W)_(x h) in bb(R)^(d times h)$ e $bold(W)_(h h) in bb(R)^(h times h)$ sono matrici di peso rispettivamente per l'input e lo stato nascosto, addestrate durante il processo di apprendimento.
- $bold(b)_h$ è il bias, un vettore che introduce flessibilità nella rappresentazione.
- $phi.alt_h$ è una funzione di attivazione, spesso una funzione non lineare come la tangente iperbolica o la sigmoide, utilizzata per garantire la continuità e stabilità dei gradienti.

#figure(grid(
  columns: 2,
  gutter: 2mm,
  raw-render(
  ```
  digraph FNN {
    node [shape=rect]
    edge [arrowhead="vee"]

    subgraph cluster_ffn {
      style=invis
      labelloc = "b"
      A1 -> B1 -> C1
    }
  }
  ```,
  labels: (
    "A1": [Input $bold(X)$], 
    "B1": [Hidden Layer $bold(H)$],
    "C1": [Output $bold(O)$]
    ),
    edges: (
      "A1": ("B1": [$bold(W)_(x h)$]),
      "B1": (
        "C1": [$bold(W)_(h o)$],
      )
    ),
    clusters: (
      "cluster_ffn": [Feedforward Neural Network]
    ),
  ),
  raw-render(
  ```
  digraph RNN {
    node [shape=rect]
    edge [arrowhead="vee"]

    subgraph cluster_rnn {
      style=invis
      labelloc = "b"
      A2 -> B2 -> C2
      B2:se -> B2:ne
    }
  }
  ```,
  labels: (
    "A2": [Input $bold(X)_t$],
    "B2": [Hidden Layer $bold(H)_t$],
    "C2": [Output $bold(O)_t$]
    ),
    edges: (
      "A2": ("B2": [$bold(W)_(x h)$]),
      "B2": (
        "C2": [$bold(W)_(h o)$],
        "B2": [$bold(W)_(h h)$]
      )
    ),
    clusters: (
      "cluster_rnn": [Recurrent Neural Network]
    ),
  )
), caption: [Schema di una rete feedforward (FFN) e di una rete ricorrente (RNN)])

L'output al tempo $t$ è poi calcolato come:

$ bold(O)_t = phi.alt_o (bold(H)_t bold(W)_(h o) + bold(b)_o) $

Come per le FFN, l'addestramento viene effettuato tramite la backpropagation. \
In questo caso tuttavia, il calcolo del gradiente deve tener conto della dipendenza temporale, e viene effettuato attraverso l'algoritmo di _backpropagation through time_ (BPTT).
Questo metodo "srotola" la rete nel tempo, trattando ogni passo temporale come un layer separato, e calcola i gradienti per ogni passo.

La funzione di loss viene calcolata sommando le loss di ogni passo temporale

$ cal(L)(bold(O), bold(Y)) = sum^T_(t-1) ell_t (bold(O)_t, bold(Y)_t) $

dove $ell_t$ è la funzione di loss al tempo $t$, $O_t$ è l'output predetto e $Y_t$ è l'output atteso.

#figure(raw-render(
  ```
  digraph BPTT {
    node [shape=circle]
    edge [arrowhead="vee"]
    rankdir=BT

    subgraph t1 {
      A [group=1]
      B [group=1, shape=square]
      C [group=1]

      A -> B -> C
    }
    
    subgraph t2 {
      A1 [group=2]
      B1 [group=2, shape=square]
      C1 [group=2]

      A1 -> B1 -> C1

      B -> B1 [minlen=2]
    }

    subgraph t3 {
      A2 [group=3]
      B2 [group=3, shape=square]
      C2 [group=3]

      A2 -> B2 -> C2

      B1 -> B2 [minlen=3, style=dashed]
    }

    {rank = same; B; B1; B2}
      
  }
  ```,
  labels: (
    "A":  [ $bold(X)_0$],
    "B":  [ $bold(H)_t$],
    "C":  [ $bold(O)_t$],
    "A1": [ $bold(X)_(1)$],
    "B1": [ $bold(H)_(1)$],
    "C1": [ $bold(O)_(1)$],
    "A2": [ $bold(X)_(t)$],
    "B2": [ $bold(H)_(t)$],
    "C2": [ $bold(O)_(t)$]
  ),
  edges: (
    "B1": ("B2": [...])
  )
), caption: [Una RNN srotolata nel tempo])

==== Problemi delle RNN <rnn_problems>

Le RNN nonostante la capacità di catturare dipendenze temporali, soffrono di problemi di esplosione o vanishing del gradiente in modo particolarmente acuto.

Infatti, dal momento che durante il training si può lavorare con stringhe (potenzialmente molto lunghe), se gestiamo valori di gradiente molto piccoli o molto grandi, la moltiplicazione di molti di questi valori può portare a valori di gradiente troppo piccoli o troppo grandi, compromettendo la convergenza del modello.

Questo problema ha spinto alla ricerca di architetture alternative, come le Long Short-Term Memory (LSTM) e le Gated Recurrent Unit (GRU), che introducono meccanismi di regolazione del flusso di informazione.

=== Long Short-Term Memory

Il problema del vanishing/exploding del gradiente non si ferma solo alla fase di apprendimento, ma può influenzare anche la capacità della rete di memorizzare informazioni a lungo termine @colah.

La lunghezza del testo da considerare è uno dei fattori: con una frase corta come "In cielo ci sono le nuvole" è facile per una RNN predire che la parola successiva sarà "nuvole" dopo aver visto "cielo".

Ci sono però anche casi in cui per poter effettuare la nostra predizione avremo bisogno di informazioni che si trovano molto più lontane nel testo.
Man mano che la distanza temporale tra le informazioni necessarie e il punto in cui ci troviamo aumenta, le RNN non riescono più a creare collegamenti tra le informazioni @rnn_deutch @rnn_difficult.

Per questo motivo sono state concepite le Long Short-Term Memory (LSTM), progettate nel #tdd(97) da #cite(<lstm>, form: "prose").
La loro architettura è intenzionalmente progettata per evitare i problemi descritti nella @rnn_problems, e i risultati sono stati molto positivi @colah @LINDEMANN2021650.

Esattamente come per le RNN, le LSTM sono reti ricorrenti, per cui si passano i dati in output anche come input.
La differenza principale è che le LSTM hanno un meccanismo di controllo che permette di decidere quali informazioni mantenere e quali scartare. 
Per far ciò non viene più utilizzata una rete, ma quattro:

#figure(
  image("../media/LSTM3-chain.png"),
  caption: [Schema di una cella LSTM, cortesia di #cite(<colah>, form: "prose").],
)



=== Transformers

=== LLM

== Framework e strumenti moderni
=== LangChain e Haystack

https://haystack.deepset.ai/
(https://www.reddit.com/r/LocalLLaMA/comments/1dxj1mo/langchain_bad_i_get_it_what_about_langgraph/)

== Conclusioni e gap da colmare