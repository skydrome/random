#Please read the end of the file for notes and more information
use strict;
use warnings;
use Xchat qw(:all);

my %XCHAT = (
	"author"      => 'culb',
	"contact"     => 'dat727boi[at]gmail.com or culb[at]mindboggle.us',
	"name"        => 'Linux sysinfo',
	"description" => 'Display to a channel or PM your systems information',
	"license"     => 'Include my name and contact info if you use ANY of my ideas and original creators.',
	"version"     => '002'
);

#--USER VARIABLES THAT MUST BE SET BEFORE USING THIS SCRIPT--#

#set to 1 if you have an nvidia card
#set to 0 if you do not have an nvidia card
my $enable_nvidia = 0;

#set to 1 if you have sensors configured on your system
#set to 0 if you do NOT have sensors configured on your system
my $enable_sensors = 1;

#set to 1 if you have a hard drive that has S.M.A.R.T. support and you want to display the temp
#set to 0 if you have a hard drive that does NOT have S.M.A.R.T. support
my $enable_hddtemp = 1;

#Set the drive to get the info from
my $smart_d = '/dev/sda';

#my $sudo = '';
my $sudo = 'sudo';

#--NO USER INTERVENTION NEEDED BEYOND THIS POINT--#

#--Global variables--#
my $global_uptime;
my $global_cpu;
my $global_cpu_number;
my $global_memory;
my $global_scsi;
my $global_scsi_all;
my $global_nvidia;

#extra path
$ENV{'PATH'} = "/usr/sbin:$ENV{'PATH'}";

sub file_executable	{
	my $command = shift;
	my @directories = split( /:/, $ENV{'PATH'} );
		for my $var ( @directories ) {
			if ( -x "$var/$command" ) {
				return 1;
			}
		}
	return 0;
}

sub system_version {
	open  ( X, '/proc/version' ) or prnt "\002" . 'ERROR: ' . "\002" . "$!" . "( sub: system_version )" . " Line:" . __LINE__ and return '0';
	my $uname = <X>;
	close (X);

	$uname =~ s/^(\S+) \S+ (\S+) .*\n$/$1 $2/;
	my $os = $1;
	my $kernel = $2;
	return ( $os, $kernel ); 
}

