kubectl label nodes <master_node> svccontroller.k3s.cattle.io/enablelb=true

kubectl apply -f https://raw.githubusercontent.com/fhb-codelabs/sample-code-repo/master/manifests/podtato-kubectl.yaml

