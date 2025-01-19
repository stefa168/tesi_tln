= Origini e Stato dell'Arte

== Chatbot rule-based

Fin dalle origini dello studio dell'elaborazione del linguaggio naturale, i cosiddetti chatbot _rule-based_ (basati su regole) hanno costituito il primo approccio per simulare un interlocutore con cui gli utenti possano interagire col linguaggio naturale.\
In questi sistemi le risposte del chatbot sono generate sulla base di pattern di input definiti in modo esplicito e di regole o template codificati dall'autore del programma. 
Tutte le componenti del dialogo sono previste e scelte in anticipo, al momento della progettazione.\
Nonostante le moderne tecniche di apprendimento automatico abbiano guadagnato terreno, i chatbot rule-based mantengono un ruolo significativo, soprattutto quando è cruciale avere un controllo totale sulle risposte, mantenendo il flusso logico esplicito e operando in un dominio ristretto.

// Bisogna spiegare anche cosa sono le regole e come funzionano, magari con un esempio

=== Origini
==== ELIZA

Uno dei primi e più noti esempi di chatbot rule-based è ELIZA, sviluppato da Joseph Weizenbaum al MIT nel 1966 @eliza @eliza_history.\
ELIZA simula le risposte di uno psicoterapeuta rogersiano #footnote[Carl Rogers è stato uno psicologo statunitense, noto per gli studi sul counseling e fondatore della "psicoterapia incentrata sulla persona". Questo genere di _terapia centrata sul cliente_ portava a una relazione collaborativa e di fiducia, basata sull'empatia, ritenuta essenziale per poter raggiungere il benessere psicologico @rogers.], basandosi su un semplice algoritmo di riscrittura (rewrite) delle frasi in input.\
L'effetto era sorprendentemente convincente in alcuni casi, poichè ELIZA trasformava abilmente le frasi dell'utente in domande di ritoro, mantenendo un'apparenza di comprensione.

// Esempio conversazione con ELIZA
#quote(block: true)[
  - *Utente*: Mi sento triste.
  - *ELIZA*: Perché ti senti triste?
  - *Utente*: Non so, mi sembra di non avere amici.
  - *ELIZA*: Perché pensi di non avere amici?
]

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