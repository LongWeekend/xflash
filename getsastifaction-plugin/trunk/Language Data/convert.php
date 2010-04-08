<?PHP

$res = mysql_connect("localhost","root","");
if (!$res) die("No db connection");
if (!mysql_select_db("transfer")) die ("couldnt select transfer DB");

// Set UTF
mysql_set_charset("utf8");

$level = "1";

$lines = file("jlpt-voc-".$level.".utf");
foreach ($lines as $line) {
	$items = explode(" ",$line);
	switch(count($items)) {
		case 1:
			// Kana word
			$headword = trim($items[0]);
			$reading = trim($items[0]);
			break;
		case 2:
			// "normal"?
			// First check that we have no parenthesis
			if (strpos($items[1],"（") !== false) {
				// We have kana word with parenthesis
				$headword = trim($items[0]);
				$reading = trim($items[0]);
				echo "¥n¥n<br><br>Gotcha: ";
				print_r($items);
			}
			else {
				$headword = trim($items[0]);
				$reading = trim($items[1]);
			}
			break;
		case 3:
			// Special
			$headword = trim($items[0]);
			$reading = trim($items[1]);
			echo "¥n¥n<br><br>Special: ";
			print_r($items);
			break;
	}
	$sql = "SELECT word_id FROM words WHERE headword LIKE '$headword' AND reading LIKE '$reading'";
	$foo = mysql_query($sql);
	if (mysql_num_rows($foo) == 0) {
		$sql = "INSERT INTO words (headword,reading,level) VALUES ('$headword','$reading',$level);";
		$foo = mysql_query($sql);
	}
	else echo "DUPE: ".$sql;
}
?>