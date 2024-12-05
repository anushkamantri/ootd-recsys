library(httr)
library(jsonlite)
library(dplyr)
# api_key <- '87fd023f6342d04cbd687f9a0dc22c4d'

# Retrieve API key from environment variable
api_key <- Sys.getenv("YOUR_ACCESS_KEY")

# Make a GET request to the Weatherstack API for current weather in London
response <- GET(url = "http://api.weatherstack.com/current",
                query = list(access_key = api_key, query = "London"))

# Parse the API response to extract weather data
weather_data <- content(response, as = "text") %>%
  fromJSON(flatten = TRUE)

# Extract temperature and weather description
current_temperature <- weather_data$current$temperature
weather_descriptions <- weather_data$current$weather_descriptions

# Save the weather data locally in the data folder for later use
if (!dir.exists("data")) {
  dir.create("data")
}
saveRDS(weather_data, "data/weather_data.rds")