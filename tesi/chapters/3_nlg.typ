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
        Calcolare l'agreement tra valutatori
*/

== Generazione di risposte tramite LLM

=== Parafrasi

=== Prompting

== Data Retrieval // Spiegazione di cosa è il data retrieval

=== Retrieval tramite query // Knowledgebase, basi di dati, ecc.
=== Retrieval basato su script
=== Retrieval automatico guidato dagli LLM

== Qualità delle risposte

=== Valutazione automatica

=== Valutazione umana

// - Qualità delle risposte valutate da persone (questionario):
//   - Tassonomia Dusek (https://d2t-llm.github.io/) per la valutazione