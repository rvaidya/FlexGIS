<?php
############################################################################################
# This class takes care of getting and creating layers
# XML (SOAP) layers are implemented as tables that are deleted when the user deletes them, and can only be refreshed explicitly.
# Metalayers are implemented as SQL views on other tables.


require_once("include.php");
header("Content-type: text/xml");
$post = trim(file_get_contents('php://input'));

global $xml;
try {
	$xml = new SimpleXMLElement($post);
} catch(Exception $e) {
	echo '<?xml version="1.0"?>
	<layers_response result="ERROR" reason="Unable to parse layer request XML."/>';
	die();
}

if(strtolower($xml->getName()) == "layers_request") {
	$token = $xml['token'];
	$array = getLayersForToken($token);
	$response = new SimpleXMLElement("<layers_response/>");
	$response->addAttribute("token",$token);
	$response->addAttribute("result","OK");
	$keys = array_keys($array[0]);
	for($i=1;$i<count($array);$i++) {
		$layer = $response->addChild("layer");
		for($j=0;$j<count($keys);$j++) {
			$layer->addAttribute($keys[$j],$array[$i][$keys[$j]]);
		}
	}
	echo formatXML($response);
}


?>