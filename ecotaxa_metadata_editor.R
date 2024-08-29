# Use this script to edit metadata in Ecotaxa .tsv files
# August 19th 2024
# E. Montes (enrique.montes@noaa.gov)

library(readr)

# read table
sample <- "ecotaxa_h24013_2023-10-02T13_09_56.023512_h24013_LK_64um"

path <- paste0("/Users/enrique.montes/Desktop/planktoscope/", sample, "/ecotaxa_export.tsv")
df <- readr::read_tsv(path)

# replace values under a specific column
# This case assigns all values under 'sample_net_gear_opening' to 6000  
# df$sample_gear_net_opening[2:nrow(df)] <- 6000

# This changes 'object_time'
df$object_time[2:nrow(df)] <- "093500"

# write TSV table
write.table(df, file = path, sep = "\t", row.names = FALSE)