#import "@preview/touying:0.6.1": *
#import themes.metropolis: *

#import "@preview/numbly:0.1.0": numbly
#import "@preview/pinit:0.2.2": *

#let lang = "it"
#set text(font: "TeX Gyre Termes", lang: lang, size: 1em, region: lang)

#show raw: it => {
  show regex("pin\d"): it => pin(eval(it.text.slice(3)))
  it
}

#show: metropolis-theme.with(
  aspect-ratio: "16-9",
  // footer: self => self.info.institution,
  footer-progress: true,
  config-info(
    title: [Design, ingegnerizzazione e realizzazione di un sistema di dialogo basato su LLM nel dominio delle tecnologie assistive],
    subtitle: [Tesi di Laurea Magistrale],
    author: [Relatore: Prof. Alessandro Mazzei\ Co-Relatori: Dott. Pier Felice Balestrucci, Dott. Michael Oliverio\ Candidato: Dott. Stefano Vittorio Porta],
    date: "2 Aprile 2025",
    institution: [Università degli Studi di Torino, Dipartimento di Informatica - Anno Accademico 2023/2024],
    logo: image("media/unito.svg", height: 3.99em),
  ),
  // config-common(datetime-format: "[day] [month] [year]")
  config-common(show-bibliography-as-footnote: bibliography("bib.yml")),
  header-right: image("media/unito.svg", height: 1.4em),
)

#set heading(numbering: numbly("{1}.", default: "1.1"))
#show heading: set text(size: 0.95em)

#title-slide()

= Contesto

== Motivazioni

Iniziamo ad ambientarci:

- *Lettura di contenuti testuali*: da 30 anni sono disponibili sistemi di sintesi vocale integrati in smartphone e computer.
#pause
- Essenziali per le persone con *disabilità visive*: consentono di accedere a contenuti testuali in modo autonomo e senza l'ausilio di un lettore umano.

#align(center)[
  #image("media/tts-audio.jpg", height: 8em)
]

---

- Pagine web. I sistemi TTS sono in grado di
  - Leggere il testo
  // #pause
  - Interpretare la struttura del documento
  - Questo permette di seguire il flusso di lettura per fornire un'esperienza di qualità

== Problema!

Tutto funziona, a patto che...
#pause
- La pagina web sia strutturata in modo semantico
#align(center)[
  #image("media/html-sementics-layout.png", height: 10em)
]
#pause
- Le immagini siano accompagnate da un testo alternativo
#align(center)[```html <img alt="...">``` o ```html <img aria-label="...">```]
#pause
// #v(1em)

#align(center)[*Queste due condizioni dipendono da chi prepara il contenuto!*]

---

I sistemi di TTS non sono in grado di interpretare il significato di un'immagine o di un elemento puramente visivo.
#pause
#align(center)[
  #let hq = 7em
  #set image(height: hq)
  #stack(dir: ltr, spacing: 2em)[
    #image("image.png")
  ][
    #image("image-1.png")
  ]
]

#pause
Se non viene fornita un'alternativa testuale contenente delle informazioni utili, l'utente non potrà comprendere appieno il contenuto della pagina o di uno specifico elemento!

#pause
Una di quattro immagini sul web non ha una descrizione testuale o non è informativa @WebAIM2024.

== Anche peggio...

Se per le immagini possiamo utilizzare tecniche di *Computer Vision* o *Reti Neurali* per generare automaticamente un testo alternativo, per le rappresentazioni grafiche di dati (grafici, diagrammi, mappe) non è così semplice.


#pause
#align(center)[
  #let hq = 10em
  #set image(height: hq)
  #stack(dir: ltr, spacing: 2em)[
    #image("image-2.png")
  ][
    #pause
    #image("image-3.png")
  ]
]

== Un aiuto

- Il Progetto NoVAGraphS si propone di rendere più accessibili questi contenuti, mediante la costruzione di sistemi di dialogo (Chatbot).
#pause

- Con essi è possibile interagire per ottenere informazioni sui dati presenti in grafi o strutture simili, per avere una comprensione *profonda* del contenuto.
#pause

- Il Progetto originale fa fondamento su AIML (Artificial Intelligence Markup Language), un linguaggio di markup per la creazione di chatbot.

== Esempi di AIML

#align(center)[
  ```xml
  <category>
    <pattern>CIAO</pattern>
    <template>Ciao! Come posso aiutarti oggi?</template>
  </category>
  ```
]

---

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

---

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

== Limitazioni di AIML

- Le strategie di wildcard e pattern matching restano *prevalentemente letterali*: Se una frase si discosta dal pattern previsto, il sistema fallisce il matching
#pause
- Sono disponibili ridotte funzionalità per la gestione di _sinonimi_, semplificazione delle _locuzioni_ e _correzione ortografica_
#pause
- La *gestione del contesto* (via `<that>`, `<topic>`, `<star>`, ecc.) è rudimentale
#pause
- L'integrazione (via `<sraix>`) con *basi di conoscenza esterne* (KB, database, API) è possibile implementando funzioni personalizzate, ma è di difficile gestione 
#pause
- Le risposte generate sono *statiche e predefinite*, e non possono essere generate dinamicamente in base a dati esterni o a contesti più ampi in modo automatico

== Obiettivi
- Sviluppare un sistema di dialogo che superi le limitazioni di AIML evidenziate
#pause
- Integrare tecniche di *Natural Language Understanding* (NLU) e *Retrieval-Augmented Generation* (RAG) per migliorare l'esperienza d'uso
#pause
- Assicurare una elevata facilità di estensione e personalizzazione per diversi domini e applicazioni

= Natural Language Understanding

== Panoramica

Il primo elemento dello stack di NLP rispetto ad AIML che vogliamo migliorare è il riconoscimento delle intenzioni dell'utente.

#pause
- Non useremo più un sistema basato su pattern matching ed espressioni regolari
- Riconosceremo la categoria di interazione affidandoci ad un classificatore basato su LLM
- Le parti variabili della frase (slot) verranno estratte tramite un sistema di Named Entity Recognition (NER)

== Classificazione

d

= Retrieval Augmented Generation

= Ingegnerizzazione del sistema

= Conclusioni

#focus-slide[
  Grazie per l'attenzione!\
  Domande?
]
