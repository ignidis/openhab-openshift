# openhab image
#
# ------------------------------------------------------------------------------
#
# ------------------------------------------------------------------------------
#
FROM    cybearth/centos:7

#
# Build Time Arguments
#
ARG NAME
ARG APP_ROOT
ARG OPENHAB_VERSION
ARG JAVA_URL
ARG NODE_VERSION
ARG	OPENHAB_SVC_NAME
ARG	OPENHAB_SVC_UID

#
# Runtime environment variables
#
ENV	EXTRA_JAVA_OPTS="" \
	OPENHAB_HTTP_PORT="8080" \
	OPENHAB_HTTPS_PORT="8443" \
	OPENHAB_FRONTTAIL_PORT="9001" \
	OPENHAB_LSP_PORT="5007" \
	OPENHAB_HOME="/home/${OPENHAB_SVC_NAME}/" \
	PATH="/opt/openhab/bin:${PATH}"

RUN \
#
# Set Installation Parameters
#
	LC_ALL="en_US.UTF-8" \
	LANG="en_US.UTF-8" \
	LANGUAGE="en_US.UTF-8" \
#
# Define Service Account variables
#
	SERVICE_USER=${OPENHAB_SVC_NAME}; \
	SERVICE_USER_UID=${OPENHAB_SVC_UID}; \
	SERVICE_GROUP=${OPENHAB_SVC_NAME}; \
	SERVICE_GROUP_UID=${OPENHAB_SVC_UID}; \
#
# Do not add sudo, if required add that group to the docker run command
#
	ADD_GROUPS=""; \
#
# Create service group and service account
#
	groupadd -g "$SERVICE_GROUP_UID" "$SERVICE_GROUP"; \
	useradd -u "$SERVICE_USER_UID" -g "$SERVICE_GROUP" --groups "$ADD_GROUPS" --shell /bin/bash --create-home "$SERVICE_USER"; \
#
# Allow service account to sudo without pasword
# We will use this only when we need a initialization run for the container, the init run should also assign the sudo group to the service user
#
#	echo "${SERVICE_USER} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/090_${SERVICE_USER}-nopasswd; \
#
#
# No need to update Base image on install EPEL as this is already in the cybearth base image
#
# Install helper packages
#
	yum -y install \
		wget \
		dpkg \
#		sudo \
		apt-utils \
		xz-utils \
		unzip \
		ca-certificates \
		sqlite3 \
	; 
#
#
# Install OPENHAB and supporting packages
#
RUN \
	ln -s -f /bin/true /usr/bin/chfn; \
	mkdir -p "${APP_ROOT}"; \ 
#
# CWD
#
	cd /home/"$SERVICE_USER"/; \
#
# Install the Java Runtime
#
	JAVA_HOME='/usr/lib/java'; \
	wget -nv -O /tmp/java.tar.gz ${JAVA_URL}; \
	mkdir ${JAVA_HOME}; \
	tar --exclude='man' --exclude='demo' --exclude='sample' --exclude='src.zip' -xvf /tmp/java.tar.gz --strip-components=1 -C ${JAVA_HOME}; \
	rm /tmp/java.tar.gz; \
	update-alternatives --install /usr/bin/java java ${JAVA_HOME}/bin/java 50; \
	update-alternatives --install /usr/bin/javac javac ${JAVA_HOME}/bin/javac 50; \
#
# Install Java unlimited strength cryptography
#
	wget -q -O /tmp/ZuluJCEPolicies.zip https://cdn.azul.com/zcek/bin/ZuluJCEPolicies.zip; \
	unzip -jo -d ${JAVA_HOME}/jre/lib/security /tmp/ZuluJCEPolicies.zip; \
	rm /tmp/ZuluJCEPolicies.zip; \
#
# Install openhab
#
	OPENHAB_URL="https://bintray.com/openhab/mvn/download_file?file_path=org/openhab/distro/openhab/${OPENHAB_VERSION}/openhab-${OPENHAB_VERSION}.zip"; \
	wget -nv -O /tmp/openhab.zip ${OPENHAB_URL}; \
	unzip -q /tmp/openhab.zip -d /opt/openhab/; \
	rm /tmp/openhab.zip; \
	mv /opt/openhab/userdata /opt/openhab/userdata.dist; \
	mv /opt/openhab/conf /opt/openhab/conf.dist; \
	mv /opt/openhab/addons /opt/openhab/addons.dist; \
	echo "export TERM=dumb" | tee -a ~/.bashrc; \
