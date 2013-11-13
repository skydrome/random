#!/usr/bin/env perl
use strict;
use warnings;

use Carp qw(croak);
use Digest::MD5 qw(md5_hex);
use Geo::Distance;
use Getopt::Long qw(:config auto_help);
use LWP::UserAgent;
use Pod::Usage;
use XML::LibXML;

GetOptions(
    'd=f' => \my $down,
    'u=f' => \my $up,
    'p=i' => \my $ping,
) or pod2usage(2);
pod2usage(2) unless 3 == grep defined, $down, $up, $ping;
for ($down, $up) {
    pod2usage(2) unless 0 < $_ and 1_000 > $_;
}

my $ua = LWP::UserAgent->new(
    agent => 'Mozilla/6.0 (Windows; U; Windows NT 6.1; en-US; rv:1.9.2.3) Gecko/20110401 Firefox/10',
);

my $time = time . sprintf "%03d", int rand(999);
my $dom = parse_config("http://speedtest.net/speedtest-config.php?x=$time");
my ($node) = $dom->findnodes('/settings/client');
my ($clat, $clon) = map { $node->findvalue("\@$_") } qw(lat lon);

# Get closest server relative to our geoip lat/longitude
$dom = parse_config("http://speedtest.net/speedtest-servers.php?x=$time");
my $geo = Geo::Distance->new;
my ($server, $distance);
for my $node ($dom->findnodes('/settings/servers/server')) {
    my ($id, $slat, $slon) = map { $node->findvalue("\@$_") } qw(id lat lon);
    my $d = $geo->distance(mile => $clon, $clat, $slon, $slat);
    if (not defined $distance or $d < $distance) {
        $server   = $id;
        $distance = $d;
    }
}
die 'Couldnt get a server to use' unless $server;

$_ *= 1_000 for ($up, $down);

my $salt = '297aae72';
my $hash = md5_hex(sprintf '%s-%s-%s-%s', $ping, $up, $down, $salt);
my $res = $ua->post(
    'http://www.speedtest.net/api/api.php',
    referer => 'http://c.speedtest.net/flash/speedtest.swf',
    content => [
        startmode           => 'recommendedselect',
        promo               => '',
        upload              => $up,
        accuracy            => 7 + int rand(20),  # ?
        recommendedserverid => $server,
        serverid            => $server,
        ping                => $ping,
        hash                => $hash,
        download            => $down,
    ]
);

die $res->dump if $res->is_error;
my %data = map { split '=' } split '&', $res->decoded_content;
die "SpeedTest.net rejected our data :(" unless $data{resultid};

printf "http://www.speedtest.net/my-result/%s\n", $data{resultid};
printf "http://speedtest.net/result/%s.png (deprecated)\n", $data{resultid};
exit;


sub parse_config {
    my ($url) = @_;
    my $res = $ua->get($url);
    croak $res->status_line if $res->is_error;

    my $xml = $res->decoded_content;
    return eval { XML::LibXML->new(recover => 2)->parse_string($xml) };
}

__END__

=head1 NAME
fake-speedtest.pl

=head1 SYNOPSIS

  fake-speedtest.pl OPTIONS
  Options:
    -d  Download speed (Mb/s) greater than 0 less then 1000
    -u  Upload speed
    -p  Ping latency (ms)

=cut