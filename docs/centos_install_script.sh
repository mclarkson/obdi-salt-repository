#!/bin/bash
# Ubuntu Install Script - A script to install Obdi and Salt Tools
# Copyright (C) 2014  Mark Clarkson
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# See: https://github.com/mclarkson/obdi-salt-repository

a=`chage -l root | grep "password must be changed" | wc -l`
[[ $a -ne 0 ]] && {
    echo "ERROR: Root password must be changed. See 'chage -l root'."
    exit 1
}

echo -n "Enter your email address > "
read email

echo -n "Enter your full name > "
read name

[[ -z $email || -z $name ]] && {
    echo "No details entered"
    exit 0
}

# Install Obdi

rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm

yum -y install \
   https://github.com/mclarkson/obdi/releases/download/0.1.4/obdi-0.1.4-2.x86_64.rpm \
   https://github.com/mclarkson/obdi/releases/download/0.1.4/obdi-worker-0.1.4-2.x86_64.rpm \
   git cronie

# Test Obdi

yum -y install curl

# Configure go_root

eval `go env | grep GOROOT`
sed -i "s#\(go_root *= *\).*#\1\"$GOROOT\"#" /etc/obdi/obdi.conf
/etc/init.d/obdi start
/etc/init.d/obdi-worker start

# Wait for obdi to start
sleep 5

# Add a Run Interface User

guid=`curl -ks -d '{"Login":"admin","Password":"admin"}' https://127.0.0.1:443/api/login | grep -o "[a-z0-9][^\"]*"`

[[ -z $guid ]] && {
    echo 'curl -k -d "{"Login":"admin","Password":"admin"}" https://127.0.0.1:443/api/login'
    curl -k -d '{"Login":"admin","Password":"admin"}' https://127.0.0.1:443/api/login
    echo -e "\nCould not log in."
    exit 0
}

curl -k -d '{
    "login":"nomen.nescio",
    "passHash":"password",
    "forename":"Nomen",
    "surname":"Nescio",
    "email":"nomen.nescio@invalid",
    "enabled":true}' "https://127.0.0.1:443/api/admin/$guid/users"

# Add a Worker User

guid=`curl -ks -d '{"Login":"admin","Password":"admin"}' https://127.0.0.1:443/api/login | grep -o "[a-z0-9][^\"]*"`

curl -k -d '{
    "login":"worker",
    "passHash":"pAsSwOrD",
    "forename":"Worker",
    "surname":"Daemon",
    "email":"worker@invalid",
    "enabled":true}' "https://127.0.0.1:443/api/admin/$guid/users"

# Install the Obdi Salt Plugins

guid=`curl -ks -d '{"Login":"admin","Password":"admin"}' https://127.0.0.1:443/api/login | grep -o "[a-z0-9][^\"]*"`

curl -k -d '{
    "Url":"https://github.com/mclarkson/obdi-core-repository.git"
}' "https://127.0.0.1:443/api/admin/$guid/repos"

curl -k -d '{
    "Url":"https://github.com/mclarkson/obdi-salt-repository.git"
}' "https://127.0.0.1:443/api/admin/$guid/repos"

guid=`curl -ks -d '{"Login":"admin","Password":"admin"}' https://127.0.0.1:443/api/login | grep -o "[a-z0-9][^\"]*"`

curl -k -d '{
    "Name":"systemjobs"
}' "https://127.0.0.1:443/api/admin/$guid/repoplugins"

curl -k -d '{
    "Name":"salt"
}' "https://127.0.0.1:443/api/admin/$guid/repoplugins"

curl -k -d '{
    "Name":"saltconfigserver"
}' "https://127.0.0.1:443/api/admin/$guid/repoplugins"

curl -k -d '{
    "Name":"saltjobviewer"
}' "https://127.0.0.1:443/api/admin/$guid/repoplugins"

curl -k -d '{
    "Name":"saltkeymanager"
}' "https://127.0.0.1:443/api/admin/$guid/repoplugins"

curl -k -d '{
    "Name":"saltregexmanager"
}' "https://127.0.0.1:443/api/admin/$guid/repoplugins"

curl -k -d '{
    "Name":"saltupdategit"
}' "https://127.0.0.1:443/api/admin/$guid/repoplugins"

# Add a Data Centre and Environment

guid=`curl -ks -d '{"Login":"admin","Password":"admin"}' https://127.0.0.1:443/api/login | grep -o "[a-z0-9][^\"]*"`

# Create the DC

curl -k -d '{
    "SysName":"testdc",
    "DispName":"Test DC"
    }' "https://127.0.0.1:443/api/admin/$guid/dcs"

