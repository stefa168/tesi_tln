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
- Il struttura della pagina web sia strutturata in modo semantico
#align(center)[
  #image("media/html-sementics-layout.png", height: 11em)
]
#pause
- Le immagini siano accompagnate da un testo alternativo (```html <img alt="...">```)
#pause
#v(1em)

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
Se non viene fornita un'alternativa testuale contenente delle informazioni utili, l'utente non potrà comprendere appieno il contenuto della pagina!

#pause
Una di quattro immagini non ha una descrizione testuale o ne ha una ma non informativa @WebAIM2024.

== Anche peggio...

#align(center)[
  Se per le immagini possiamo utilizzare sofisticate tecniche di *Computer Vision* per generare automaticamente un testo alternativo, per le rappresentazioni grafiche di dati (grafici, diagrammi, mappe) non è così semplice.
]
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

= Natural Language Understanding

= Retrieval Augmented Generation

= Ingegnerizzazione del sistema

= Conclusioni

#focus-slide[
  Grazie per l'attenzione!\
  Domande?
]
