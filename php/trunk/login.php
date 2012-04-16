<?php

/* This is a partially-implemented stub for handling user logins.  There is no security
 * implemented.  The script will accept a username and password, check for a valid login, and
 * will generate a session token (and insert it into the sessions table) for the user.  If the
 * user is already logged in, it will simply update the sessions table with updated timestamps.
 */

require_once("include.php");
global $session_id;
$username = $_REQUEST["username"];
$password = $_REQUEST["password"];

$pgc = postgis_connect();

@$result = pg_query($pgc, "SELECT u.id FROM $postgis_table_users as u WHERE username='$username' AND password='$password' AND username != 'public';");
if (!$result) die("0");
global $user_id, $user_data;
if(pg_num_rows($result) == 0 || $username == "public") die("0");
while ($row = pg_fetch_row($result)) {
	$user_id = $row[0];
}
pg_free_result($result);
//if($user_pass != $password) die("0");
@$result = pg_query($pgc, "SELECT token FROM $postgis_table_sessions WHERE user_id='$user_id';");
if(!$result) die("0");
$breakout = 0;
if(pg_num_rows($result) != 0) {
	$row = pg_fetch_row($result);
	$token = $row[0];
	$time = timestamp();
	@$result2 = pg_query("UPDATE $postgis_table_sessions SET time_accessed='$time' WHERE user_id='$user_id';");
	if(!$result) die("0");
	pg_free_result($result2);
	$breakout = 1;
}
pg_free_result($result);
while(!$breakout) {
	$token = generate_token();
	$time = timestamp();
	$qstr = "INSERT INTO $postgis_table_sessions(token,user_id,time_created,time_accessed)
	VALUES('$token',$user_id,'$time','$time');";
	@$result = pg_query($pgc, $qstr);
	if($result) {
		pg_free_result($result);
		$breakout = 1;
	}
}
echo $token;
pg_close($pgc);
?>