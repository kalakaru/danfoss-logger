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
client_id <- Sys.getenv("DANFOSS_CLIENT_ID")
client_secret <- Sys.getenv("DANFOSS_CLIENT_SECRET")
#token_url <- "https://api.danfoss.com/oauth2/token"
token_url <- "https://e2e.api.danfoss.com/oauth2/token"


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
# (Passe diese URL an, falls du einen anderen Endpunkt nutzt)
#api_endpoint <- "https://api.danfoss.com/ally/devices"
api_endpoint <-  "https://e2e.api.danfoss.com/ally/devices"

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
raw_df <- danfoss_data$result

tidy_danfoss <- raw_df %>%
  select(name, update_time, status) %>%
  # Zeitstempel in Schweizer Zeit umwandeln
  mutate(update_time = as_datetime(update_time, tz = "Europe/Zurich")) %>%
  # Status-Spalte entpacken
  unnest(cols = c(status), keep_empty = TRUE) %>%
  # Leere Sensoren herausfiltern
  filter(!is.na(code))

# ==========================================
# 5. Daten historisieren (In CSV anhängen)
# ==========================================
datei_pfad <- "danfoss-logger.csv"

message("Speichere neue Daten in CSV...")
# Wir gehen davon aus, dass die Datei existiert, da wir sie initial hochgeladen haben.
# write.table mit append = TRUE fügt die neuen Zeilen ohne Spaltennamen (col.names = FALSE) unten an.
write.table(tidy_danfoss, file = datei_pfad, sep = ",", dec = ".",
            append = TRUE, col.names = FALSE, row.names = FALSE)

message("Erfolgreich abgeschlossen!")
