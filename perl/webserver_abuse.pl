#!/usr/bin/perl

use strict;
use warnings;

## Calomel.org .:. https://calomel.org
##   name     : web_server_abuse_detection.pl
##   version  : 0.03

## Description: this script will watch the web server logs (like Apache or
## Nginx) and count the number of http error codes an ip has triggered. At a user
## defined amount of errors we can execute an action to block the ip using our
## local firewall software.

## which log file do you want to watch?
  my $log = "/var/log/nginx/access.log";

## how many errors can an ip address trigger before we block them?
  my $errors_block = 10;

## how many seconds before an unseen ip is considered old and removed from the hash?
  my $expire_time = 7200;

## how many error log lines before we trigger clean up of old ips in the hash?
  my $cleanup_time = 10;

## do you want to debug the scripts output ? on=1 and off=0
  my $debug_mode = 1;

## declare some internal variables and the hash of abusive ip addresses
  my ( $ip, $errors, $time, $newtime, $newerrors );
  my $trigger_count=1;
  my %abusive_ips = ();

## open the log file. we are using the system binary tail which is smart enough
## to follow rotating logs. We could have used File::Tail, but tail is easier.
## Tail "-f" should work for you, but you may want to use the "--follow" line
## _if_ you "man tail" page in linux says it is best to follow rotating log files.
 #open(LOG,"tail --follow=$log |") || die "Failed!\n"; ## For Linux (Ubuntu) systems
  open(LOG,"tail -f $log |") || die "Failed!\n";       ## For OpenBSD, FreeBSD or Linux systems

  while(<LOG>) {
       ## process log line if it contains one of these error codes. This is the regular
       ## expression we are looking for on each line. This is the line you want to edit
       ## to add or delete conditions. For example, to look for .vbs file access and
       ## consider that a blocking condition. 
       if ($_ =~ m/( 401 | 402 | 403 | 404 | 405 | 406 | 407 | 409 | 410 | 411 | 412 | 413 | 414 | 415 | 416 | 417 | 444 | 500 | 501 | 502 | 503 | 504 | 505 )/)
         {

       ## USER EDIT: Whitelisted ips. This is where you can whitelist ip addresses
       ## that cause errors, but you do NOT want them to be blocked. Googlebot at
       ## 66.249/16 is a good example. We also whitelisted the private subnet 192.168/16
       ## so that web developers inside the firewall can test and never be blocked. 
        if ($_ !~ m/(^66\.249\.\d{1-3}\.d{1-3}|^192\.168\.\d{1-3}\.d{1-3})/)
        {

         ## extract the ip address from the log line and get the current unix time
          $time = time();
          $ip = (split ' ')[0];

         ## if an ip address has never been seen before we need
         ## to initialize the errors value to avoid warning messages.
          $abusive_ips{ $ip }{ 'errors' } = 0 if not defined $abusive_ips{ $ip }{ 'errors' };

         ## increment the error counter and update the time stamp for the bad ip.
          $abusive_ips{ $ip }{ 'errors' } = $abusive_ips{ $ip }->{ 'errors' } + 1;
          $abusive_ips{ $ip }{ 'time' } = $time;

         ## DEBUG: show detailed output
         if ( $debug_mode == 1 ) {
           $newerrors  = $abusive_ips{ $ip }->{ 'errors' };
           $newtime = $abusive_ips{ $ip }->{ 'time' };
           print "unix_time:  $newtime, errors:  $newerrors, ip:  $ip, cleanup_time: $trigger_count\n";
         }

         ## if an ip has triggered the $errors_block value we block them and do something with the system() call.
          if ($abusive_ips{ $ip }->{ 'errors' } >= $errors_block ) {

             ## DEBUG: show detailed output
             if ( $debug_mode == 1 ) {
               print "ABUSIVE IP! unix_time:  $newtime, errors:  $newerrors, ip:  $ip, cleanup_time: $trigger_count\n";
             }

             ## USER EDIT: this is the system() call you will set to block the abuser. You can add the command
             ##  line you want to execute outside of this script against the ip address of the abuser. For example,
             ##  we are using logger to echo the line out to /var/log/messages and then we are adding the offending
             ##  ip address to our OpenBSD Pf table which we have setup to block ips at the Pf firewall. As an example
             ##  we have commented out the line to block the ip using iptables in linux too.  
            #system("logger '$ip blocked by calomel abuse detection'; iptables -I INPUT -s $ip -j DROP");
             system("logger '$ip blocked by calomel abuse detection'; pfctl -t BLOCKTEMP -T add $ip");

             ## after the ip is blocked it does not need to be in the hash anymore
             delete($abusive_ips{ $ip });
          }

         ## increment the trigger counter which is used for the following clean up function. 
          $trigger_count++;

         ## clean up function: when the trigger counter reaches the $cleanup_time we
         ## remove any expired hash entries from the $abusive_ips hash
          if ($trigger_count >= $cleanup_time) {
             my $time_current =  time();

             ## DEBUG: show detailed output
             if ( $debug_mode == 1 ) {
               print "  Clean up... pre-size of hash:  " . keys( %abusive_ips ) . ".\n";
             }

              ## clean up ip addresses we have not seen in a long time
               while (($ip, $time) = each(%abusive_ips)){

               ## DEBUG: show detailed output
               if ( $debug_mode == 1 ) {
                 my $total_time = $time_current - $abusive_ips{ $ip }->{ 'time' };
                 print "    ip: $ip, seconds_last_seen: $total_time, errors:  $newerrors\n";
               }

                  ## if the time the ip has been absent is greater then the expire time we
                  ## remove this ip from the hash.
                  if ( ($time_current - $abusive_ips{ $ip }->{ 'time' } ) >= $expire_time) {
                       delete($abusive_ips{ $ip });
                  }
               }

            ## DEBUG: show detailed output
            if ( $debug_mode == 1 ) {
               print "   Clean up.... post-size of hash:  " . keys( %abusive_ips ) . ".\n";
             }

             ## reset the clean up trigger counter
              $trigger_count = 1;
          }
         }
        }
  }
#### EOF ####
