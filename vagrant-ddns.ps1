# 
# 
# 

param (
  [string]$action = $(throw "-action is required"),
  [string]$dnsserver = "127.0.0.1",
  [string]$machinename = "default",
  [string]$interface = $(throw "-interface is required"),
  [string]$hostname = $(throw "-hostname is required"),
  [string]$nsupdatekey = $(throw "-nsupdatekey is required")
)

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
  $ipcmd = "vagrant ssh $machinename -c `"ifconfig $interface | grep -oE 'inet.*?([0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3})'`""
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
if ($action -eq "add") {
  $ip = Get-Ip-Address
  $cmd_stack = Nsupdate-Add $cmd_stack
}
elseif ($action -eq "delete") {
  $cmd_stack = Nsupdate-Delete $cmd_stack
}
# Always append send at the end 
$cmd_stack = Nsupdate-Send $cmd_stack
# Write-Output $cmd_stack

# Do the nsupdate
$nsupcmd = "Write-Output `"" + [string]::join("`r`n", $cmd_stack) + "`" | nsupdate -v -k $nsupdatekey"
$nsup_line = Invoke-Expression $nsupcmd 2>&1
