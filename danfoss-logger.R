# ==========================================
# Vorbereitung & Pakete laden
# ==========================================
# (GitHub Actions installiert diese Pakete vorab durch die .yml Datei)
library(httr)
library(jsonlite)
library(dplyr)
library(tidyr)
library(lubridate)

message("Starte Danfoss Data Logger...")

# ==========================================
# 1. Konfiguration & Credentials (via GitHub Secrets)
# ==========================================
# trimws() entfernt automatisch unsichtbare Leerzeichen, die beim
# Kopieren in die GitHub Secrets versehentlich mitgenommen wurden.
client_id <- trimws(Sys.getenv("DANFOSS_CLIENT_ID"))
client_secret <- trimws(Sys.getenv("DANFOSS_CLIENT_SECRET"))

token_url <- "https://api.danfoss.com/oauth2/token"

# ==========================================
# 2. Access Token abrufen
# ==========================================
message("Rufe Token ab...")
token_response <- POST(
  url = token_url,
  authenticate(client_id, client_secret, type = "basic"),
  body = list(grant_type = "client_credentials"),
  encode = "form"
)

stop_for_status(token_response, task = "Token-Abruf fehlgeschlagen")
token_content <- content(token_response, as = "parsed", type = "application/json")
access_token <- token_content$access_token

# ==========================================
# 3. Daten von Danfoss abrufen
# ==========================================
api_endpoint <- "https://api.danfoss.com/ally/devices"

message("Rufe Sensordaten ab...")
data_response <- GET(
  url = api_endpoint,
  add_headers(
    Authorization = paste("Bearer", access_token),
    Accept = "application/json"
  )
)

stop_for_status(data_response, task = "Daten-Abruf fehlgeschlagen")

danfoss_raw_text <- content(data_response, as = "text", encoding = "UTF-8")
danfoss_data <- fromJSON(danfoss_raw_text, flatten = TRUE)

# ==========================================
# 4. Daten bereinigen (Tidy Format)
# ==========================================
message("Formatiere Daten...")

server_zeit_ms <- danfoss_data$t
server_zeit <- as.POSIXct(server_zeit_ms / 1000, origin="1970-01-01", tz="Europe/Zurich")

raw_df <- danfoss_data$result

tidy_danfoss <- raw_df %>%
  select(name, status) %>%
  # update_time: Wir überschreiben/ergänzen den Zeitstempel mit der aktuellen Server-Zeit
  mutate(update_time = server_zeit) %>%
  unnest(cols = c(status), keep_empty = TRUE) %>%
  # code bereinigen
  filter(!is.na(code)) %>%
  filter(code != "battery_percentage")
  # Reihenfolge der Spalten definieren
  select(name, code, update_time, value)

# ==========================================
# 5. Daten historisieren (In CSV anhängen)
# ==========================================
datei_pfad <- "danfoss-logger.csv"

message("Speichere neue Daten in CSV...")
# write.table mit append = TRUE fügt die neuen Zeilen ohne Spaltennamen (col.names = FALSE) unten an.
write.table(tidy_danfoss, file = datei_pfad, sep = ",", dec = ".",
            append = TRUE, col.names = FALSE, row.names = FALSE)

message("Erfolgreich abgeschlossen!")
