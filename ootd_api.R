library(plumber)
library(DBI)
library(RSQLite)
library(jsonlite)
library(magick)

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
  
  return(outfit)
}


make_collage <- function(outfit) {
  canvas <- image_blank(width = 400, height = 400, color = "white")
  canvas <- canvas %>%
    image_annotate(text = paste("Date:", Sys.Date()), 
                   size = 30, 
                   gravity = "northwest", 
                   location = "+10+50", 
                   color = "black") %>%
    image_annotate(text = paste("Weather:", weather_desc), 
                   size = 20, 
                   gravity = "northwest", 
                   location = "+10+120", 
                   color = "black")
  
  # Initialize an empty list to store the images
  images <- list()
  
  # Loop through each item in the outfit
  for (item in outfit) {
    if (!is.null(item$image_url)) {
      # Extract content from the image URL
      extracted_content <- gsub(".*/products/([a-zA-Z0-9\\-]+).*", "\\1", item$image_url)
      extracted_content <- gsub("-", "_", extracted_content)  # Replace dashes with underscores
      
      # Construct the image path
      image_path <- paste0("images/", item$category, "_", extracted_content, ".jpg")
      
      # Read the image if it exists
      if (file.exists(image_path)) {
        img <- image_read(image_path)
        # Append the image to the list
        images <- append(images, list(img))
      } else {
        message("Image file does not exist: ", image_path)
      }
    }
  }
  
  images <- image_join(images)
  # img <- image_scale(img, "300x300")

  # collage <- image_append(img)
  canvas <- image_append(c(canvas, images))
  
  # Save the collage
  if (!dir.exists("output")) {
    dir.create("output")
  }
  image_write(canvas, "output/outfit_collage.png")
  print(canvas)
}


outfit <- get_ootd()
make_collage(outfit)

#* Get Raw Product Data
# * @get /rawdata
get_raw_product_data <- function() {
  conn <- dbConnect(SQLite(), dbname = "closet.db")
  data <- dbGetQuery(conn, "SELECT * FROM closet")
  dbDisconnect(conn)
  return(toJSON(data))
}

# Disconnect
dbDisconnect(conn)
