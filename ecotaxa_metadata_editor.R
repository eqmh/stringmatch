# R Script to batch process zipped plankton data folders.
# Use this script to edit metadata in Ecotaxa .tsv files
# August 19th 2024
# E. Montes (enrique.montes@noaa.gov)

library(readr)
library(dplyr)

# Specify the directory containing the compressed folders
# dir_path <- "/Users/enrique.montes/Desktop/planktoscope"
dir_path <- "/Users/enrique.montes/Desktop/test"

# Get a list of all `.zip` files in the directory
zip_files <- list.files(path = dir_path, pattern = "\\.zip$", full.names = TRUE)

# Create a temporary directory to store extracted .tsv files
extracted_tsv_dir <- tempfile()
dir.create(extracted_tsv_dir)

# Loop through each `.zip` file
for (zip_file in zip_files) {
  
  # Print the name of the zip file being processed
  print(paste("Processing:", zip_file))
  
  # Unzip the file into a temporary directory
  temp_dir <- tempfile()
  dir.create(temp_dir)
  unzip(zip_file, exdir = temp_dir)
  
  # Find the `.tsv` file in the unzipped folder (case-insensitive, recursive)
  tsv_file <- list.files(temp_dir, pattern = "\\.tsv$", full.names = TRUE, recursive = TRUE, ignore.case = TRUE)
  tsv_file <- tsv_file[!grepl("__MACOSX", tsv_file)]  # Exclude macOS metadata
  
  # Debug: Print the found .tsv files
  print(".tsv file found")
  
  if (length(tsv_file) == 1) {
    # Read the `.tsv` file
    df <- readr::read_tsv(tsv_file, show_col_types = FALSE)
    
    # Modify the 'sample_gear_net_opening' column
    df$sample_gear_net_opening[2:nrow(df)] <- 600
    
    # Write the modified `.tsv` file back
    write.table(df, file = tsv_file, sep = "\t", row.names = FALSE)
    
    # Generate a new file name for the extracted .tsv file
    zip_file_name <- tools::file_path_sans_ext(basename(zip_file))  # Get the zip file name without extension
    new_tsv_name <- file.path(extracted_tsv_dir, paste0("ecotaxa_export_", zip_file_name, ".tsv"))
    
    # Copy the modified .tsv file to the extracted_tsv_dir with the new name
    success <- file.copy(tsv_file, new_tsv_name)
    
    # Debug: Check if the file was successfully copied
    if (success) {
      print("Copied .tsv file to directory")
    } else {
      print("Failed to copy .tsv file")
    }
    
  } else {
    warning("No .tsv file found in zip file")
  }
  
  # Compress the folder back into a `.zip` file
  new_zip_file <- file.path(dir_path, basename(zip_file))
  old_wd <- getwd()
  setwd(temp_dir)
  
  # List files to include in the zip archive, excluding macOS metadata
  files_to_zip <- list.files(temp_dir, recursive = TRUE)
  files_to_zip <- files_to_zip[!grepl("__MACOSX|\\._", files_to_zip)]  # Exclude macOS metadata
  
  # Use the zip command to compress the folder and suppress output
  zip_command <- sprintf("zip -r %s %s > /dev/null 2>&1", shQuote(new_zip_file), ".")
  system(zip_command)
  
  # Return to main directory
  setwd(old_wd)
  
  # Clean up the temporary directory
  unlink(temp_dir, recursive = TRUE)
}

# Debug: Check the contents of the extracted_tsv_dir
files_in_dir <- list.files(extracted_tsv_dir, full.names = TRUE)
print("Contents of extracted_tsv_dir:")
print(paste("Number of files in extracted_tsv_dir:", length(files_in_dir)))

# Create a new zip file containing all the extracted .tsv files
output_zip <- file.path(dir_path, "extracted_tsv_files.zip")
old_wd <- getwd()
setwd(extracted_tsv_dir)

# Get the list of files (relative paths) in the extracted_tsv_dir
files_to_zip <- list.files()

# Debug: Check the files to be zipped
print("Files to be zipped:")
print(files_to_zip)

# Use the zip command to create the zip file
if (length(files_to_zip) > 0) {
  zip(output_zip, files = files_to_zip)
  print(paste("Created zip file with extracted .tsv files:", output_zip))
} else {
  print("No .tsv files found to zip.")
}

setwd(old_wd)

# Clean up the temporary directory for extracted .tsv files
unlink(extracted_tsv_dir, recursive = TRUE)

print("Processing complete!")

# # #########################################################################################
# # #########################################################################################

# Use this section for making changes to the tsv table of a selected folder.
# read table
# sample <- "ecotaxa_ws23203_2023-09-26T04_09_49.641649_ws23203_LK_64um"
# 
# path <- paste0("/Users/enrique.montes/Desktop/planktoscope/", sample, "/ecotaxa_export.tsv")
# df <- readr::read_tsv(path)
# print(df$object_time[2])
# 
# # replace values under a specific column
# # This case assigns all values under 'sample_net_gear_opening' to 600  
# df$sample_gear_net_opening[2:nrow(df)] <- 600
# 
# # This changes 'object_time'
# # df$object_time[2:nrow(df)] <- "070000"
# 
# # write TSV table
# write.table(df, file = path, sep = "\t", row.names = FALSE)