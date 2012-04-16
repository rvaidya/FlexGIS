<?php

require_once("helper.php");

$tmpdir = "C:/ms4w/apps/flexmapviewer/tmp/";

$head = "MAP
	NAME FLEX_LAYERS
	STATUS ON
	SIZE 256 256
	#EXTENT -125.107805 32.291815 -113.505409 42.246534
	UNITS meters

	PROJECTION
	  'proj=longlat'
	  'ellps=WGS84'
	  'datum=WGS84'
	  'no_defs'
	  ''
	END
	
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

	QUERYMAP
	  STYLE HILITE
	  COLOR 255 0 0
	END
";
$filename = $tmpdir . "a.txt";
if (is__writable($filename)) {
	echo "Writable";
	$handle = fopen($filename, 'w');
	fwrite($handle, $head);
	fclose($handle);
}
else echo "Not writable";
?>