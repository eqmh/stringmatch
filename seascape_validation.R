library(tidyverse)
library(hrbrthemes)
library(viridis)

# # Read data table
dir_path <- "~/Library/CloudStorage/GoogleDrive-enriquemontes01@gmail.com/My Drive/GDrive/OCED_AOML/WS_cruises/plankton_imaging/CPICS/ws_cruise_ctd"
file_name <- list.files(path = dir_path, pattern = "AOML_SFP_regional_WQ_surface_w_sscp.csv", full.names = TRUE)
sfp_df <- read.csv(file_name, fill = TRUE)

# # Load seascape color palette used with Matlab and extract RGB values for observed unique seascapes
# For NOAA machines
# palette_dir <- "/Users/enrique.montes/Library/CloudStorage/GoogleDrive-enriquemontes01@gmail.com/My Drive/GDrive/software/matlab/m_map/seascape_cm"
# For personal machine
palette_dir <- "~/Library/CloudStorage/GoogleDrive-enriquemontes01@gmail.com/My Drive/GDrive/software/matlab/m_map/seascape_cm"
palette_file <- list.files(path = palette_dir, pattern = "cmap1.csv", full.names = TRUE)
palette_df <- read.csv(palette_file, header = FALSE)
colnames(palette_df) <- c("r", "g", "b")
unique_seascapes <- sort(unique(na.omit(sfp_df$seascape_week)))
subset_palette_df <- palette_df[unique_seascapes, ]

# set RGB values for the plots
r_vals <- round(subset_palette_df$r * 255, 0)
g_vals <- round(subset_palette_df$g * 255, 0)
b_vals <- round(subset_palette_df$b * 255, 0)
custom_pal <- cbind(r_vals, g_vals, b_vals)
custom_pal_hex <- rgb(custom_pal[, 1], custom_pal[, 2], custom_pal[, 3], maxColorValue=255)

# filter out rows with NA values in column seascapes
df_filtered <- sfp_df[complete.cases(sfp_df$seascape_week),]

# Convert the 'x' column to character
df_filtered$seascape_week <- as.character(df_filtered$seascape_week)

# # Reorder seascape categories in X axis
df_filtered$seascape_week <- factor(df_filtered$seascape_week, levels = c("3", "7", "11", "13", "15", "17", "18", "21","27"))

# Define custom colors for each level
custom_colors <- c("3" = custom_pal_hex[1], "5" = custom_pal_hex[2], "7" = custom_pal_hex[3],
                   "11" = custom_pal_hex[4], "13" = custom_pal_hex[5], "15" = custom_pal_hex[6],
                   "17" = custom_pal_hex[7], "18" = custom_pal_hex[8], "21" = custom_pal_hex[9], 
                   "27" = custom_pal_hex[10])

# Filter out seascape class as desired
seascapes_to_exclude <- c("5", "17", "18")
df_filtered <- df_filtered[!(df_filtered$seascape_week %in% seascapes_to_exclude), ]
df_filtered <- df_filtered[complete.cases(df_filtered$seascape_week),]
df_filtered <- df_filtered[grepl("^\\d+\\.?\\d*$", df_filtered$chla), , drop = FALSE]

# Plot
# See https://cran.r-project.org/web/packages/viridis/vignettes/intro-to-viridis.html for color palette options
pp <- df_filtered %>%
  ggplot( aes(x=seascape_week, y=chla, fill=seascape_week)) +
  geom_jitter(color="grey", size=0.7, alpha=0.8) +
  geom_boxplot(outlier.shape = NA) +
  # geom_violin(outline.type = "blank") +
  # scale_fill_viridis(option="H", discrete = TRUE, alpha=0.6) +
  scale_fill_manual(values = custom_colors) +
  labs(x = "Seascape class") +
  labs(y = expression("[Chl-a] (mg/L)")) +
  # labs(y = expression("Salinity")) +
  # labs(y = expression(paste("Temperature (", degree, "C) at 1 m depth"))) +
  # labs(y = expression("DO (mg/L)")) +
  # labs(y = expression("NO"["x"] ~ mu*"M")) +
  # labs(y = expression("PO"["4"]^"3-" ~ mu*"M")) +
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
  ylim(0, 7) +
  theme(axis.text.x = element_text(size = 32),  # Set X-axis label font size
        axis.text.y = element_text(size = 32)) +
  theme(axis.title.x = element_text(size = 18),
        axis.title.y = element_text(size = 18)) +
  theme(legend.text = element_text(size = 32)) 
pp


################################################################################
# Perform principal component analysis on the count data
library(ggalt)

sel_vars <- c(
  "seascape_week",
  # "temp",
  # "salinity",
  "chla",
  "po4",
  "no3_no2")

# filter out rows with NA values in column seascapes
df_filtered_pca <- sfp_df[complete.cases(sfp_df[, sel_vars]), ]
exclude_seascapes <- c(5, 7, 11, 17, 18)
filt_df_pca <- df_filtered_pca[!df_filtered_pca$seascape_week %in%
                                 exclude_seascapes, sel_vars]

pca <- prcomp(filt_df_pca, scale. = TRUE)

# Extract PC1 and PC2 scores for each sampling event
pc_scores <- data.frame(seascape = as.character(filt_df_pca$seascape_week), # for hydrography
                        PC1 = pca$x[, 1], 
                        PC2 = pca$x[, 2])

# Create the plot
pc_scores$seascape <- factor(pc_scores$seascape, levels = c("3", "13", "15", "21", "27"))
bb <- ggplot(pc_scores, aes(x = PC1, y = PC2, color = seascape)) + 
  geom_point() +
  labs(x = "PC1", y = "PC2", color = "Seascape") 

# add circle around cluster of data points
yy <- ggplot(pc_scores, aes(x = PC1, y = PC2, color = seascape)) + 
  geom_point() +
  stat_ellipse(aes(fill = seascape), level = 0.90, geom = "polygon", alpha = 0.3, color = "black") +
  scale_color_manual(values = custom_colors) +
  scale_fill_manual(values = custom_colors) +
  theme_classic() +
  xlim(-2.5,3) +
  ylim(-2.5,2.5) +
  # xlim(-2,2) +
  # ylim(-2,2) +
  geom_point(size=2) +
  guides(colour = guide_legend(override.aes = list(size=2))) + 
  theme(axis.text.x = element_text(size = 32),  # Set X-axis label font size
        axis.text.y = element_text(size = 32)) +
  theme(axis.title.x = element_text(size = 32),
        axis.title.y = element_text(size = 32)) +
  theme(legend.text = element_text(size = 32))

yy
