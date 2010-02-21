<?PHP

$res = mysql_connect("localhost","root","");
if (!$res) die("No db connection");
if (!mysql_select_db("transfer")) die ("couldnt select transfer DB");

set_time_limit(0);

// Set UTF
mysql_set_charset("utf8");

$level = "1";

// Now open up the sqlite DB
$sql3 = new SQLite3('/Users/Ross/iPhone/jFlash/sql/jFlash.db');

$myStr = "SELECT * FROM words WHERE level = '$level'";
$foo = mysql_query($myStr);
while ($row = mysql_fetch_assoc($foo)) {
	$headword = $row['headword'];
	$reading = $row['reading'];
	
	// Try the direct match first
	$card_id = $sql3->querySingle("SELECT card_id FROM cards_ja WHERE headword LIKE '$headword' AND reading LIKE '$reading'");
	if ($card_id > 0) {
		// Match, insert
		$insertQuery = "INSERT INTO matches (word_id,card_id) VALUES ('".$row['word_id']."','".$card_id."')";
		mysql_query($insertQuery);
	}
	else {
		// Try the one-hand match second (e.g. kanji), but display it
		$card_id = $sql3->querySingle("SELECT card_id FROM cards_ja WHERE headword LIKE '$headword'");
		if ($card_id > 0) {
			// Match, insert
			$insertQuery = "INSERT INTO matches (word_id,card_id) VALUES ('".$row['word_id']."','".$card_id."')";
			mysql_query($insertQuery);
		}
		else {
			// Try the one-hand match third on the reading only
			$card_id = $sql3->querySingle("SELECT card_id FROM cards_ja WHERE reading LIKE '$reading'");
			if ($card_id > 0) {
				// Match, insert
				$insertQuery = "INSERT INTO matches (word_id,card_id,quality) VALUES ('".$row['word_id']."','".$card_id."',0)";
				mysql_query($insertQuery);
			}
			else {
		 		// No match
		 		echo "No match: ".$headword."<br />";
			}
		}
	}
}

?>