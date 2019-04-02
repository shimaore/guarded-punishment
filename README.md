Remontée des CDRs vers un point commun & expiration des DB journaliéres
-----------------------------------------------------------------------

Ce code est un service qui tourne sur les regclients, et:
- s'assure que les DB de CDR sont répliquées sur un serveur commun
- supprime les DBs expirées qui ont été correctement répliquées
