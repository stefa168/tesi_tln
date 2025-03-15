#import "styles.typ": template

#let acknowledgments = [
  Todo
]

#let abstract = [
Nel campo delle tecnologie assistive, l’accessibilità di contenuti complessi – come grafi, diagrammi e mappe concettuali – rappresenta una sfida significativa, soprattutto per utenti con disabilità visive. Questa tesi si propone di realizzare un sistema di dialogo basato su Large Language Models capace di “tradurre” tali contenuti in interazioni testuali comprensibili, consentendo agli utenti di esplorare e comprendere in modo approfondito le informazioni racchiuse in forme grafiche.

In particolare, sono state svolte ricerche e sperimentazioni su diverse tecniche di Natural Language Understanding (rule-based e neurali) per valutarne l’accuratezza e la robustezza. Sul piano ingegneristico è stata progettata un’architettura modulare che integra pipeline di elaborazione e retrieval di dati, garantendo sia la scalabilità sia la flessibilità del sistema.
]

#show: template.with(
  title: "Design, ingegnerizzazione e realizzazione di un sistema di dialogo basato su LLM nel dominio delle tecnologie assistive",

  academic-year: [2023/2024],

  subtitle: "Tesi di Laurea Magistrale",

  candidate: (
    name: "Stefano Vittorio Porta",
    matricola: 859133,
  ),

  supervisor: (
    "Prof. Alessandro Mazzei"
  ),

  co-supervisor: ("Pier Felice Balestrucci", "Michael Oliverio"),

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

  keywords: text(hyphenate: false)[
    NLU mediante classificazione,
    data annotation,
    data augmentation,
    data retrieval,
    NLG basata su LLM,
    software engineering
  ],
)

#set smartquote(alternative: true)

#let appendix(body) = {
  set heading(numbering: "A", supplement: [Appendix])
  counter(heading).update(0)
  body
}

#show table: set text(hyphenate: false)
#set table(
  align: (x, y) => (left + if y == 0 { bottom } else { top }),
  fill: (_, y) => if calc.odd(y) { gray.lighten(50%) },
  stroke: none,
)

#show figure.where(kind: "plot"): set figure(supplement: [Grafico])
#show figure.where(kind: "snip"): set figure(supplement: [Snippet])
#show figure.where(kind: "script"): set figure(supplement: [Script])
#show figure.where(kind: "fun"): set figure(supplement: [Funzione])
#show figure.where(kind: "cls"): set figure(supplement: [Classe])
#show figure.where(kind: "query"): set figure(supplement: [Query])
#show figure.where(kind: "diag"): set figure(supplement: [Diagramma])
// #show figure.where(kind: "snip"): set block(breakable: true)

#set raw(syntaxes: ("sparql.sublime-syntax", "turtle.sublime-syntax"))

#pagebreak(weak: true, to: "odd")

#include "chapters/1_introduction.typ"

#pagebreak(weak: true, to: "odd")

#include "chapters/2_nlu.typ"

#pagebreak(weak: true, to: "odd")

#include "chapters/3_nlg.typ"

#pagebreak(weak: true, to: "odd")

#include "chapters/4_engi.typ"

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
#show bibliography: set text(size: 0.9em)

#pagebreak(weak: true)

#bibliography("bib.yml", full: false)

// #show: appendix // https://github.com/typst/typst/discussions/4031