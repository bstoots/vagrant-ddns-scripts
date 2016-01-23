# 
# 
# 

param (
  [string]$a = $(Throw "action is required. e.g. add, delete, dryadd, drydelete"),
  [string]$s = $(Throw "server is required. e.g. 127.0.0.1, localhost"),
  [string]$m,
  [string]$i,
  [string]$h = $(Throw "hostname is required. e.g. vm.localhost"),
  [string]$k = $(Throw "nsupdatekey is required. e.g. C:\Path\To\Klocalhost.key")
)
# Sanity check vars
# Currently supported actions are add, delete
if ($a -ne "add" -and $a -ne "delete" -and $a -ne "dryadd" -and $a -ne "drydelete") {
  Throw "Invalid action, valid actions are: add, delete, dryadd, drydelete"
}
# If action is add we need an interface in order to determine IP address
if ($a -eq "add" -and ($i -eq $null -or $i -eq "")) {
  Throw "Interface must be provided for add"
}
# Set vars again to give us an interface
$action = $a
$dnsserver = $s
$machineid = $m
$interface = $i
$hostname = $h
$nsupdatekey = $k

<##
#>
function Nsupdate-Server([array]$cmd_stack) {
  $cmd_stack += "server $dnsserver"
  return ,$cmd_stack
}

<##
#>
function Nsupdate-Add([array]$cmd_stack) {
  $cmd_stack += "update add $hostname 60 A $ip"
  return ,$cmd_stack
}

<##
#>
function Nsupdate-Delete([array]$cmd_stack) {
  $cmd_stack += "update delete $hostname"
  return ,$cmd_stack
}

<##
#>
function Nsupdate-Send([array]$cmd_stack) {
  $cmd_stack += "send"
  return ,$cmd_stack
}

<##
 # Build a simple ifconfig / grep command for maximum cross-OS compatibility.  Ideally this should 
 # work on all *nix based operating systems.  If not tune it until it does.
 #>
function Get-Ip-Address() {
  $ipcmd = "vagrant ssh $machineid -c `"ifconfig $interface | grep -oE 'inet.*?([0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3})'`""
  $ip_line = Invoke-Expression $ipcmd 2>&1
  # Parse the output with more powerful PS regex capturing
  if ( $ip_line -match 'inet.*?([0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3})' -eq $true ) {
    return $matches[1]
  }
  else {
    Throw "No IP address found, ip_line was: $ip_line"
  }
}

# Build nsupdate command 
$cmd_stack = @()
# Always specify DNS server for sanity
$cmd_stack = Nsupdate-Server $cmd_stack
if ($action -eq "add" -or $action -eq "dryadd") {
  $ip = Get-Ip-Address
  $cmd_stack = Nsupdate-Add $cmd_stack
}
elseif ($action -eq "delete" -or $action -eq "drydelete") {
  $cmd_stack = Nsupdate-Delete $cmd_stack
}
# Always append send at the end 
$cmd_stack = Nsupdate-Send $cmd_stack
# Write-Output $cmd_stack

# Do the nsupdate if this is not a dryrun
$nsupcmd = "Write-Output `"" + [string]::join("`r`n", $cmd_stack) + "`" | nsupdate -v -k $nsupdatekey"
if ($action -eq "add" -or $action -eq "delete") {
  Invoke-Expression $nsupcmd
}
elseif ($action -eq "dryadd" -or $action -eq "drydelete") {
  Write-Output $nsupcmd
}