# Get the ID of the DC

dcid=`curl -ks "https://127.0.0.1:443/api/admin/$guid/dcs?sys_name=testdc" | grep Id | grep -o "[0-9]"`

# Check that dcid is a number (probably '1')
echo $dcid

# Create the Environment

curl -k -d '{
    "SysName":"testenv",
    "DispName":"Test Environment",
    "DcId":'"$dcid"',
    "WorkerUrl":"https://127.0.0.1:4443/",
    "WorkerKey":"lOcAlH0St"
}' "https://127.0.0.1:443/api/admin/$guid/envs"

# Change User Permissions

guid=`curl -ks -d '{"Login":"admin","Password":"admin"}' https://127.0.0.1:443/api/login | grep -o "[a-z0-9][^\"]*"`

# Add a function to the running shell

add_perm() {
    opts="-k";proto="https";ipport="127.0.0.1:443"
    userid=`curl $opts "$proto://$ipport/api/admin/$guid/users?login=$1" | grep Id | grep -o "[0-9]"`
    dcid=`curl $opts "$proto://$ipport/api/admin/$guid/dcs?sys_name=$2" | grep Id | grep -o "[0-9]"`
    envid=`curl $opts "$proto://$ipport/api/admin/$guid/envs?sys_name=$3&dc_id=$dcid" | grep -w Id | grep -o "[0-9]"`
    curl $opts -d '{
        "UserId":'"$userid"',
        "EnvId":'"$envid"',
        "Enabled":'"$4"',
        "Writeable":'"$5"'
    }' "$proto://$ipport/api/admin/$guid/perms"
}

# Give 'nomen.nescio' rw permission to testenv

add_perm nomen.nescio testdc testenv true true

# Creating the Repository

mkdir -p /srv/repos/saltrepo.git
cd /srv/repos/saltrepo.git/
git --bare init

git config --global user.email "$email"
git config --global user.name "$name"

cd
git clone file:///srv/repos/saltrepo.git
cd saltrepo

echo "The master branch is not used and no top.sls is required" >README

git add README 
git commit -am "Added README"
git push -u origin master

git branch testenv
git checkout testenv 

echo "This is the 'testenv' branch. No top.sls is required" >README

mkdir root
git add root
git commit -am "Initial setup"
git push -u origin testenv

mkdir -p ~/saltrepo/root/tree
cd ~/saltrepo/root/tree
echo "# INFO: Installs the 'tree' command." >init.sls
echo -e "\ntree:\n  pkg.installed" >>init.sls
cd ..
git add tree
git commit -am "Added tree formula"
git push -u origin testenv

# Installing Salt Stack

echo "127.0.1.2 salt" >>/etc/hosts

yum -y install salt-master salt-minion GitPython

# Back up the original salt master config file
cp /etc/salt/master /etc/salt/master.orig

# Write a new salt master config file
cat >/etc/salt/master <<EnD
fileserver_backend:
  - git
gitfs_remotes:
  - file:///srv/repos/saltrepo.git
gitfs_root: root

# Use the Obdi external node classifier
master_tops:
  ext_nodes: enc_query.py

# JSON output on a single line
output_indent: Null

# Required since version 2014.7.0 if using GitPython. Salt doesn't check
# for it anymore. (https://github.com/saltstack/salt/issues/17945).
gitfs_provider: gitpython
EnD

/etc/init.d/salt-master start
/etc/init.d/salt-minion start

# Final Tasks

cp /usr/share/obdi/static/plugins/saltconfigserver/scripts/enc_query.py /usr/bin/

chmod +x /usr/bin/enc_query.py

# Configure the Salt Job Viewer

# Add a user with no permissions to any environments

guid=`curl -ks -d '{"Login":"admin","Password":"admin"}' https://127.0.0.1:443/api/login | grep -o "[a-z0-9][^\"]*"`

curl -k -d '{
    "login":"jobviewer",
    "passHash":"PasSWOrd",
    "forename":"Jobviewer",
    "surname":"Daemon",
    "email":"jobviewer@invalid",
    "enabled":true}' "https://127.0.0.1:443/api/admin/$guid/users"

# Write the configuration file

echo -e 'STATUS_USER="jobviewer"\nSTATUS_PASS="PasSWOrd"' >/etc/obdi/job_status.conf

# Add a cron job

crontab -l >newcron
echo "* * * * * /usr/share/obdi/static/plugins/saltjobviewer/scripts/job_notify.sh" >>newcron
crontab newcron
rm newcron

echo "FINISHED"

