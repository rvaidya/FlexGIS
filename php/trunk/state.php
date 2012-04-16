<?php
############
# This class implements the full RPC for state load/save.
require_once("include.php");
header("Content-type: text/xml");

//print_r($qresult);
$post = trim(file_get_contents('php://input'));
global $xml;
try {
	$xml = new SimpleXMLElement($post);
} catch(Exception $e) {
	echo '<?xml version="1.0"?>
	<state_response result="ERROR" reason="Unable to parse state request XML."/>';
	die();
}
if(strtolower($xml->getName()) == "state_save") {
	$token = $xml['token'];
	$state = $xml->state;
	echo $token;
	$qresult = postgis_query("SELECT s.user_id,length(state) AS state_size FROM $postgis_table_sessions AS s LEFT OUTER JOIN $postgis_table_states AS t ON s.user_id=t.user_id WHERE s.token='$token';");
	if(count($qresult) < 2) {
		echo '<?xml version="1.0"?>
		<state_response result="EMPTY" reason="No session exists."/>';
		die();
	}
	$user_id = $qresult[1]['user_id'];
	if((int)$qresult[1]['state_size'] == 0) {
		postgis_query("INSERT INTO $postgis_table_states(user_id,state) VALUES($user_id,'$state');");
	}
	else {
		postgis_query("UPDATE $postgis_table_states SET state='$state' WHERE user_id=$user_id;");
	}
	echo '<?xml version="1.0"?>
		<state_response result="OK" token="' . $token . '"/>';
		die();
}
else if(strtolower($xml->getName()) == "state_load") {
	$token = $xml['token'];
	$qresult = postgis_query("SELECT s.user_id,state FROM $postgis_table_sessions AS s,$postgis_table_states AS t WHERE s.user_id=t.user_id AND s.token='$token';");
	if(count($qresult) < 2) {
		echo '<?xml version="1.0"?>
		<state_response result="EMPTY" reason="No state exists."/>';
		die();
	}
	
	$xmlresponse = new SimpleXMLElement("<state_response />");
	$xmlresponse->addAttribute("result","OK");
	$xmlresponse->addAttribute("token",$token);
	$xmlresponse->addChild("state",$qresult[1]['state']);
	echo formatXML($xmlresponse);
}
else {
	echo '<?xml version="1.0"?>
		<state_response result="ERROR" reason="Invalid state request."/>';
		die();
}
?>