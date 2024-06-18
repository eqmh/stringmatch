# # This script moves annotated images from the main data folder (cpics_img) into 
# # corresponding folders in another directoty: diatoms, acantharea, copedos, etc.
# # June 17th 2024
# # Enrique Montes

library(tidyverse)
library(lubridate)

## Load taxa lists and metadata table
# specify the directory where the files are located
dir_path <- "~/Library/CloudStorage/GoogleDrive-enriquemontes01@gmail.com/My Drive/GDrive/OCED_AOML/WS_cruises/plankton_imaging/CPICS/TS.Master_selection"

# obtain a list of file names in the directory
file_names <- list.files(path = dir_path, pattern = ".txt", full.names = TRUE)

# loop over each file and import the tables (use this for DATES)
for (file in file_names) {
  table_name <- gsub(".txt", "", basename(file)) # get the name of the table from the file name
  assign(table_name, read.table(file = file, header = FALSE, sep = "\t") %>%
           mutate(date = as.POSIXct(substr(V1, start = 24, stop = 38), format="%Y%m%d_%H%M%S", tz="UTC")))
}

# List of folder names with files lists
data_frame_names <- ls(pattern = "^class\\.")  # Get all data frames starting with "class."

# Set path to main directory
path_to_files <- "~/Desktop/cpics_img/"
setwd(path_to_files)

# Loop through each data frame
for (df_name in data_frame_names) {
  # Get the data frame using the name
  current_df <- get(df_name)
  
  # Rename filename column if needed
  current_df <- current_df %>% rename(img_file_name = V1)
  
  # Get the data frame name without the "class." prefix
  df_name_without_prefix <- sub("^class\\.", "", df_name)
  
  # Create directory for the current taxa list
  dir.create(df_name_without_prefix)
  
  # Iterate through each row in the data frame
  for (row in 1:nrow(current_df)) {
    filename <- current_df[row, "img_file_name"]
    
    # Construct the full path to the image file in directory
    full_path <- file.path(path_to_files, filename)
    
    # # Copy the image to the 'selected' directory - USE TO SAVE IMAGES LISTED IN TAXA LISTS IN "SELECTED" FOLDER
    selected_path <- file.path(selected_dir, basename(filename))
    file.copy(full_path, selected_path)
  }
}

