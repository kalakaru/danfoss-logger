# Erstellt einen leeren Datensatz mit den richtigen Spalten
leere_daten <- data.frame(
  name = character(),
  code = character(),
  update_time = character(),
  value = numeric()
)

# Speichert die leere Tabelle als CSV ab
write.csv(leere_daten, "data/danfoss-logger.csv", row.names = FALSE)
