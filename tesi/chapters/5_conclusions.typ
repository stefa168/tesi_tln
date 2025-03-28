= Conclusioni
== Confronto con AIML

Il sistema sviluppato rappresenta un'evoluzione significativa rispetto al modello AIML tradizionale, introducendo maggiore flessibilità e potenza espressiva. AIML, pur essendo una tecnologia consolidata per la creazione di chatbot, presenta alcune limitazioni strutturali che, come mostrato, il nuovo sistema ha cercato di superare. Le riassiumiamo brevemente:

- Per quanto riguarda il *riconoscimento delle intenzioni* dell'utente, AIML si affida esclusivamente al pattern matching basato su espressioni regolari attraverso tag come `<pattern>` e `<template>`, con tutti i limiti che comportano. Il sistema proposto invece, permette di scegliere quale sistema di classificazione utilizzare, lasciando la possibilità di usare tanto un classificatore neurale quanto un classificatore basato su regole, a seconda delle esigenze del progetto.
- Mentre AIML utilizza il tag `<topic>` per gestire il *contesto della conversazione* in modo piuttosto rigido, il sistema introdotto implementa un meccanismo di `Flow` più articolato, che permette di definire *percorsi di interazione complessi* con maggiore granularità. La statefulness in AIML è gestita attraverso variabili (`<set>` e `<get>`) e predicati limitati, mentre il nuovo sistema offre un contesto di esecuzione completo, manipolabile attraverso espressioni Python valutate a runtime tramite la libreria Asteval.
- Un altro aspetto rilevante è la capacità di *gestire dati variabili o esterni*. AIML prevede l'uso di `<sraix>` per interagire con servizi esterni, ma questa soluzione resta periferica rispetto all'architettura principale del linguaggio. Il nuovo sistema, invece, integra nativamente moduli di retrieval estensibili, rendendo l'interazione con dati esterni un elemento centrale del design.
- La struttura di *controllo del flusso* in AIML è relativamente semplice, basata principalmente su condizioni (`<condition>`) e ricorsione (`<srai>`). Il nostro sistema implementa un meccanismo di controllo del flusso più articolato, con branching condizionale e la possibilità di passare da un flusso all'altro in modo dinamico, permettendo interazioni più sofisticate.

Il paradigma ibrido proposto, che combina un approccio dichiarativo con la flessibilità di Python e la potenza delle reti neurali, si propone di superare le limitazioni strutturali del modello AIML tradizionale, offrendo una soluzione più scalabile e adattabile alle esigenze dei progetti di chatbot più complessi, richiedendo meno sforzo durante la progettazione, lo sviluppo e anche la manutenzione.

Inoltre, la possibilità di decidere in modo minuzioso come la sequenza delle interazioni tra utente e macchina debba svolgersi assicura un controllo totale sul comportamento del chatbot, a differenza dell'utilizzo puro di Large Language Models, che potrebbero soffrire di problemi di explainability @ALI2023101805 @zhao2023explainabilitylargelanguagemodels (essendo trattabili alla pari di delle black-box), allucinazione @xu2025hallucinationinevitableinnatelimitation @Huang_2025 e jailbreaking @xu2024comprehensivestudyjailbreakattack @jiang2024artpromptasciiartbasedjailbreak @peng2024playinglanguagegamellms.

== Sviluppi futuri

Nonostante il sistema sia stato progettato per essere il più flessibile possibile, permettendo l'implementazione di `Step` personalizzati, e astraendo allo stesso tempo le complessità maggiori quali l'utilizzo di modelli di classificazione, vi sono alcune limitazioni che il sistema comunque presenta, e che potranno essere oggetto di futuri sviluppi.

In primo luogo, l'utilizzo di `Asteval` per l'esecuzione di codice Python a runtime è molto potente, ma allo stesso tempo molto pericoloso. La libreria permette di eseguire qualsiasi codice Python fornito, e non fornisce alcun tipo di protezione contro codice dannoso o malevolo, se le keywords sbagliate del linguaggio Python fossero mai abilitate durante lo sviluppo.

Una possibile soluzione potrebbe essere l'utilizzo di un sistema di sandboxing, che permetta di eseguire il codice in un ambiente controllato. Asteval supporta già diversi generi di controlli e limitazioni configurabili, ma in alcuni casi potrebbe essere necessario implementare verifiche più stringenti attualmente non presenti.

Un'interessante _side-project_ potrebbe essere l'implementazione di una utility che permetta di migrare un sistema AIML esistente in un sistema basato su questo framework, convertendo i pattern e le risposte in attesa di un refactoring successivo. Questo permetterebbe di sfruttare le potenzialità del sistema proposto nel momento in cui si intenda aggiungere nuove interazioni, senza dover partire da zero.

Bisogna anche aggiungere come, nonostante il formato YAML per la configurazione sia molto potente, durante lo sviluppo esso sia stato spinto al limite delle sue capacità. Per flow semplici, il formato è molto chiaro e leggibile, ma se si inizia a dover lavorare con espressioni python lunghe o con strutture complesse, il formato può diventare ostico e difficile da mantenere, rendendo problematica anche la comprensione del flusso di esecuzione.

