# plot 1 ----
plot_temp <- danfoss_df %>%
  filter(code == "temp_current")

ggplot(plot_temp, aes(x = update_time, y = value, color = name)) +
  geom_line(linewidth = 1, alpha = 0.8) +
  theme_minimal() +
  labs(
    title = "Temperaturverlauf der Danfoss-Geräte",
    subtitle = "Live abgerufen aus dem privaten GitHub-Repository",
    x = "Zeit",
    y = "Temperatur (°C)",
    color = "Gerät/Raum"
  ) +
  theme(legend.position = "bottom")


# plot 2 ----
# 1. Daten einlesen

# 2. Daten für den Tagesverlauf aufbereiten
df_plot <- raw_daten %>%
  # Nur Luftfeuchtigkeit herausfiltern
  filter(code == "humidity_value") %>%
  mutate(
    # Werte in Prozent umwandeln
    Luftfeuchtigkeit = value / 10,
    # Zeitstempel parsen
    Zeit = ymd_hms(update_time),
    # Die Uhrzeit in eine Dezimalzahl umwandeln (z. B. 14:30 Uhr wird zu 14.5).
    # Das ermöglicht es, alle Messtage als einen einzigen 24h-Zyklus zu überlagern.
    Stunde_dezimal = hour(Zeit) + minute(Zeit) / 60
  )

# 3. ggplot erstellen
ggplot(df_plot, aes(x = Stunde_dezimal, y = Luftfeuchtigkeit, color = name)) +

  # Rohe Messpunkte (sehr transparent, zeigt die Streuung und Spitzen an einzelnen Tagen)
  geom_point(alpha = 0.1, size = 0.5) +

  # Geglättete Trendlinie (zeigt den "typischen" durchschnittlichen Verlauf)
  geom_smooth(method = "loess", span = 0.3, se = FALSE, linewidth = 1.2) +

  # Rote, gestrichelte Referenzlinie bei 60% (Grenze für optimales Klima)
  geom_hline(yintercept = 60, linetype = "dashed", color = "red", alpha = 0.7) +

  # Für jeden Raum ein eigenes kleines Diagramm (Facet) erstellen
  facet_wrap(~ name) +

  # X-Achse lesbar machen (0:00 bis 24:00 Uhr in 4-Stunden-Schritten)
  scale_x_continuous(
    breaks = seq(0, 24, by = 4),
    labels = function(x) paste0(x, ":00")
  ) +

  # Titel und Achsenbeschriftungen
  labs(
    title = "Typischer Tagesverlauf der Luftfeuchtigkeit pro Raum",
    subtitle = "Überlagerung aller Messtage (Rote Linie = 60% Grenze)",
    x = "Uhrzeit",
    y = "Luftfeuchtigkeit (%)"
  ) +

  # Ein aufgeräumtes Design ohne störenden Hintergrund
  theme_minimal() +
  theme(
    legend.position = "none", # Legende unnötig, da die Räume als Titel darüber stehen
    strip.text = element_text(face = "bold", size = 11), # Raum-Titel hervorheben
    panel.grid.minor = element_blank() # Hilfslinien im Hintergrund reduzieren
  )


# plot 3 ----

df_plot <- danfoss_df %>%
  # Nur Luftfeuchtigkeit herausfiltern
  filter(code == "humidity_value") %>%
  mutate(
    # Werte in Prozent umwandeln
    Luftfeuchtigkeit = value / 10,
    # Zeitstempel parsen
    Zeit = ymd_hms(update_time),
    # Nur die volle Stunde extrahieren (Werte von 0 bis 23)
    Stunde = hour(Zeit)
  )

ggplot(df_plot, aes(x = Stunde, y = Luftfeuchtigkeit, fill = name)) +

  # Boxplot pro Stunde zeichnen
  # group = Stunde ist wichtig, damit pro Stunde ein eigener Boxplot entsteht
  geom_boxplot(aes(group = Stunde),
               outlier.alpha = 0.3,  # Ausreisser leicht transparent
               outlier.size = 0.8,   # Ausreisser etwas kleiner
               alpha = 0.7,          # Boxplots leicht transparent für einen weicheren Look
               linewidth = 0.4) +    # Dünnere Linien für die Boxen

  # Rote, gestrichelte Referenzlinie bei 60%
  geom_hline(yintercept = 60, linetype = "dashed", color = "red", linewidth = 0.8, alpha = 0.8) +

  # Für jeden Raum ein eigenes Diagramm (Facet) erstellen
  facet_wrap(~ name) +

  # X-Achse lesbar machen (0:00 bis 24:00 Uhr in 4-Stunden-Schritten)
  scale_x_continuous(
    breaks = seq(0, 24, by = 4),
    labels = function(x) paste0(x, ":00")
  ) +

  # Titel und Achsenbeschriftungen
  labs(
    title = "Feuchtigkeitsschwankungen im Tagesverlauf",
    subtitle = "Boxplots pro Stunde (Rote Linie = 60% Grenze)",
    x = "Uhrzeit",
    y = "Luftfeuchtigkeit (%)"
  ) +

  # Aufgeräumtes Design
  theme_minimal() +
  theme(
    legend.position = "none", # Legende ausblenden, da Räume als Titel stehen
    strip.text = element_text(face = "bold", size = 11), # Raum-Titel hervorheben
    panel.grid.minor = element_blank() # Hilfslinien im Hintergrund reduzieren
  )
# daten ----
summary_table <- danfoss_df %>%
  # Nur Luftfeuchtigkeitswerte behalten
  filter(code == "humidity_value") %>%
  # Nach Raum gruppieren
  group_by(Raum = name) %>%
  # Statistiken berechnen
  summarise(
    Durchschnitt = mean(value, na.rm = TRUE),
    Maximum = max(value, na.rm = TRUE),
    `Zeit über 60%` = (sum(value > 60, na.rm = TRUE) / n()) * 100
  ) %>%
  # Absteigend nach Durchschnittsfeuchtigkeit sortieren (wie in der Tabelle)
  arrange(desc(Durchschnitt)) %>%
  # Alle numerischen Werte für eine saubere Ausgabe auf eine Nachkommastelle runden
  mutate(across(c(Durchschnitt, Maximum, `Zeit über 60%`), ~round(., 1)))

# daten2---

# Weiteres ----
## Wie viele Messwerte > 60% value? (Am Beispiel 'Schrank') ----
df_hum_sel2 <- danfoss_df %>%
  filter(code == "humidity_value") %>%
  filter(name == "Schrank") %>%
  mutate(feucht_kat = ifelse(value <= 60, "ok", "zu_hoch")) %>%
  group_by(feucht_kat) %>%
  summarize(
    anz = n(),
  ) %>%
  ungroup() %>%
  mutate(ant = anz/sum(anz)*100)
