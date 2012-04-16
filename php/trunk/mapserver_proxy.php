<?php

/* Deprecated MapServer control method, use mapserver_mapscript.php
 * 
 */

require_once("HTTP/Request.php");
$mapserver_cgi = "http://localhost/cgi-bin/mapserv.exe";
$mapfile_location = "C:/ms4w/apps/flexmapviewer/map/example.map";

//#####################

$x = $_REQUEST["X"];
$y = $_REQUEST["Y"];
$z = $_REQUEST["Z"];
$token = $_REQUEST["TOKEN"];
$layers = $_REQUEST["LAYERS"];
$request = "$mapserver_cgi?TOKEN=$token&MODE=tile&TILEMODE=gmap&TILE=$x+$y+$z&MAP=$mapfile_location&LAYERS=$layers";
$req =& new HTTP_Request("$mapserver_cgi?TOKEN=$token&MODE=tile&TILEMODE=gmap&TILE=$x+$y+$z&MAP=$mapfile_location&LAYERS=$layers");
if (!PEAR::isError($req->sendRequest())) {
    echo $req->getResponseBody();
}
?>