Una possibile soluzione potrebbe essere l'utilizzo di un DSL (Domain Specific Language) che permetta di definire le configurazioni in modo più chiaro e conciso, e che permetta di eseguire controlli di validità in fase di scrittura. Questa opzione è stata considerata durante lo sviluppo, ma è stata scartata per motivi di complessità e ridondanza considerando altre alternative.

Un'opzione più favorevole sarebbe la conversione del sistema in una libreria Python pura, che permetta di definire le configurazioni direttamente in codice Python, sfruttando le capacità di introspezione e validazione del linguaggio. In questo modo sarebbe sufficiente implementare delle funzioni che rappresentano flow e step, abbassando la barriera all'ingresso per nuovi sviluppatori già esperti in Python.

D'altra parte, questa soluzione potrebbe rendere più complesso lo sviluppo per utenti non esperti, motivo per cui comunque il supporto al formato YAML potrebbe dover essere mantenuto.
Bisogna tenere comunque a mente che già la scrittura di chatbot in AIML non richiede conoscenze indifferenti, anche se non si tratta direttamente di programmazione, ma comunque di una forma di scripting che implica la comprensione di concetti come la programmazione logica, la gestione di variabili e la sintassi di XML.
Una migrazione a Python puro renderebbe anche più veloce l'implementazione e, soprattutto, il testing di nuove integrazioni, aumentando la comodità per gli sviluppatori e riducendo il tempo complessivamente necessario per sviluppare nuove funzionalità.

Naturalmente la conversione del sistema in una libreria Python pura potrebbe risolvere anche il problema dell'utilizzo della libreria `ASTEVAL`, lasciando invece la libertà di fare fondamento sulle capacità di introspezione del linguaggio per eseguire controlli di validità sul codice fornito.
Inoltre, la vasta disponibilità di IDE avanzati con sistemi di completamento già largamente diffusi a livello professionale, come _PyCharm_ di JetBrains o _Visual Studio Code_ di Microsoft, permetterebbe di ridurre gli errori di sintassi e di semantica, e di velocizzare lo sviluppo di nuove funzionalità, senza dover implementare nuovi strumenti per la validazione delle configurazioni.

È doveroso anche indicare la necessità di effettuare sperimentazioni complessive dell'intera pipeline, dal momento che durante lo sviluppo sono stati effettuati test solo su singoli componenti, e non su tutto il sistema integrato, come illustrato nella @llm-quality. Questo permetterebbe di valutare l'efficacia del sistema nel suo complesso, e di individuare eventuali problemi di integrazione o di performance che potrebbero emergere solo in fase di test finale.

== Sorgente e tool utilizzati

Tutto il codice, i notebook, la documentazione, l'implementazione del sistema e il sorgente di questa tesi sono disponibili su GitHub all'indirizzo https://github.com/stefa168/tesi_tln

#import "@preview/cades:0.3.0": qr-code

#align(center)[
  #qr-code("https://github.com/stefa168/tesi_tln", width: 3cm)
]

#import "@preview/metalogo:1.2.0": LaTeX

I principali tool utilizzati durante lo sviluppo di questa tesi sono stati:
- Typst (https://typst.com) per la stesura del testo, in alternativa a #LaTeX
- Tinymist (https://github.com/Myriad-Dreamin/tinymist) per l'integrazione Typst in VSC
- Visual Studio Code (https://code.visualstudio.com) come ambiente di scrittura
- IntelliJ IDEA (https://www.jetbrains.com/idea) per lo sviluppo del codice Python
- Jupyter (https://jupyter.org) per la prototipazione e l'analisi dei dati
- PlantUML (https://plantuml.com) per la creazione di diagrammi UML

#let icon_height = 20pt
#align(center)[
  #box(height: icon_height, image("../media/github-mark.svg"))
  #box(height: icon_height, image("../media/typst_logo.jpeg"))
  #box(height: icon_height, image("../media/myriad-dreamin.tinymist-logo.png"))
  #box(height: icon_height, image("../media/Visual_Studio_Code_1.35_icon.svg"))
  #box(height: icon_height, image("../media/IntelliJ_IDEA_Icon.svg"))
  #box(height: icon_height, image("../media/jupyter.svg"))
  #box(height: icon_height, image("../media/Plantuml_Logo.svg"))
]

/* #hrule()

In conclusione a questa tesi, mi auguro che la tecnologia diventi sempre più inclusiva e che le persone con disabilità possano accedere pienamente ai contenuti più disparati, dalla formazione scientifica a quella artistica. Se già ai tempi delle caverne l'uomo imparò a prestare assistenza a chiunque ne avesse bisogno, oggi, con gli strumenti attuali, abbiamo tutte le possibilità di proseguire su quella strada e andare anche oltre, realizzando una società autenticamente aperta e solidale. */
