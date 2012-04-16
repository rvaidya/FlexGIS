<?php
/* 
 * Makes a connection to the PostGIS server using parameters specified in config-*.inc.php
 */
function postgis_connect() {
	global $postgis_host, $postgis_port, $postgis_dbname, $postgis_user, $postgis_pass;
	$pg_connect_string = "host=$postgis_host port=$postgis_port dbname=$postgis_dbname 
	user=$postgis_user password=$postgis_pass";
	return pg_connect($pg_connect_string);
}

// Performs a query, returns query results as an associative array of field name -> value, starting from index 1.  Index 0 contains types
// If more information is needed (table name, etc.), use standard PostGIS query functions.
// Return Values:
//   Array size 0: Error
//   Array size 1: No rows returned
//   Array size >1: Data
//	 	When data is returned, Array index 0 is the types of the data (field name -> type)
//      nd 1+ are the data.
//   An existing connection to PostGIS can be included as a parameter.  If it is not, the
//	 function makes a connection, and closes it after execution.
function postgis_query($string, $pgc = NULL) {
	$pgct = $pgc;
	if($pgc == NULL) $pgct = postgis_connect();
	@$result = pg_query($pgct, $string);
	if($pgc == NULL) pg_close($pgct);
	$retval = array();
	if(!$result) return $retval;
	$arow = array();
	for($i=0;$i<pg_num_fields($result);$i++) {
		$arow[pg_field_name($result, $i)] = pg_field_type($result, $i);
	}
	$retval[0] = $arow;
	$ctr = 1;
	while($row = pg_fetch_row($result)) {
		$arow = array();
		for($i=0;$i<count($row);$i++) {
			$arow[pg_field_name($result, $i)] = $row[$i];
		}
		$retval[$ctr] = $arow;
		$ctr++;
	}
	pg_free_result($result);
	return $retval;
}

function timestamp() {
	return date("Y-m-d H:i:s P");
}

// Generate an alphanumeric token with length specified in config-*.inc.php
function generate_token() {
	global $sessionID_length;
	$string = "";
	for($i=0;$i<$sessionID_length;$i++) {
		$r = mt_rand(48, 83);
		if($r > 57) $r += 7;
		$string = $string . chr($r);
	}
	return $string;
}
// Format an XML object with whitespace so that it is easier to read.
function formatXML($xml) {
	$doc = new DOMDocument('1.0');
	$doc->preserveWhiteSpace = false;
	$doc->loadXML($xml->asXML());
	$doc->formatOutput = true;
	return $doc->saveXML();
}

// Converts tile indices to latitude/longitude extent, no projection.
// Input :
// ( $x, $y ) = Overlay Image Index
// $z = Zoom Level
//
// Output :
// Array contains
// 0 => SW Longitude
// 1 => SW Latitude
// 2 => NE Longitude
// 3 => NE Latitude
function getBoundaries($x, $y, $z){

        $grid_count = pow(2, $z);
        $block_size = 360.0 / $grid_count;

        $temp_x = -180.0 + ( $block_size * $x );
        $temp_y = 180.0 - ( $block_size * $y );

        $temp_x2 = $temp_x + $block_size;
        $temp_y2 = $temp_y - $block_size;

        $lon = $temp_x;
        $lat = ( 2.0* atan( exp( $temp_y / 180.0 * pi() ) ) - pi() / 2.0 ) * 180.0 / pi();

        $lon2 = $temp_x2;
        $lat2 = ( 2.0* atan( exp( $temp_y2 / 180.0 * pi() ) ) - pi() / 2.0 ) * 180.0 / pi();

        $array = array();
        $array[0] = $lon;
        $array[1] = $lat2;
        $array[2] = $lon2;
        $array[3] = $lat;

		return $array;

}

// Converts latitude/longitude extent to tile indices, no projection.
// Input :
// Latitude, Longitude, and Zoom-Level
//
// Output :
// array[0] = x
// array[1] = y where ( x, y ) = Overlay Image Index
function getOverlayIndex($lat, $lon, $z){

        $grid_count = pow(2, $z);
        $block_size = 360.0 / $grid_count;

        $x = ( $lon + 180.0 ) / $block_size;

        $lat_mod = ( 180.0 / pi() ) * log( tan( (1.0 / 2.0) * ( $lat * pi() / 180.0 + pi() / 2.0 ) ) );
        $y = ( $lat_mod - 180.0 ) / ( -1.0 * $block_size );

        $array = array();
        $array[0] = floor($x);
        $array[1] = floor($y);

        return $array;
}

