library(plumber)
library(DBI)
library(RSQLite)
library(jsonlite)
library(magick)

#* @apiTitle Outfit Recommendation API
# Load weather data
weather_data <- readRDS("data/weather_data.rds")
temperature <- weather_data$current$temperature
weather_desc <- weather_data$current$weather_descriptions

#* Get Outfit of the Day
#* @get /ootd
#* @serializer contentType list(type = "image/png")
get_ootd <- function() {
  # Connect to database
  conn <- dbConnect(SQLite(), dbname = "closet.db")
  # Initialize outfit list
  outfit <- list()
  # Apply rules
  if (temperature > 25) {
    # Select light clothing
    outfit$top <- dbGetQuery(conn, 
                             "SELECT * FROM closet 
                             WHERE category = 'Tshirt'
                             ORDER BY RANDOM()
                             LIMIT 1")
    
    outfit$bottom <- dbGetQuery(conn, 
                                "SELECT * FROM closet 
                                WHERE category = 'Shorts' 
                                ORDER BY RANDOM()
                                LIMIT 1")
    
    outfit$shoes <- dbGetQuery(conn, 
                               "SELECT * FROM closet 
                               WHERE category = 'Sandals' OR category = 'Slides'
                               ORDER BY RANDOM()
                               LIMIT 1")
  } else if (temperature >= 15 && temperature <= 25) {
    # Select comfortable clothing
    outfit$top <- dbGetQuery(conn, 
                             "SELECT * FROM closet 
                             WHERE category = 'Longsleeve' OR category = 'Quarterzip' 
                             ORDER BY RANDOM()
                             LIMIT 1")
    
    outfit$bottom <- dbGetQuery(conn, 
                                "SELECT * FROM closet 
                                WHERE category = 'Jeans' 
                                ORDER BY RANDOM()
                                LIMIT 1")
    
    outfit$shoes <- dbGetQuery(conn, 
                               "SELECT * FROM closet 
                               WHERE category = 'Sneakers' OR category = 'Loafers'
                               ORDER BY RANDOM()
                               LIMIT 1")
    
  } else {
    # Select warm clothing
    outfit$top <- dbGetQuery(conn, 
                             "SELECT * FROM closet 
                             WHERE category = 'Jumper' OR category = 'Quarterzip'
                             ORDER BY RANDOM()
                             LIMIT 1")
    
    outfit$bottom <- dbGetQuery(conn, 
                                "SELECT * FROM closet 
                                WHERE category = 'Trousers' 
                                ORDER BY RANDOM()
                                LIMIT 1")
    
    outfit$outerwear <- dbGetQuery(conn, 
                                "SELECT * FROM closet 
                                WHERE category = 'Jacket' 
                                ORDER BY RANDOM()
                                LIMIT 1")
    
    outfit$shoes <- dbGetQuery(conn, 
                               "SELECT * FROM closet 
                               WHERE category = 'Boots' OR category = 'Loafers'
                               ORDER BY RANDOM()
                               LIMIT 1")
  }
  # Check for rain
  if (grepl("Rain", weather_desc)) {
    outfit$accessory <- dbGetQuery(conn, 
                                   "SELECT * FROM closet 
                                   WHERE category = 'Umbrella' 
                                   LIMIT 1")
  } else if (grepl("Sunny", weather_desc)) {
    outfit$accessory <- dbGetQuery(conn, 
                                   "SELECT * FROM closet 
                                   WHERE category = 'Sunglasses' 
                                   ORDER BY RANDOM()
                                   LIMIT 1")
  }
  dbDisconnect(conn)
  canvas <- make_collage(outfit)
  
  # To display png image on swagger
  tmpfile <- tempfile(fileext = ".png")
  image_write(canvas, path = tmpfile, format = "png")
  image_binary <- readBin(tmpfile, "raw", file.info(tmpfile)$size)
  unlink(tmpfile)
  
  return(image_binary)
}


make_collage <- function(outfit) {
  canvas <- image_blank(width = 1000, height = 200, color = "white")
  canvas <- canvas %>%
    image_annotate(text = paste("Today's Date:", Sys.Date()),
                   size = 30,
                   gravity = "northwest",
                   location = "+10+50",
                   color = "#011e62") %>%
    image_annotate(text = paste("Temperature:", temperature, "°C"),
                   size = 30,
                   gravity = "northwest",
                   location = "+10+90",
                   color = "#011e62") %>%
    image_annotate(text = paste("Weather:", weather_desc),
                   size = 30,
                   gravity = "northwest",
                   location = "+10+130",
                   color = "#011e62")

  # Initialize an empty list to store the images
  images <- list()

  # Loop through each item in the outfit
  for (item in outfit) {
    label <- strwrap(item$category, width = 30) %>% 
      paste(collapse = "\n")
    
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
        img <- img %>% 
          image_annotate(text = label,
                         size = 30,
                         gravity = "southeast",
                         color = "#011e62",
                         boxcolor = "white")
        images <- append(images, list(img))
      } else {
        message("Image file does not exist: ", image_path)
      }
    }
  }

  images <- image_join(images)
  # Process the images to ensure consistent size
  processed_images <- image_join(images)
  processed_images <- image_scale(processed_images, "400x400")
  
  # Arrange images based on the number of items
  if (length(images) <= 3) {
    # Single row if 3 or fewer images
    image_grid <- image_append(images, stack = FALSE)
  } else {
    # Two rows if more than 3 images
    row1 <- image_append(images[1:3], stack = FALSE)
    row2 <- image_append(images[4:length(images)], stack = FALSE)
    image_grid <- image_append(c(row1, row2), stack = TRUE)
  }
  
  # Combine the canvas (top text) with the image grid
  canvas <- image_append(c(canvas, image_grid), stack = TRUE)
  
  # Save the collage
  if (!dir.exists("output")) {
    dir.create("output")
  }
  
  # image_write(canvas, "output/outfit_collage.png")
  
  return(canvas)
}

#* Get Raw Product Data
#* @get /rawdata
get_raw_product_data <- function() {
  conn <- dbConnect(SQLite(), dbname = "closet.db")
  data <- dbGetQuery(conn, "SELECT * FROM closet")
  dbDisconnect(conn)
  return(toJSON(data))
}
