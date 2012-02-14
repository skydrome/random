<?php

// Possible processors on Linux
$linux_proc = array(
    'i686',
    'x86_64'
);

// Mac processors (i also added U;)
$mac_proc = array(
    'Intel',
    'PPC',
    'U; Intel',
    'U; PPC'
);

// Add as many languages as you like.
$lang = array(
    'en-US',
    'sl-SI'
);

function firefox() {
    global $linux_proc, $mac_proc, $lang;

    $ver = array(
	'Gecko/' . date('Ymd', rand(strtotime('2011-1-1'), mktime())) . ' Firefox/' . rand(5, 7) . '.0',
	'Gecko/' . date('Ymd', rand(strtotime('2011-1-1'), mktime())) . ' Firefox/' . rand(5, 7) . '.0.1',
	'Gecko/' . date('Ymd', rand(strtotime('2010-1-1'), mktime())) . ' Firefox/3.6.' . rand(1, 20),
	'Gecko/' . date('Ymd', rand(strtotime('2010-1-1'), mktime())) . ' Firefox/3.8'
    );

    $platforms = array(
	'(Windows NT ' . rand(5, 6) . '.' . rand(0, 1) . '; ' . $lang[array_rand($lang, 1)] . '; rv:1.9.' . rand(0, 2) . '.20) ' . $ver[array_rand($ver, 1)],
	'(X11; Linux ' . $linux_proc[array_rand($linux_proc, 1)] . '; rv:' . rand(5, 7) . '.0) ' . $ver[array_rand($ver, 1)],
	'(Macintosh; ' . $mac_proc[array_rand($mac_proc, 1)] . ' Mac OS X 10_' . rand(5, 7) . '_' . rand(0, 9) . ' rv:' . rand(2, 6) . '.0) ' . $ver[array_rand($ver, 1)]
    );

    return $platforms[array_rand($platforms, 1)];
}

function safari() {
    global $linux_proc, $mac_proc, $lang;

    $saf = rand(531, 535) . '.' . rand(1, 50) . '.' . rand(1, 7);
    if (rand(0, 1) == 0) {
	$ver = rand(4, 5) . '.' . rand(0, 1);
    } else {
	$ver = rand(4, 5) . '.0.' . rand(1, 5);
    }

    $platforms = array(
	'(Windows; U; Windows NT ' . rand(5, 6) . '.' . rand(0, 1) . ") AppleWebKit/$saf (KHTML, like Gecko) Version/$ver Safari/$saf",
	'(Macintosh; U; ' . $mac_proc[array_rand($mac_proc, 1)] . ' Mac OS X 10_' . rand(5, 7) . '_' . rand(0, 9) . ' rv:' . rand(2, 6) . '.0; ' . $lang[array_rand($lang, 1)] . ") AppleWebKit/$saf (KHTML, like Gecko) Version/$ver Safari/$saf",
	'(iPod; U; CPU iPhone OS ' . rand(3, 4) . '_' . rand(0, 3) . ' like Mac OS X; ' . $lang[array_rand($lang, 1)] . ") AppleWebKit/$saf (KHTML, like Gecko) Version/" . rand(3, 4) . ".0.5 Mobile/8B" . rand(111, 119) . " Safari/6$saf",
    );

    return $platforms[array_rand($platforms, 1)];
}

function iexplorer() {
    $ie_extra = array(
	'',
	'; .NET CLR 1.1.' . rand(4320, 4325) . '',
	'; WOW64'
    );
    $platforms = array(
	'(compatible; MSIE ' . rand(5, 9) . '.0; Windows NT ' . rand(5, 6) . '.' . rand(0, 1) . '; Trident/' . rand(3, 5) . '.' . rand(0, 1) . ')'
    );

    return $platforms[array_rand($platforms, 1)];
}

function opera() {
    global $linux_proc, $lang;

    $op_extra = array(
	'',
	'; .NET CLR 1.1.' . rand(4320, 4325) . '',
	'; WOW64'
    );
    $platforms = array(
	'(X11; Linux ' . $linux_proc[array_rand($linux_proc, 1)] . '; U; ' . $lang[array_rand($lang, 1)] . ') Presto/2.9.' . rand(160, 190) . ' Version/' . rand(10, 12) . '.00',
	'(Windows NT ' . rand(5, 6) . '.' . rand(0, 1) . '; U; ' . $lang[array_rand($lang, 1)] . ') Presto/2.9.' . rand(160, 190) . ' Version/' . rand(10, 12) . '.00'
    );

    return $platforms[array_rand($platforms, 1)];
}

function chrome() {
    global $linux_proc, $mac_proc;

    $saf = rand(531, 536) . rand(0, 2);

    $platforms = array(
	'(X11; Linux ' . $linux_proc[array_rand($linux_proc, 1)] . ") AppleWebKit/$saf (KHTML, like Gecko) Chrome/" . rand(13, 15) . '.0.' . rand(800, 899) . ".0 Safari/$saf",
	'(Windows NT ' . rand(5, 6) . '.' . rand(0, 1) . ") AppleWebKit/$saf (KHTML, like Gecko) Chrome/" . rand(13, 15) . '.0.' . rand(800, 899) . ".0 Safari/$saf",
	'(Macintosh; U; ' . $mac_proc[array_rand($mac_proc, 1)] . ' Mac OS X 10_' . rand(5, 7) . '_' . rand(0, 9) . ") AppleWebKit/$saf (KHTML, like Gecko) Chrome/" . rand(13, 15) . '.0.' . rand(800, 899) . ".0 Safari/$saf"
    );

    return $platforms[array_rand($platforms, 1)];
}

// Choose a random browser
function random_uagent() {
    $x = rand(1, 5);
    switch ($x) {
	case 1:
	    echo "Mozilla/5.0 " . firefox() . "\n";
	    break;
	case 2:
	    echo "Mozilla/5.0 " . safari() . "\n";
	    break;
	case 3:
	    echo "Mozilla/" . rand(4, 5) . ".0 " . iexplorer() . "\n";
	    break;
	case 4:
	    echo "Opera/" . rand(8, 9) . '.' . rand(10, 99) . ' ' . opera() . "\n";
	    break;
	case 5:
	    echo 'Mozilla/5.0' . chrome() . "\n";
	    break;
    }
}

random_uagent();
?>
