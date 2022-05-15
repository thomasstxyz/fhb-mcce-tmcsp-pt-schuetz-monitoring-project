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

## Development environment with Vagrant/Virtualbox

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

## Deployment

### Terraform

- Set the name of your EC2 key pair name

for Windows PowerShell:

    $env:TF_VAR_ssh_key = "my_key_pair"

for Linux/MacOS:

    export TF_VAR_ssh_key="my_key_pair"

- Apply Terraform

```
cd terraform
terraform apply
```

This will create EC2 instances and write their public ip addresses into the file `ansible/inventory`.

### Ansible

- Run Ansible Playbook

```
cd ansible
ansible-playbook -i inventory main.yml
```

This will install a Kubernetes Cluster.

## Jaeger Installation

All Kubernetes manifests used in the following,
are at `./kubernetes/manifests/`.

SSH into your master and follow the installation steps.

    ssh ubuntu@<node_ip>
    sudo su -
    kubectl get nodes

### jaeger operator

kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.6.3/cert-manager.yaml

kubectl create namespace observability
kubectl create -f https://github.com/jaegertracing/jaeger-operator/releases/download/v1.33.0/jaeger-operator.yaml -n observability

### sample deployment

kubectl apply -f podtato-kubectl.yaml

### jaeger instance

kubectl -n podtato-kubectl apply -f https://raw.githubusercontent.com/jaegertracing/jaeger-operator/main/examples/simplest.yaml

### Expose Jaeger UI on NodePort

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

