<?php
/*
	Suhosin Configuration Checker
	@author  NewEraCracker
	@version 0.5.4
	@date    2012/01/03
	@license Public Domain
*/

/* -------------
   Configuration
   ------------- */

// Value has to be the same or higher to pass tests
$test_values = array(
	array( 'suhosin.get.max_name_length', 512 ),
	array( 'suhosin.get.max_totalname_length', 512 ),
	array( 'suhosin.get.max_value_length', 1024 ),
	array( 'suhosin.post.max_array_index_length', 256 ),
	array( 'suhosin.post.max_name_length', 512 ),
	array( 'suhosin.post.max_totalname_length', 8192 ),
	array( 'suhosin.post.max_vars', 4096 ),
	array( 'suhosin.post.max_value_length', 1000000 ),
	array( 'suhosin.request.max_array_index_length', 256 ),
	array( 'suhosin.request.max_totalname_length', 8192 ),
	array( 'suhosin.request.max_vars', 4096 ),
	array( 'suhosin.request.max_value_length', 1000000 ),
	array( 'suhosin.request.max_varname_length', 512 ),
);

// Value has to be false to pass tests
$test_false = array(
	'suhosin.sql.bailout_on_error',
	'suhosin.cookie.encrypt',
	'suhosin.session.encrypt',
);

/* ---------
   Main code
   --------- */

$informations = $problems = array();

if( !extension_loaded('suhosin') )
{
	$informations[] = "<b>There is no Suhosin in here :)</b>";
}
else
{
	$informations[] = "<b>Suhosin installation detected!</b>";

	foreach($test_false as $test)
	{
		if( ini_get($test) != false )
			$problems[] = "Please ask your host to <b>disable (turn off) {$test}</b> in php.ini.";
	}
	foreach($test_values as $test)
	{
		if( isset($test['0']) && isset($test['1']) )
		{
			if( ini_get($test['0']) < $test['1'])
				$problems[] = "Please ask your host to set <b>{$test['0']}</b> in php.ini to <b>{$test['1']}</b> or higher.";
		}
	}
	if( !count($problems) )
		$informations[] = "<b>No problems detected!</b>";
}

echo "<pre>";
foreach($informations as $info)
	echo $info."\r\n";

foreach($problems as $problem)
	echo $problem."\r\n";

echo "</pre>";
?>
