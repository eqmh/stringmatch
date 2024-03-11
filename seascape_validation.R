library(tidyverse)
library(hrbrthemes)
library(viridis)

# # Load seascape color palette used with Matlab and extract RGB values for observed unique seascapes
# For NOAA machines
# palette_dir <- "/Users/enrique.montes/Library/CloudStorage/GoogleDrive-enriquemontes01@gmail.com/My Drive/GDrive/software/matlab/m_map/seascape_cm"
# For personal machine
palette_dir <- "~/Library/CloudStorage/GoogleDrive-enriquemontes01@gmail.com/My Drive/GDrive/software/matlab/m_map/seascape_cm"
palette_file <- list.files(path = palette_dir, pattern = "cmap1.csv", full.names = TRUE)
palette_df <- read.csv(palette_file, header = FALSE)
colnames(palette_df) <- c("r", "g", "b")
unique_seascapes <- sort(unique(na.omit(ctd_meta$X8.day.seascapes)))
subset_palette_df <- palette_df[unique_seascapes, ]

# set RGB values for the plots
r_vals <- round(subset_palette_df$r * 255, 0)
g_vals <- round(subset_palette_df$g * 255, 0)
b_vals <- round(subset_palette_df$b * 255, 0)
custom_pal <- cbind(r_vals, g_vals, b_vals)
custom_pal_hex <- rgb(custom_pal[, 1], custom_pal[, 2], custom_pal[, 3], maxColorValue=255)
# pal_final <- c(custom_pal_hex[3], custom_pal_hex[4], custom_pal_hex[5], )

# filter out rows with NA values in column seascapes
df_filtered <- taxa_meta[complete.cases(taxa_meta$X8.day.seascapes),]

# Convert the 'x' column to character
df_filtered$X8.day.seascapes <- as.character(df_filtered$X8.day.seascapes)

# Variables
# Avg.chl.a..ug.L.
# salinity
# NH4...uM.
# NO3.NO2..uM.
# PO4...uM.
# DO..mg.L.
# temp..degC.

# # Reorder seascape categories in X axis
df_filtered$X8.day.seascapes <- factor(df_filtered$X8.day.seascapes, levels = c("3", "5", "7", "11", "13", "15","21","27"))

# Define custom colors for each level
custom_colors <- c("3" = custom_pal_hex[1], "5" = custom_pal_hex[2], "7" = custom_pal_hex[3],
                   "11" = custom_pal_hex[4], "13" = custom_pal_hex[5], "15" = custom_pal_hex[6],
                   "21" = custom_pal_hex[7], "27" = custom_pal_hex[8])

# Filter out seascape class as desired
df_filtered <- df_filtered[df_filtered$X8.day.seascapes != "5", ]

# Plot
# See https://cran.r-project.org/web/packages/viridis/vignettes/intro-to-viridis.html for color palette options
pp <- df_filtered %>%
  ggplot( aes(x=X8.day.seascapes, y=PO4...uM., fill=X8.day.seascapes)) +
  geom_boxplot() +
  # scale_fill_viridis(option="H", discrete = TRUE, alpha=0.6) +
  scale_fill_manual(values = custom_colors) +
  geom_jitter(color="black", size=0.8, alpha=0.9) +
  labs(x = "Seascape class") +
  # labs(y = expression("[Chl-a] (mg/L)")) +
  # labs(y = expression("Salinity")) +
  # labs(y = expression(paste("Temperature (", degree, "C) at 1 m depth"))) +
  # labs(y = expression("DO (mg/L)")) +
  # labs(y = expression("NO"["x"] ~ mu*"M")) +
  labs(y = expression("PO"["4"]^"3-" ~ mu*"M")) +
  # theme(axis.title.y = element_text(hjust = 1))
  # scale_x_discrete(labels= c("Tropical/Subtropical Upwelling", 
  #                          "Tropical Seas", 
  #                          "Warm, Blooms, High Nuts", 
  #                          "Tropical/Subtropical Transition", 
  #                          "Temperate Transition")) +
  theme_ipsum() +
  theme(
    legend.position="none",
    plot.title = element_text(size=11)
  ) +
  # ggtitle("A boxplot with jitter") +
  # theme(axis.text.x = element_text(angle = 45)) +
  # ylim(15, 28) +  
  theme(axis.text.x = element_text(size = 32),  # Set X-axis label font size
        axis.text.y = element_text(size = 32)) +
  theme(axis.title.x = element_text(size = 18),
        axis.title.y = element_text(size = 18)) +
  theme(legend.text = element_text(size = 32)) 
pp