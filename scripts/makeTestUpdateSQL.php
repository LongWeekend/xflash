<?PHP

// Generates "num" random SQL update statements for Japanese Flash card_id updates
// and writes the SQL statements out to file specified by "output" argument

$argument = getopt("n:o:");
$numToGenerate = $argument['n'];
$outputFilename = $argument['o'];

if (empty($numToGenerate) || empty($outputFilename))
{
	echo "Generates random SQL update statements for Japanese Flash card_id update testing\n";
	echo "Usage: -n NumToGenerate -o outputFilename\n";
	exit();
}


if (!is_numeric($numToGenerate) && $numToGenerate > 0)
{
	die("incorrect input");
}

$fh = fopen($outputFilename,"w");
if (!$fh)
{
	die("Unable to open output file $outputFilename for writing");
}

$beginStatements = array();
$beginStatements[] = "ALTER TABLE user_history ADD COLUMN updated BOOL DEFAULT 0;";
$beginStatements[] = "ALTER TABLE card_tag_link ADD COLUMN updated BOOL DEFAULT 0;";

// Get to it
$oldCardIdArray = array();
$newCardIdArray = array();
$user_history = array();
$card_tag_link = array();
for ($i = 0; $i < $numToGenerate; $i++)
{
	$oldCardId = rand(1,147000); 
	$newCardId = rand(1,147000);
	while (in_array($newCardId,$newCardIdArray))
	{
		$newCardId = rand(1,147000);
	}
	$newCardIdArray[] = $newCardId;
	$user_history[]  = "UPDATE user_history SET card_id = '$newCardId', updated = '1' WHERE updated = '0' AND card_id = '$oldCardId';";
	$card_tag_link[] = "UPDATE card_tag_link SET card_id = '$newCardId', updated = '1' WHERE updated = '0' AND card_id = '$oldCardId';";
}

$endingStatements = array();
$endingStatements[] = "UPDATE user_history SET updated = NULL;";
$endingStatements[] = "UPDATE card_tag_link SET updated = NULL;";
$endingStatements[] = "ALTER TABLE main.cards_html RENAME TO old_cards_html;";
$endingStatements[] = "ALTER TABLE main.cards RENAME TO old_cards;";
//$endingStatements[] = "ALTER TABLE main.cards_search_content RENAME TO old_cards_search_content;";
$endingStatements[] = "ANALYZE;";

foreach($beginStatements as $sql)
{
	fwrite($fh,$sql."\n");
}

foreach($user_history as $sql)
{
	fwrite($fh,$sql."\n");
}

foreach($card_tag_link as $sql)
{
	fwrite($fh,$sql."\n");
}

foreach($endingStatements as $sql)
{
	fwrite($fh,$sql."\n");
}
fclose($fh);
?>
