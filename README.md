# vagrant-ddns-scripts

## Goals
* Allow for dynamically updating DNS when Vagrant machines change state.
  vagrant-triggers plugin handles hooking into the events, the scripts 
  provided in this repo bridge the gap between Vagrant and nsupdate.

## Prerequisites 
* [nsupdate](http://linux.die.net/man/1/nsupdate)
* DNS server configured to accept DDNS updates
* Powershell >= 3.0 or Bash >= 3.0
* [Vagrant](https://www.vagrantup.com)
* [vagrant-triggers](https://github.com/emyl/vagrant-triggers)

## Setup
* Put the appropriate script for your environment somewhere in your path.  I recommend a dedicated scripts directory.

## Usage
* There are two ways you can use the vagrant-ddns scripts, implicitly within a Vagrant project or explicitly via the command line.

### Options
* **-a**: _(Required)_ nsupdate actions.  Currently add, delete, dryadd, and drydelete are supported.
* **-e**: _(Optional)_ run with elevated permissions.  Executes ifconfig as sudo.
* **-s**: _(Required)_ DNS server supporting DDNS updates.  IP address or hostname.
* **-m**: _(Optional)_ Vagrant machine id.  Optional for implicit usage, Required for explicit.
* **-i**: _(Optional)_ Interface on the guest machine to extract IP address from.  Required when action is add.
* **-h**: _(Required)_ Hostname to be added to DNS.
* **-k**: _(Required)_ Path to keyfile required to perform DDNS update.

### Explicit
* Occasionally it may be necessary to dynamically modify DNS entries for virtual machines directly from the command line.  This could be useful in the event that a trigger doesn't actually fire properly or you need to manually update your DNS server.
* Since the script may be called from anywhere in the filesystem -m (machine id) IS required.
  ```powershell
  # Get the list of machines on this host
  C:\> vagrant global-status
  id       name    provider   state   directory
  -------------------------------------------------------------------------------------------------------
  ea6156e  myvm    virtualbox running C:/Path/To/vagrant-ddns-scripts/example
  
  # Explicitly add a DNS entry for this guest
  C:\> vagrant-ddns -a add -s 127.0.0.1 -m ea6156e -h myvm.localhost -i eth0 -k C:\Path\To\vagrant-ddns-scripts\example\Klocalhost.+157+11776.key

  # Explicitly delete the DNS entry of this guest
  C:\> vagrant-ddns -a delete -s 127.0.0.1 -m ea6156e -h myvm.localhost -k C:\Path\To\vagrant-ddns-scripts\example\Klocalhost.+157+11776.key
  ```

### Implicit
* Implicit usage is outlined in the example/ Vagrantfile.  Basically you define your DDNS particulars and then hook the script into various Vagrant machine events.
* Since the script is being called from within Vagrant it automatically knows which machine it should be interacting with, therefore -m (machine id) is not required.
