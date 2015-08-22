# Obdi Salt Stack Setup Guide for Centos 6

<div class="toc">
<ul>
<li><a href="#obdi-salt-stack-setup-guide-for-ubuntu-trusty">Obdi Salt Stack Setup Guide for Centos 6</a></li>
<li><a href="#installing-obdi">Installing Obdi</a><ul>
<li><a href="#installation-script">Installation Script</a></li>
<li><a href="#running-commands">Running Commands</a></li>
<li><a href="#installation">Installation</a><ul>
<li><a href="#install-ubuntu">Install Centos</a></li>
<li><a href="#install-obdi">Install Obdi</a></li>
<li><a href="#test-obdi">Test Obdi</a></li>
</ul>
</li>
<li><a href="#configuration">Configuration</a><ul>
<li><a href="#configure-go_root">Configure go_root</a></li>
<li><a href="#add-a-run-interface-user">Add a Run Interface User</a></li>
<li><a href="#add-a-worker-user">Add a Worker User</a></li>
<li><a href="#install-the-obdi-salt-plugins">Install the Obdi Salt Plugins</a></li>
<li><a href="#add-a-data-centre-and-environment">Add a Data Centre and Environment</a></li>
<li><a href="#change-user-permissions">Change User Permissions</a></li>
<li><a href="#view-the-admin-interface">View the Admin interface</a></li>
</ul>
</li>
<li><a href="#local-git-setup">Local GIT Setup</a><ul>
<li><a href="#creating-the-repository">Creating the Repository</a></li>
</ul>
</li>
<li><a href="#installing-salt-stack">Installing Salt Stack</a></li>
<li><a href="#final-tasks">Final Tasks</a><ul>
<li><a href="#install-the-external-node-classifier">Install the External Node Classifier</a></li>
<li><a href="#configure-the-salt-job-viewer">Configure the Salt Job Viewer</a></li>
<li><a href="#change-default-passwords">Change Default Passwords</a></li>
</ul>
</li>
<li><a href="#all-done">All done</a></li>
</ul>
</li>
<li><a href="#using-obdi">Using Obdi</a><ul>
<li><a href="#quick-guide">Quick Guide</a><ul>
<li><a href="#accept-the-minions-key">Accept the Minion's Key</a></li>
<li><a href="#version-the-git-repo">Version the GIT Repo</a></li>
<li><a href="#map-classes-to-hosts">Map Classes to Hosts</a></li>
<li><a href="#configure-the-server">Configure the Server</a></li>
<li><a href="#view-the-job-status">View the Job Status</a></li>
<li><a href="#all-done_1">All done</a></li>
</ul>
</li>
</ul>
</li>
</ul>
</div>

# Installing Obdi

The processes required to get the Obdi Salt plugins working are explained in
this guide. The emphasis is to get up and running as simply and as quickly as
possible. 

Once this guide has been completed it will be possible to further refine the
installation for your environment.

## Installation Script

All the commands in this document have been collected together into an
installation script.

The script can be used instead of typing, or copy/pasting, all the commands in
this document.

The installation script, `ubuntu_install_script.sh` is available at:

