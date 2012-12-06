<?php
/*
	iS MA HOS' NOOBISH?
	@author   NewEraCracker
	@version  2.5.6
	@date     2012/01/03
	@license  Public Domain
	@notes    newfags can't triforce
*/

// Config
$functionsToBeDisabled = array('link', 'symlink', 'system', 'shell_exec', 'passthru', 'exec', 'pcntl_exec', 'popen', 'proc_close', 'proc_get_status', 'proc_nice', 'proc_open', 'proc_terminate');
$functionsToBeEnabled = array('php_uname', 'base64_decode', 'fpassthru', 'ini_set');

// Init
$crlf = "\r\n";
$disabledFunctions = array_map("trim", explode(",",@ini_get("disable_functions")));
$issues = array();

// Functions to be disabled
foreach ($functionsToBeDisabled as $test)
{
	if(function_exists($test) && !(in_array($test, $disabledFunctions)))
		$issues[] = "Function ".$test." should be disabled!";
}
unset($test);

// Functions to be enabled
foreach ($functionsToBeEnabled as $test)
{
	if(!function_exists($test) || in_array($test, $disabledFunctions))
		$issues[] = "Function ".$test." should be enabled!";
}
unset($test);

// Do we have access to eval?
if( in_array("eval", $disabledFunctions) )
{
	$issues[] = "Language construct eval is required to be enabled in PHP!";
}

// dl (in)security
if( function_exists('dl') && !(in_array('dl', $disabledFunctions)) )
{
	if (ini_get('enable_dl'))
		$issues[] = "enable_dl should be Off!";
}

// Safe mode?
if (ini_get('safe_mode'))
	$issues[] = "Issue: safe_mode is On!";

// magic_quotes_gpc?
if (ini_get('magic_quotes_gpc'))
	$issues[] = "Issue: magic_quotes_gpc is On!";

// Output results
echo "<pre>";
if( !count($issues) )
{
	echo "Host is not noobish! Ready for use!";
}
else
{
	echo "Your host scored ".count($issues)." noobish points!".$crlf.$crlf;

	foreach($issues as $issue)
		echo "Issue: {$issue}".$crlf;
}
echo "</pre>";
?>
