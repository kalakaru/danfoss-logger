# boxplot_df
boxplot_df <- danfoss_df %>%
  filter(code == "humidity_value") %>%
  mutate(
    Stunde = hour(ymd_hms(update_time))
  )

# check_df ----
check_df <- boxplot_df %>%
  group_by(name, Stunde) %>%
  summarise(
    Anzahl = n(),
    Mean = mean(value, na.rm=TRUE),
    Q10 = quantile(value, 0.1, na.rm = TRUE),
    Q25 = quantile(value, 0.25, na.rm = TRUE),
    Q50 = quantile(value, 0.5, na.rm=TRUE),
    Q75 = quantile(value, 0.75, na.rm=TRUE),
    Q90 = quantile(value, 0.9, na.rm=TRUE),
    .groups = "drop" # Gruppierung nach der Zusammenfassung sauber auflösen
  ) %>%
  mutate(
    # Farbe für das ggplot-Label definieren: Rot, wenn der Durchschnitt > 60% ist
    text_color = ifelse(Q50 > 60, "red", "black")
  )
write.table(check_df, paste0(path_out, "check_df.csv"), row.names=FALSE, sep = ",", fileEncoding ="UTF-8")

# calc_stat ----
calc_stat <- function(x) {
  n <- sum(!is.na(x))
  stats <- quantile(x, probs = c(0.1, 0.25, 0.5, 0.75, 0.9), na.rm = TRUE)
  names(stats) <- c("ymin", "lower", "middle", "upper", "ymax")
  return(stats)
}

# ggplot ----
ggplot(boxplot_df, aes(x = Stunde, y = value)) +

  # A. Boxplots mit benutzerdefinierten Grenzen (10% bis 90%)
  stat_summary(
    aes(group = Stunde),
    fun.data = calc_stat,
    geom = "boxplot",
    fill = "grey70",
    color = "grey40",
    alpha = 0.7,
    linewidth = 0.4,
    width = 0.7
  ) +

  # B. Uhrzeit-Labels über den Boxplots (Daten aus check_df)
  geom_text(
    data = check_df,
    aes(
      x = Stunde,
      y = Q90 + 2.5,       # Y-Position leicht über dem 90. Perzentil
      label = Stunde,
      color = text_color   # Farbe aus check_df anwenden
    ),
    size = 2.8,
    vjust = 0
  ) +
  # Aktiviert die tatsächlichen Farben ("red", "black") aus der Spalte text_color
  scale_color_identity() +

  # C. Rote, gestrichelte Referenzlinie bei 60%
  geom_hline(yintercept = 60, linetype = "solid", color = "red", linewidth = 0.8, alpha = 0.2) +

  # D. Für jeden Raum ein eigenes Diagramm (Facet) erstellen
  facet_wrap(~ name) +

  # E. Skalen anpassen
  scale_x_continuous(breaks = seq(0, 23, by = 1)) +
  scale_y_continuous(
    breaks = seq(0, 100, by = 10),      # 10er Schritte beschriftet
    minor_breaks = seq(0, 100, by = 5), # 5er Schritte als Hilfslinien
    expand = expansion(mult = c(0.05, 0.15)) # Oben mehr Platz für die Labels lassen
  ) +

  # F. Titel und Achsenbeschriftungen
  labs(
    title = "Feuchtigkeitsschwankungen im Tagesverlauf",
    subtitle = "Boxplots pro Stunde: Whiskers = 10% & 90%, Box = 25% & 75%, Median =  50%\nVerteilung: 1/4 der Daten in oberer/unterer Box, Whiskers beinhalten je 15% der Daten\nRote Linie = 60%, Rote Uhrzeit = Stunden-Durchschnitt > 60%",    x = "",
    y = "Luftfeuchtigkeit (%)"
  ) +

  # G. Aufgeräumtes Design (Theme)
  theme_minimal() +
  theme(
    legend.position = "none",
    strip.text = element_text(face = "bold", size = 11),

    # X-Achse unten: Beschriftungen und Ticks komplett ausblenden
    axis.text.x = element_blank(),
    axis.ticks.x = element_blank(),

    # X-Achse Rasterlinien: komplett ausblenden (vermeidet Kreuzungen mit Y-Hilfslinien)
    panel.grid.major.x = element_blank(),
    panel.grid.minor.x = element_blank(),

    # Y-Achse Rasterlinien: 10er-Schritte durchgezogen, 5er-Schritte gestrichelt
    panel.grid.major.y = element_line(color = "grey65", linewidth = 0.3, linetype = "solid"),
    panel.grid.minor.y = element_line(color = "grey65", linewidth = 0.3, linetype = "dashed")
  )