#
#
# Install the nodeJS Runtime
#
# Add the nodeJS Release team's, gpg keys to our keyring
# gpg keys listed at https://github.com/nodejs/node#release-team
	set -ex; \
	for key in \
		4ED778F539E3634C779C87C6D7062848A1AB005C \
		B9E2F5981AA6E0CD28160D9FF13993A75599653C \
		B9AE9905FFD7803F25714661B63B535A4C206CA9 \
		77984A986EBC2AA786BC0F66B01FBB92821C587A \
		71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
		FD3A5288F042B6850C66B31F09FE44734EB7990E \
		8FCCA13FEF1D0C2E91008E09770F7A9A5AE15600 \
		C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
		DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
		A48C2BEE680E841632CD4E44F07496B3EB3C1762 \
	;	do \
			gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
		done; \
	ARCH= \ 
		dpkgArch="$(dpkg --print-architecture)"; \
		case "${dpkgArch##*-}" in \
			amd64) ARCH='x64';; \
			ppc64el) ARCH='ppc64le';; \
			s390x) ARCH='s390x';; \
			arm64) ARCH='arm64';; \
			armhf) ARCH='armv7l';; \
			i386) ARCH='x86';; \
			*) echo "unsupported architecture"; exit 1 ;; \
		esac; \
	curl -fSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-$ARCH.tar.xz"; \
	curl -fSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc"; \ 
	gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc; \ 
	grep " node-v$NODE_VERSION-linux-$ARCH.tar.xz\$" SHASUMS256.txt | sha256sum -c -; \ 
	tar -xJf "node-v$NODE_VERSION-linux-$ARCH.tar.xz" -C "${APP_ROOT}" --no-same-owner; \ 
	ln -s "${APP_ROOT}/node-v$NODE_VERSION-linux-$ARCH" "${APP_ROOT}/node"; \ 
	ln -s "${APP_ROOT}/node/bin/node" "${APP_ROOT}/node/bin/nodejs"; \ 
	rm "node-v$NODE_VERSION-linux-$ARCH.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt; \ #
#
# Install frontail
#
	/opt/node/bin/npm i frontail -g; \
#
# Set permisions for application and nodejs directory
#
	chown -R "$SERVICE_USER":"$SERVICE_GROUP" "/opt/openhab/"; \
	chown -R "$SERVICE_USER":"$SERVICE_GROUP" "/opt/node-v$NODE_VERSION-linux-$ARCH"; \
#
# Final system update and reduce image size by removing files that are used only for building the image
#
	yum -y erase \
		dpkg \
		wget \
		ca-certificates \
		unzip \
		xz-utils \
		apt-utils \
	; \
	yum -q -y clean all; \
#
#
# Clean yum cache and logs
#
	rm -f /etc/yum.repos.d/*.rpm; \
#
# Rebuild the RPM Database
#
	rm -f /var/lib/rpm/__db*; \
	rpm --rebuilddb; \
#
	rm -rf /var/cache/*;\
	rm -rf /var/temp;\
	rm -f /var/log/* \
	;
#
# Copy the frontail openhab config files
#
COPY	frontail.dist/frontail-preset.json /opt/node/lib/node_modules/frontail/preset/openhab.json
COPY	frontail.dist/frontail-theme.css /opt/node/lib/node_modules/frontail/web/assets/styles/openhab.css
RUN		chown -R "${OPENHAB_SVC_NAME}":"${OPENHAB_SVC_NAME}" /opt/node/lib/node_modules/frontail/

#
# Copy the start command
#
COPY	bin/openhab-run.sh "/opt/openhab/openhab-run.sh"
RUN		chown "${OPENHAB_SVC_NAME}":"${OPENHAB_SVC_NAME}" "/opt/openhab/openhab-run.sh" && chmod +x "/opt/openhab/openhab-run.sh"

#
# Ammend the access rights to the configuration areas
# This will only work if the runtime user is member of the root group - this is the case with openshift
# In non openshift environment we should do the configuration volume initialization before attaching or make the executing user member of the root group
#
# add permisions to the application
# in addition allow the non root user to insert the anonymous openshift user if we want to use it
# and ensure we can read the config files
#
RUN  \
	chmod -R u+x ${APP_ROOT}/bin && \
	chgrp -R 0 ${APP_ROOT} && \
	chmod -R g=u ${APP_ROOT} /etc/passwd \
	; 
#
# Create the Configuration directory
#
VOLUME	/home/${OPENHAB_SVC_NAME}/.openhab/

#
# Publish the web app ports
#
# EXPOSE	8080 8443 9001 5007
#
EXPOSE "${OPENHAB_HTTP_PORT}" "${OPENHAB_HTTPS_PORT}"  "${OPENHAB_FRONTTAIL_PORT}" "${OPENHAB_LSP_PORT}"


USER		${OPENHAB_SVC_UID}
WORKDIR 	"/opt/openhab/"
ENTRYPOINT	[ "/opt/openhab/openhab-run.sh" ]
CMD			["./start.sh"]
#
#
# For testing and debugging comment out the above ENTRYPOINT, CMD and uncomment the following
#
#WORKDIR "/home/${OPENHAB_SVC_NAME}/"
#ENTRYPOINT [ "/bin/bash" ]