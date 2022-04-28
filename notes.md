kubectl label nodes <master_node> svccontroller.k3s.cattle.io/enablelb=true

kubectl apply -f https://raw.githubusercontent.com/fhb-codelabs/sample-code-repo/master/manifests/podtato-kubectl.yaml

# jaeger installation

kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.6.3/cert-manager.yaml

kubectl create namespace observability # <1>
kubectl create -f https://github.com/jaegertracing/jaeger-operator/releases/download/v1.33.0/jaeger-operator.yaml -n observability # <2>

# helm install

curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod +x get_helm.sh
./get_helm.sh
helm

# elasticsearch install

helm repo add elastic https://helm.elastic.co
curl -O https://raw.githubusercontent.com/elastic/helm-charts/master/elasticsearch/examples/minikube/values.yaml
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
helm install elasticsearch elastic/elasticsearch -f ./values.yaml
kubectl get pods –-namespace=default -l app=elasticsearch-master -w
helm test elasticsearch
kubectl port-forward svc/elasticsearch-master 9200

# jaeger install (https://docs.dapr.io/operations/monitoring/tracing/supported-tracing-backends/jaeger/)

## Install Jaeger
helm repo add jaegertracing https://jaegertracing.github.io/helm-charts
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
helm install jaeger-operator jaegertracing/jaeger-operator
kubectl apply -f jaeger-operator.yaml

## Wait for Jaeger to be up and running
kubectl wait deploy --selector app.kubernetes.io/name=jaeger --for=condition=available

kubectl apply -f simplest.yaml
