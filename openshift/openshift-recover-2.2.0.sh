 oc new-build "2.2.0/amd64/centos" --name="openhab" --to="openhab:2.2.0-amd64-centos" && \
 oc start-build openhab --from-dir "2.2.0/amd64/centos" && \
 oc adm policy add-scc-to-user anyuid system:serviceaccount:openhab:default && \
 oc create -f openhab-deployment.yaml && \
 oc create -f openhab-service.yaml && \
 oc create -f openhab-routes.yaml