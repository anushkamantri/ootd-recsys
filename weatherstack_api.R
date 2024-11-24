library(httr)
library(jsonlite)
library(dplyr)

# Retrieve API key from environment variable
# api_key <- Sys.getenv("YOUR_ACCESS_KEY")
api_key <- '87fd023f6342d04cbd687f9a0dc22c4d'

# Construct API request
response <- GET(
  url = "http://api.weatherstack.com/current",
  query = list(
    access_key = api_key,
    query = "London"
  )
)

# Parse response
weather_data <- content(response, as = "text") %>% 
  fromJSON(flatten = TRUE)

# Extract relevant information
current_temperature <- weather_data$current$temperature
weather_descriptions <- weather_data$current$weather_descriptions

# Save weather data for use in recommendation logic
if (!dir.exists("data")) {
  dir.create("data")
}

saveRDS(weather_data, "data/weather_data.rds")