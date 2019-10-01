#!/bin/bash -x
whoami && id
# Karaf needs a pseudo-TTY so exit and instruct user to allocate one when necessary
test -t 0
if [ $? -eq 1 ]; then
    echo "Please start the openHAB container with a pseudo-TTY using the -t option or 'tty: true' with docker compose"
    exit 1
fi

set -euo pipefail
IFS=$'\n\t'

# Install Java unlimited strength cryptography
if [ "${CRYPTO_POLICY}" = "unlimited" ] && [ ! -f "${JAVA_HOME}/jre/lib/security/README.txt" ]; then
  echo "Installing Zulu Cryptography Extension Kit (\"CEK\")..."
  sudo wget -q -O /tmp/ZuluJCEPolicies.zip https://cdn.azul.com/zcek/bin/ZuluJCEPolicies.zip
  sudo unzip -jo -d ${JAVA_HOME}/jre/lib/security /tmp/ZuluJCEPolicies.zip
  sudo rm /tmp/ZuluJCEPolicies.zip
fi

# Deleting instance.properties to avoid karaf PID conflict on restart
# See: https://github.com/openhab/openhab-docker/issues/99
sudo rm -f ${APPDIR}/runtime/instances/instance.properties

# The instance.properties file in OH2.x is installed in the tmp
# directory
sudo rm -f ${APPDIR}/userdata/tmp/instances/instance.properties

# Add possible device groups for different host systems
# GPIO Group for RPI access
if ! [ $(getent group gpio) ]; then
	sudo groupadd -g 997 gpio
fi
sudo usermod -a -G dialout,gpio openhab

# Copy initial files to host volume
case ${OPENHAB_VERSION} in
  1.8.3)
      if [ -z "$(ls -A "${APPDIR}/configurations")" ]; then
        # Copy userdata dir for version 1.8.3
        echo "No configuration found... initializing."
        # Initialize the permisions for the mounted volumes
        sudo chown -R openhab:openhab ${APPDIR}/configurations/
        sudo -u openhab cp -av "${APPDIR}/configurations.dist/." "${APPDIR}/configurations/"
      fi
    ;;
  2.0.0|2.1.0|2.2.0|2.3.0-snapshot)
      # Initialize empty host volumes
      if [ -z "$(ls -A "${APPDIR}/userdata")" ]; then
        # Initialize the permisions for the mounted volumes
        sudo chown -R openhab:openhab ${APPDIR}/addons/
        sudo chown -R openhab:openhab ${APPDIR}/conf/
        sudo chown -R openhab:openhab ${APPDIR}/userdata/
        # Copy userdata dir for version 2.0.0
        echo "No userdata found... initializing."
        sudo -u openhab cp -av "${APPDIR}/userdata.dist/." "${APPDIR}/userdata/"
      fi

      # Upgrade userdata if versions do not match
      if [ ! -z $(cmp "${APPDIR}/userdata/etc/version.properties" "${APPDIR}/userdata.dist/etc/version.properties") ]; then
        echo "Image and userdata versions differ! Starting an upgrade."

        # Make a backup of userdata
        backupFile=userdata-$(date +"%FT%H:%M:%S").tar
        if [ ! -d "${APPDIR}/userdata/backup" ]; then
          sudo -u openhab mkdir "${APPDIR}/userdata/backup"
        fi
        sudo -u openhab tar --exclude="${APPDIR}/userdata/backup" -c -f "${APPDIR}/userdata/backup/${backupFile}" "${APPDIR}/userdata"
        echo "You can find backup of userdata in ${APPDIR}/userdata/backup/${backupFile}"

        # Copy over the updated files
        sudo -u openhab cp "${APPDIR}/userdata.dist/etc/all.policy" "${APPDIR}/userdata/etc/"
        sudo -u openhab cp "${APPDIR}/userdata.dist/etc/branding.properties" "${APPDIR}/userdata/etc/"
        sudo -u openhab cp "${APPDIR}/userdata.dist/etc/branding-ssh.properties" "${APPDIR}/userdata/etc/"
        sudo -u openhab cp "${APPDIR}/userdata.dist/etc/config.properties" "${APPDIR}/userdata/etc/"
        sudo -u openhab cp "${APPDIR}/userdata.dist/etc/custom.properties" "${APPDIR}/userdata/etc/"
        if [ -f "${APPDIR}/userdata.dist/etc/custom.system.properties" ]; then
          sudo -u openhab cp "${APPDIR}/userdata.dist/etc/custom.system.properties" "${APPDIR}/userdata/etc/"
        fi
        sudo -u openhab cp "${APPDIR}/userdata.dist/etc/distribution.info" "${APPDIR}/userdata/etc/"
        sudo -u openhab cp "${APPDIR}/userdata.dist/etc/jre.properties" "${APPDIR}/userdata/etc/"
        sudo -u openhab cp "${APPDIR}/userdata.dist/etc/org.apache.karaf"* "${APPDIR}/userdata/etc/"
        sudo -u openhab cp "${APPDIR}/userdata.dist/etc/org.ops4j.pax.url.mvn.cfg" "${APPDIR}/userdata/etc/"
        if [ -f "${APPDIR}/userdata.dist/etc/overrides.properties" ]; then
          sudo -u openhab cp "${APPDIR}/userdata.dist/etc/overrides.properties" "${APPDIR}/userdata/etc/"
        fi
        sudo -u openhab cp "${APPDIR}/userdata.dist/etc/profile.cfg" "${APPDIR}/userdata/etc/"
        sudo -u openhab cp "${APPDIR}/userdata.dist/etc/startup.properties" "${APPDIR}/userdata/etc"
        sudo -u openhab cp "${APPDIR}/userdata.dist/etc/system.properties" "${APPDIR}/userdata/etc"
        sudo -u openhab cp "${APPDIR}/userdata.dist/etc/version.properties" "${APPDIR}/userdata/etc/"
        echo "Replaced files in userdata/etc with newer versions"

        # Clear the cache and tmp
        sudo rm -rf "${APPDIR}/userdata/cache"
        sudo rm -rf "${APPDIR}/userdata/tmp"
        sudo sudo -u openhab mkdir "${APPDIR}/userdata/cache"
        sudo sudo -u openhab mkdir "${APPDIR}/userdata/tmp"
        echo "Cleared the cache and tmp"
      fi

      if [ -z "$(ls -A "${APPDIR}/conf")" ]; then
        # Copy userdata dir for version 2.0.0
        echo "No configuration found... initializing."
        sudo -u openhab cp -av "${APPDIR}/conf.dist/." "${APPDIR}/conf/"
      fi
    ;;
  *)
      echo openHAB version ${OPENHAB_VERSION} not supported!
    ;;
esac

exec "$@"