[https://github.com/mclarkson/obdi-salt-repository/docs](https://github.com/mclarkson/obdi-salt-repository/blob/master/docs/)

To download and install on a new Ubuntu Trusty server, type:

    wget https://raw.githubusercontent.com/mclarkson/obdi-salt-repository/master/docs/centos_install_script.sh
    bash centos_install_script.sh

The script can be run many times without causing any problems. This may
need to be done if, for instance, the internet connection was down when
running the script the first time.

Once the script has completed successfully proceed to the [Using Obdi](#using-obdi) section.

## Running Commands

All commands should be run as the 'root' user.

Copy commands from this document directly into a terminal.

## Installation

### Install Centos

Install Centos 6 on a server, with a minimal set of packages, and ensure
all packages are up to date.

### Install Obdi

Obdi is available from Fedora COPR. EPEL repositories are also required
to install golang, which is required for compile-on-demand.

Install Obdi:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Enable EPEL YUM repository
rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm

# Enable Obdi COPR YUM repository
curl -o /etc/yum.repos.d/obdi.repo \
  https://copr.fedoraproject.org/coprs/mclarkson/Obdi/repo/epel-6/mclarkson-Obdi-epel-6.repo

# Install Obdi
yum -y install obdi obdi-worker git cronie
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

### Test Obdi

Now that Obdi is installed it would be a good idea to give it a quick test
before continuing further.

**Test the Admin Interface**

Using a Web Browser, connect to the Admin interface at: 

> https://SERVER/manager/admin

Replace &lsquo;SERVER&rsquo; with the host name or IP Address of the server.

A log-in screen should be shown. Log in with user name &lsquo;admin&rsquo; and
the default password &lsquo;admin&rsquo;.

<a name="test-the-run-interface"></a> **Test the Run Interface**

Log out and test the Run interface by connecting to:

> https://SERVER/manager/run

It's not possible to log in yet, unless a non admin user has been added, but
this verifies that the run interface is accessible.

**Test the REST interface**

The unix program, *curl*, is required, so install it:

    yum -y install curl

Using an *ssh* client, log into SERVER and issue two REST commands using
*curl*; the first will log into Obdi and return a session ID, and the second
will list all users.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Log in
guid=`curl -ks -d '{"Login":"admin","Password":"admin"}' https://127.0.0.1:443/api/login | grep -o "[a-z0-9][^\"]*"`

# Show the session id. This should not be empty.
echo $guid

# Show the list of users
curl -ks https://127.0.0.1:443/api/admin/$guid/users
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## Configuration

Obdi can be configured from the Admin interface using a Web Browser, or by
using REST commands. The REST interface will be used in this guide to keep it
short.

For simplicity, default user names and passwords will be used, where
applicable, and these should be changed after installation.

### Configure go_root

Obdi needs to know where to find the Google Go files. The following code will
modify `/etc/obdi/obdi.conf` with the correct 'go_root':

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
eval `go env | grep GOROOT`
sed -i "s#\(go_root *= *\).*#\1\"$GOROOT\"#" /etc/obdi/obdi.conf
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Start the Obdi services, as they do not start automatically:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
/etc/init.d/obdi start                                                                                          
/etc/init.d/obdi-worker start                                                                                   
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

### Add a Run Interface User

The 'admin' user is not allowed to log into the Run interface, and is blocked
from doing so.

Create a user for logging into the Run interface. Permissions will be applied
later, after data centres and environments have been added.

Add the user, 'nomen.nescio' (or any other name):

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
guid=`curl -ks -d '{"Login":"admin","Password":"admin"}' https://127.0.0.1:443/api/login | grep -o "[a-z0-9][^\"]*"`

curl -ks -d '{
    "login":"nomen.nescio",
    "passHash":"password",
    "forename":"Nomen",
    "surname":"Nescio",
    "email":"nomen.nescio@invalid",
    "enabled":true}' "https://127.0.0.1:443/api/admin/$guid/users"
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Test this user by logging into the Run interface as detailed in &lsquo;[Test
the Run Interface](#test-the-run-interface)&rsquo; above. A generic user
interface should be displayed with almost no content.

### Add a Worker User

The Worker needs a user set up for it to log into the Manager. By default this
is the user, 'worker', with password, 'pAsSwOrD', which is defined in
`/etc/obdi-worker/obdi-worker.conf`.

Add the 'worker' user:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
guid=`curl -ks -d '{"Login":"admin","Password":"admin"}' https://127.0.0.1:443/api/login | grep -o "[a-z0-9][^\"]*"`

curl -ks -d '{
    "login":"worker",
    "passHash":"pAsSwOrD",
    "forename":"Worker",
    "surname":"Daemon",
    "email":"worker@invalid",
    "enabled":true}' "https://127.0.0.1:443/api/admin/$guid/users"
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

### Install the Obdi Salt Plugins

Refer to [Obdi Plugins
Documentation](https://github.com/mclarkson/obdi/blob/master/doc/plugins.md)
for more information about Plugins.

**Add the Repository URLs**

The repositories,
[obdi-salt-repository](https://github.com/mclarkson/obdi-salt-repository) and
[obdi-core-repository](https://github.com/mclarkson/obdi-core-repository), will
be added as follows:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
guid=`curl -ks -d '{"Login":"admin","Password":"admin"}' https://127.0.0.1:443/api/login | grep -o "[a-z0-9][^\"]*"`

curl -ks -d '{
    "Url":"https://github.com/mclarkson/obdi-core-repository.git"
}' "https://127.0.0.1:443/api/admin/$guid/repos"

curl -ks -d '{
    "Url":"https://github.com/mclarkson/obdi-salt-repository.git"
}' "https://127.0.0.1:443/api/admin/$guid/repos"
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**Install the Plugins**

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
guid=`curl -ks -d '{"Login":"admin","Password":"admin"}' https://127.0.0.1:443/api/login | grep -o "[a-z0-9][^\"]*"`

curl -ks -d '{
    "Name":"systemjobs"
}' "https://127.0.0.1:443/api/admin/$guid/repoplugins"

curl -ks -d '{
    "Name":"salt"
}' "https://127.0.0.1:443/api/admin/$guid/repoplugins"

