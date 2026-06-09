# Pakete laden
library(httr)
library(readr)
library(dplyr)
library(lubridate)
library(ggplot2)

# ==========================================
# 1. Konfiguration
# ==========================================
github_pat <- "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"

# Die saubere Raw-URL OHNE angehängten Token!
raw_url <- "https://raw.githubusercontent.com/kalakaru/danfoss-logger/main/danfoss-logger.csv"

# ==========================================
# 2. Daten abrufen
# ==========================================
response <- GET(
  url = raw_url,
  add_headers(Authorization = paste("Bearer", github_pat))
  # Hinweis: Bei feingranularen PATs ("github_pat_...") ist "Bearer" oft sicherer als "token"
)

stop_for_status(response, task = "GitHub-Download fehlgeschlagen")

# ==========================================
# 3. Einlesen und Tidy-Data Aufbereitung
# ==========================================
# Da das Action-Skript die Daten per 'append' ohne Spaltennamen anfügt,
# definieren wir die Namen hier beim Einlesen.
raw_daten <- read_csv(
  content(response, as = "text", encoding = "UTF-8"),
  show_col_types = FALSE
) %>%
  distinct(name, update_time, code, .keep_all = TRUE) %>%
  # 1. R mitteilen, dass die CSV-Daten in UTC (GitHub-Zeit) vorliegen
  mutate(update_time = ymd_hms(update_time, tz = "UTC")) %>%
  # 2. Die Zeit für die Auswertung in Schweizer Zeit umwandeln
  mutate(update_time = with_tz(update_time, tzone = "Europe/Zurich"))

# ==========================================
# 4. Erster explorativer ggplot
# ==========================================
# Filtern auf nur einen Metric-Typ (z.B. Temperatur)
plot_temp <- raw_daten %>%
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