sub system_processor {
	my $CPU = 0;
	my $NUM = 0;
	my $MIPS = 0;
	my $MODEL = 'Single';

	open ( X, '/proc/cpuinfo' ) or prnt "\002" . 'ERROR: ' . "\002" . "$!" . "( sub: system_processor )" . " Line:" . __LINE__ and return '0';
	while ( <X> ) {
		if ( /^(cpu model|model name).*: (.*)\n$/ ) {
			$MODEL = $2;
			$MODEL =~ s/\s+/ /g;
			$NUM += 1;
		}
			elsif ( !$CPU && /^cpu MHz.*: (.*)\n$/ ) {
				$CPU = $1;
			}
				elsif (/^bogomips.*: (.*)\n$/i) {
					$MIPS += $1;
				}
					elsif (/^cpu cores\s+:\s+(.*)$/i) {
						if ( $1 > 1 ) {
							$NUM = $1
						}
					}
	}
    close (X);

    #--SUPPORT FOR MULTIPLE PROCS--#
	 $MODEL = "2x $MODEL" if $NUM == 2;
	 $MODEL = "4x $MODEL" if $NUM == 4;

    # Fix for Linux/Mips
	my $VGA = 'unknown';
	if ( !$CPU ) {
	open ( X, '/var/log/dmesg' ) or prnt "\002" . 'ERROR: ' . "\002" . "$!" . "( sub: system_processor )" . " Line:" . __LINE__ and return '0';
		while ( <X> ) {
			if ( /\ \[?(\d+\.\d+) MHz (CPU|processor)/ ) { 
				$CPU = $1;
			}
				if ( /^Console: (.*) \d+x\d+/ ) { 
					$VGA = $1;
				}
		}
		close (X);
	}
	$global_cpu = $CPU;
	$global_cpu_number = $NUM;
	return ( $MODEL, $CPU, $MIPS, $NUM );	
}

sub system_memory {
	my $memused = 0;
	my $memfree = 0;
	my $memtotal = 0;
	my $total_mem = 0;
	my $memfreepercent = 0;
	my $memusedpercent = 0;
	my $memtotalpercent = 0;
	open( X, '/proc/meminfo' ) or prnt "\002" . 'ERROR: ' . "\002" . "$!" . "( sub: system_memory )" . " Line:" . __LINE__ and return '0';
	while( <X> ) {
		chomp;
		if(/^MemTotal:\s+(\d+)/){
			$memtotal = sprintf("%.0f",$1/1024);
		}
			elsif ( /^MemFree:\s+(\d+)/ ) {
				$memfree = sprintf("%.0f",$1/1024);
			}
				elsif ( /^Buffers:\s+(\d+)/ ) {
					$memfree += sprintf("%.0f",$1/1024);
				}
					elsif ( /^Cached:\s+(\d+)/ ) {
						$memfree += sprintf("%.0f",$1/1024);
					}
    }
    close( X );
	$memused = $memtotal - $memfree;
	$global_memory = $memtotal;
	$total_mem = $memtotal;
    #Percents
	$memfreepercent = sprintf( "%.2f", ( $memfree / $memtotal * 100 ) );
	$memusedpercent = sprintf( "%.2f", ( $memused / $memtotal * 100 ) );
	$memtotalpercent = sprintf( "%.2f", ( $memtotal / $memtotal * 100 ) );
	#Graph
	my $FREEBAR = int( $memfreepercent / 10 );
	my $membar;
	my $x;
	$membar = "\002\[\002";
	for ( $x = 0; $x < 10; $x++ ) {
        if ( $x == $FREEBAR ) {
	    $membar .= "\002";
		}
		$membar .= "\|";
	}
    $membar .= "]";
	$memused .= ' MB';
	$memfree .= ' MB';
	$memtotal .= ' MB';
	return ( $memtotal, $memfree, $memused, $memfreepercent, $memusedpercent, $memtotalpercent, $membar, $total_mem );
}

sub system_hard_drive {
	my $HDD = 0;
	my $HDDFREE = 0;
	my $HDDFREE2 = 0;
	my $HDDFREEPERC = 0;
	my $SCSI = 0;
	my $SCSIFREE = 0;
	for ( `df` ) {
		if ( /^\/dev\/(ida\/c[0-9]d[0-9]p[0-9]|[sh]d[a-z][0-9]+)\s+(\d+)\s+\d+\s+(\d+)\s+\d+%/ ) {
			$HDD += $2;
			$HDDFREE += $3;
		}
			if ( /^\/dev\/(ida\/c[0-9]d[0-9]p[0-9]|sd[a-z][0-9]+)\s+(\d+)\s+\d+\s+(\d+)\s+\d+%/ ) {
				$SCSI += $2;
				$SCSIFREE += $3;
			}
	}
	my $ALL = $HDD;
	$HDDFREE2 = sprintf("%.02f", $HDDFREE / 1048576)."G";
	$HDDFREEPERC = sprintf("%.02f", ( $HDDFREE / $HDD * 100 ) ); #return percentage instead
	$HDD = sprintf("%.02f", $HDD / 1048576)."G";
	$global_scsi = $SCSI;
	$global_scsi_all = $ALL;
	return ( $HDD, $HDDFREE2, $HDDFREEPERC, $SCSI, $ALL );
}

sub system_processes {
	opendir( PROC, '/proc' ) or prnt "\002" . 'ERROR: ' . "\002" . "$!" . "( sub: system_processes )" . " Line:" . __LINE__ and return '0';
	my $proc = scalar grep( /^\d/,readdir PROC );
	close ( PROC );
	return $proc;
}

sub system_uptime {
	my $up = 0;
	my $time = 0;
	my $uptime = 0;
	open( X, '/proc/uptime' ) or prnt "\002" . 'ERROR: ' . "\002" . "$!" . "( sub: system_uptime )" . " Line:" . __LINE__ and return '0';
	$uptime = <X>;
	close ( X );
		if ( $uptime ne 0 ) {
	    $uptime =~ s/(\d+\.\d+)\s\d+\.\d+/$1/;
	    my $days = int( $uptime / 86400 );
		    for my $var ( [31536000, "yr"], [604800, "wk"], [86400, "day"], [3600, "hr"], [60, "min"], [1, "sec"] ) {
				$time = sprintf ( "%.1d", $uptime / $var->[0] ) or 0;
				$uptime -= ( $time * $var->[0] );
				$up .= $time =~ /^1$/ ? "$time $var->[1]" : "$time $var->[1]s" if $time;
		    }
		}		    
	$global_uptime = $uptime;
	return ( $up, $uptime );
}

sub system_loadavg {
	if ( open( X, '/proc/loadavg' ) ) {
	my $LOADAVG = <X>;
	close ( X );
	$LOADAVG =~ s/^((\d+\.\d+\s){3}).*\n$/$1/;
	return $LOADAVG;
    }
}

sub system_graphic_card {
	my $vga = 'unknown';
    if ( file_executable( 'lspci' ) ) {
		for ( `lspci` ) {
			if ( /VGA compatible controller:\s(.*)$/ ) {
				$vga = $1;
			}
		}
	}
		elsif ( -e '/proc/pci' ) {
			open( X, "/proc/pci" ) or prnt "\002" . 'ERROR: ' . "\002" . "$!" . "( sub: system_graphic_card )" . " Line:" . __LINE__ and return '0';
				while ( <X> ) {
					chomp;
					if ( /VGA compatible controller:\s(.*)\.$/ ) {
						$vga = $1;
					}
				}
			close( X );
		}
	return $vga;
}

sub system_screen_res {
	my $dimensions = 0;
	my $depth = 0;
	if ( file_executable( 'xdpyinfo' ) ) {
		for ( `xdpyinfo` ) {
			if ( /\s+dimensions:\s+(.+)/ ) {
				$dimensions = $1;
			}
				elsif ( /\s+depth:\s+(\S+)/ ) {
					$depth = $1;
				}
		}
		if ( $depth ) {
			return ( $dimensions, $depth );
		}
	}
}

sub system_network {
    my $in = 0;
    my $out = 0;	
	my $route = "";
	my $netdev = "";
	my $netdevice = "lo";

	open( X, '/proc/net/route' ) or $route = "NA";
    while ( <X> ) {
    	chomp;
    	if (/^(.*?)\s+\d+\s+.*\s+0003\s+\d\s+/)
		{ $netdevice = $1; }
    }
    close( X );

    if ( open( X, '/proc/net/dev' ) ) {
	while ( <X> ) {
		chomp;
		if ( /^(\s+)?$netdevice/ ) {
		/^\s+(.*?):(\s+|)(\d+)\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+(\d+)\s+/;
		$in = sprintf( "%.2f",$3 / 1048576 );
		$out = sprintf( "%.2f",$4 / 1048576 );
		}
	}
	close( X );
	if ( $in < 1024 ) {
		$in .= "M";
	}
	else {
		$in = sprintf( "%.02f", $in / 1024 ) . "G";
	}
		if ( $out < 1024 ) {
			$out .= "M";
		}
		else {
			$out = sprintf( "%.02f", $out / 1024 ) . "G";
		}
	return ( $netdevice, $in, $out );
    }
} 


sub system_nvidia_nvclock {
	my $nvc = 0;
	my $nvc2 = 0;
	my $nvt = 0;
	my $nvt2 = 0;
	my $nvt3 = 0;
	my $nvt4 = 0;
	if ( file_executable( 'nvclock' ) ) {
		$global_nvidia = 1;
		for ( `$sudo nvclock -s` ) {
#	if (/^C.*ore speed:\s+(\d+\.\d+\sMHz)$/){
			if ( /^Coolbits 3D:\s+(\d+\.\d+\sMHz)\s+(\d+\.\d+\sMHz)$/ ) {
				$nvc = $1;
				$nvc2 = $2;
			}
				for ( `$sudo nvclock -T` ) {
					if ( /^=> GPU temperature:\s+(\d+)C$/){
						$nvt  = $1;
						$nvt2 = $nvt * 1.8 + 32;
						$nvt  .= 'C';
						$nvt2 .= 'F';
					}
						if ( /^=> Board temperature:\s+(\d+)C$/ ) {
							$nvt3 = $1;
							$nvt4 = $nvt3 * 1.8 + 32;
							$nvt3 .= 'C';
							$nvt4 .= 'F';
						}
				}
		}
	}
		elsif ( ! file_executable( 'nvclock' ) ) {
			#Could use qq{} so only one print is emitted but this is cleaner looking
			prnt "\002Could not access Nvidia information because nvclock is not executable.";
		#	prnt( "\002As root: chmod +x `which nvclock` (sudo chmod +x `which nvclock`) on MOST system should resolve this issue" );
		}
	return ( $nvc, $nvc2, $nvt, $nvt2, $nvt3, $nvt4 );
}

sub system_temp_sensors {
	my $sensor1 = "NA";
	my $sensor2 = "NA";
	my $sensor3 = "NA";
	my $sensor4 = "NA";

	if ( file_executable( 'sensors' ) ) {
		for ( `sensors` ) {
			if ( /^[tT]emp2.*:\s+(.*(\s|.|)[FC])\s+\(.*\)(\s+ALARM)?/ ) {
				if (!$2) {
					$sensor1 = " $1";
				} 
				else {
					$sensor1 = " $1";
				}
			}
				elsif ( /^[tT]emp1.*:\s+(.*(\s|.|)[FC])\s+\(.*\)(\s+ALARM)?/ ) {
					if ( !$2 ) {
						$sensor2 = " $1";
					} 
					else { 
						$sensor2 = " $1";
					}
				}
					elsif ( /^fan1:\s+(\d+\sRPM)\s+\(.*\)(\s+ALARM)?/ ) {
						if ( !$2 ) {
							$sensor3 = " $1";
						} 
						else {
							$sensor3 = " $1";
						}
					}
						elsif ( /^fan2:\s+(\d+\sRPM)\s+\(.*\)(\s+ALARM)?/ ) {
							if ( !$2 ) {
								$sensor4 = " $1";
							} 
							else {
								$sensor4 = " $1";
							}
						}
	 	}
		if ( $sensor1 . $sensor2 . $sensor3 . $sensor4 ne "NANANANA") {
			$sensor1 =~ s/ C/ °C/g;
			$sensor2 =~ s/ C/ °C/g;
		}
    }
	return ( $sensor1, $sensor2, $sensor3, $sensor4 );
}

sub system_hard_drive_temp {
	my $hddtemp = 0;
	my $hddmodel;
	my $degc;
	my $degf;
	my $symbol;
	if ( file_executable( 'hddtemp' ) ) {
       for (`$sudo hddtemp $smart_d`){
			if (/^\/dev\/[sh]da:\s+(.*):\s+(\d+)(.+)$/) {
				$hddmodel = $1;
				$degc = $2;
				$degf = $degc * 1.8 + 32;
				$symbol = $3;
				$degc .= 'C';
				$degf .= 'F';
				$hddtemp = "$hddmodel:$degf/$degc";
			}
		} 
	}
		elsif ( ! file_executable( 'hddtemp' ) ) {
			#Could use qq{} so only one print is emitted but this is cleaner looking
			prnt "\002Could not access HDD information because hddtemp is not executable.";
			#prnt( "\002As root: chmod +x `which hddtemp` (sudo chmod +x `which hddtemp`) on MOST system should resolve this issue" );
		}
	return $hddtemp;
}

sub display_sys {
	if ( context_info->{type} eq '1' ) {
		prnt( "\002Please switch to a channel or PM window" );
		return EAT_XCHAT;
	}
	my ( $system_os, $system_kernel ) = system_version;
	my ( $distro ) = `lsb_release -i -s`; chomp $distro;
	my ( $arch ) = `uname -m`; chomp $arch;
	my ( $model, $cpu, $mips, undef ) = system_processor;
	my ( $memtotal, $memfree, $memused, $memfreepercent, $memusedpercent, $memtotalpercent, $membar, undef ) = system_memory;
	my ( $hddtotal, $hddfree, $hddfreepercent, undef, undef ) = system_hard_drive;
	my $system_processes = system_processes;
	my ( $up, undef ) = system_uptime;
	my $system_loadavg = system_loadavg;
	my $system_graphic_card = system_graphic_card;
	my ( $dimensions, $depth ) = system_screen_res;
	my ( $netdevice, $in, $out ) = system_network;
	my ( $nvc, $nvc2, $nvt, $nvt2, $nvt3, $nvt4 ) = system_nvidia_nvclock if $enable_nvidia;
	my $system_temp_sensors = system_temp_sensors;
	my $system_hdd_temp = system_hard_drive_temp;

	command( "say \002os\002[$system_os $system_kernel $arch] \002distro\002[$distro] \002cpu\002[$model] \002mem\002[Total: $memtotal, $memfreepercent% free] \002procs\002[$system_processes] \002load\002[$system_loadavg] \002disk\002[Total: $hddtotal, $hddfreepercent% free] \002video\002[$system_graphic_card] \002net\002[In: $in Out: $out]" );

	if ( $global_nvidia ) {
		command ( "say \002Nvidia\002: GeForce 8600 GT [G84] \002GPU speed:\002 700 MHz \002GPU Memory speed:\002 899 MHz \002GPU Temp:\002 $nvt2/$nvt" );
		command ( "say \002HDD:\002 Total: $hddtotal Free: $hddfree \002Temp:\002 $system_hdd_temp" );
	}
	return EAT_XCHAT;
}


sub display_processor {
	if ( context_info->{type} eq '1' ) {
		prnt( "\002Please switch to a channel or PM window" );
		return EAT_XCHAT;
	}
	my ( $model, $cpu, $mips ) = system_processor;
	command ( "say \002Processor:\002 \002Model\002: $model \002CPU MHz:\002 $cpu \002BogoMips:\002 $mips" );
	return EAT_XCHAT;
}

sub display_uptime {
	if ( context_info->{type} eq '1' ) {
		prnt( "\002Please switch to a channel or PM window" );
		return EAT_XCHAT;
	}
	my ( $up, undef ) = system_uptime;
	command ( "say \002Uptime:\002 $up" );
	return EAT_XCHAT;
}

sub display_memory {
	if ( context_info->{type} eq '1' ) {
		prnt( "\002Please switch to a channel or PM window" );
		return EAT_XCHAT;
	}
	my ( $memtotal, $memfree, $memused, $memfreepercent, $memusedpercent, $memtotalpercent, $membar, undef ) = system_memory;
	command ( "say \002Memory:\002 \002Total:\002 $memtotal \002Free:\002$memfree($memfreepercent%) \002Used:\002$memused($memusedpercent%)\002" );
	return EAT_XCHAT;
}

sub display_version {
	if ( context_info->{type} eq '1' ) {
		prnt( "\002Please switch to a channel or PM window" );
		return EAT_XCHAT;
	}
	my ( $system_os, $system_kernel ) = system_version;
	my ( $distro ) = `lsb_release -i -s`;
	my ( $arch ) = `uname -m`;
	command ( "say \002OS:\002 $distro \002Kernel:\002 $system_kernel $arch" );
	return EAT_XCHAT;
}

sub display_hdd {
	if ( context_info->{type} eq '1' ) {
		prnt( "\002Please switch to a channel or PM window" );
		return EAT_XCHAT;
	}
	my ( $hddtotal, $hddfree, undef, undef, undef ) = system_hard_drive;
	command ( "say \002HDD:\002 Total: $hddtotal Free: $hddfree" );
	return EAT_XCHAT;
}

sub display_processes {
	if ( context_info->{type} eq '1' ) {
		prnt( "\002Please switch to a channel or PM window" );
		return EAT_XCHAT;
	}
	my $processes = system_processes;
	command ( "say \002Processes:\002 $processes" );
	return EAT_XCHAT;
}

sub display_load {
	if ( context_info->{type} eq '1' ) {
		prnt( "\002Please switch to a channel or PM window" );
		return EAT_XCHAT;
	}
	my $loadavg = system_loadavg;
	command ( "say \002Load Averages:\002 $loadavg" );
	return EAT_XCHAT;
}

sub display_graphics {
	if ( context_info->{type} eq '1' ) {
		prnt( "\002Please switch to a channel or PM window" );
		return EAT_XCHAT;
	}
	my $g_card = system_graphic_card;
	my ( $dimensions, $depth ) = system_screen_res;
	command ( "say \002Graphics:\002$g_card \002Screen Res.:\002 $dimensions ($depth bpp)" );
	return EAT_XCHAT;
}

sub display_network {
	if ( context_info->{type} eq '1' ) {
		prnt( "\002Please switch to a channel or PM window" );
		return EAT_XCHAT;
	}
	my ( $netdevice, $in, $out ) = system_network;
	command ( "say \002Network:\002 $netdevice: In: $in Out: $out" );
	return EAT_XCHAT;
}

sub display_nvclock {
	if ( context_info->{type} eq '1' ) {
		prnt( "\002Please switch to a channel or PM window" );
		return EAT_XCHAT;
	}
	my ( $nvc, $nvc2, $nvt, $nvt2, $nvt3, $nvt4 ) = system_nvidia_nvclock;
	command ( "say \002Nvidia\002: \002GPU speed:\002 $nvc \002--\002 \002GPU Memory speed:\002 $nvc2 \002--\002 \002GPU Temp:\002 $nvt2/$nvt \002--\002 \002GPU Board Temp:\002 $nvt4/$nvt3" );
	return EAT_XCHAT;
}

sub display_sensors {
	if ( context_info->{type} eq '1' ) {
		prnt( "\002Please switch to a channel or PM window" );
		return EAT_XCHAT;
	}
	my ( $sensor1, $sensor2, $sensor3, $sensor4 ) = system_temp_sensors;
	command ( "say \002Temp\002: $sensor1 \002Temp2:\002 $sensor2 \002Fan:\002 $sensor3 \002Fan2:\002 $sensor4" );
	return EAT_XCHAT;
}

sub display_hdd_temp {
	if ( context_info->{type} eq '1' ) {
		prnt( "\002Please switch to a channel or PM window" );
		return EAT_XCHAT;
	}
	my $system_hard_drive_temp = system_hard_drive_temp;
	command ( "say \002HDD Temp:\002 $system_hard_drive_temp" );
	return EAT_XCHAT;
}

#Hooks
hook_command( 'sys', 'display_sys', {
	help_text => '/sys - Display ALL of your systems info to a channel or PM'
	}
);

hook_command( 'sys-ver', 'display_version', {
	help_text => '/sys-ver - Display the version of your system to a channel or PM'
	}
);

hook_command( 'sys-processor', 'display_processor', {
	help_text => '/sys-processor - Display the processor of your system to a channel or PM'
	}
);

hook_command( 'sys-uptime', 'display_uptime', {
	help_text => '/sys-uptime - Display the uptime to a channel or PM'
	}
);

hook_command( 'sys-memory', 'display_memory', {
	help_text => '/sys-memory - Display the memory information to a channel or PM'
	}
);

hook_command( 'sys-hdd', 'display_hdd', {
	help_text => '/sys-hdd - Display the Hard drive information to a channel or PM'
	}
);

hook_command( 'sys-proc', 'display_processes', {
	help_text => '/sys-proc - Display the number of processes to a channel or PM'
	}
);

hook_command( 'sys-load', 'display_load', {
	help_text => '/sys-load - Display the load averages to a channel or PM'
	}
);

hook_command( 'sys-video', 'display_graphics', {
	help_text => '/sys-video - Display the video card specs to a channel or PM'
	}
);

hook_command( 'sys-net', 'display_network', {
	help_text => '/sys-net - Display the network traffic to a channel or PM'
	}
);

hook_command( 'sys-nvidia', 'display_nvclock', {
	help_text => '/sys-nvidia - Display the Nvidia video card specs and temps( if card supports it ) to a channel or PM'
	}
) if $enable_nvidia;

hook_command( 'sys-sensors', 'display_sensors', {
	help_text => '/sys-sensors - Display your systems temperatures and fan speeds ( if your system supports it ) to a channel or PM'
	}
) if $enable_sensors;

hook_command( 'sys-hddtemp', 'display_hdd_temp', {
	help_text => '/sys-hddtemp - Display your systems hard drive temperature ( The hard drive must support S.M.A.R.T. ) to a channel or PM'
	}
) if $enable_hddtemp;

menus();
sub menus{
	command( 'MENU ADD _Sysinfo' );
	command( 'MENU ADD "_Sysinfo/_Sysinfo" sys' );
	command( 'MENU ADD "_Sysinfo/_OS" sys-ver' );
	command( 'MENU ADD "_Sysinfo/_Processor" sys-processor' );
	command( 'MENU ADD "_Sysinfo/_Processes" sys-proc' );
	command( 'MENU ADD "_Sysinfo/_Hard Drive" sys-hdd' );
	command( 'MENU ADD "_Sysinfo/_Uptime" sys-uptime' );
	command( 'MENU ADD "_Sysinfo/_Memory" sys-memory' );
	command( 'MENU ADD "_Sysinfo/_Load" sys-load' );
	command( 'MENU ADD "_Sysinfo/_Graphics" sys-video' );
	command( 'MENU ADD "_Sysinfo/_Network" sys-net' );
	command( 'MENU ADD "_Sysinfo/_Nvidia Specs" sys-nvidia' ) if $enable_nvidia;
	command( 'MENU ADD "_Sysinfo/_Sensors" sys-sensors' ) if $enable_sensors;
	command( 'MENU ADD "_Sysinfo/_Hard drive temp" sys-hddtemp' ) if $enable_hddtemp;
}

sub unload_menus {
	command("MENU DEL Sysinfo");
}

register ( $XCHAT{'name'}, $XCHAT{'version'}, $XCHAT{'description'}, \&unload_menus );
prnt ("\002$XCHAT{'name'} script loaded. Version: $XCHAT{'version'}" );

__END__
	1: Original script by 'sick boy', spamtospamandmailtosick@drunk.at

	2: The original script was used as a base since my sysinfo scripts were lost and
	   I'm to lazy to start over :-)

	3: Please get ahold of me if you run into any problems or thinking of any new features that can be added.
	   I would really like to add ATI support, so if anyone knows of the ATI equivalent of nvclock(that is still maintained)
	   hit me up! :-)

	Usage: /sys - in a channel or PM
		   Use the menu at the top of the client.

	Version History:
		Alot of scripts were lost so this is the first version but it's not the first version.
		Not listing old scripts, only new ones.
		001: Initial release

	NOTES:
		1: For the parts of the script that require 'root'(sudo) access, it is best you edit the sudoers file ( /etc/sudoers ) so you don't have to enter a password.
		   In most cases commenting out "%admin ALL=(ALL) ALL" and adding this "%admin ALL=NOPASSWD: ALL" will do the trick. Although your situation may vary.
		3: Sensor outputs are not all the same so even if you have sensors configured, it all might not be displayed.
		   If you run into this problem, please pastebin.com the output of 'sensors' and send me a link and i will edit the script to your needs. 
		   NO GUARANTEED RETURN TIME. But it will be quick :-)
