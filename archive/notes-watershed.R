
tmap::tmap_mode("view")
# Visualize terminal flow points
outlets = sf::st_read("./assets/SHP/outlets_multiple.shp", quiet=T)
dem_acc = terra::rast("./assets/TIF/dem_chilwa_14_flow_accumulation.tif")

whitebox::wbt_d_inf_flow_accumulation(
  input = "dem_chilwa_13_flow_direction_dINF.tif",
  output = "dem_chilwa_14_flow_accumulation_dINF.tif",
  wd = "./assets/TIF/"
)


tmap::tm_shape(outlets) + tmap::tm_symbols(col = "red", size = 0.5,
col.legend = tm_legend(title = "Terminal Flow Points", labels = "")) +

    
tmap::tm_shape(dem_acc) + tmap::tm_raster(values="OrRd", title = "D8 Flow Accumulation",
  breaks = c(1, 2, 3, 5, 10, 50, 100, 1000, 1200000),
  labels = c("1-2", "2-3", "3-5", "5-10", "10-50", "50-100", "100-1K", ">1K")) +
  tmap::tm_shape(lake) + tmap::tm_borders(col = "turquoise", lwd = 2) +
  tmap::tm_shape(outlets) + tmap::tm_symbols(col = "red", size = 0.5,
      col.legend = tm_legend(title = "Terminal Flow Points", labels = "")) +
  tmap::tm_layout(legend.text.size = 0.8, legend.title.size = 1)

# ----------------- Public/Private ----------------- #


# Breach Depressions
whitebox::wbt_breach_depressions(
  dem   = "dem_chilwa_00_raw.tif",
  output= "dem_chilwa_11_breached_flat.tif",
  wd    = "./assets/TIF/",
  max_depth = 3,  
  flat_increment = 0.001
  )

# Fill Sinks (x2)
whitebox::wbt_fill_depressions_wang_and_liu(
  dem = "dem_chilwa_11_breached_flat.tif",
  output = "dem_chilwa_12_filled_wang.tif",
  wd = "./assets/TIF/"
)

whitebox::wbt_fill_depressions(
  dem    = "dem_chilwa_11_breached.tif",
  output = "dem_chilwa_12_filled.tif",
  wd     = "./assets/TIF/",
  fix_flats = T,
  flat_increment = 0.001,
  max_depth = 10  # Preserves larger depressions
  )

# Locate Depression Network 
dem_breach <- terra::rast("./assets/TIF/dem_chilwa_11_breached_flat.tif")
dem_filled <- terra::rast("./assets/TIF/dem_chilwa_12_filled_wang.tif")
depression_effect <- dem_filled - dem_breach
terra::writeRaster(depression_effect, 
  "./assets/TIF/dem_chilwa_13_depression_effects.tif",
  overwrite=TRUE)

# Compute Flow Direction (x2)
whitebox::wbt_d8_pointer(
  dem = "dem_chilwa_12_filled_wang.tif",
  output = "dem_chilwa_14_flow_direction_D8.tif",
  wd = "./assets/TIF/"
)

whitebox::wbt_d_inf_flow_accumulation(
  input = "dem_chilwa_13_flow_direction_dINF.tif",
  output = "dem_chilwa_14_flow_accumulation_dINF.tif",
  wd = "./assets/TIF/"
)

# Compute Flow Accumulation
whitebox::wbt_d8_flow_accumulation(
  input = "dem_chilwa_14_flow_direction_D8.tif", 
  pntr = T,
  output= "dem_chilwa_14_flow_accumulation_D8.tif",
  wd = "./assets/TIF/"
  )

# Calculate drainage areas of sinks
whitebox::wbt_depth_in_sink(
  dem = "dem_chilwa_00_raw.tif",  # Use breached or raw, not filled
  output = "dem_chilwa_15_sink_depth.tif", 
  wd = "./assets/TIF/",
  zero_background = FALSE
)

# Calculate TPI for marshland delineation in later sections
whitebox::wbt_wetness_index(
  sca = "dem_chilwa_14_flow_accumulation_D8.tif",
  slope = "dem_chilwa_12_filled_wang.tif",  
  output = "dem_chilwa_16_wetness_index.tif",
  wd = "./assets/TIF/"
)

# Identify watershed from conditioned layers
flow_accum = terra::rast("./assets/TIF/dem_chilwa_14_flow_accumulation_D8.tif")
dem_condt  = terra::rast("./assets/TIF/dem_chilwa_12_filled_wang.tif")
depth_sink = terra::rast("./assets/TIF/dem_chilwa_15_sink_depth.tif")

