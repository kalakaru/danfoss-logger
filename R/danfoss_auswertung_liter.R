# https://gemini.google.com/app/a3f4f059ddcebedb

# danfoss_sel_def -----
danfoss_sel_def <- danfoss_df %>%
  mutate(update_time_rounded = floor_date(update_time, "hour")) %>%
  group_by(name, update_time_rounded, code) %>%
  summarise(value = mean(value, na.rm = TRUE), .groups = "drop") %>%
  tidyr::pivot_wider(names_from = code, values_from = value) %>%
  tidyr::drop_na(temp_current, humidity_value)

# Absolute Luftfeuchtigkeit berechnen (Magnus-Formel) ----

flaeche <- 110
raumhoehe <- 2.5
volumen <- flaeche * raumhoehe

df_calc <- danfoss_sel_def %>%
  mutate(
    # Magnus-Formel
    # Sättigungsdampfdruck (hPa)
    Es = 6.112 * exp((17.67 * temp_current) / (temp_current + 243.5)),
    # Tatsächlicher Dampfdruck (hPa)
    E = Es * (humidity_value / 100),
    # Absolute Luftfeuchtigkeit (g/m³)
    AH_g_m3 = (216.7 * E) / (temp_current + 273.15)
  ) %>%
  group_by(update_time_rounded) %>%
  summarise(
    avg_AH_g_m3 = mean(AH_g_m3, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    total_water_g = volumen * avg_AH_g_m3,        # Gesamtmasse in Gramm
    total_water_liter = total_water_g / 1000      # 1000g = 1 Liter
  ) %>%
  arrange(update_time_rounded)

# ggplot ----

ggplot(df_calc, aes(x = update_time_rounded, y = total_water_liter)) +
  geom_line(color = "#007acc", linewidth = 1) +
  # Eine weiche Trendlinie hinzufügen, um den generellen Verlauf zu sehen
  geom_smooth(method = "loess", color = "darkred", se = FALSE, linetype = "dashed", linewidth = 0.8) +
  labs(
    title = "Gesamtwassermenge in der Wohnungsluft",
    subtitle = paste0("Berechnet für ", volumen, " m³ Volumen (", flaeche, " m² × ", raumhoehe, " m)"),
    x = "Datum / Uhrzeit",
    y = "Wasser in Litern (L)",
    caption = "Daten: Danfoss Logger | Berechnung: Magnus-Formel"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 16),
    plot.subtitle = element_text(color = "gray30"),
    axis.title = element_text(face = "bold"),
    panel.grid.minor = element_blank()
  )


