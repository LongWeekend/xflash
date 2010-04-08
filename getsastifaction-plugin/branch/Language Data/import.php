<?PHP

$res = mysql_connect("localhost","root","");
if (!$res) die("No db connection");
if (!mysql_select_db("transfer")) die ("couldnt select transfer DB");

set_time_limit(0);

// Set UTF
mysql_set_charset("utf8");

$level = "1";

// Now open up the sqlite DB
$sql3 = new SQLite3('/Users/Ross/iPhone/jFlash/sql/jFlash.db',SQLITE3_OPEN_READWRITE);

$myStr = "SELECT * FROM tag_link";
$foo = mysql_query($myStr);
while ($row = mysql_fetch_assoc($foo)) {
	$tag = $row['tag_id'];
	$card = $row['card_id'];	
	echo "INSERT INTO card_tag_link (tag_id,card_id) VALUES ('$tag','$card'); <br />";
}

?>