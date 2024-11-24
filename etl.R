library(RSQLite)
library(dplyr)
library(httr)

# Data cleaning
clean_data <- function(products) {
  products_clean <- products %>%
    filter(!is.na(title), 
           !is.na(category), 
           !is.na(image_url)) %>%
    # Remove everything after the "?" to clean the URL
    mutate(image_url = gsub("\\?.*", "", image_url) %>% 
             # Prepend "https:"
             paste0("https:", .))
  
  return(products_clean)
}

save_product_images <- function(products) {
  products %>%
    mutate(extracted_content = gsub(".*/products/([a-zA-Z0-9\\-]+).*", "\\1", image_url),
            extracted_content = gsub("-", "_", extracted_content),  # Replace dashes with underscores
            # Construct the image path
            image_path = paste0("images/", category, "_", extracted_content, ".jpg")) %>%
    rowwise() %>%
    mutate(download = {
      tryCatch({
        # Use httr's GET with User-Agent
        response <- GET(image_url, 
                        user_agent("Mozilla/5.0"))
        
        if (status_code(response) == 200) {
          writeBin(content(response, "raw"), image_path) # Save the image to the file
        } else {
          message("Failed to download image: ", image_url, " - Status code: ", status_code(response))
        }
      }, error = function(e) {
        message("Error downloading image: ", image_url)
      })
    }) %>%
    ungroup()
}

load_into_db <- function(products) {
  # Connect to SQLite database
  conn <- dbConnect(SQLite(), dbname = "closet.db")
  
  # Create table schema using SQL commands
  dbExecute(conn, "
  DROP TABLE IF EXISTS closet;
  ")
  
  dbExecute(conn, "
  CREATE TABLE IF NOT EXISTS closet (
   id INTEGER PRIMARY KEY AUTOINCREMENT,
   name TEXT,
   category TEXT,
   image_path TEXT
  );
  ")
  
  # Write data to database
  dbWriteTable(conn, "closet", 
               products, 
               overwrite = TRUE, 
               row.names = FALSE)
  # Disconnect
  dbDisconnect(conn)
}

# Read raw data 
products <- read.csv("data/products_raw.csv", 
                     stringsAsFactors = FALSE)

if (!dir.exists("images")) {
  dir.create("images")
}

# Clean raw product data
products_clean <- clean_data(products)

# Save product images
save_product_images(products_clean)

# Load clean data into database
load_into_db(products_clean)