# Extract watershed values at terminal drainage points
outlet_depth = terra::extract(depth_sink, terra::vect(outlets))[1, 2]
outlet_elev  = terra::extract(dem_condt, terra::vect(outlets))[1, 2]
print(paste("Lake depth in sink:", outlet_depth, "m"))
print(paste("Lake elevation:", outlet_elev, "m"))

# Watershed indicators used to define areas that:
# 1. Are within elevation threshold (750m based on your stats)
# 2. AND are part of the depression network (depth_in_sink > 0)
# 3. OR have flow accumulation draining toward the lake

# Define watershed & sink thresholds
mask = (dem_condt <= 750) & (depth_sink > 0)

# A: Delineate watershed using conditioned flow
whitebox::wbt_watershed(
  d8_pntr = "dem_chilwa_13_flow_direction_D8.tif",  
  pour_pts = "./assets/SHP/outlets.shp",
  output = "dem_chilwa_17_watershed_conditioned.tif",
  wd = "./assets/TIF/"
  )

# B: Delineate watershed using depth indicators
watershed_flow = terra::rast("./assets/TIF/dem_chilwa_17_watershed_conditioned.tif")
if(all(is.na(values(watershed_flow)))) {
  print("Flow-based method failed - using depth in sink approach")
  watershed_final <- mask
  } else { # Combine both approaches
  watershed_final <- (watershed_flow == 1) | mask
}

# Tidy & convert to sf
watershed_clean = terra::focal(watershed_final, w = 5, fun = "modal") |>
  terra::as.polygons(dissolve = TRUE) |>
  sf::st_as_sf()

# Extract largest polygon
watershed_clean$area_ha = as.numeric(sf::st_area(watershed_clean)) * 0.0001
watershed_clean = watershed_clean[which.max(watershed_clean$area_ha), ]

# Visualize all layers
par(mfrow = c(1, 3))
plot(dem_breach, main = "Breached DEM")
plot(flow_accum, main = "Flow Accumulation")
plot(depth_sink, main = "Depth in Sink")
#plot(watershed_final, main = "Final Watershed")
#plot(sf::st_geometry(watershed_clean), main = "Watershed Polygon", col = "lightblue")
#
#
#
#


# Interactive map mode: "view"
tmap::tmap_mode("view")
tmap::tm_shape(aoi_country) +
  tmap::tm_borders(lwd = 1, col = "green") +
  tmap::tm_shape(aoi_site) +
  tmap::tm_borders(lwd = 2, col = "red")

  tmap::tm_shape(lakes_site) + tm_fill ("steelblue") +
  tmap::tm_shape(watershed_site) + tm_borders(col = "red", lwd=1)


lakes = sf::st_read("./assets/SHP/lakes.shp") |> sf::st_cast("POLYGON")
basins= sf::st_read("./assets/SHP/basins.shp") |> sf::st_cast("MULTIPOLYGON")
rivers= sf::st_read("./assets/SHP/streams.shp")|> sf::st_cast("MULTILINESTRING")
dem   = terra::rast("./assets/TIF/dem_7arc_condt.tif") 
h <- nrow(dem)
w <- ncol(dem)

tmap::tmap_mode("view")
tmap::tm_shape(dem_filled) + tmap::tm_raster(values = "brewer.greens") +
  tmap::tm_shape(chilwa_basin) + tmap::tm_borders(lwd=2, col="blue") +
  tmap::tm_shape(lake) + tmap::tm_polygon(lwd = 0.7, col = "steelblue") +
  tmap::tm_scalebar(position=c("RIGHT", "BOTTOM"), text.size = .5) +
  tmap::tm_compass(color.dark="gray60",position=c("RIGHT", "top")) +
  tmap::tm_graticules(lines=T,labels.rot=c(0,90),lwd=0.2) +
  tmap::tm_title("Endorheic Watershed Delineation", size=.8) +
  tmap::tm_basemap("Esri.WorldImagery")




tmap::tmap_mode("view")
tmap::tm_shape(dem_filled) + tmap::tm_raster(values = "brewer.greens") +
  tmap::tm_shape(chilwa_basin) + tmap::tm_borders(lwd=2, col="blue") +
  tmap::tm_shape(lake) + tmap::tm_polygon(lwd = 0.7, col = "steelblue") +
  tmap::tm_scalebar(position=c("RIGHT", "BOTTOM"), text.size = .5) +
  tmap::tm_compass(color.dark="gray60",position=c("RIGHT", "top")) +
  tmap::tm_graticules(lines=T,labels.rot=c(0,90),lwd=0.2) +
  tmap::tm_title("Endorheic Watershed Delineation", size=.8) +
  tmap::tm_basemap("Esri.WorldImagery")




#| warning: false
#| message: false
#| error: false
#| eval: false
#| echo: true
#| comment: NA
tmap::tmap_mode("view")

