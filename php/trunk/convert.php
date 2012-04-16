<?php 
require_once("include.php");

$path_to_converter = "C:/Program Files/PostgreSQL/8.3/bin";
$geometry_name = "geom";
$shapefile = "C:/ms4w/apps/flexmapviewer/htdocs/data/county/fe_2007_06_county.shp";
$table_name = "county";


echo `"$path_to_converter/shp2pgsql" -d -g $geometry_name -N insert $shapefile $table_name`;
?>