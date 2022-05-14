# K8Cluster

[A word](http://blog.plataformatec.com.br/2019/10/kubernetes-and-the-erlang-vm-orchestration-on-the-large-and-the-small/)

```bash
> export POD_IP=app@127.0.0.1
> echo $POD_IP | sed 's/\./-/g'
app@127-0-0-1
```

`alias tilt=/usr/local/bin/tilt`

## Local registry: `Ctlplt`

Create a local registry for Docker images to be used by k8 (no more needed to push Docker images to the Docker hub)

```bash

cat <<EOF | ctlptl apply -f -
apiVersion: ctlptl.dev/v1alpha1
kind: Cluster
product: minikube
registry: ctlptl-registry
kubernetesVersion: v1.23.3
EOF
```

- See running clusters: `ctlptl get`

- Delete cluster: `ctlptl delete cluster minikube`

- Create cluster: `ctlptl create cluster minikube --registry=ctlptl-registry`

- Create registry: `ctlptl apply -f ctlptl-registry.yml`

Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default
Switched to context "minikube".
 🔌 Connected cluster minikube to registry ctlptl-registry at localhost:5000
 👐 Push images to the cluster like 'docker push localhost:5000/alpine'
cluster.ctlptl.dev/minikube created

From the root project folder, run (all the Docker & k8 files are located under /k8):

- build and tag the Dockerfile
`docker build -t localhost:5000/k8cluster -f k8/Dockerfile .`
- build the image to the local registry:
`docker push localhost:5000/k8cluster`
- deploy the image:
`kubectl apply -f k8/myapp.yml` which references the previous image

- Check registries: `ctlptl get registry`
NAME              HOST ADDRESS     CONTAINER ADDRESS   AGE
ctlptl-registry   127.0.0.1:5000   172.17.0.2:5000     6m

- Delete: `ctlptl delete registry minikube-registry`

- Create registry: `ctlptl apply -f registry.yml`
or
`ctlptl create registry ctlptl-registry --port=5000 --listen-address 0.0.0.0`

## Libcluster

[Source for k8](https://blog.differentpla.net/blog/2022/01/08/libcluster-kubernetes/)

```bash
kubectl exec -it myapp-bbf85b547-mnqnq -- iex --name a@10-244-0-34.default.pod.cluster.local -S mix

kubectl get pods -l app=myapp -o json | \
  jq '.items[] | {ip: .status.podIP, namespace: .metadata.namespace}'

```

```json
{
  "ip": "10.244.0.33",
  "namespace": "default"
}
{
  "ip": "10.244.0.34",
  "namespace": "default"
}
```

kubectl get pods -o wide
NAME                    STATUS    IP            NODE
myapp-d4444db6d-m9m82   Running   10.244.0.48   minikube

kubectl exec -it myapp-d4444db6d-m9m82 -- iex --name k8_cluster@10.244.0.48 -S mix
