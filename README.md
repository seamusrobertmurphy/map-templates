------------------------------------------------------------------------

# [Terrain Mapping eBook](https://seamusrobertmurphy.quarto.pub/map-templates)

This e-book provides a series of mapping templates and guides for deriving standard operational maps. The sequence of chapters was designed for data stream efficiency: site context establishes area-of-interest geometry, watershed delineation derives flow structure, stream delineation extracts hydrological features, topographic analysis conditions elevation data and computes terrain metrics, climate mapping interpolates environmental surfaces, and demographic mapping contextualizes human populations. Each stage reuses outputs from prior chapters, minimizing reprocessing and enabling iterative refinement of area-of-interest boundaries, coordinate systems, and spatial resolution.

------------------------------------------------------------------------

# Mapping Workflows

## Chapter 1: Site Maps

Define area-of-interest (AOI), establish coordinate reference system (CRS), load boundary geometries, and create reference maps. All downstream chapters inherit AOI and CRS from this stage.

## Chapter 2: Watershed Maps

Download and condition digital elevation models. Breach channels, fill depressions. Compute flow direction and accumulation. Delineate watershed boundaries. Validate against observed drainage patterns. Watershed boundaries define the fundamental geographic unit for all subsequent analysis.

## Chapter 3: Riparian Maps

Extract stream networks from flow accumulation surfaces. Delineate riparian zones and floodplain extent. Validate stream locations against hydrographic databases and field observations. Stream networks and riparian zones structure all operational mapping.

## Chapter 4: Topography Maps

Use conditioned DEM from Chapter 2. Compute slope and aspect. Classify terrain. Generate hillshade and relief visualization. Topographic products describe landscape geometry essential to operations and analysis.

## Chapter 5: Climate Maps

Download weather station data. Temporally aggregate (daily, monthly, seasonal, annual). Spatially interpolate using kriging or inverse distance weighting. Generate temperature, precipitation, humidity, and wind surfaces. Climate data provide environmental context for operations.

## Chapter 6: Population Maps

Download census and settlement data. Interpolate population density. Classify settlement, visualize demographic context. Population data situate operations within human geography.

------------------------------------------------------------------------

###### Gallery

![](https://raw.githubusercontent.com/seamusrobertmurphy/map-templates/refs/heads/main/assets/outputs/03-locator-map.png)

![](https://raw.githubusercontent.com/seamusrobertmurphy/map-templates/refs/heads/main/assets/outputs/06-watershed-3D.png)

![](https://raw.githubusercontent.com/seamusrobertmurphy/map-templates/refs/heads/main/assets/MAP/stream_map_high_b.png)

![](https://raw.githubusercontent.com/seamusrobertmurphy/map-templates/refs/heads/main/assets/MAP/aspect_chilwa_2d.png)

![](https://raw.githubusercontent.com/seamusrobertmurphy/forest-fire-risk-cffdrs/main/assets/PNG/temp.png)

![](https://raw.githubusercontent.com/seamusrobertmurphy/map-templates/refs/heads/main/assets/outputs/04-population-map.png)
