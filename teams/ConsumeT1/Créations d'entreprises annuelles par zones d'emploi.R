
### Recuperation du nb de creations d'entreprise par commune dans SIREN 35 et 92 via RDF/SPARQL ###

query <-"
PREFIX sx: <https://sireneld.io/vocab/sirext#>
PREFIX sn: <https://sireneld.io/vocab/sirene#>

SELECT ?code_commune (COUNT(?annee_creation) as ?count) ?annee_creation
WHERE {
?uri_etab sx:siret ?siret .
?uri_etab sn:DCRET ?dcret .
?uri_etab sx:commune ?code_commune .
BIND(SUBSTR(?dcret, 1, 4) as ?annee_creation)
}
GROUP BY ?code_commune ?annee_creation
"

# Sauvegarde des r�sultats dans un data frame

qd <- SPARQL(end_siren,query)
df <- qd$results

# Export au format CSV

write.csv(df, file = "crea_emploi_35_92")

### Passage des communes aux zones d'emploi 2010
# Remarque : l'�tape de conversion peut �tre integr�e directement dans la requ�te SPARQL pr�c�dente en appelant la table de conversion 
# commune <-> zone emploi qui existe au format RDF, � l'aide de l'instruction SERVICE.
# Nous n'avons pas pu exploiter cette possibilit� car l'appel � deux endpoints diff�rents ne fonctionnait plus.

# Import des donn�es SIREN

cre_35_92 <- read.csv(file = "crea_emploi_35_92.csv", header = T, stringsAsFactors = F)[,2:4]

# Import et pr�-traitements de la table de conversion commune <-> zone emploi

table_ze_com <- read.csv(file = "ZE2010 au 01-01-2018.csv", header = T, stringsAsFactors = F)[,1:2]
table_ze_com <- table_ze_com[substr(table_ze_com$CODGEO, 1, 2) %in% c("35", "92"),]
table_ze_com$CODGEO <- as.numeric(table_ze_com$CODGEO)

# Conversion

com_to_ze <- function(code_comm) {
  return(table_ze_com$ZE2010[which(table_ze_com$CODGEO == code_comm)])
}

cre_35_92$ze <- sapply(cre_35_92$code_commune, com_to_ze)

# Calcul du nombre de cr�ations d'entreprise annuelles par zone d'emploi

df_agreg_ze <- aggregate(cre_35_92$count, by=list(cre_35_92$ze, cre_35_92$annee_creation), FUN=sum)
df_agreg_ze <- df_agreg_ze[df_agreg_ze$annee != 1900,]
colnames(df_agreg_ze) <- c("ze", "annee", "count")

# Export des donn�es

write.csv(df_agreg_ze, "df_agreg_ze.csv")

