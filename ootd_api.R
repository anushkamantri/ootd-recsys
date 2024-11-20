library(plumber)
library(DBI)
library(RSQLite)
library(jsonlite)

#* @apiTitle Outfit Recommendation API

#* Get Outfit of the Day
#* @get /ootd
get_ootd <- function() {
  # Load weather data
  weather_data <- readRDS("data/weather_data.rds")
  temperature <- weather_data$current$temperature
  weather_desc <- weather_data$current$weather_descriptions
  # Connect to database
  conn <- dbConnect(SQLite(), dbname = "closet.db")
  # Initialize outfit list
  outfit <- list()
  # Apply rules
  if (temperature > 25) {
    # Select light clothing
    outfit$top <- dbGetQuery(conn, 
                             "SELECT * FROM closet 
                             WHERE category = 'tshirts' 
                             LIMIT 1")
    
    outfit$bottom <- dbGetQuery(conn, 
                                "SELECT * FROM closet 
                                WHERE category = 'shorts' 
                                LIMIT 1")
    
    outfit$shoes <- dbGetQuery(conn, 
                               "SELECT * FROM closet 
                               WHERE category = 'sandals' 
                               LIMIT 1")
  } else if (temperature >= 15 && temperature <= 25) {
    # Select comfortable clothing
    outfit$top <- dbGetQuery(conn, 
                             "SELECT * FROM closet 
                             WHERE category = 'longsleeves' 
                             LIMIT 1")
    
    outfit$bottom <- dbGetQuery(conn, 
                                "SELECT * FROM closet 
                                WHERE category = 'jeans' 
                                LIMIT 1")
    
    outfit$shoes <- dbGetQuery(conn, 
                               "SELECT * FROM closet 
                               WHERE category = 'sneakers' 
                               LIMIT 1")
    
  } else {
    # Select warm clothing
    outfit$top <- dbGetQuery(conn, 
                             "SELECT * FROM closet 
                             WHERE category = 'jumpers' 
                             LIMIT 1")
    
    outfit$bottom <- dbGetQuery(conn, 
                                "SELECT * FROM closet 
                                WHERE category = 'trousers' 
                                LIMIT 1")
    
    outfit$outerwear <- dbGetQuery(conn, 
                                "SELECT * FROM closet 
                                WHERE category = 'jackets' 
                                LIMIT 1")
    
    outfit$shoes <- dbGetQuery(conn, 
                               "SELECT * FROM closet 
                               WHERE category = 'boots' 
                               LIMIT 1")
  }
  # Check for rain
  if (grepl("Rain", weather_desc)) {
    outfit$accessory <- dbGetQuery(conn, 
                                   "SELECT * FROM closet 
                                   WHERE category = 'umbrellas' 
                                   LIMIT 1")
  } else if (grepl("Sunny", weather_desc)) {
    outfit$accessory <- dbGetQuery(conn, 
                                   "SELECT * FROM closet 
                                   WHERE category = 'sunglasses' 
                                   LIMIT 1")
  }
  
  print(outfit)
  # Proceed to create the plot with selected items
  plot.new()
  # Example plot code:
  plot.window(xlim=c(0,1), ylim=c(0,1))
  text(0.5, 0.9, paste("Date:", Sys.Date()), cex=1.5)
  text(0.5, 0.8, paste("Weather:", weather_desc), cex=1.2)
  # Add images (this is a placeholder, you need to use functions like rasterImage)
  # Return the plot
}
get_ootd()

#* Get Raw Product Data
#* @get /rawdata
get_raw_product_data <- function() {
  conn <- dbConnect(SQLite(), dbname = "closet.db")
  data <- dbGetQuery(conn, "SELECT * FROM closet")
  dbDisconnect(conn)
  return(toJSON(data))
}

# Disconnect
dbDisconnect(conn)
