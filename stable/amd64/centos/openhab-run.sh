#!/bin/bash
#
# Echo DEBUG Info to the console
#
USER="$(id -un)"
USER_ID="$(id -u)"
echo "Starting openHAB version: $OPENHAB_VERSION"
echo "Service Account: $USER $USER_ID"
echo "HTTP Port: $OPENHAB_HTTP_PORT"
echo "HTTPS Port: $OPENHAB_HTTPS_PORT"
echo "FRONTAIL Port: $OPENHAB_FRONTAIL_PORT"
echo "CALLBACK Range: $OPENHAB_CALLBACK_RANGE"
#
# Karaf needs a pseudo-TTY so exit and instruct user to allocate one when necessary
#
	test -t 0
	if [ $? -eq 1 ]; then
    	echo "Please start the openHAB container with a pseudo-TTY using the -t option or 'tty: true' with docker compose"
	    exit 1
	fi
	set -euo pipefail
	IFS=$'\n\t'
#
# Check if the persistent configuration exists and link it into the container
#
	if ! [ -d ~/.openhab/userdata ]; then
		mkdir -p ~/.openhab/userdata;
		ln -s ~/.openhab/userdata /opt/openhab/userdata;
		#
		# Create log directory and file
		#
		mkdir -p /opt/openhab/userdata/logs;
		touch /opt/openhab/userdata/logs/openhab.log;
		touch /opt/openhab/userdata/logs/events.log;
		#
		# Copy initial userdata
		#
	    echo "No userdata found... initializing."
    	cp -av "/opt/openhab/userdata.dist/." "/opt/openhab/userdata/"
	fi
	if ! [ -d ~/.openhab/conf ]; then
		mkdir -p ~/.openhab/conf;
		ln -s ~/.openhab/conf /opt/openhab/conf;
		#
        # Copy initial configuration
		#
        echo "No configuration found... initializing."
        cp -av "/opt/openhab/conf.dist/." "/opt/openhab/conf/"
	fi
	if ! [ -d ~/.openhab/addons ]; then
		mkdir -p ~/.openhab/addons;
		ln -s ~/.openhab/addons /opt/openhab/addons;
	fi
#
# Create the container links to the persistent configuration
#
	if ! [ -L /opt/openhab/userdata ]; then
		ln -s ~/.openhab/userdata /opt/openhab/userdata;
	fi
	if ! [ -L /opt/openhab/conf ]; then
		ln -s ~/.openhab/conf /opt/openhab/conf;
	fi
	if ! [ -L /opt/openhab/addons ]; then
		ln -s ~/.openhab/addons /opt/openhab/addons;
	fi
#
# Remove the instance.properties file to avoid Karaf startup issues
#
	rm -f ~/.openhab/userdata/tmp/instances/instance.properties

#
# Upgrade userdata if versions do not match
#
	if [ ! -z $(cmp "/opt/openhab/userdata/etc/version.properties" "/opt/openhab/userdata.dist/etc/version.properties") ]; then
        echo "Image and userdata versions differ! Starting an upgrade."

		#
        # Make a backup of userdata
		#
        backupFile=userdata-$(date +"%FT%H:%M:%S").tar
        if [ ! -d "/opt/openhab/userdata/backup" ]; then
        	mkdir "/opt/openhab/userdata/backup"
        fi
        tar --exclude="/opt/openhab/userdata/backup" -c -f "/opt/openhab/userdata/backup/${backupFile}" "/opt/openhab/userdata"
        echo "You can find backup of userdata in /opt/openhab/userdata/backup/${backupFile}"

		#
        # Copy over the updated files
		#
        cp "/opt/openhab/userdata.dist/etc/all.policy" "/opt/openhab/userdata/etc/"
        cp "/opt/openhab/userdata.dist/etc/branding.properties" "/opt/openhab/userdata/etc/"
        cp "/opt/openhab/userdata.dist/etc/branding-ssh.properties" "/opt/openhab/userdata/etc/"
        cp "/opt/openhab/userdata.dist/etc/config.properties" "/opt/openhab/userdata/etc/"
        cp "/opt/openhab/userdata.dist/etc/custom.properties" "/opt/openhab/userdata/etc/"
        if [ -f "/opt/openhab/userdata.dist/etc/custom.system.properties" ]; then
        	cp "/opt/openhab/userdata.dist/etc/custom.system.properties" "/opt/openhab/userdata/etc/"
        fi
        cp "/opt/openhab/userdata.dist/etc/distribution.info" "/opt/openhab/userdata/etc/"
        cp "/opt/openhab/userdata.dist/etc/jre.properties" "/opt/openhab/userdata/etc/"
        cp "/opt/openhab/userdata.dist/etc/org.apache.karaf"* "/opt/openhab/userdata/etc/"
        cp "/opt/openhab/userdata.dist/etc/org.ops4j.pax.url.mvn.cfg" "/opt/openhab/userdata/etc/"
        if [ -f "/opt/openhab/userdata.dist/etc/overrides.properties" ]; then
          cp "/opt/openhab/userdata.dist/etc/overrides.properties" "/opt/openhab/userdata/etc/"
        fi
        cp "/opt/openhab/userdata.dist/etc/profile.cfg" "/opt/openhab/userdata/etc/"
        cp "/opt/openhab/userdata.dist/etc/startup.properties" "/opt/openhab/userdata/etc"
        cp "/opt/openhab/userdata.dist/etc/system.properties" "/opt/openhab/userdata/etc"
        cp "/opt/openhab/userdata.dist/etc/version.properties" "/opt/openhab/userdata/etc/"
        echo "Replaced files in userdata/etc with newer versions"

		#
       	# Clear the cache and tmp
		#
        rm -rf "/opt/openhab/userdata/cache"
        rm -rf "/opt/openhab/userdata/tmp"
        mkdir "/opt/openhab/userdata/cache"
        mkdir "/opt/openhab/userdata/tmp"
        echo "Cleared the cache and tmp"
      fi
#
# Initialize and Start frontail
#
if [ -e /opt/node/bin/frontail ]; then
	if ! [ -d ~/.openhab/frontail ]; then
        echo "Initialize Frontail config"
		mkdir -p ~/.openhab/frontail/preset;
		cp -av /opt/node/lib/node_modules/frontail/preset/. ~/.openhab/frontail/preset;
	fi
	if [ -e ~/.openhab/frontail/preset/openhab.json ]; then
        echo "Start Frontail in the background"
		/opt/node/bin/frontail --ui-highlight --ui-highlight-preset ~/.openhab/frontail/preset/openhab.json -t openhab -l 2000 -n 200 /opt/openhab/userdata/logs/openhab.log /opt/openhab/userdata/logs/events.log &>/dev/null &
		disown;
	fi
fi
#
# Start Openhab
#
exec "$@"
