<?php
require_once("include.php");

/* This is a very bare-bones database table installation script.  It will create the necessary
 * tables, and insert some junk values as examples of proper values to insert.
 */

$pgc = postgis_connect();

// Create users table
// Public user owns layers that are accessible to everyone.
$idx = $postgis_table_users . "_username_idx";
pg_query($pgc, "DROP TABLE $postgis_table_users CASCADE;");
$query = "CREATE TABLE $postgis_table_users(
		id SERIAL PRIMARY KEY,
		username TEXT UNIQUE NOT NULL,
		password TEXT NOT NULL);
		CREATE INDEX $idx ON $postgis_table_users(username);
		INSERT INTO $postgis_table_users(id, username, password) VALUES(0, 'public', '');
		INSERT INTO $postgis_table_users(username, password) VALUES('rvaidya', 'garbage');";
pg_query($pgc, $query);

// Create data table
pg_query($pgc, "DROP TABLE $postgis_table_states;");
$query = "CREATE TABLE $postgis_table_states(
		user_id SERIAL PRIMARY KEY REFERENCES $postgis_table_users(id),
		state TEXT);";
pg_query($pgc, $query);

// Create layers table
$idx = $postgis_table_layers . "_owner_idx";
pg_query($pgc, "DROP TABLE $postgis_table_layers;");
$query = "CREATE TABLE $postgis_table_layers(
		id SERIAL PRIMARY KEY,
		owner INTEGER NOT NULL,
		name TEXT UNIQUE NOT NULL,
		type INTEGER NOT NULL,
		display_name TEXT NOT NULL,
		geometry_type TEXT NOT NULL,
		geometry_name TEXT NOT NULL,
		geometry_symbol TEXT NOT NULL);
		CREATE INDEX $idx ON $postgis_table_layers(owner);
		INSERT INTO $postgis_table_layers(owner,name,type,display_name,geometry_type,geometry_name,geometry_symbol) VALUES(0,'stations',0,'Weather Stations','POINT','geom','station.gif');
		INSERT INTO $postgis_table_layers(owner,name,type,display_name,geometry_type,geometry_name,geometry_symbol) VALUES(0,'county',0,'CA Counties','POLYGON','geom','144 50 207');
		INSERT INTO $postgis_table_layers(owner,name,type,display_name,geometry_type,geometry_name,geometry_symbol) VALUES(1,'rahul',1,'Junky Layer','POLYGON','geom','station.gif');";
pg_query($pgc, $query);

// Create sessions table
$idx = $postgis_table_sessions . "_user_id_idx";
pg_query($pgc, "DROP TABLE $postgis_table_sessions;");
$query = "CREATE TABLE $postgis_table_sessions(
		token VARCHAR(32) PRIMARY KEY,
		user_id INTEGER UNIQUE NOT NULL,
		time_created TIMESTAMP NOT NULL,
		time_accessed TIMESTAMP NOT NULL);
		CREATE INDEX $idx ON $postgis_table_sessions(user_id);
		INSERT INTO $postgis_table_sessions(token,user_id,time_created,time_accessed) VALUES('NIA3L4IL160FNULPLRTX55L91QBC20W1',1,'2009-02-18 00:32:36','2009-02-18 00:32:36');";
pg_query($pgc, $query);

// Insert Google Maps Mercator Projection into spatial_ref_sys, for reprojection.
pg_query($pgc, "INSERT into spatial_ref_sys (srid, auth_name, auth_srid, proj4text, srtext) values ( 96, 'sr-org', 6, '+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +wktext  +no_defs', 'PROJCS[\"unnamed\",GEOGCS[\"unnamed ellipse\",DATUM[\"unknown\",SPHEROID[\"unnamed\",6378137,0]],PRIMEM[\"Greenwich\",0],UNIT[\"degree\",0.0174532925199433]],PROJECTION[\"Mercator_2SP\"],PARAMETER[\"standard_parallel_1\",0],PARAMETER[\"central_meridian\",0],PARAMETER[\"false_easting\",0],PARAMETER[\"false_northing\",0],UNIT[\"Meter\",1],EXTENSION[\"PROJ4\",\"+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +wktext  +no_defs\"]]');");

pg_close($pgc);
?>