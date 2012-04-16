<?php

/* This handles direct SQL queries to the database from the client.  This functionality
 * is disabled by default (enable it to test/debug your app).  Communicates with the Query
 * Window.
 */

die("Querying disabled");
require_once("helper.php");
header("Content-type: text/xml");

$post = trim(file_get_contents('php://input'));
global $xml;
try {
	$xml = new SimpleXMLElement($post);
} catch(Exception $e) {
	echo '<?xml version="1.0"?>
	<query_result result="ERROR" reason="Unable to parse query XML."/>';
	die();
}
$query_type = strtolower($xml->type);
$query_table = $xml->table;
$query_fields = $xml->fields;
$query_limit = $xml->limit;
$query_order = $xml->order;
$query_where = $xml->where;
$query_token = $xml['token'];
$qtext = $query_type;
if($query_fields != "") $qtext = $qtext . " $query_fields";
else $qtext = $qtext . " *";
$qtext = $qtext . " FROM $query_table";
if($query_where != "") $qtext = $qtext . " WHERE $query_where";
if($query_order != "") $qtext = $qtext . " ORDER BY $query_order";
if($query_limit != "") $qtext = $qtext . " LIMIT $query_limit";
$qtext = $qtext . ";";
//echo $post;
echo $qtext . "\n";
//echo $post . "\n" . $qtext . "\n";
$pgc = postgis_connect();
@$result = pg_query($pgc, $qtext);
pg_close($pgc);

if (!$result) {
  echo '<?xml version="1.0"?>
  <query_result result="ERROR" reason="Error performing query: Query failed in database."/>';
  die();
}
$xml = new SimpleXMLElement("<query_result/>");
$xml->addAttribute("table",pg_field_table($result, 0));
$xml->addAttribute("token",$query_token);
if($query_limit == "0") {
	$xml->addAttribute("result","FIELDS");
	for($i=0;$i<pg_num_fields($result);$i++) {
		$field = $xml->addChild("field");
		$field->addAttribute("name", pg_field_name($result,$i));
		$field->addAttribute("type", pg_field_type($result,$i));
	}
}
else $xml->addAttribute("result","ROWS");
while ($row = pg_fetch_row($result)) {
	$rowXML = $xml->addChild("row");
	for($i=0;$i<count($row);$i++) {
		$field = $rowXML->addChild("field", $row[$i]);
		$field->addAttribute("name", pg_field_name($result,$i));
		$field->addAttribute("type", pg_field_type($result,$i));
	}
}
pg_free_result($result);
echo formatXML($xml);
?>