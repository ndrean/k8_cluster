# K8Cluster

[A word](http://blog.plataformatec.com.br/2019/10/kubernetes-and-the-erlang-vm-orchestration-on-the-large-and-the-small/)

Setup of a cluster of connected Erlang nodes within a Kubernetes cluster with `libcluster`.
We have no endpoint, no HTTP communication in this app. The only communication will be within the TCP connection between e-nodes encapsulated in a k8-pod, and k8 itself via it's TCP connections.

Two dockerfiles will produce respectively a release (**Dockerfile.rel**, image of 20 Mb) and an IEX shell (**Dockerfile.mix**, image of 150Mb) from the same app.
We spin-up several pods of the release, and one shell to interact with the releases via `:rpc.call(remote_node, Module, function, args)`.

The library `libcluster` will give automatic connection of the releases with the topology `Cluster.Strategy.Kubernetes`, with:

- `kubernetes_ip_lookup_mode: :pods`
- `mod: :ip`,
- and a `ServiceAccount` set.

## Namespace

Added a namespace to isolate the whole. The namespace has to be added in the app for `libcluster` and set by `kubectl`. Create the ns with `kubectl` and set the namespace with `kubens`:

```bash
>kubectl create namespace stage
namespace/stage created

> kubens stage
Context "minikube" modified.
Active namespace is "stage".

> kubens
kube-node-lease
kube-public
kube-system
*stage
```

## Launch

```bash
> ctlptl apply -f k8/ctlptl-minikube-cluster-reg.yml
Switched to context "minikube".
cluster.ctlptl.dev/minikube created

> ctlptl get
CURRENT   NAME       PRODUCT    AGE   REGISTRY
*         minikube   minikube   13m   localhost:64612

> ctlptl get registry
NAME                       HOST ADDRESS      CONTAINER ADDRESS   AGE
ctlptl-minikube-registry   127.0.0.1:64612   172.17.0.2:5000     16m

> The shell has just a `CMD ["sh"]`. The pod will automatically connect once we `kubectl exec -it runner-pod-name -- sh` and the following in the pod shell:

```bash
> kubectl get pods -o wide

NAME                    STATUS    IP            NODE
myapp-d4444db6d-m9m82   Running   10.244.0.48   minikube

> kubectl exec -it runner-5696b7f8cf-4k9g9 -- sh

bash# iex --cookie "$(echo $ERLANG_COOKIE)" --name "$(echo k8_cluster@$(echo $POD_IP))" -S mix
```

## Cookies

[Nice post](https://blog.differentpla.net/blog/2022/01/09/erlang-cookies-and-kubernetes/)

By default, Erlang reads the cookie from **~/.erlang.cookie** (created if not exist).

Elixir releases
If you’re using mix release, a random cookie is created at build time and written to _build/prod/rel/myapp/releases/COOKIE. This means that the cookie changes every time you build from clean, which will break your cluster.

You can specify a cookie with the :cookie option in mix.exs. I would avoid doing this because it means that the cookie is now visible in source control history.

The other way to set the cookie is to set the RELEASE_COOKIE environment variable before starting the release. You can do this in rel/env.sh.eex, or from a Kubernetes secret.

Secrets:

```bash
> ERLANG_COOKIE=$(head -c 40 < /dev/random | base64 | tr '/+' '_-')
# or in Elixir:
iex> Base.url_encode64(:crypto.strong_rand_bytes(40))

>kubectl --namespace myapp create secret generic erlang-cookie --from-literal=cookie="$ERLANG_COOKIE"
```

Remember: secrets are scoped to the namespace, so you might want to put your app name as a prefix, unless you’re using a dedicated namespace. A secret can contain multiple items. The example above uses cookie as the key. Secrets aren’t actually that secret. Fortunately, Erlang cookies aren’t actually that secret either.
Set the environmental variables for a deployment:

```yml
containers:
- name: myapp
  env:
  - name: RELEASE_COOKIE  # or RELX_COOKIE (or just set both)
    valueFrom:
      secretKeyRef:
        name: erlang-cookie
        key: cookie
```

## Not to forget

`alias tilt=/usr/local/bin/tilt`

[Access k8 API from within a pod](https://blog.differentpla.net/blog/2022/01/16/k8s-api-elixir-container/) using `:httpc` so simply (compared to Ruby!!), and the [k8s](https://hexdocs.pm/k8s/readme.html) package.

## Local registry: `ctlplt`

Create a local registry for Docker images to be used by `k3d` or `minikube`. No more needed to push Docker images to the Docker hub. The images wil lbe registred under `172.17.0.2:5000:my-image`

- Create registry: `ctlptl apply -f ctlptl-registry.yml`
- Delete cluster: `ctlptl delete -f ctlptl-registry.yml`
- Check registries: `ctlptl get registry`

```txt
NAME              HOST ADDRESS     CONTAINER ADDRESS   AGE
ctlptl-registry   127.0.0.1:5000   172.17.0.2:5000     6m
```

Then Tilt will use this local registry and not go to the Docker hub.

## Tiltfile

Run `tilt up` and `tilt down`.

## Libcluster

[Source for k8](https://blog.differentpla.net/blog/2022/01/08/libcluster-kubernetes/)

```bash
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

## Docker comamnds

```bash
docker build  -t elixcluster -f Dockerfile.ex

docker network create erl-cluster

docker run -it --rm --network erl-cluster --name bnode  elixcluster  iex --sname b -S mix

docker build -t localhost:5000/k8cluster

docker run --rm  -it --user=root caching:test

# If bare elixir, do
docker run --mount type=bind,src=$(pwd),dst=/app  --rm localhost:5000/elixir-min mix deps.get && mix deps.compile && iex --sname a -S mix

docker run -v "$(pwd)":/app --rm elixir-min mix deps.get && mix deps.compile && iex --sname a -S mix
```
