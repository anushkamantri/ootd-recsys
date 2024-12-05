library(RSQLite)
library(dplyr)
library(httr)

# Function to clean product data
clean_data <- function(products) {
  products_clean <- products %>%
    filter(!is.na(title), !is.na(category), !is.na(image_url)) %>% # Remove rows with missing values
    # Clean and standardize image URLs
    mutate(image_url = gsub("\\?.*", "", image_url) %>% # Remove query parameters
             paste0("https:", .)) # Prepend "https:" to make URLs valid
  
  return(products_clean)
}

# Function to download and save product images
save_product_images <- function(products) {
  products %>%
    mutate(
      extracted_content = gsub(".*/products/([a-zA-Z0-9\\-]+).*", "\\1", image_url),
      extracted_content = gsub("-", "_", extracted_content),
      # Replace dashes with underscores
      # Construct file paths for images
      image_path = paste0("images/", category, "_", extracted_content, ".jpg")
    ) %>%
    rowwise() %>%
    mutate(download = {
      tryCatch({
        # Download image using GET request with User-Agent
        response <- GET(image_url, user_agent("Mozilla/5.0"))
        
        if (status_code(response) == 200) {
          writeBin(content(response, "raw"), image_path) # Save image to file
        } else {
          # Log a message if the image download fails due to a non-200 status code
          message(
            "Failed to download image: ",
            image_url,
            " - Status code: ",
            status_code(response)
          )
        }
      }, error = function(e) {
        # Log a message if there is an error during the image download process
        message("Error downloading image: ", image_url)
      })
    }) %>%
    ungroup()
}

# Function to load product data into an SQLite database
load_into_db <- function(products) {
  # Connect to SQLite database
  conn <- dbConnect(SQLite(), dbname = "closet.db")
  
  # Create table schema in SQLite
  dbExecute(conn, "DROP TABLE IF EXISTS closet;") # Drop existing table if it exists
  # Create closet table with product name, category, and image url
  dbExecute(
    conn,
    "
  CREATE TABLE IF NOT EXISTS closet (
   id INTEGER PRIMARY KEY AUTOINCREMENT,
   name TEXT,
   category TEXT,
   image_path TEXT
  );
  "
  )
  
  # Insert clean product data into the database
  dbWriteTable(conn,
               "closet",
               products,
               overwrite = TRUE,
               row.names = FALSE)
  
  # Disconnect from the database
  dbDisconnect(conn)
}

# Read raw data from CSV file
products <- read.csv("data/products_raw.csv", stringsAsFactors = FALSE)

# Create images directory if it doesn't exist
if (!dir.exists("images")) {
  dir.create("images")
}

# Clean raw product data
products_clean <- clean_data(products)

# Download and save product images
save_product_images(products_clean)

# Load cleaned data into the SQLite database
load_into_db(products_clean)