// Gets the mercator projection extent of a Google Map tile in meters.

// Input : Google Maps Tile Index (X, Y, ZOOM)
// Output: Array with tile bounds in meters (Mercator projection)

function getMercatorExtent($x, $y, $z) {
	$grid_count = pow(2, $z);
	$block_size = 360.0 / $grid_count;
	
	$temp_x = -180.0 + ( $block_size * $x );
	$temp_y = 180.0 - ( $block_size * $y );
	
	$temp_x2 = $temp_x + $block_size;
	$temp_y2 = $temp_y - $block_size;
	
	$lon = $temp_x;
	$lat = ( 2.0* atan( exp( $temp_y / 180.0 * pi() ) ) - pi() / 2.0 ) * 180.0 / pi();
	
	$lon2 = $temp_x2;
	$lat2 = ( 2.0* atan( exp( $temp_y2 / 180.0 * pi() ) ) - pi() / 2.0 ) * 180.0 / pi();
	
	$projIn = ms_newProjectionObj("proj=latlong");
	$projOut = ms_newProjectionObj("+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +units=m +k=1.0 +nadgrids=@null");
	$sw = ms_newPointObj();
	$ne = ms_newPointObj();
	$sw->setXY($lon,$lat2);
	$ne->setXY($lon2, $lat);
	$sw->project($projIn, $projOut);
	$ne->project($projIn, $projOut);
	$array = array();
	$array[0] = $sw->x;
	$array[1] = $sw->y;
	$array[2] = $ne->x;
	$array[3] = $ne->y;
	return($array);
}

function is__writable($path) {
//will work in despite of Windows ACLs bug
//NOTE: use a trailing slash for folders!!!
//see http://bugs.php.net/bug.php?id=27609
//see http://bugs.php.net/bug.php?id=30931

    if ($path{strlen($path)-1}=='/') // recursively return a temporary file path
        return is__writable($path.uniqid(mt_rand()).'.tmp');
    else if (is_dir($path))
        return is__writable($path.'/'.uniqid(mt_rand()).'.tmp');
    // check tmp file for read/write capabilities
    $rm = file_exists($path);
    $f = @fopen($path, 'a');
    if ($f===false)
        return false;
    fclose($f);
    if (!$rm)
        unlink($path);
    return true;
}

//  Get the layers from the layers table that are available for a specific session
//  token.

function getLayersForToken($token, $where = NULL) {
	global $postgis_table_layers, $postgis_table_sessions;
	if($where != NULL) {
		$array = postgis_query("SELECT l.* FROM $postgis_table_layers AS l LEFT OUTER JOIN $postgis_table_sessions AS s ON l.owner=s.user_id WHERE (s.token='$token' OR l.owner = 0) AND $where;");
	}
	else $array = postgis_query("SELECT l.* FROM $postgis_table_layers AS l LEFT OUTER JOIN $postgis_table_sessions AS s ON l.owner=s.user_id WHERE (s.token='$token' OR l.owner = 0);");
	return $array;
}

//  Get the layers from the layers table that are available for a specific session
//  token.  This version includes the PROJ4 projection parameters string as an additional
//  column.

function getLayersForTokenWithPROJ4($token, $where = NULL) {
	$pgc = postgis_connect();
	global $postgis_table_layers, $postgis_table_sessions;
	if($where != NULL) {
		$array = postgis_query("SELECT l.* FROM $postgis_table_layers AS l LEFT OUTER JOIN $postgis_table_sessions AS s ON l.owner=s.user_id WHERE (s.token='$token' OR l.owner = 0) AND $where;",$pgc);
	}
	else $array = postgis_query("SELECT l.* FROM $postgis_table_layers AS l LEFT OUTER JOIN $postgis_table_sessions AS s ON l.owner=s.user_id WHERE (s.token='$token' OR l.owner = 0);",$pgc);
	for($i=1;$i<count($array);$i++) {
		$arr = postgis_query("SELECT proj4text as proj4 FROM spatial_ref_sys as s,geometry_columns as g WHERE g.f_table_name='" . $array[$i]['name'] . "' AND s.srid=g.srid;",$pgc);
		if(count($arr) > 1) {
			$array[$i]['PROJ4'] = $arr[1]['proj4'];
		}
	}
	pg_close($pgc);
	return $array;
}



?>