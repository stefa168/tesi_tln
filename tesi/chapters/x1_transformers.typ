=== Transformers

Il meccanismo introdotto con le LSTM possiamo considerarlo come un processo in cui il modello impara su quali informazioni durante il passaggio del tempo sia più importante prestare *attenzione*.

L'architettura dei Transformer, introdotta da #cite(<vaswani2023attentionneed>, form: "prose"), parte da questa idea e la porta all'estremo, basandosi solamente su di essa per creare un modello in grado di catturare le dipendenze a lungo termine.
Non utilizzando più reti ricorrenti, l'architettura è composta da diversi encoders e decoders che lavorano in parallelo, e che si scambiano informazioni tramite meccanismi di attenzione.
Questo permette di lavorare su sequenze di dati in parallelo, potenziando l'addestramento e migliorando le prestazioni.

==== Intuizione di base

Il meccanismo di *self-attention* è il cuore dell'architettura dei Transformer.
Questo meccanismo consente al modello di decidere l'importanza di ogni parola #footnote[In questa tesi ci concentreremo prevalentemente sull'utilizzo dei transformer progettati con il fine di creare modelli linguistici.] in una sequenza rispetto alle altre, senza essere limitato dalla loro distanza posizionale.
Ciò permette ai Transformer di identificare e concentrarsi sulle parti più rilevanti dell'input, anche in sequenze molto lunghe.

Tuttavia, questo approccio comporta una complessità computazionale quadratica rispetto alla lunghezza della sequenza, rendendolo costoso in termini di risorse di calcolo e memoria.

Per gestire questa complessità e migliorare le prestazioni, si utilizza una context window per limitare il numero di token considerati in ogni calcolo di attenzione. 
Questo bilancia la capacità del modello di cogliere relazioni rilevanti senza esaurire le risorse disponibili, specialmente nei casi in cui si fa affidamento a dataset di grandi dimensioni.

==== Struttura del Transformer

#figure(
  image("../media/transformers_structure1.png", height: 50%),
  caption: [Architettura di un Transformer come inizialmente ideata @vaswani2023attentionneed.]
)

L'architettura dei Transformer è composta da due parti principali: l'encoder e il decoder.
L'encoder elabora l'input, mentre il decoder #footnote[Spesso è utilizzato nei modelli di traduzione automatica] genera l'output.

Normalmente si utilizza una sequenza di encoder e decoder, con in cima un layer di output composto da una rete neurale fully connected, che sceglie la parola successiva da generare.

Vediamo le componenti più in dettaglio:

- *Positional Encoding*: Poiché i Transformer non processano sequenzialmente i dati, le informazioni sulla posizione delle parole vengono aggiunte tramite codifiche posizionali sinusoidali.
  In questo modo il modello è in grado di differenziare i token basandosi sulla loro posizione relativa nella sequenza.

- *Encoder*: è costituito da una serie di livelli identici, ognuno dei quali comprende un modulo di auto-attenzione multi-head e una rete feedforward.\
  L'auto-attenzione permette di identificare relazioni tra le parole nella sequenza di input, mentre la rete feedforward esegue trasformazioni non lineari per migliorare la rappresentazione dei dati.
  Ogni livello è dotato di dropout per prevenire l'overfitting e di normalizzazione layer-wise per stabilizzare l'addestramento.

- *Decoder*: Simile all'encoder, il decoder utilizza un modulo di auto-attenzione per elaborare il contesto generato in precedenza e un modulo di _cross-attention_ per incorporare le informazioni elaborate dall'encoder.\
  Questo processo consente al modello di generare sequenze di output con un forte legame semantico con l'input originale.

- *Multi-Head Attention*: Questo componente consente al modello di applicare meccanismi di attenzione paralleli su diverse sotto-rappresentazioni dei dati.\
  Gli output di queste _attention head_ vengono combinate e trasformate, migliorando la comprensione del contesto a più livelli.

- Ogni livello del Transformer contiene una _Rete Neurale Feedforward_ composta da due strati completamente connessi e una funzione di attivazione intermedia, solitamente la ReLU #footnote[Rectified Linear Unit]:
  $ "ReLU"(x) = x^+ = max(0,x) = (x + abs(x)) / 2 = cases(
    x "if" x > 0,
    0 "otherwise"
  ) $
  Questa rete aggiunge complessità non lineare al modello.

==== Impatto

Dal loro sviluppo, i Transformer hanno rivoluzionato il panorama dell'AI, portando alla nascita delle LLM.\
Modelli come GPT e BERT hanno dimostrato le loro potenzialità in numerosi compiti, dal completamento del testo alla traduzione automatica, fino alla generazione di contenuti creativi.
Inoltre, i Transformer hanno trovato applicazione in campi come la bioinformatica, la visione artificiale e l'apprendimento multimodale.

Negli ultimi anni, i Transformer sono diventati una tecnologia fondamentale per molti prodotti utilizzati quotidianamente.\
Grandi aziende come Google, OpenAI e Microsoft li hanno integrati nei loro servizi #footnote[Anche se a volte con grossi problemi, si veda l'articolo della BBC scritto da #cite(<bbc_google_fails>, form: "prose"). Naturalmente non mancano anche le sezioni apposite su siti come reddit:\ #link("https://www.reddit.com/r/aifails/").], dai motori di ricerca come Google Search ai sistemi di assistenza virtuale come ChatGPT, Claude e Gemini.

Parallelamente, i Transformer hanno trasformato l'interazione tra utenti e macchine, rendendo più intuitivi e umanizzati i servizi basati sull'intelligenza artificiale.
La capacità di questi modelli di comprendere e generare linguaggio naturale ha migliorato significativamente l'accessibilità tecnologica, consentendo un'interazione più fluida anche per utenti con conoscenze tecniche limitate.

[Aggiungere cenni su Mamba]