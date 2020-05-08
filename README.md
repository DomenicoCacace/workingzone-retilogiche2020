# Prova Finale - Progetto di Reti Logiche - A.A. 2019/2020
Scopo del progetto è l'implementazione in linguaggio VHDL di un componente hardware che, dato un indirizzo di memoria a 7 bit, ne produca la sua codifica seguendo una versione semplificata della codifica [Working Zone](https://ieeexplore.ieee.org/document/736129). Ulteriori informazioni a riguardo possono essere trovate nel documento di [specifica](docs/specs.pdf).

## Implementazione
L'[implementazione](src/FSM_source.vhd) consiste nella realizzazione di un automa a stati finiti che risolva il problema; ulteriori informazioni a riguardo possono essere trovate nella [relazione](docs/report.pdf)

## Testing
Il testing dell'automa è stato effettuato su Vivado (ulteriori dettagli su versione e FPGA utilizzata [qui](docs/rules.pdf)); il processo di testing è quasi del tutto automatizzato, tramite il [testbench](src/FSM_testbench.vhd), il [generatore di casi di test](testing/testGenerator.py) ed un piccolo [tool](testing/resultAnalyzer.py) per l'analisi dei risultati ottenuti.
