#!/usr/bin/env perl 

#####################################
# xchat script to use with mpd
# V0.5 - Add album info
#      - Support unix sockets
#      - Remove netcat dependancies 
#      - Full socket usage

use strict;
use warnings;
use POSIX;
use File::Basename;
use IO::Socket;
use Xchat qw(:all);

##############
#[ CONFIG ]#####
##################

#my $prefix = "listening:";
#my $prefix = "is now playing";
#my $prefix = "is tripping to";
my $prefix = "♫";
my $suffix = "♫";

my $addr   = "localhost";
my $port   = "6600";
my $socket = "/tmp/.mpd.socket";

#################
##[ END ]######
#############

hook_command("np",       "mpdstatus");
hook_command("pause",    "mpdpause");
hook_command("play",     "mpdplay");
hook_command("next",     "mpdnext");
hook_command("previous", "mpdprevious");
hook_command("stop",     "mpdstop");

my $txt;

sub mpd_sock {
    my $param = "@_";
    my $sock;

    if(-S $socket) {
        $sock = IO::Socket::UNIX->new(Peer => $socket, Type => SOCK_STREAM);
    } else {
        $sock = IO::Socket::INET->new(PeerAddr => $addr, PeerPort => $port, Proto => 'tcp');
    }

    print $sock "$param\nclose\n";
    $sock->read($txt,1024);
    print $txt;
    close($sock);
}

sub mpdstatus {
    my ($status,$song,$tmpvar,$file,$artist,$album,$title,$time,$fullname,$bitrate,$state);
    my ($mcurrent,$scurrent,$mtotal,$stotal,$current,$total);

    mpd_sock("status");
    $status = $txt;
    mpd_sock("currentsong");
    $song = $txt;

    my @tab = split "\n", $status;
    my @tab1 = split "\n", $song;

    foreach $tmpvar (@tab1) {
        $file = $tmpvar if($tmpvar =~ s/file: //);
        $artist = $tmpvar if($tmpvar =~ s/Artist: //);
        $album = $tmpvar if($tmpvar =~ s/Album: //);
        $title = $tmpvar if($tmpvar =~ s/Title: //);
    }

    #mpd_sock("list");
    #my $shit = $txt;
    #my @tab2 = split "\n", $shit;
    #foreach $tmpvar (@tab2) {
    #    prnt($tmpvar);
    #}

    $file = basename($file);

    foreach $tmpvar (@tab) {
        $time = $tmpvar if($tmpvar =~ s/time: //);
        $bitrate = $tmpvar if($tmpvar =~ s/bitrate: //);
        $state = $tmpvar if($tmpvar =~ s/state: //);
    }
    
    if($state eq "stop") {
        prnt("Nothing playing");
        return;
    }

    my @time = split ":", $time;
    ($mcurrent,$scurrent) = (floor($time[0]/60), $time[0]%60);
    ($mtotal,$stotal) = (floor($time[1]/60), $time[1]%60);
    $mcurrent = "0" . $mcurrent if($mcurrent =~ /^\d$/);
    $scurrent = "0" . $scurrent if($scurrent =~ /^\d$/);
    $mtotal = "0" . $mtotal if($mtotal =~ /^\d$/);
    $stotal = "0" . $stotal if($stotal =~ /^\d$/);
    $current = $mcurrent . ":" . $scurrent;
    $total = $mtotal . ":" . $stotal;
    $artist = "Unknown" if($artist eq "");
    $title = "Unknown" if($title eq "");
    $fullname = $artist . "-»" . $album . " | " . $title;
    $fullname = $file if($artist eq "Unknown" && $title eq "Unknown");

    command("me $prefix $artist-»$album | $title [$current/$total] [$bitrate kbps] $suffix");
}

sub mpdpause {
	mpd_sock("pause");
}
sub mpdplay {
    mpd_sock("play");
}
sub mpdnext {
    mpd_sock("next");
}
sub mpdprevious {
    mpd_sock("previous");
}
sub mpdstop {
    mpd_sock("stop");
}

register("MPD Controler", "0.5", "Control MPD through XChat", "");
prnt "MPD Controller Loaded";
