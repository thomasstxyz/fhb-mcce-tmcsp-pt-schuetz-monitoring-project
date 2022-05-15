## sample nginx deployment

```
kubectl create deployment nginx --image=nginx
kubectl get deployments
kubectl describe deployment nginx

kubectl create service nodeport nginx --tcp=80:80
kubectl get svc

curl <public_node_ip>

kubectl scale --replicas=3 deployment nginx

kubectl get pods -o wide

curl <cluster_ip_of_pod>
```
