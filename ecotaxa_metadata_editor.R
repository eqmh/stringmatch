# Use this script to edit metadata in Ecotaxa .tsv files
# August 19th 2024
# E. Montes (enrique.montes@noaa.gov)

library(readr)

# read table
sample <- "ecotaxa_ws23203_2023-09-26T02_15_45.164133_ws23203_LK_64um"

path <- paste0("/Users/enrique.montes/Desktop/planktoscope/", sample, "/ecotaxa_export.tsv")
df <- readr::read_tsv(path)

# replace values under a specific column
# This case assigns all values under 'sample_net_gear_opening' to 6000  
df$sample_gear_net_opening[2:nrow(df)] <- 6000

# write TSV table
write.table(df, file = "ecotaxa_export.tsv", sep = "\t", row.names = FALSE)