curl -ks -d '{
    "Name":"saltconfigserver"
}' "https://127.0.0.1:443/api/admin/$guid/repoplugins"

curl -ks -d '{
    "Name":"saltjobviewer"
}' "https://127.0.0.1:443/api/admin/$guid/repoplugins"

curl -ks -d '{
    "Name":"saltkeymanager"
}' "https://127.0.0.1:443/api/admin/$guid/repoplugins"

curl -ks -d '{
    "Name":"saltregexmanager"
}' "https://127.0.0.1:443/api/admin/$guid/repoplugins"

curl -ks -d '{
    "Name":"saltupdategit"
}' "https://127.0.0.1:443/api/admin/$guid/repoplugins"
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Log into the Run interface again, as detailed in &lsquo;[Test the Run
Interface](#test-the-run-interface)&rsquo; above. The user interface should now
show navigation links in the left hand side of the window.

### Add a Data Centre and Environment

One data centre, 'testdc', and one environment, 'testenv', will be added using
the following code:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
guid=`curl -ks -d '{"Login":"admin","Password":"admin"}' https://127.0.0.1:443/api/login | grep -o "[a-z0-9][^\"]*"`

# Create the DC

curl -ks -d '{
    "SysName":"testdc",
    "DispName":"Test DC"
    }' "https://127.0.0.1:443/api/admin/$guid/dcs"

# Get the ID of the DC

dcid=`curl -ks "https://127.0.0.1:443/api/admin/$guid/dcs?sys_name=testdc" | grep Id | grep -o "[0-9]"`

# Check that dcid is a number (probably '1')
echo $dcid

# Create the Environment

curl -ks -d '{
    "SysName":"testenv",
    "DispName":"Test Environment",
    "DcId":'"$dcid"',
    "WorkerUrl":"https://127.0.0.1:4443/",
    "WorkerKey":"lOcAlH0St"
}' "https://127.0.0.1:443/api/admin/$guid/envs"
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

### Change User Permissions

Now that the environment, testenv, is set up, the 'nomen.nescio' user
needs to be given access to it.

A function, 'add_perm', is temporarily added to the shell in the code
below that takes the following arguments:

1. login (text)
2. data centre (text)
3. environment (text)
4. Enabled (true|false)
5. Writeable (true|false)

Apply the permission:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
guid=`curl -ks -d '{"Login":"admin","Password":"admin"}' https://127.0.0.1:443/api/login | grep -o "[a-z0-9][^\"]*"`

