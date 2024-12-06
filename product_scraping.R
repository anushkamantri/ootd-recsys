library(rvest)
library(dplyr)
library(purrr)
library(httr)

# Function to fetch the webpage from a given URL
fetch_webpage <- function(url) {
  tryCatch({
    response <- GET(url, user_agent("Mozilla/5.0")) # Send GET request with a user-agent
    webpage <- content(response, as = "text", encoding = "UTF-8") %>%
      read_html() # Parse the HTML content of the response
    return(webpage)
  }, error = function(e) {
    message("Error fetching URL: ", url) # Handle any errors during the request
    return(NULL)
  })
}

# Function to scrape product details from the webpage
scrape_product_details <- function(webpage, category) {
  if (is.null(webpage)) {
    return(data.frame()) # Return an empty data frame if the webpage is invalid
  }
  
  # Extract product titles
  product_titles <- webpage %>%
    html_nodes("p.productDescription_sryaw") %>%
    html_text()
  
  # Extract product image URLs
  product_images <- webpage %>%
    html_nodes(".productTile_U0clN img") %>%
    html_attr("src")
  
  # Ensure titles and images are matched correctly
  product_titles <- product_titles[1:min(length(product_titles), 
                                         length(product_images))]
  
  # Return the scraped data as a data frame
  data.frame(
    category = category,
    title = product_titles,
    image_url = product_images,
    stringsAsFactors = FALSE
  )
}

# Function to scrape and save products for each category-link pair
scrape_and_save_products <- function(category_links) {
  # Initializing an empty data frame to store the product details
  products <- data.frame(
    category = character(),
    title = character(),
    image_url = character(),
    stringsAsFactors = FALSE
  )
  
  # Loop through each category and scrape data
  for (category_name in names(category_links)) {
    url <- category_links[[category_name]] # Get the URL for the category
    message("Scraping category: ", category_name) # Log the category being scraped
    
    # Fetch the webpage for the category
    webpage <- fetch_webpage(url)
    
    # Scrape product details from the webpage
    category_products <- scrape_product_details(webpage, category_name)
    
    # Append the scraped data to the main data frame
    products <- bind_rows(products, category_products)
  }
  
  # Save the combined product data to a CSV file in the data folder
  write.csv(products, "data/products_raw.csv", row.names = FALSE)
}

# Dictionary of category-link pairs (categories mapped to their URLs)
category_links <- c(
  "Tshirt" = "https://www.asos.com/search/?q=short%20sleeve%20t%20shirts&refine=floor:1000",
  "Shorts" = "https://www.asos.com/search/?q=womens+linen+shorts",
  "Sandals" = "https://www.asos.com/search/?q=birkenstock+arizona",
  "Slides" = "https://www.asos.com/search/?q=slides",
  "Longsleeve" = "https://www.asos.com/search/?q=knits&refine=floor:1000",
  "Quarterzip" = "https://www.asos.com/search/?q=quarter%20zip&refine=floor:1000",
  "Jeans" = "https://www.asos.com/women/jeans/cat/?cid=3630&refine=floor:1000",
  "Trousers" = "https://www.asos.com/search/?q=trousers&refine=floor:1000",
  "Sneakers" = "https://www.asos.com/search/?q=trainers",
  "Loafers" = "https://www.asos.com/search/?q=loafers",
  "Jumper" = "https://www.asos.com/women/jumpers-cardigans/cat/?cid=2637",
  "Jacket" = "https://www.asos.com/search/?q=jacket&refine=floor:1000",
  "Boots" = "https://www.asos.com/search/?q=boots&refine=floor:1000",
  "Umbrella" = "https://www.asos.com/search/?q=umbrella&refine=attribute_1047:8274",
  "Sunglasses" = "https://www.asos.com/search/?q=sunglasses"
)

# Execute the scraping and save the data
scrape_and_save_products(category_links)