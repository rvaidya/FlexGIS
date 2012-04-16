<?php 
include("include.php");

// This class receives identify requests and returns the results.  This includes point clicked, and all of the fields associated
// with the clicked geometry.  Inputs: layer name and lat/lng clicked.
header("Content-type: text/xml");
$post = trim(file_get_contents('php://input'));

global $xml;
try {
	$xml = new SimpleXMLElement($post);
} catch(Exception $e) {
	echo '<?xml version="1.0"?>
	<identify_response result="ERROR" reason="Unable to parse identify request XML."/>';
	die();
}

if(strtolower($xml->getName()) == "identify_request") {
	
	// Get all of the parameters in the request XML.
	
	$token = $xml['token'];
	$layer = $xml['layer'];
	$lat = $xml['lat'];
	$lng = $xml['lng'];

	$qresult = getLayersForToken($token, "l.name = '$layer'");
	if(count($qresult) <= 1) {
		die('<identify_response result="ERROR" reason="TABLE NOT FOUND"/>');
	}
	$g_type = $qresult[1]['geometry_type'];
	$g_name = $qresult[1]['geometry_name'];
	
	switch(strtolower($g_type)) {
		case "linestring":
		case "multilinestring":
		case "line":
		case "multipoint":
		case "point": {
			
			/* Get the identify information for lines and points.
			 * Lines and points are dealt with in the same manner.
			 * The function will get the CLOSEST point or line from the point clicked, and
			 * will get the information for that.  It will then format the response as XML.
			 * 
			 * Setting thresholds for maximum distance allowed to query a specific point
			 * is left as FUTURE WORK.  Currently, even if you click far away from any
			 * geometry, the function will still pull the closest one.  A dynamic threshold
			 * (varied based on zoom level) will need to be set to restrict the distance from
			 * which results can be gained.
			 */
			
			$result = postgis_query("SELECT *, ST_Distance(GeomFromText('POINT($lng $lat)'),l.$g_name) as calc_dist FROM $layer as l ORDER BY calc_dist ASC LIMIT 1;");
			if(count($result) <= 1) {
				die('<identify_response result="EMPTY" reason="NO MATCHING VALUES"/>');
			}
			$xml = new SimpleXMLElement("<identify_response/>");
			$xml->addAttribute("token",$token);
			$xml->addAttribute("result","OK");
			foreach($result[1] as $k => $v) {
				if($k == $g_name || $k == "calc_dist" || $k == "oid") continue;
				$field = $xml->addChild("field",htmlspecialchars($v));
				$field->addAttribute("name",$k);
			}
			echo formatXML($xml);
			break;
		}
		case "multipolygon":
		case "polygon": {
			
			/* Since polygons are container objects, they are handled differently from points
			 * and lines.  The function checks to see within which geometry the query was
			 * initiated from, and will return that geometry.
			 */
			
			$result = postgis_query("SELECT * FROM $layer as l WHERE ST_Contains(l.$g_name,GeomFromText('POINT($lng $lat)')) = true LIMIT 1;");
			if(count($result) <= 1) {
				die('<identify_response result="EMPTY" reason="NO MATCHING VALUES"/>');
			}
			$xml = new SimpleXMLElement("<identify_response/>");
			$xml->addAttribute("token",$token);
			$xml->addAttribute("result","OK");
			foreach($result[1] as $k => $v) {
				if($k == $g_name || $k == "oid") continue;
				$field = $xml->addChild("field",$v);
				$field->addAttribute("name",$k);
			}
			echo formatXML($xml);
			break;
		}
		default: {
			die('<identify_response result="ERROR reason="UNRECOGNIZED GEOMETRY TYPE"/>');
		}
	}
}

?>