# Add a function to the running shell

add_perm() {
    opts="-ks";proto="https";ipport="127.0.0.1:443"
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
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

### View the Admin interface

At this point most of the work setting up Obdi is complete, so
take some time in a Web Browser looking through the Admin interface
to see what has been done. All the configuration done thus far could
have been completed using the Admin interface as it makes the same
REST calls. Further configuration using the Admin
interface, such as setting up more environments, or adding users,
might be easier.

## Local GIT Setup

Obdi relies on [GIT](https://git-scm.com/) branches to map environments and
versions. Refer to the
[obdi-saltconfigserver](https://github.com/mclarkson/obdi-saltconfigserver)
plugin page for more information.

A GIT repository should be created with a **branch** named 'testenv' to match
the **environment** named 'testenv' that was set up earlier. The 'testenv' GIT
branch holds the Salt Stack files for the 'testenv' environment.

A bare GIT repository will be created at `/srv/repos/saltrepo.git`, then this
repository will be cloned and populated with a single Salt Formula.  Obdi will
apply version numbers to this repository using branches.

**NOTE**: If using a remote repository, this local repository will still need
to be created, but the local repository should be created as a 'mirror' of the
remote one. Obdi 'fetches' changes from the remote repository before applying
versions thereby keeping the remote repository free of multiple version
branches.

The [obdi-saltupdategit](https://github.com/mclarkson/obdi-saltupdategit)
plugin deals with versioning and was installed earlier.

### Creating the Repository

The following commands will set up GIT as described above.

Create the bare GIT repository:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
mkdir -p /srv/repos/saltrepo.git
cd /srv/repos/saltrepo.git/
git --bare init
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Set GIT up:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
git config --global user.email "YOUR.EMAIL@ADDRESS"
git config --global user.name "YOUR NAME"
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Clone the GIT repository and set up the 'master' and 'testenv' branches.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
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
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Now add a Salt Formula for installing the Unix *tree* command:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
mkdir -p ~/saltrepo/root/tree
cd ~/saltrepo/root/tree
echo "# INFO: Installs the 'tree' command." >init.sls
echo -e "\ntree:\n  pkg.installed" >>init.sls
cd ..
git add tree
git commit -am "Added tree formula"
git push -u origin testenv
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## Installing Salt Stack

Install Salt Stack from the Ubuntu PPA (Instructions were taken from
the [Salt Docs](http://docs.saltstack.com/en/latest/topics/installation/rhel.html)). At the time of writing the following steps installed Salt Stack version 2015.5.2.

The following code block installs the Salt Master and Minion:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Add a convenience 'hosts' entry so the Minion doesn't need configuring

echo "127.0.1.2 salt" >>/etc/hosts

# Install Salt

yum -y install salt-master salt-minion GitPython
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Create a Salt configuration file:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
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
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Start the Salt services, as they do not start automatically:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
/etc/init.d/salt-master start
/etc/init.d/salt-minion start
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## Final Tasks

### Install the External Node Classifier

The External Node Classifier, or ENC, replaces `top.sls` files. A python
script, `enc_query.py`, should be copied to the system `PATH` so that
Salt can find it.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
cp /usr/share/obdi/static/plugins/saltconfigserver/scripts/enc_query.py /usr/bin/

chmod +x /usr/bin/enc_query.py
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

### Configure the Salt Job Viewer

The Salt Job Viewer relies on a daemon that watches for changes in Salt's
job queue.

This daemon:

* Should be run from the *cron* daemon.
* Requires a new user to accept job status submissions.
* Needs a configuration file at `/etc/obdi/job_status.conf`.

Set up the Job Viewer:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Add a user with no permissions to any environments

guid=`curl -ks -d '{"Login":"admin","Password":"admin"}' https://127.0.0.1:443/api/login | grep -o "[a-z0-9][^\"]*"`

curl -ks -d '{
    "login":"jobviewer",
    "passHash":"CHANGE_THIS_PASSWORD",
    "forename":"Jobviewer",
    "surname":"Daemon",
    "email":"jobviewer@invalid",
    "enabled":true}' "https://127.0.0.1:443/api/admin/$guid/users"

# Write the configuration file

echo -e 'STATUS_USER="jobviewer"\nSTATUS_PASS="CHANGE_THIS_PASSWORD"' >/etc/obdi/job_status.conf

# Add a cron job

crontab -l >newcron
echo "* * * * * /usr/share/obdi/static/plugins/saltjobviewer/scripts/job_notify.sh" >>newcron
crontab newcron
rm newcron
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

### Change Default Passwords

**Change the 'admin' password**

Log into the Admin interface, click &lsquo;Users&rsquo;, then change
the password for the 'admin' user.

**Change the worker passwords** 

In `/etc/obdi-worker/obdi-worker.conf` change:

*   The 'key' variable. Then:

    Log into the Admin interface, click &lsquo;Environments&rsquo;,
    then change the password for the relevant environment.

*   The 'man_password' variable. Then:

    Log into the Admin interface, click &lsquo;Users&rsquo;, and change
    the password for the relevant user. The user to change is defined in
    the 'man_user' variable in the `obdi-worker.conf` file.

## All done

That's it for the configuration side. Read on for a quick
tour of the user interface.

# Using Obdi

This section provides a whirlwind tour of the user interface.

## Quick Guide

Using a Web Browser, log into the Run Interface.

Click on &lsquo;Salt Tools&rsquo; to expand the menu item.

### Accept the Minion's Key

Click the 'tick' icon to accept the key and wait for it to move to the Accepted
Keys section.

Click the Environment Setting icon and enter the following details:

* Datacentre: **testdc**
* Environment: **testenv**
* Version: *leave empty*

Click Apply. Wait. Click Go Back.

### Version the GIT Repo

In the left menu, click Update Git Repository.

Choose the Environment then Show Git Versions,

Use the arrows to choose '0.1.0' for the initial version, or any other version you like.

Click Apply. Wait. A version list will appear.

### Map Classes to Hosts

An entry that installs 'tree' on all servers will be created.

Click Map Classes to Hosts in the left hand side menu.

Choose the Environment then Show Host Mappings. Wait - this
will take a long time to load as the Go source
is compiled. The source file uses sqlite, which takes a long
time to compile.

Click Add Regular Expression and enter the following details:

* Name: **allservers**
* Description: **All servers**
* Regex: **.***

Note that the Regex field accepts Perl regular expressions only. If server host
names reflect their purpose then this feature can reduce the amount of
configuration that needs to be done when setting up a new server.

Click Apply. Wait. Go Back

Click the Configure Classes icon. Wait - it's compiling.

Click Choose option and select 'tree' then click the Add Class icon.

Click Apply. Wait. Go Back.

### Configure the Server

Click Map Configure Server in the left hand side menu.

Choose the Environment then List Servers. Wait. The server will be
shown.Configure Classes

Click the check box in the left most column of the table and the row will be
hilighted.

Click the plus sign in the Version column and choose the '0.1.0' version. Click
Apply, wait, then Go Back.

Click the Server Configuration icon. Wait - it's compiling.
The server already has 'tree' in the list since it was added
earlier in Map Classes to Hosts.

Go Back.

Click View Server Grains to see some server details.

Go Back.

Click Review.

Click Apply.

### View the Job Status

Wait a couple minutes for 'tree' to be installed, the click
Job Viewer in the left hand side menu.

Choose the Environment then Show Salt Jobs.

Lots of jobs will be shown. Filter the jobs by typing 'high'
into the Search box above the left hand side menu.

Click the View Result icon to see the output from state.highstate.

### All done

That's it for the quick tour of the Salt Tools user
interface.
