# openhab image
#
# ------------------------------------------------------------------------------
#
# ------------------------------------------------------------------------------
#
FROM    builder:openhab-amd64-centos

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

# Do some bookeeping for the repository and openshift
#
#
# It is deprecated but guess what...There are a lot of tools that still use it
#
MAINTAINER ignidis(at)cybearth(dot)net (https://github.com/ignidis/node-docker)

#
# And this is for those new tools
#
LABEL summary="${NAME}-${OPENHAB_VERSION} is an SMARTHOME Platform based on JAVA" \
      description="${NAME}  is an SMARTHOME Platform based on JAVA" \
      io.k8s.description="${NAME} is an SMARTHOME Platform based on JAVA" \
      io.k8s.display-name="${NAME}-${OPENHAB_VERSION}" \
      io.openshift.tags="builder,${NAME},${NAME}-${NODE_VERSION}" \
      name="${NAME}" \
      version="${OPENHAB_VERSION}-amd64-centos" \
      maintainer="ignidis(at)cybearth(dot)net" \
      help="For more information visit https://github.com/ignidis/openhab-docker" \
      usage="s2i build <SOURCE-REPOSITORY> ${NAME}:${OPENHAB_VERSION}-amd64-centos <APP-NAME>"

#
#
# Setup runtime variables
#
ENV	EXTRA_JAVA_OPTS="" \
	OPENHAB_VERSION=${OPENHAB_VERSION} \
	OPENHAB_HTTP_PORT="8080" \
	OPENHAB_HTTPS_PORT="8443" \
	OPENHAB_FRONTAIL_PORT="9001" \
	OPENHAB_LSP_PORT="5007" \
	OPENHAB_CALLBACK_RANGE="9125-9145" \
	OPENHAB_HOME="/var/lib/openhab" \
	PATH="${APP_ROOT}/node/bin:${APP_ROOT}/openhab/bin:${PATH}"

#
# Publish the web app ports
#
# EXPOSE	8080 8443 9001 5007
#
EXPOSE "${OPENHAB_HTTP_PORT}" "${OPENHAB_HTTPS_PORT}"  "${OPENHAB_FRONTTAIL_PORT}" "${OPENHAB_LSP_PORT}"

#
# Create the Configuration directory
#
VOLUME	[${OPENHAB_HOME}]


USER		${OPENHAB_SVC_UID}
WORKDIR 	"${APP_ROOT}/openhab/"
ENTRYPOINT	[ "./bin/init" ]
CMD			["./start.sh"]
#
#
# For testing and debugging comment out the above ENTRYPOINT, CMD and uncomment the following
#
#WORKDIR "/home/${OPENHAB_SVC_NAME}/"
#ENTRYPOINT [ "/bin/bash" ]