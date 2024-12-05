library(plumber)
library(DBI)
library(RSQLite)
library(jsonlite)
library(magick)

#* @apiTitle Outfit Recommendation API

# Load weather data (temperature and weather descriptions)
weather_data <- readRDS("data/weather_data.rds")
temperature <- weather_data$current$temperature
weather_desc <- weather_data$current$weather_descriptions

#* Get Outfit of the Day
#* @get /ootd
#* @serializer contentType list(type = "image/png")
get_ootd <- function() {
  # Connect to SQLite database and initialize outfit list
  conn <- dbConnect(SQLite(), dbname = "closet.db")
  
  # Annotate the blank canvas with the header including the date and weather
  canvas <- make_collage_header()
  
  # For loop to create 2 different outfit options
  for (x in 1:2) {
    outfit <- list()
    # Apply temperature-based outfit selection rules
    if (temperature > 25) {
      # Select light clothing: T-shirt, shorts, sandals/slides
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
                                 LIMIT 1"
      )
    } else if (temperature >= 15 && temperature <= 25) {
      # Select comfortable clothing: long-sleeve, jeans, sneakers/loafers
      outfit$top <- dbGetQuery(conn,
                               "SELECT * FROM closet
                               WHERE category = 'Longsleeve' OR category = 'Quarterzip'
                               ORDER BY RANDOM()
                               LIMIT 1"
      )
      
      outfit$bottom <- dbGetQuery(conn,
                                  "SELECT * FROM closet
                                  WHERE category = 'Jeans'
                                  ORDER BY RANDOM()
                                  LIMIT 1")
      
      outfit$shoes <- dbGetQuery(conn,
                                 "SELECT * FROM closet
                                 WHERE category = 'Sneakers' OR category = 'Loafers'
                                 ORDER BY RANDOM()
                                 LIMIT 1"
      )
      
    } else {
      # Select warm clothing: jumper, trousers, outerwear, boots
      outfit$top <- dbGetQuery(conn,
                               "SELECT * FROM closet
                               WHERE category = 'Jumper' OR category = 'Quarterzip'
                               ORDER BY RANDOM()
                               LIMIT 1"
      )
      
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
                                 LIMIT 1"
      )
    }
    # Add weather-based accessories (umbrella for rain, sunglasses for sun)
    if (grepl("Rain", weather_desc)) {
      outfit$accessory <- dbGetQuery(conn, "SELECT * FROM closet
                                     WHERE category = 'Umbrella'
                                     LIMIT 1")
    } else if (grepl("Sunny", weather_desc)) {
      outfit$accessory <- dbGetQuery(conn,
                                     "SELECT * FROM closet
                                     WHERE category = 'Sunglasses'
                                     ORDER BY RANDOM()
                                     LIMIT 1")
    }
    
    # Create and return the outfit collage
    outfit <- make_collage(outfit, x)
    # Keep appending the resulting outfit collages to the canvas
    canvas <- image_append(c(canvas, outfit), stack = TRUE)
  }
  
  dbDisconnect(conn) # Close database connection
  
  
  # Temporary file to store the image
  tmpfile <- tempfile(fileext = ".png")
  # Save the canvas image to a temporary file in PNG format
  image_write(canvas, path = tmpfile, format = "png")
  # Read the saved image as a raw binary stream for API response
  image_binary <- readBin(tmpfile, "raw", file.info(tmpfile)$size)
  # Remove temporary file
  unlink(tmpfile)
  
  return(image_binary)
}

# Function to create the outfit collage's header, including the date and weather
make_collage_header <- function() {
  # Initialize canvas for top text including today's date, temperature, and weather description
  canvas <- image_blank(width = 1000,
                        height = 200,
                        color = "white") %>%
    image_annotate(
      text = paste("Today's Date:", Sys.Date()),
      size = 30,
      gravity = "northwest",
      location = "+10+50",
      color = "#011e62"
    ) %>%
    image_annotate(
      text = paste("Temperature:", temperature, "°C"),
      size = 30,
      gravity = "northwest",
      location = "+10+90",
      color = "#011e62"
    ) %>%
    image_annotate(
      text = paste("Weather:", weather_desc),
      size = 30,
      gravity = "northwest",
      location = "+10+130",
      color = "#011e62"
    )
  
  return(canvas)
}

# Function to create an outfit collage
make_collage <- function(outfit, option_number) {
  images <- list() # List to store outfit images
  
  # Process each outfit item, overlay text labels, and append to the canvas
  for (item in outfit) {
    # Wrap category text to fit within 30 characters per line
    label <- strwrap(item$category, width = 30) %>% 
      paste(collapse = "\n")
    
    # Check if the item has a valid image URL
    if (!is.null(item$image_url)) {
      # Construct the image file path based on the category and URL
      image_path <- paste0("images/",
                           item$category,
                           "_",
                           gsub(
                             "-",
                             "_",
                             gsub(
                               ".*/products/([a-zA-Z0-9\\-]+).*",
                               "\\1",
                               item$image_url
                             )
                           ),
                           ".jpg")
      
      # Check if the image file exists locally
      if (file.exists(image_path)) {
        # Read the image and annotate it with the category label
        img <- image_read(image_path) %>%
          image_annotate(
            text = label,
            size = 30,
            gravity = "southeast",
            color = "#011e62",
            boxcolor = "white"
          )
        
        # Add the annotated image to the images list
        images <- append(images, list(img))
      }
    }
  }
  
  # Process the images to ensure consistent size
  images <- image_join(images)
  processed_images <- image_join(images)
  processed_images <- image_scale(processed_images, "400x400")
  
  # Arrange images dynamically based on the number of items
  if (length(images) <= 3) {
    # Arrange in a single row if 3 or fewer images
    image_grid <- image_append(images, stack = FALSE)
  } else {
    # Split into two rows if more than 3 images
    row1 <- image_append(images[1:3], stack = FALSE)
    row2 <- image_append(images[4:length(images)], stack = FALSE)
    
    # Stack the two rows vertically
    image_grid <- image_append(c(row1, row2), stack = TRUE)
  }
  
  
  # Combine text canvas and image grid
  canvas <- image_blank(width = 1000,
                        height = 200,
                        color = "white") %>% 
    # Annotate with the outfit option number (1 or 2)
    image_annotate(
      text = paste("Outfit Option", option_number),
      size = 30,
      gravity = "northwest",
      location = "+10+15",
      color = "#011e62"
    )
  
  # Joining the outfit collage to the annotated blank canvas
  canvas <- image_append(c(canvas, image_grid), stack = TRUE)
  return(canvas)
}

#* Get Raw Product Data
#* @get /rawdata
get_raw_product_data <- function() {
  # Connect to database, retrieve all product data, and return as JSON
  conn <- dbConnect(SQLite(), dbname = "closet.db")
  data <- dbGetQuery(conn, "SELECT * FROM closet")
  dbDisconnect(conn)
  return(toJSON(data))
}
