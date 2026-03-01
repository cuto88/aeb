# Contesto
Questa è una pagina di manuale tecnico di una pompa di calore / centralina.
Obiettivo: estrarre parametri configurabili e I/O della PCB terminal block.

# Vincoli
- Non inventare valori mancanti
- Se un campo è ambiguo, marcarlo come "AMBIGUO"
- Separare sempre:
  - DATI_CERTI
  - IPOTESI
  - DOMANDE_APERTE

# Parametri configurabili (estratti dalla pagina)

- C402 = default 1
  Descrizione: Stato operativo nella condizione di Off.
  0 = Tutte le funzioni/uscite sono in Off ad eccezione della protezione antigelo
  1 = Rimane attiva la sola produzione ACS e la protezione antigelo

- C403 = default 0
  Descrizione: Non utilizzato

- C404 = default 0
  Descrizione: Attivazione del circolatore di rilancio Pump2
  0 = Solo per il sistema radiante
  1 = Sia per il sistema radiante che il SetPoint 2
  2 = Solo per il SetPoint 2

- C405 = default 0 (Off)
  Descrizione: Curva climatica Set Point 2
  0 (Off) = Disattiva
  1 (On) = Attiva

- C406 = default 1
  Descrizione: Non utilizzato

- C407 = default 0
  Descrizione: Acqua Calda Sanitaria
  0 = Prodotta dall’Eco Hot Water
  1 = Prodotta dalla PdC collegata allo scambiatore di un accumulo
  2 = Non disponibile

- C408 = default 0
  Descrizione: Funzionamento del circolatore interno Pump1 con compressore spento per temperatura di target soddisfatta
  0 = Sempre attivo
  1 = Saggi ad intervalli regolari di 15 min
  2 = Saggi ad intervalli calcolati automaticamente

# Specifiche di connessione alla PCB terminal block

- Sonda temperatura esterna
  Rif I/O: Outdoor temp.
  Terminali: A+ / A-
  Elettrico: NTC 10kΩ a 25°C
  Cavo: BUS-SCS

- C420 = default 0
  Descrizione: Non utilizzato
  Terminali: B+ / B-

- C421 = default 0
  Descrizione: Sonda temperatura acqua calda sanitaria
  Rif I/O: 100
  Terminali: C+ / C-
  Elettrico: NTC 10kΩ a 25°C
  Cavo: BUS-SCS

- C422 = default 0
  Descrizione: Termostato ambiente
  Rif I/O: 101
  Terminali: D+ / D-
  Elettrico: Ingresso digitale (contatto pulito)
  Cavo: BUS-SCS

- C423 = default 0
  Descrizione: On/Off da remoto
  Rif I/O: 102
  Terminali: E+ / E-
  Elettrico: Ingresso digitale (contatto pulito)
  Cavo: BUS-SCS

- C424 = default 0
  Descrizione: Limitazione frequenza compressore
  Rif I/O: 103
  Terminali: F+ / F-
  Elettrico: Ingresso digitale (contatto pulito)
  Cavo: BUS-SCS

- C425 = default 0
  Descrizione: Estate / Inverno da remoto
  Rif I/O: 104
  Terminali: G+ / G-
  Elettrico: Ingresso digitale (contatto pulito)
  Cavo: BUS-SCS

- C426 = default 0
  Descrizione: Set point 2
  Rif I/O: 105
  Terminali: H+ / H-
  Elettrico: Ingresso digitale (contatto pulito)
  Cavo: BUS-SCS

- C427 = default 0
  Descrizione: Consenso riscaldatore addizionale
  Rif I/O: 200
  Terminali: R1
  Elettrico: Uscita in tensione 230V max 8A

- C428 = default 0
  Descrizione: Non utilizzato
  Rif I/O: 201
  Terminali: T1

- C429 = default 0
  Descrizione: Consenso all’Eco Hot Water
  Rif I/O: 202
  Terminali: M1 / M2
  Elettrico: Ingresso digitale (contatto pulito)
  Cavo: 1,5 mm²

- C430 = default 0
  Descrizione: Segnalazione PdC in allarme
  Rif I/O: 203
  Terminali: P2
  Elettrico: Uscita in tensione 230V max 2A
  Cavo: 1,5 mm²

- C431 = default 0
  Descrizione: Consenso alla valvola 3-vie ACS
  Rif I/O: 204
  Terminali: W1
  Elettrico: Uscita in tensione 230V max 2A
  Cavo: 1,5 mm²

- C432 = default 0
  Descrizione: Non utilizzato
  Rif I/O: 205
  Terminali: U1

- C433 = default 0
  Descrizione: Non utilizzato
  Rif I/O: 206
  Terminali: X+ / X-

- Pompa di rilancio
  Terminali: P1
  Elettrico: Uscita in tensione 230V max 2A
  Cavo: 1,5 mm²

- RS-485
  Descrizione: Collegamento dell’interfaccia seriale RS-485
  Protocollo: Modbus RTU
  Parametri: Baudrate 9600, Frame 8E1, Address 1, Timeout 1000
  Terminali: - + G
  Cavo: BUS-SCS

# Task
Genera i seguenti output:

1. Una tabella JSON strutturata così:
{
  "config_params": [],
  "io_points": [],
  "sensors": [],
  "outputs": [],
  "bus": []
}

2. Una tabella markdown con:
- codice
- funzione
- tipo segnale
- morsetti
- default
- note operative

3. Una proposta di naming per Home Assistant / Node-RED:
- binary_sensor
- switch
- sensor
- select

4. Un elenco delle sole voci realmente utili per supervisione impianto.

5. Una sezione finale:
- DATI_CERTI
- IPOTESI
- RISCHI_DI_INTEGRAZIONE