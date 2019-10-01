# openhab image
#
# ------------------------------------------------------------------------------
#               NOTE: THIS DOCKERFILE IS GENERATED VIA "update.sh"
#
#                       PLEASE DO NOT EDIT IT DIRECTLY.
# ------------------------------------------------------------------------------
#
FROM 	centos:7

# Set container type
ENV 	container docker

# Set variables and locales
ENV		APPDIR="/opt/openhab" \
		EXTRA_JAVA_OPTS="" \
		OPENHAB_HTTP_PORT="8080" \
		OPENHAB_HTTPS_PORT="8443" \
		LC_ALL="en_US.UTF-8" \
		LANG="en_US.UTF-8" \
		LANGUAGE="en_US.UTF-8" \
		CRYPTO_POLICY="limited"

# Set arguments on build
ARG		BUILD_DATE
ARG		VCS_REF
ARG		VERSION

# Basic build-time metadata as defined at http://label-schema.org
LABEL	org.label-schema.build-date=$BUILD_DATE \
		org.label-schema.docker.dockerfile="/Dockerfile" \
		org.label-schema.license="EPL" \
		org.label-schema.name="openHAB" \
		org.label-schema.vendor="openHAB Foundation e.V." \
		org.label-schema.version=$VERSION \
		org.label-schema.description="An open source, technology agnostic home automation platform" \
		org.label-schema.url="http://www.openhab.com/" \
		org.label-schema.vcs-ref=$VCS_REF \
		org.label-schema.vcs-type="Git" \
		org.label-schema.vcs-url="https://github.com/openhab/openhab-docker.git" \
		# As long as this image remains unofficial the maintainer must not be the official repo ;)
		maintainer="Baby Doe <baby.doe@cybearth.net>"

# Install basepackages
RUN		yum -y install epel-release; \
		yum -y install sudo wget unzip dpkg; \
		yum -y update &&  yum -y upgrade; \
		ln -s -f /bin/true /usr/bin/chfn

# Install java
ENV		JAVA_URL="https://www.azul.com/downloads/zulu/zdk-8-ga-linux_x64.tar.gz" \
		JAVA_HOME='/usr/lib/java-8'
RUN		wget -nv -O /tmp/java.tar.gz ${JAVA_URL}; \
		mkdir ${JAVA_HOME}; \
		tar --exclude='demo' --exclude='sample' --exclude='src.zip' -xvf /tmp/java.tar.gz --strip-components=1 -C ${JAVA_HOME}; \
		rm /tmp/java.tar.gz; \
		update-alternatives --install /usr/bin/java java ${JAVA_HOME}/bin/java 50; \
		update-alternatives --install /usr/bin/javac javac ${JAVA_HOME}/bin/javac 50;

# Install GOSU
ENV		GOSU_VERSION 1.10
RUN		set -ex; \
		dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"; \
		wget -O /usr/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch"; \
		wget -O /tmp/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc"; \
		# verify the signature
		export GNUPGHOME="$(mktemp -d)"; \
		gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; \
		gpg --batch --verify /tmp/gosu.asc /usr/bin/gosu; \
		rm -r "$GNUPGHOME" /tmp/gosu.asc; \
		chmod +x /usr/bin/gosu; \
		# verify that the binary works
		gosu nobody true;


# Install openhab
# Set permissions for openhab. Export TERM variable. See issue #30 for details!
ENV		OPENHAB_VERSION="2.2.0" \
		OPENHAB_URL="https://bintray.com/openhab/mvn/download_file?file_path=org%2Fopenhab%2Fdistro%2Fopenhab%2F2.2.0%2Fopenhab-2.2.0.zip"
RUN		wget -nv -O /tmp/openhab.zip ${OPENHAB_URL}; \
		unzip -q /tmp/openhab.zip -d ${APPDIR}-${OPENHAB_VERSION};  \
		rm /tmp/openhab.zip; \
		mkdir -p ${APPDIR}-${OPENHAB_VERSION}/userdata/logs; \
		touch ${APPDIR}-${OPENHAB_VERSION}/userdata/logs/openhab.log; \
		cp -a ${APPDIR}-${OPENHAB_VERSION}/userdata ${APPDIR}-${OPENHAB_VERSION}/userdata.dist; \
		cp -a ${APPDIR}-${OPENHAB_VERSION}/conf ${APPDIR}-${OPENHAB_VERSION}/conf.dist; \
		echo "export TERM=dumb" | tee -a ~/.bashrc; \
		ln -s ${APPDIR}-${OPENHAB_VERSION} ${APPDIR};

# Create openhab group and service account
RUN		groupadd -g 9001 openhab; \ 
		useradd  -u 9001 -g openhab --no-create-home --home-dir ${APPDIR} openhab

# Set permisions for application directory and symlink
RUN		chown -R openhab:openhab ${APPDIR}-${OPENHAB_VERSION}; \
		chown -R openhab:openhab ${APPDIR};

# Expose volume with configuration and userdata dir
VOLUME	${APPDIR}-${OPENHAB_VERSION}/conf ${APPDIR}-${OPENHAB_VERSION}/userdata ${APPDIR}-${OPENHAB_VERSION}/addons

# Expose HTTP, HTTPS, Console and LSP ports
EXPOSE	8080 8443 8101 5007

# Final system update and reduce image size by removing files that are used only for building the image
RUN     yum -y remove wget dpkg unzip; \
        yum -y update && yum -y upgrade; \
        yum clean all -y; \
        rm -rf /var/cache/yum; \
        rm -rf /var/temp; 

#
# Openshift Security fixes
#
# Openshift doesn't like containers running as root, no one does, so we use a user and group defined for the purpose
# We define an unprivileged host user that has the same UID as a container user with root privileges via wheel
# Then we start the image using that unprivileged host user and in the container entrypoint use sudo for the privileged commands
# and then gosu to change to the unprivileged openhab user running the application
# To avoid sudo asking for a password we must allow wheel users without password to do ALL privileged commands
# You can refine the sudo privileges to limit the operations without password if you please, but IMHO this has no benefit to overall security
# Basically you simulate root starting the container, which is the usual behavior for most images
#
# To make sure that Openshift starts the container with the user UID defined below you must add the OS Project
# service account to the anyuid SCC
# oc adm policy add-scc-to-user anyuid system:serviceaccount:myproject:default
# This approach can be used for any image that needs root access in the container

# Create the service account user that will have full root access in the container
# Override the sudo password requirement
# Tell Docker the (unprivileged) host UID we want to use for starting the container
RUN		useradd -u 9009 -G wheel,openhab -r -s /sbin/nologin service
COPY	sudoers /etc/sudoers
USER 	9009

# Set working directory, image Entrypoint and start command
WORKDIR	${APPDIR}
ADD		entrypoint.sh /opt/
RUN		sudo chmod +x /opt/entrypoint.sh;\
		sudo chown 9009:root /opt/entrypoint.sh
ENTRYPOINT	["/opt/entrypoint.sh"]
CMD			["sudo", "gosu", "openhab", "./start.sh"]
