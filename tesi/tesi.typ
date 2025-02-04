#import "styles.typ": template

#let acknowledgments = [ 
  Todo
]

#let abstract = [ 
  Todo.
]

#show: template.with(
  title: "Design, ingegnerizzazione e realizzazione di un sistema di dialogo basato su LLM nel dominio delle tecnologie assistive",

  academic-year: [2023/2024],

  subtitle: "Tesi di Laurea Magistrale",

  candidate: (
    name: "Stefano Vittorio Porta",
    matricola: 859133
  ),

  supervisor: (
    "Prof. Alessandro Mazzei"
  ),

  affiliation: (
    university: "Università degli Studi di Torino",
    school: "Scuola di Scienze della Natura",
    degree: "Corso di Laurea Magistrale in Informatica",
  ),

  lang: "it",

  logo: image("media/unito.svg", width: 40%),

  // bibliography: bibliography("bib.yml", full:true),

  acknowledgments: acknowledgments,
  abstract: abstract,

  keywords: [
    "classificazionexNLU", 
    "data annotation/augmentation", 
    "NLGBasataSuParafrasi", 
    "ingegnerizzazione"
  ]
)

#let appendix(body) = {
  set heading(numbering: "A", supplement: [Appendix])
  counter(heading).update(0)
  body
}

#include "chapters/1_introduction.typ"
#pagebreak(weak: true)

#include "chapters/2_nlu.typ"

#pagebreak(weak: true)

= Data Retrieval // Spiegazione di cosa è il data retrieval

== Retrieval tramite query // Knowledgebase, basi di dati, ecc.
== Retrieval basato su script
== Retrieval automatico guidato dalle LLM

#pagebreak(weak: true)

= Natural Language Generation
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
*/


== Come vengono fornite le risposte in AIML

== Generazione di risposte tramite LLM

=== Parafrasi

=== Prompting

== Qualità delle risposte

=== Valutazione automatica

=== Valutazione umana

// - Qualità delle risposte valutate da persone (questionario):
//   - Tassonomia Dusek (https://d2t-llm.github.io/) per la valutazione

#pagebreak(weak: true)

= Ingegnerizzazione

// sviluppo di un sistema con funzionalità simili ad AIML ma che integri le migliorie sopra spiegate e approfondite.

== Composizione del sistema

== Compilatore

=== Pipeline

== Runner

/*
- *NLU*: Inizialmente modificare aiml-high per rendere più flessibile la parte di comprensione mediante classificazione
  - *Bert/T1/Word embedding tensor*
    - L'idea è di utilizzare un classificatore fine-tuned su un Encoder per determinare una gerarchia di interazioni possibili. Una volta individuata la classe specifica, è possibile fare slot-filling.
    - Dataset:
      - Annotazione automatica tramite LLM. Posso usarle per avere dei bronze-corpora su cui fare fine tuning?
      - Data augmentation con LLM. Valutazione manuale (globale e a campione)
    - *Valutazione*: metriche usate in letteratura (precision, recall, F1)
  - Spacy: estrazione delle entità per gli slot
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
- *Data Retrieval*: query esterne, da KB, con script
- *Ingegnerizzazione*: sviluppo di un sistema con funzionalità simili ad AIML ma che integri le migliorie sopra spiegate e approfondite.
*/
// #show bibliography: set text(size: 0.9em)

#bibliography("bib.yml", full: false)

// #show: appendix // https://github.com/typst/typst/discussions/4031

// = 