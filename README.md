# Projektarbeit in LV TMCSP-PT / Schütz

Im Rahmen der Projektarbeit ist eine Lösung zum Monitoring einer Applikation mittels Open Source Projekten zu erstellen. Die Applikation soll aus mindestens 3 Services bestehen, davon manche mit mehreren Replicas.

## Aufgaben

- Je nach verwendeter Lösung ist diese Applikation entsprechend zu instrumentieren (Metriken, Traces, ev. Logs)
- Die angebotenen Telemetriedaten sollen von einem geeigneten Tool konsumiert werden
- Diese Lösung ist zu implementieren und zu dokumentieren und die technischen Schritte sollten weitgehend nachvollziehbar sein (Installationsscripts/Konfigurationsdateien)
- Die Präsentation wird vorab aufgenommen und an einen OneDrive Ordner übermittelt (wird als eigener Ordner angeboten). Diese Aufnahme wird den anderen Studierenden bereitgestellt.

## Constraints

- Projektdokumentation: 3-5 Seiten auf IEEE Template (https://www.ieee.org/conferences/publishing/templates.html)
- Code und Konfiguration ist ausreichend dokumentiert/kommentiert
- Jede Gruppe verwendet weitgehend unterschiedliche Tools
- Sämtliche Deliverables werden einer Plagiatsprüfung unterzogen, es wird vorausgesetzt dass die jeweiligen Konfigurationen von euch stammen

# Development environment with Vagrant/Virtualbox

Install [Oracle Virtualbox](https://www.virtualbox.org/wiki/Downloads) and
[Hashicorp Vagrant](https://www.vagrantup.com/downloads) on your machine.

Create your VM with Vagrant.

    vagrant up

Open a shell to your VM.

    vagrant ssh

Now, inside the VM, navigate to `/vagrant`, which is 
where the current directory is mapped.

    cd /vagrant

Before continuing with the deployment in the next section, 
setup your `~/.aws/credentials`
and your private SSH key.

# Deployment

## Terraform

- Set the name of your EC2 key pair name

for Windows PowerShell:

    $env:TF_VAR_ssh_key = "my_key_pair"

for Linux/MacOS:

    export TF_VAR_ssh_key="my_key_pair"

- Apply Terraform

```
cd terraform
terraform init
terraform apply
```

This will create EC2 instances and write their public ip addresses into the file `ansible/inventory`.

## Ansible

- Run Ansible Playbook

```
cd ansible
ansible-galaxy install -r roles/requirements.yml
ansible-playbook -i inventory main.yml
```

This will install a Kubernetes Cluster.

## Kubernetes

All Kubernetes manifests used in the following,
are at `./kubernetes/manifests/`.

    scp -r kubernetes ubuntu@<node_ip>:.

SSH into your master and follow the installation steps.

    ssh ubuntu@<node_ip>
    sudo su -
    cd /home/ubuntu/kubernetes/manifests
    kubectl get nodes

### Rook-Ceph storage

Since this is a bare Kubernetes cluster, a storage class,
which allows for dynamic volume provisioning, needs to be provided.

    kubectl apply -f lvm.yaml
    git clone --single-branch --branch release-1.3 https://github.com/rook/rook.git
    cd rook/cluster/examples/kubernetes/ceph
    kubectl create -f common.yaml
    kubectl create -f operator.yaml
    kubectl get pod -n rook-ceph

Wait for the pods to be up and running.

    NAME                                READY   STATUS    RESTARTS   AGE
    rook-ceph-operator-8d9bf87c-2sfsb   1/1     Running   0          74s
    rook-discover-6fh5h                 1/1     Running   0          53s
    rook-discover-d9lj6                 1/1     Running   0          53s
    rook-discover-dmwqd                 1/1     Running   0          53s

Create a ceph cluster.

    # cp ../../../../../cephcluster.yaml .
    cd -
    kubectl apply -f cephcluster.yaml
    kubectl get pod -n rook-ceph

This usually takes a couple of minutes, before all pods are running.

```
NAME                                                         READY   STATUS    RESTARTS   AGE  
csi-cephfsplugin-4vg2p                                       3/3     Running   0          3m43s
csi-cephfsplugin-bw6ps                                       3/3     Running   0          3m43s
csi-cephfsplugin-n9k6n                                       3/3     Running   0          3m43s
csi-cephfsplugin-provisioner-6748bb9646-bf598                5/5     Running   0          3m43s
csi-cephfsplugin-provisioner-6748bb9646-fr8dx                5/5     Running   0          3m43s
csi-rbdplugin-7tqq6                                          3/3     Running   0          3m44s
csi-rbdplugin-provisioner-78db9f787f-nstfv                   6/6     Running   0          3m44s
csi-rbdplugin-provisioner-78db9f787f-zmlsb                   6/6     Running   0          3m44s
csi-rbdplugin-sxds8                                          3/3     Running   0          3m44s
csi-rbdplugin-wqgdf                                          3/3     Running   0          3m44s
rook-ceph-crashcollector-ip-172-31-1-255-59bf886954-wvw4l    1/1     Running   0          39s
rook-ceph-crashcollector-ip-172-31-12-158-66684d8d54-g42d6   1/1     Running   0          101s
rook-ceph-crashcollector-ip-172-31-9-245-58b4977d65-4xsk5    1/1     Running   0          70s
rook-ceph-mgr-a-568bcd87df-48fdc                             1/1     Running   0          39s
rook-ceph-mon-a-7b9c94f654-mc92l                             1/1     Running   0          107s
rook-ceph-mon-b-845d78597b-7zzxw                             1/1     Running   0          101s
rook-ceph-mon-c-6f854cf567-4d62k                             1/1     Running   0          70s
rook-ceph-operator-8d9bf87c-2sfsb                            1/1     Running   0          6m13s
rook-ceph-osd-prepare-ip-172-31-1-255-blskv                  1/1     Running   0          37s
rook-ceph-osd-prepare-ip-172-31-12-158-k7dmk                 1/1     Running   0          36s
rook-ceph-osd-prepare-ip-172-31-9-245-g9bvl                  1/1     Running   0          36s
rook-discover-6fh5h                                          1/1     Running   0          5m52s
rook-discover-d9lj6                                          1/1     Running   0          5m52s
rook-discover-dmwqd                                          1/1     Running   0          5m52s
```

Now create the Storage Class and make it the default.

    cd rook/cluster/examples/kubernetes/ceph
    kubectl apply -f ./csi/rbd/storageclass.yaml
    kubectl patch storageclass rook-ceph-block -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
    kubectl get storageclass





### Jaeger

    kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.6.3/cert-manager.yaml
    kubectl -n cert-manager get all

Wait until cert-manager is ready.

Create the Jaeger operator.

    kubectl create namespace observability
    kubectl create -f https://github.com/jaegertracing/jaeger-operator/releases/download/v1.33.0/jaeger-operator.yaml -n observability

Create an example deployment.

    kubectl apply -f podtato-kubectl.yaml

Create a jaeger instance in the namespace of the example deployment.

    kubectl -n podtato-kubectl apply -f https://raw.githubusercontent.com/jaegertracing/jaeger-operator/main/examples/simplest.yaml

Expose Jaeger UI on a NodePort.

We do not setup Ingress for this demo purpose.
Therefore we expose the Jaeger UI on a NodePort.

    kubectl -n podtato-kubectl edit service/simplest-query

Change `ClusterIP` to `NodePort`.

Now get the random port via kubectl.

```
$ kubectl -n podtato-kubectl get svc simplest-query

service/simplest-query                    NodePort    10.107.250.51   <none>        16686:31835/TCP,16685:31352/TCP          29m
```

In this case, the port would be `31835`.

Finally, access the Jaeger UI in your Browser at `http://<node_ip>:<node_port>`.

### ELK Stack

Install Helm.

```
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 > get_helm.sh
chmod 700 get_helm.sh
./get_helm.sh
```

Add Elastic Helm Repository.

```
helm repo add elastic https://helm.elastic.co
helm repo update
helm search hub elasticsearch
```

Create a file `values-elasticsearch.yaml`

```yaml
# Shrink default JVM heap.
esJavaOpts: "-Xmx128m -Xms128m"

# Allocate smaller chunks of memory per pod.
resources:
  requests:
    cpu: "100m"
    memory: "512M"
  limits:
    cpu: "1000m"
    memory: "512M"

# Request smaller persistent volumes.
volumeClaimTemplate:
  accessModes: [ "ReadWriteOnce" ]
  storageClassName: "standard"
  resources:
    requests:
      storage: 100M
```

Install Elasticsearch.

    helm install elk-elasticsearch elastic/elasticsearch -f values-elasticsearch.yaml

Wait for all cluster members to come up.

    kubectl get pods --namespace=default -l app=elasticsearch-master -w

Install Kibana.

    helm install elk-kibana elastic/kibana





**error**: Kubernetes complains about too few resources available (cpu, memory, ..., also disk taint,....)
