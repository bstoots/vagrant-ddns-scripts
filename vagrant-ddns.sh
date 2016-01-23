#!/bin/bash
# set -e

#
#
#

function _assign {
  eval "$1=$_return"
  _return=''
}

function _return {
  echo "$_return"
  _return=''
}

function _exit {
  echo $2
  exit $1
}

function nsupdate_server {
  _return="server $1\n"
}

function nsupdate_add {
  _return="update add $1 60 A $2\n"
}

function nsupdate_delete {
  _return="update delete $1\n"
}

function nsupdate_send {
  _return="send"
}

function get_ip_address {
  # Haven't tested this yet, need a Linux host ...
  ip_line=`vagrant ssh $1 -c "ifconfig $2 | grep -oE 'inet.*?([0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3})'"`
  # ip_line=`ifconfig $2 | grep -oE 'inet.*?([0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3})'`
  linux_regex="inet addr:([0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3})"
  bsd_regex="inet ([0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3})"
  # echo $ip_line
  if [[ "$ip_line" =~ "$linux_regex" ]]; then
    _return=${BASH_REMATCH[1]}
  elif [[ "$ip_line" =~ "$bsd_regex" ]]; then
    _return=${BASH_REMATCH[1]}
  else
    _exit 1 "No IP address found, ip_line was: $ip_line"
  fi
}

# Parse arguments
dnsserver=127.0.0.1
machineid=""
while getopts ":a::s::m::i::h::k:" opt; do
  case $opt in
    a)
      # add, delete
      action=$OPTARG
      ;;
    s)
      # DNS server hostname or address
      dnsserver=$OPTARG
      ;;
    m)
      # vagrant machine name
      machineid=$OPTARG
      ;;
    i)
      # guest machine interface
      interface=$OPTARG
      ;;
    h)
      # guest machine hostname
      hostname=$OPTARG
      ;;
    k)
      # nsupdate key file for DDNS updates
      nsupdatekey=$OPTARG
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done
# Sanity check vars
# Currently supported actions are add, delete, dryadd, drydelete
if [ "$action" != "add" ] && [ "$action" != "delete" ] && [ "$action" != "dryadd" ] && [ "$action" != "drydelete" ]; then
  _exit 1 "Invalid action, valid actions are: add, delete, dryadd, drydelete"
fi
# If action is add or dryadd we need an interface in order to determine IP address
if ([ "$action" = "add" ] || [ "$action" = "dryadd" ]) && [ -z "$interface" ]; then
  _exit 1 "Interface must be provided for $action"
fi

# Build nsupdate command
cmd_stack=""
# Always specify DNS server for sanity
cmd_stack+=$(nsupdate_server "$dnsserver" && _return)
if [ "$action" = "add" ] || [ "$action" = "dryadd" ]; then
  get_ip_address "$machineid" "$interface" && _assign ip
  cmd_stack+=$(nsupdate_add $hostname $ip && _return)
elif [ "$action" = "delete" ] || [ "$action" = "drydelete" ]; then
  cmd_stack+=$(nsupdate_delete "$hostname" && _return)
fi
# Always append send at the end
cmd_stack+=$(nsupdate_send && _return)
# echo $cmd_stack

# Do the nsupdate if this is not a dryrun
if [ "$action" = "add" ] || [ "$action" = "delete" ]; then
  echo -e "${cmd_stack}" | nsupdate -v -k $nsupdatekey 2>&1
elif [ "$action" = "dryadd" ] || [ "$action" = "drydelete" ]; then
  echo "Dry-run command: echo -e ${cmd_stack} | nsupdate -v -k $nsupdatekey" 2>&1
fi
