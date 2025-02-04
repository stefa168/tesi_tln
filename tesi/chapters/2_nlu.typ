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

#pagebreak(weak: true)

== Dataset // Data augmentation con LLM, prompt e valutazione manuale

=== Etichettatura automatica // Classificazione automatica con LLM + snippet estesi nell'appendice

=== Data augmentation 

=== Etichettatura manuale

#pagebreak(weak: true)

== NLU: Capire cosa si sta dicendo

=== Metodi classici con Spacy // CNN, Text2Vec, ecc.

=== Classificazione con LLM // Cosa ho usato delle LLM per fare classificazione

// - Addestramento di un modello di classificazione tramite Bert
//   - Spiegazione di BERT con puntatore all'appendice sui transformer
//   - Paper di riferimento per gli iperparametri
//   - Utilizzo delle librerie di Hugging Face, con snippet di codice

=== Valutazione e performance // Spiegazione di come ho valutato i risultati dei classificatori

#pagebreak(weak: true)

== NLU: Capire di cosa si sta parlando

=== NER e Slot-filling // Spiegazione di cosa sono 

==== Il ritorno di Spacy // Come ho implementato la parte di NER con spacy

=== Valutazione e performance

// Metriche di valutazione (F1 con CoNLL, ACE, MUC https://www.davidsbatista.net/blog/2018/05/09/Named_Entity_Evaluation/)