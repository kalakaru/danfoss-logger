# Erstellt einen leeren Datensatz mit den richtigen Spalten
leere_daten <- data.frame(
  name = character(),
  update_time = character(),
  code = character(),
  value = numeric()
)

# Speichert die leere Tabelle als CSV ab
write.csv(leere_daten, "danfoss-logger.csv", row.names = FALSE)
