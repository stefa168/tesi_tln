= Origini e Stato dell'Arte

== Chatbot rule-based

Fin dalle origini dello studio dell'elaborazione del linguaggio naturale, i cosiddetti chatbot _rule-based_ (basati su regole) hanno costituito il primo approccio per simulare un interlocutore con cui gli utenti possano interagire col linguaggio naturale.\
In questi sistemi le risposte del chatbot sono generate sulla base di pattern di input definiti in modo esplicito e di regole o template codificati dall'autore del programma. 
Tutte le possibili ramificazioni delle conversazioni sono previste e scelte in anticipo, al momento della progettazione.\
Nonostante le moderne tecniche di apprendimento automatico abbiano guadagnato terreno, i chatbot rule-based mantengono un ruolo significativo, soprattutto quando è cruciale avere un controllo totale sulle risposte, mantenendo il flusso logico esplicito e operando in un dominio ristretto.

// Bisogna spiegare anche cosa sono le regole e come funzionano, magari con un esempio

=== Origini
==== ELIZA

Uno dei primi e più noti esempi di chatbot rule-based è ELIZA, sviluppato da Joseph Weizenbaum al MIT nel 1966 @eliza @eliza_history.\
ELIZA simulava le risposte di uno psicoterapeuta rogersiano #footnote[Carl Rogers è stato uno psicologo statunitense, noto per gli studi sul counseling e fondatore della "psicoterapia incentrata sulla persona". Questo approccio portava alla costruzione di una relazione collaborativa e di fiducia, basata sull'empatia, ritenuta essenziale per poter raggiungere il benessere psicologico @rogers.], basandosi su un semplice algoritmo di riscrittura (rewrite) delle frasi in input.\
L'effetto era sorprendentemente convincente in alcuni casi, poichè ELIZA trasformava abilmente le frasi dell'utente in domande di ritorno, mantenendo un'apparenza di comprensione.

#let mono(body, font: "JetBrains Mono NL") = {
  text(upper(body), font: font, size: 10pt)
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
      #mono[IL TUO RAGAZZO TI HA FATTA VENIRE QUI.]
    ]
    v(0.25em)
  },
  caption: [Un esempio di conversazione con ELIZA da #cite(<eliza>, form: "prose")], 
  kind: "listing", 
  supplement: [Listato]
) <eliza_example>

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

Ciononostante, ELIZA non era in grado di comprendere il significato delle frasi, ma si limitava a riconoscere e riscrivere parole chiave: un utente che ne è consapevole può potenzialmente "ingannare" il sistema con frasi prive di senso, ottenendo comunque risposte coerenti.

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

== Approcci basati su NLU e Stato dell'Arte
=== Modelli neurali
=== Altri approcci
(regex, expreg, metriche come BertScore)

== Framework e strumenti moderni
=== LangChain e Haystack

https://haystack.deepset.ai/
(https://www.reddit.com/r/LocalLLaMA/comments/1dxj1mo/langchain_bad_i_get_it_what_about_langgraph/)

== Conclusioni e gap da colmare