= Natural Language Understanding // Spiegazione di cosa si tratta

== Come AIML gestisce la comprensione // Collegamento a come AIML gestisce la comprensione

=== Criticità e limiti di AIML // Spiegazione a passaggi di cosa ho fatto per migliorare la comprensione

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