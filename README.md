
# Outfit of the Day Recommendation System

A dynamic recommendation system that generates an outfit suggestion based on current weather conditions in London. The project includes web scraping, weather API integration, data processing, and an interactive API to generate outfit recommendations with visual outputs.

---

## Table of Contents
- [Project Overview](#project-overview)
- [Prerequisites and Dependencies](#prerequisites-and-dependencies)
- [Installation and Setup](#installation-and-setup)
- [Project Structure](#project-structure)
- [Usage Instructions](#usage-instructions)
- [Recommendation Logic](#recommendation-logic)
- [Output Description](#output-description)
- [Additional Features (Bonus Implementations)](#additional-features-bonus-implementations)
- [Troubleshooting and FAQs](#troubleshooting-and-faqs)

---

## Project Overview
This system recommends an outfit based on weather conditions retrieved from the Weatherstack API and data from an SQLite database. The output includes a visual collage with:
- Date, temperature, and weather details
- Recommended clothing items for 2 outfit options with annotated images

---

## Prerequisites and Dependencies

### Required Software
- **R (version 4.0 or later)**: Ensure R is installed on your system.
- **SQLite**: Required for database operations.
- **Bash Shell**: To run the pipeline script.

### Required R Packages
Install the following R packages:
```R
install.packages(c("rvest", "httr", "jsonlite", "DBI", "RSQLite", "plumber", "dplyr", "magick"))
```

### System Requirements
- Internet connection for web scraping and API calls.
- Supported on macOS, Linux, and Windows systems with R and SQLite installed.

---

## Installation and Setup

### Clone the Repository
```bash
git clone https://github.com/anushkamantri/ootd-recsys.git
cd ootd-recsys
```

### Setting up the Weatherstack API Key
1. Obtain an API key from [Weatherstack](https://weatherstack.com/).
2. Export the API key as an environment variable:
   ```bash
   export YOUR_ACCESS_KEY=your_api_key_here
   ```

### Ensure Directory Structure
- Create `data/`, `images/`, and `output/` directories:
  ```bash
  mkdir data images output
  ```

---

## Project Structure

### Key Scripts
- **`product_scraping.R`**: Scrapes product data and images.
- **`weatherstack_api.R`**: Fetches current weather data.
- **`etl.R`**: Cleans and processes data into an SQLite database.
- **`ootd_api.R`**: Defines the API endpoints using Plumber.
- **`run_ootd_api.R`**: Runs the API server.
- **`run_pipeline.sh`**: Automates the pipeline for scraping, processing, and API setup.

### Directories
- **`images/`**: Stores product images.
- **`data/`**: Contains intermediate data files (e.g., `weather_data.rds`, `products_raw.csv`).
- **`output/`**: Stores the generated outfit recommendations as an image.
- **`closet.db`**: SQLite database storing product data.

---

## Usage Instructions

### Running the Full Pipeline
To run the entire pipeline:
```bash
./run_pipeline.sh YOUR_ACCESS_KEY
```

### Accessing API Endpoints
1. **Start the API Server**:
   ```bash
   Rscript run_ootd_api.R
   ```
2. **Access Endpoints**:
   - `/ootd`: Generates and returns the outfit collage.
     ```bash
     curl "http://127.0.0.1:8000/ootd" --output ootd_plot.png
     ```
   - `/rawdata`: Retrieves raw product data as JSON.
     ```bash
     curl "http://127.0.0.1:8000/rawdata"
     ```

---

## Recommendation Logic

### Temperature-Based Rules
- **Above 25°C**: Light clothing (e.g., T-shirt, shorts, sandals/slides).
- **15–25°C**: Comfortable clothing (e.g., long sleeves, jeans, sneakers/loafers).
- **Below 15°C**: Warm clothing (e.g., jumper, trousers, outerwear).

### Weather-Specific Accessories
- **Rain**: Adds an umbrella.
- **Sunny**: Adds sunglasses.

---

## Output Description

### Generated Outputs
- **`ootd_plot.png`**: Visual collage containing:
  - Date, temperature, and weather conditions.
  - Recommended clothing items for 2 outfit options with annotated images.

---

## Additional Features (Bonus Implementations)

#### Extra Items in the Closet
- This project includes additional clothing and accessory items beyond the required 25, such as:
  - **Footwear Variety**: Sandals, slides, sneakers, loafers, and boots for diverse outfit recommendations.
  - **Colder Weather Options**: A range of jackets, jumpers, and quarter-zips to suit colder temperatures.

#### Multiple Outfit Suggestions
- **Two Outfit Options**:
  - The API generates two different outfit suggestions for each weather condition.
  - Both options are tailored based on temperature and weather conditions but incorporate randomized selection from the closet for variety.
  - The `/ootd` endpoint produces a collage with these two outfit options displayed sequentially, allowing users to pick their favorite.

---

## Troubleshooting and FAQs

### Common Issues
1. **Missing API Key**:
   - Ensure the `YOUR_ACCESS_KEY` environment variable is set.
2. **Port Conflicts**:
   - If the API server fails to start, check if port `8000` is already in use and clear it for usage. Change the port in `run_ootd_api.R` if needed.
3. **Image Download Errors**:
   - Verify the URLs in the scraped data and ensure they are valid.

---

## Contact Information
For questions or feedback, contact:
- **Name**: Anushka Mantri
- **Email**: amantri.mam2025@london.edu
