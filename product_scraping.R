library(rvest)
library(dplyr)
library(purrr)
library(httr)

# Function to fetch the webpage
fetch_webpage <- function(url) {
  tryCatch({
    response <- GET(url, user_agent("Mozilla/5.0"))
    webpage <- content(response, as = "text", encoding = "UTF-8") %>%
      read_html()
    return(webpage)
  }, error = function(e) {
    message("Error fetching URL: ", url)
    return(NULL)
  })
}

# Function to scrape product details
scrape_product_details <- function(webpage, category) {
  if (is.null(webpage)) {
    return(data.frame())
  }
  
  # Extract product titles
  product_titles <- webpage %>%
    html_nodes("p.productDescription_sryaw") %>%
    html_text()
  
  # Extract product image URLs 
  product_images <- webpage %>%
    html_nodes(".productTile_U0clN img") %>%
    html_attr("src") 
  
  # Ensure lengths match for consistency
  product_titles <- product_titles[1:min(length(product_titles), 
                                         length(product_images))]
  
  # Return the scraped data
  data.frame(
    category = category,
    title = product_titles,
    image_url = product_images,
    stringsAsFactors = FALSE
  )
}

# Main loop to process each category-link pair
scrape_and_save_products <- function(category_links) {
  products <- data.frame(
    category = character(),
    title = character(),
    image_url = character(),
    stringsAsFactors = FALSE
  )
  
  for (category_name in names(category_links)) {
    url <- category_links[[category_name]]
    message("Scraping category: ", category_name)
    
    # Fetch webpage
    webpage <- fetch_webpage(url)
    
    # Scrape product details
    category_products <- scrape_product_details(webpage, category_name)
    
    # Append to the main data frame
    products <- bind_rows(products, category_products)
  }
  
  write.csv(products, "data/products_raw.csv", row.names = FALSE)
}

# Dictionary of category-link pairs
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

scrape_and_save_products(category_links)