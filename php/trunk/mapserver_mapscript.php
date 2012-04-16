<?php

require_once("include.php");

/* This script accepts render requests from the client (using XYZ Google Maps tile indices)
 * and returns 256x256 tile images containing the requested layers.  The parameters for the
 * layers are fetched from the layers table, and are used to generate the images.
 */

// ##############################
// Mapfile

$mapfile = $mapfile_directory . "mapscript.map";

// ##############################

if (!extension_loaded("MapScript")) dl("php_mapscript." . PHP_SHLIB_SUFFIX);
############################
# DEBUG MODE OUTPUTS MAPFILE TO STDOUT
$DEBUG = $_REQUEST["DEBUG"];


$x = $_REQUEST["X"];
$y = $_REQUEST["Y"];
$z = $_REQUEST["Z"];
$token = $_REQUEST["TOKEN"];
$layers = explode(",",$_REQUEST["LAYERS"]);

$map = ms_newMapObj($mapfile);


/* The following commented-out code is not implemented in MapServer 5.2.  When MapServer
 * 5.4 is included in both ms4w and FGS, this will be updated.
 * Update: 5.4 is included in FGS, but not ms4w (June 05, 2009)

$map = ms_newMapObjFromString("
MAP
	NAME FLEX_LAYERS
	STATUS ON
	SIZE 256 256
	UNITS meters
	
	IMAGECOLOR 192 192 192
	IMAGEQUALITY 95
	IMAGETYPE png
	OUTPUTFORMAT
		NAME png
		DRIVER 'GD/PNG'
		MIMETYPE 'image/png'
		EXTENSION 'png'
		TRANSPARENT ON
	END
END
");*/

/* Set the output map projection as Google Maps Mercator.  If the layer geometries are in
 * WGS84 or some other projection, they will be reprojected into Mercator.
 */

$map->setProjection("+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +units=m +k=1.0 +nadgrids=@null", MS_TRUE);
$extentArray = getMercatorExtent($x, $y, $z);
$map->setExtent($extentArray[0], $extentArray[1], $extentArray[2], $extentArray[3]);

// Construct layer objects based on requested layers

$phplayers = getLayersForTokenWithPROJ4($token);
for($i=1;$i<count($phplayers);$i++) {
	$skipThisLayer = 1;
	for($j=0;$j<count($layers);$j++) {
		if(strtolower($phplayers[$i]['name']) == strtolower($layers[$j])) {
			$skipThisLayer = 0;
			break;
		}
	}
	//print_r($phplayers[$i]);
	if($skipThisLayer) continue;
	$layer = ms_newLayerObj($map);
	$layer->set("status",MS_ON);
	$layer->set("opacity",100);
	$layer->set("name",$phplayers[$i]['name']);
	$layer->setMetaData("wms_title",$phplayers[$i]['name']);
	//$layer->setConnectionType(MS_POSTGIS);
	$layer->set("connectiontype",MS_POSTGIS);
	$layer->set("connection","user=$postgis_user dbname=$postgis_dbname host=$postgis_host port=$postgis_port password=$postgis_pass");
	$layer->set("data",$phplayers[$i]['geometry_name'] . " FROM " . $phplayers[$i]['name']);
	
	// If the layer does not have a projection, set the projection to WGS84.
	if($phplayers[$i]['PROJ4'] == NULL)	$layer->setProjection("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs");
	else $layer->setProjection($phplayers[$i]['PROJ4']);
	
	// Construct a class object, with style
	
	$class = ms_newClassObj($layer);
	//$class->updateFromString('CLASS NAME className STYLE OUTLINECOLOR 144 50 207 END END');
	$class->set("name",$phplayers[$i]['name']);
	$style = ms_newStyleObj($class);
	
	/* Set the graphical representation parameters of the geometry.  If the geometry is a
	 * point, render the image associated with the layer (in the layers table, image is
	 * residing in the images folder specified in config-*.inc.php).  If the geometry is
	 * a line or a polygon, draw a line using the (R G B) colors specified in the layers
	 * table.
	 */
	
	switch(strtolower($phplayers[$i]['geometry_type'])) {
		case "multipoint":
		case "point": {
			$gsymbol = $phplayers[$i]['geometry_symbol'];
			$layer->set("type",MS_LAYER_POINT);
			$style->set("symbol",MS_SYMBOL_PIXMAP);
			$symbol = $map->getSymbolObjectById(ms_newSymbolObj($map, $gsymbol));
			$symbol->setImagePath($image_directory . $gsymbol);
			$style->set("symbolname",$gsymbol);
			break;
		}
		case "multipolygon":
		case "polygon": {
			$gsymbol = explode(" ",$phplayers[$i]['geometry_symbol']);
			$layer->set("type",MS_LAYER_POLYGON);
			$style->outlinecolor->setRGB((int)$gsymbol[0],(int)$gsymbol[1],(int)$gsymbol[2]);
			break;
		}
		case "linestring":
		case "multilinestring":
		case "line": {
			$gsymbol = explode(" ",$phplayers[$i]['geometry_symbol']);
			$layer->set("type",MS_LAYER_LINE);
			$style->outlinecolor->setRGB((int)$gsymbol[0],(int)$gsymbol[1],(int)$gsymbol[2]);
			break;
		}
		default: // geometrycollection?
			$layer->set("type",MS_LAYER_NULL);
			break;
	}
}

if($DEBUG) {
	$map->save('php://temp');
	die();
}

header('Content-type: image/png');
$map->draw()->saveImage(""); // outputs to stdout (http response)

?>