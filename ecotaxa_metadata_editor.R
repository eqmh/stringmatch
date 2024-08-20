# Use this script to edit metadata in Ecotaxa .tsv files
# August 19th 2024
# E. Montes (enrique.montes@noaa.gov)

library(readr)

# read table
path <- "/Users/enrique.montes/Desktop/planktoscope/ecotaxa_ws23011_2023-09-19T05_54_09.156965_ws23011_WS_64um/ecotaxa_export.tsv"
df <- readr::read_tsv(path)

# replace values under a specific column
# This case assigns all values under 'sample_net_gear_opening' to 6000  
df$sample_gear_net_opening[2:nrow(df)] <- 6000

# write TSV table
write.table(df, file = "ecotaxa_export.tsv", sep = "\t", row.names = FALSE)