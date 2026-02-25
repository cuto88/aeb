# STEP8 Hardening Plan (2026-02-25)

Date: 2026-02-25  
Scope: piano operativo post-hardening iniziale.

## Obiettivo
Consolidare la qualita` repo/runtime riducendo artefatti non necessari e aumentando la robustezza dei gate.

## Backlog prioritizzato
1. Anti-artefatti estesi (P1)
   - Estendere i gate per intercettare anche:
     - `**/__pycache__/**`
     - eventuali `*.map` / `*.gz` non richiesti dal runtime
   - Criterio di uscita: gate rosso su nuovi artefatti non consentiti.

2. Policy vendor assets (P1)
   - Definire lista esplicita di asset consentiti in repo (`www/community`, frontend HACS, ecc.).
   - Criterio di uscita: policy documentata + check automatico.

3. Gate severity model (P2)
   - Formalizzare quali warning restano warning e quali diventano blocker.
   - Criterio di uscita: matrice severita` in docs + comportamento identico locale/CI.

4. Retention evidence locale (P2)
   - Script di pruning per `docs/runtime_evidence/` e `_ha_runtime_backups/`.
   - Criterio di uscita: retention automatica per data/tag, senza perdita evidenze critiche.

5. Audit continuity (P3)
   - Aggiornare `DELTA_AUDIT_STATUS` a fine ogni ciclo deploy.
   - Criterio di uscita: timeline audit continua senza gap.

## Sequenza consigliata (7 giorni)
1. Giorno 1-2: definizione policy asset consentiti e blacklist artefatti.
2. Giorno 3: implementazione gate anti-artefatti estesi.
3. Giorno 4: dry-run sui branch principali e fix falsi positivi.
4. Giorno 5: attivazione enforcement su CI.
5. Giorno 6-7: retention evidence + consolidamento documentale.

## Rischi e mitigazioni
- Rischio: falsi positivi sui file runtime necessari.
  - Mitigazione: allowlist esplicita per path/file richiesti a deploy/runtime.
- Rischio: aumento attrito sviluppo.
  - Mitigazione: messaggi gate chiari con remediation immediata.
