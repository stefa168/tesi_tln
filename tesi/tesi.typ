#import "styles.typ": template

#let acknowledgments = [ 
  Todo
]

#let abstract = [ 
  Todo.
]

#show: template.with(
  title: "Design, realizzazione e ingegnerizzazione di un sistema di dialogo basato su LLM nel dominio delle tecnologie assistive",

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

  bibliography: bibliography("bib.yml"),

  acknowledgments: acknowledgments,
  abstract: abstract,

  keywords: [
    "classificazionexNLU", 
    "data annotation/augmentation", 
    "NLGBasataSuParafrasi", 
    "ingegnerizzazione"
  ]
)

#include "chapters/1_introduction.typ"
#pagebreak(weak: true)

#include "chapters/2_origin_state_art.typ"
#pagebreak(weak: true)