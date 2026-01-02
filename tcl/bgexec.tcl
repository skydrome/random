# bgexec.tcl v1.1 - by strikelight ([sL] @ EFNet) (09/05/02)
#
# For eggdrop1.1.5-eggdrop1.6.x
#
# Contact:
# - E-Mail: strikelight@tclscript.com
# - WWW   : http://www.TCLScript.com
# - IRC   : #Scripting @ EFNet
#
##
#
# Description:
#
# This script is for other scripters to use as a replacement
# for the "exec" command so that they may execute commands to
# the system in the background. (non-blocking mode)
#
##
#
# History:
#
# (09/05/02):v1.1 - Fixed callback bug to allow calling of a callback
#                   procedure with a list of parameters
#                   (ie. bgexec <command> [list <command_callback> <arg1> <arg2>])
#
# (05/27/02):v1.0 - Initial Release
#
##

set bgexec(version) "1.1"

proc bgexec_process {fileid callback} {
  global buffer bgexectest
  if {[eof $fileid]} {
    catch {close $fileid}
    set buffer($fileid) [lrange $buffer($fileid) 0 [expr [llength $buffer($fileid)] - 2]]
    set buffer($fileid) [join $buffer($fileid) "\n"]
    catch {eval $callback {$buffer($fileid)}}
    catch {unset buffer($fileid)}
    set bgexectest($fileid) 1
    return
  }
  if {[catch {gets $fileid dataline} err]} {
    catch {close $fileid}
    set buffer($fileid) "error: $err"
    catch {eval $callback {$buffer($fileid)}}
    catch {unset buffer($fileid)}
    set bgexectest($fileid) 1
  }
  lappend buffer($fileid) $dataline
}

proc bgexec {{command ""} {callback ""} {flush 5}} {
  global buffer bgeggversion
  if {($command == "") || ($callback == "")} {
    return -code error "wrong # args: should be \"bgexec command callback ?wait?\""
  }
  if {[catch {info body [lindex [split $callback] 0]} err]} {
    return -code error "$err"
  }
  if {[catch {set infile [open "|$command" "r+"]} err]} {
    return -code error "$err"
  }
  set buffer($infile) ""
  fileevent $infile readable [list bgexec_process $infile $callback]
  fconfigure $infile -blocking 0
  if {[info exists bgeggversion] && ($bgeggversion < 1040000)} {
    utimer $flush "bgexec_flush $infile"
  }
  return $infile
}

if {[info exists version]} {
  set bgeggversion [string trimleft [lindex $version 1] 0]
  if {$bgeggversion < 1040000} {
    proc bgexec_flush {fileid} {
      global bgexectest
      vwait bgexectest($fileid)
      catch {unset bgexectest($fileid)}
    }
  }
}

putlog "bgexec.tcl v$bgexec(version) loaded"
