<?php
//#######################################################
// PostGIS settings

$postgis_host = "localhost";
$postgis_port = "5432"; 
$postgis_dbname = "postgis";
$postgis_user = "postgres";
$postgis_pass = "gis4all";

// Table prefix for FlexGIS internal tables.  This allows multiple FlexGIS apps to be deployed
// on the same machine.
$postgis_table_prefix = "fgis_";
//######################################################
// Session settings
// The length of the session token.  The generation function uses this length when generating
// a session token.
$token_length = 32;
//######################################################
// MapServer settings

// Location of mapscript.map
$mapfile_directory = "C:/ms4w/apps/flexmapviewer/htdocs/map/"; // INCLUDE TRAILING SLASH
// Location of all images that are used as symbols for POINT layers.
$image_directory = "C:/ms4w/apps/flexmapviewer/htdocs/img/"; // INCLUDE TRAILING SLASH

//######################################################


$postgis_table_users = $postgis_table_prefix . "users";
$postgis_table_states = $postgis_table_prefix . "states";
$postgis_table_layers = $postgis_table_prefix . "layers";
$postgis_table_sessions = $postgis_table_prefix . "sessions";

?>