streams_sf = sf::st_read("./assets/SHP/streams_chilwa.shp")
sf::st_crs(streams_sf) = 3857

# Visualize
tmap::tmap_mode("view")
tmap::tm_shape(dem_filled) + tmap::tm_raster(values = "brewer.greens") +
  tmap::tm_shape(chilwa_basin) + tmap::tm_borders(lwd=2, col="blue") +
  tmap::tm_shape(lake) + tmap::tm_polygon(lwd = 0.7, col = "steelblue") +
  tmap::tm_scalebar(position=c("RIGHT", "BOTTOM"), text.size = .5) +
  tmap::tm_compass(color.dark="gray60",position=c("RIGHT", "top")) +
  tmap::tm_graticules(lines=T,labels.rot=c(0,90),lwd=0.2) +
  tmap::tm_title("Endorheic Watershed Delineation", size=.8) +
  tmap::tm_basemap("Esri.WorldImagery")


if (file.exists("./assets/TIF/dem_chilwa_19_streams_d8.tif")) {
  par(mfrow = c(2, 1), mar = c(3, 1, 2, 1))
  plot(rast("./assets/TIF/dem_chilwa_19_streams_d8.tif"), main = "Streams",col = "black")
  plot(rast("./assets/TIF/dem_chilwa_20_tributaries.tif"),main = "TributaryIdentifier")
  }

watershed = terra::rast("./assets/TIF/dem_chilwa_20_watershed_unnested.tif") |>
  terra::as.polygons(dissolve = TRUE) |> sf::st_as_sf()





whitebox::wbt_tributary_identifier(
  d8_pntr = "dem_chilwa_14_flow_direction_D8.tif",
  streams = "dem_chilwa_19_streams_d8.tif",
  output  = "dem_chilwa_20_tributaries.tif", 
  wd = "./assets/TIF/"
  )



# Derive terminal drainage points near high flow accumulation
outlets = mapedit::editMap(mapview::mapView(dem_acc)) 
outlets = outlets$all |> # convert to sf
  sf::st_transform(crs_master) |>
  dplyr::select(geometry)
outlets$id <- "chilwa_drainage_terminus"

# Add terminal flow points to improve delineation
outlets_add = mapedit::editMap(mapview::mapView(dem_acc)) 
outlets_add = outlets_add$all |> # convert to sf
  sf::st_transform(crs_master) |>
  dplyr::select(geometry)
outlets_add$id <- "chilwa_drainage_terminus_multiple"

# Visualize & save terminal flow points for reproducibility
sf::st_write(outlets, "./assets/SHP/outlets.shp", delete_layer=T, quiet=T)
sf::st_write(outlets_add, "./assets/SHP/outlets_multiple.shp", delete_layer=T)
dem_acc   = terra::rast("./assets/TIF/dem_chilwa_14_flow_accumulation.tif")
tmap::tm_shape(dem_acc) + tmap::tm_raster(values="brewer.reds") +
  tmap::tm_shape(lake) + tmap::tm_borders(col="lightblue") +
  tmap::tm_shape(outlets) + tmap::tm_symbols(shape="id",lwd=2)



# Define threshold at 750m elevation based on `summary(dem_100m)` & process
mask        = dem_100m <= 750
smooth      = terra::focal(mask, w = 9, fun = "modal", na.rm=T)
smooth_poly = terra::as.polygons(smooth==1, dissolve=T, values=T)
watershed   = sf::st_as_sf(smooth_poly)

outlets_elev <- terra::extract(dem_100m, terra::vect(outlets))[1, 2]

# This captures the basin while excluding high mountains outside


whitebox::wbt_breach_depressions_least_cost(
  dem = "dem_chilwa_00_raw.tif",
  output = "dem_chilwa_11_breached_lc.tif",
  wd = "./assets/TIF/",
  dist=100, max_cost=100, fill = T
  )

whitebox::wbt_fill_depressions_wang_and_liu(
  dem = "dem_chilwa_11_breached_lc.tif",
  output = "dem_chilwa_12_filled_wang.tif",
  wd = "./assets/TIF/"
  )

whitebox::wbt_d8_pointer(
  dem = "dem_chilwa_11_breached_lc.tif",
  output = "dem_chilwa_13_flow_direction_D8.tif",
  wd = "./assets/TIF/"
  )

whitebox::wbt_unnest_basins(
  d8_pntr = "dem_chilwa_13_flow_direction_D8.tif",
  pour_pts = "./assets/SHP/outlets.shp",
  output = "dem_chilwa_20_watershed_unnest.tif",
  wd = "./assets/TIF/"
  )

print(paste("Basin area:", round(chilwa_basin$area_km2, 1), "km²"))

