TEST_DOCKER_REGISTRY='harbor.testos39.com'
TEST_NAMESPACE='zp1dev'

echo "This script is using TEST_DOCKER_REGISTRY as docker registry, and TEST_NAMESPACE as namespace"
echo "You should modify this script to use yours"
echo ""

oc project $TEST_NAMESPACE
oc create sa sdnchecker
oc adm policy add-cluster-role-to-user system:sdn-reader -z sdnchecker
oc adm policy add-scc-to-user anyuid -z sdnchecker

docker build -t sdnchecker .
if [[ $? -ne 0 ]]; then
    echo "Failed to build image. Exit"
    exit 1
fi
docker tag sdnchecker $TEST_DOCKER_REGISTRY/$TEST_NAMESPACE/sdnchecker:v1
docker push $TEST_DOCKER_REGISTRY/$TEST_NAMESPACE/sdnchecker:v1

echo "!!!"
echo "!!! NODES_FETCH_INTV change interval to fetch hostsubnets via openshift API, currently not set"
echo "!!!"

for i in `oc get node -o=jsonpath='{range .items[*]}{.metadata.name}{" "}'`; do
    oc get node $i -o=jsonpath='{.metadata.labels}' | grep -q "sdnChecking:true"
    if [[ $? -ne 0 ]]; then
        oc label node $i sdnChecking=true
    fi
done

sed "s/TEST_DOCKER_REGISTRY/$TEST_DOCKER_REGISTRY/g" sdnchecker.yml >> sdnchecker-test.yml
sed -i "s/TEST_NAMESPACE/$TEST_NAMESPACE/g" sdnchecker-test.yml
oc create -f sdnchecker-test.yml