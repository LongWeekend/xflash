<?PHP

// Generates "num" random user history data records for Japanese Flash card_id updates
// and writes the SQL statements out to file specified by "output" argument

$argument = getopt("n:o:");
$numToGenerate = $argument['n'];
$outputFilename = $argument['o'];

if (empty($numToGenerate) || empty($outputFilename))
{
	echo "Generates random user history data records for Japanese Flash card_id update testing\n";
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

// Get to it
$user_history = array();
for ($i = 0; $i < $numToGenerate; $i++)
{
	$levelId = rand(1,5);
	$cardId = rand(0,147000);
	$wrongCount = rand(0,10);
	$rightCount = rand(0,10);
	$user_history[]  = "INSERT INTO user_history (card_id, timestamp, user_id, right_count, wrong_count, created_on, card_level) VALUES ('$cardId',current_timestamp,'1','$rightCount','$wrongCount',current_timestamp,'$levelId');";
}

$endingStatements = array();
$endingStatements[] = "ANALYZE;";

foreach($user_history as $sql)
{
	fwrite($fh,$sql."\n");
}

foreach($endingStatements as $sql)
{
	fwrite($fh,$sql."\n");
}
fclose($fh);
?>