drainage  = stars::read_stars("./assets/TIF/dem_chilwa_17_watershed.tif")
watershed = stars::st_contour(drainage, breaks = 1) |> 
  sf::st_geometry() |> 
  sf::st_cast("POLYGON")

watershed_bdry <- watershed[which.max(st_area(watershed))]


# Delineate watershed from flow terminus and flow direction 
whitebox::wbt_watershed(
  d8_pntr = "dem_chilwa_13_flow_direction.tif",
  pour_pts = "./assets/SHP/outlets_multiple.shp",
  output = "dem_chilwa_17_watershed.tif",
  wd = "./assets/TIF/"
)

# Delineate sub-basins and extract target watershed
whitebox::wbt_basins(
  d8_pntr = "dem_chilwa_13_flow_direction.tif",
  output = "dem_chilwa_18_basins.tif",
  wd = "./assets/TIF/"
)

# Recommended algorithm for endorheic drainages
whitebox::wbt_stochastic_depression_analysis(
  dem = "dem_chilwa_12_filled.tif",
  output = "dem_chilwa_19_depressions.tif",
  rmse = 5.0,  # RMSE in elevation units
  range = 100,  
  iterations = 100,
  wd = "./assets/TIF/"
)

# Due to flat basin, we derive thresholds to filter depressions by area
dem_condt   = terra::rast("./assets/TIF/dem_chilwa_12_filled.tif")
depressions = terra::rast("./assets/TIF/dem_chilwa_19_depressions.tif")
depressions_poly = terra::as.polygons(depressions, dissolve=F) 
depressions_sf   = sf::st_as_sf(depressions_poly) #|>ms_simplify(keep=0.1)

# Calculate areas of depression polygons 
depressions_sf$area_ha = as.numeric(sf::st_area(depression_sf)) * 0.0001
print(summary(depressions_sf$area_ha, na.rm = TRUE))
# Min.1stQ, Median:1, Mean:87.9, 3rdQ: 3.0 Max:2126474.0 

# Extract largest polygon & visualize
depressions_max = depressions_sf[which.max(depressions_sf$area_ha), ]
sf::st_write(depressions_sf,"./assets/SHP/depressions_poly.gpkg",delete_layer=T)
plot(depressions_max)






tmap::tmap_mode("view")
tmap::tm_shape(dem_filled) + tmap::tm_raster(values = "brewer.greens") +
  tmap::tm_shape(chilwa_basin) + tmap::tm_borders(lwd=2, col="blue") +
  tmap::tm_shape(lake) + tmap::tm_polygon(lwd = 0.7, col = "steelblue") +
  tmap::tm_scalebar(position=c("RIGHT", "BOTTOM"), text.size = .5) +
  tmap::tm_compass(color.dark="gray60",position=c("RIGHT", "top")) +
  tmap::tm_graticules(lines=T,labels.rot=c(0,90),lwd=0.2) +
  tmap::tm_title("Endorheic Watershed Delineation", size=.8) +
  tmap::tm_basemap("Esri.WorldImagery")













#outlets = sf::read_sf("./assets/SHP/outlets.shp", quiet=T)
dem_acc = terra::rast("./assets/TIF/dem_chilwa_14_flow_accumulation.tif")
outlets = sf::st_read("./assets/SHP/outlets_multiple.shp", quiet=T)
tmap::tm_shape(dem_acc) + tmap::tm_raster(values="brewer.reds") +
  tmap::tm_shape(lake) + tmap::tm_borders(col="lightblue") +
  tmap::tm_shape(outlets) + tmap::tm_symbols(shape="id",lwd=2)

dem_breach_diff <- dem_100m - dem_breach
dem_breach_diff[dem_breach_diff == 0] <- NA
dem_fill_diff <- dem_100m - dem_fill
dem_fill_diff[dem_fill_diff == 0] <- NA

depression_effect <- dem_filled - dem_breach
breach_effect = dem_100m - dem_breach  
fill_effect   = dem_filled - dem_breach
total_effect  = dem_filled - dem_100m  

total_effect[total_effect == 0] <- NA
total_log <- log10(total_effect + 0.01)  # +0.01 to handle small values




whitebox::wbt_find_main_stem(
  d8_pntr = "dem_chilwa_14_flow_direction_D8.tif",
  streams = "dem_chilwa_19_streams_d8.tif",
  output = "dem_chilwa_20_streams_trunk.tif",
  wd = "../assets/TIF/"
)



watershed = sf::st_read("../assets/inputs/watershed_site.shp") |> 
  dplyr::select("fid") |> sf::st_transform("EPSG:3857") |>
  dplyr::rename(chilwa_basin = fid)

