# K8Cluster

[A word](http://blog.plataformatec.com.br/2019/10/kubernetes-and-the-erlang-vm-orchestration-on-the-large-and-the-small/)

Setup of a cluster of connected Erlang nodes within a Kubernetes cluster with `libcluster`.
We have no endpoint, no HTTP comminication in this app. The only communication will be within the TCP connection between e-nodes encapsulated in a k8-pod.

Two dockerfiles will produce respectively a release (**Dockerfile.rel**, image of 20 Mb) and an IEX shell (**Dockerfile.iex**, image of 150Mb) from the same app.
We spin-up several pods of the release, and one shell to interact with the releases via `:rpc.call(remote_node, Module, function, args)`.

The library `libcluster` will give automatic connection of the releases with `Cluster.Strategy.Kubernetes`, whith `kubernetes_ip_lookup_mode: :pods` and `mod: :ip`.
The shell has just a `CMD ["sh"]` since we don't know have an IP addresspod will automatically connect once we exec `iex -S mix`:

```bash
kubectl exec -it runner-5696b7f8cf-4k9g9 -- iex --name "k8_cluster@10.244.0.11" --cookie "release_secret" -S mix
```

```bash
> export POD_IP=app@127.0.0.1
> echo $POD_IP | sed 's/\./-/g'
app@127-0-0-1
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

Remember:

Secrets are scoped to the namespace, so you might want to put your app name as a prefix, unless you’re using a dedicated namespace.
A secret can contain multiple items. The example above uses cookie as the key.
Secrets aren’t actually that secret. Fortunately, Erlang cookies aren’t actually that secret either.

and the environmental varaibles for a deployment:

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

## Local registry: `Ctlplt`

Create a local registry for Docker images to be used by k8. No more needed to push Docker images to the Docker hub.

```bash
cat <<EOF | ctlptl apply -f -
apiVersion: ctlptl.dev/v1alpha1
kind: Cluster
product: minikube
registry: ctlptl-registry
kubernetesVersion: v1.23.3
EOF
```

- Create registry: `ctlptl apply -f ctlptl-registry.yml`
- Delete cluster: `ctlptl delete -f ctlptl-registry.yml`
- Check registries: `ctlptl get registry`
NAME              HOST ADDRESS     CONTAINER ADDRESS   AGE
ctlptl-registry   127.0.0.1:5000   172.17.0.2:5000     6m

## Tiltfile

```python
docker_build('rel-cluster', '.', dockerfile="Dockerfile.rel")
```

and reference containers.image: rel-cluster in the k8 manifest.

- build and tag the Dockerfile
`docker build -t cluster-of-rel -f k8/Dockerfile.rel .`

- build the image to the local registry:
`docker push localhost:5000/k8cluster`

- deploy the image:
`kubectl apply -f k8/myapp.yml` which references the previous image

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

iex --cookie "$(echo $ERLANG_COOKIE)" --name "$(echo k8_cluster@$(echo $POD_IP))" -S mix

:rpc.call(:"k8_cluster@10.244.0.45", K8Cluster, :hello, [] )
"Hello world"

## Docker comamnds

docker build  -t elixcluster -f Dockerfile.ex

docker network create erl-cluster

docker run -it --rm --network erl-cluster --name bnode  elixcluster  iex --sname b -S mix

docker build -t localhost:5000/k8cluster

docker run --rm  -it --user=root caching:test

If bare elixir, do
docker run --mount type=bind,src=$(pwd),dst=/app  --rm localhost:5000/elixir-min mix deps.get && mix deps.compile && iex --sname a -S mix
docker run -v "$(pwd)":/app --rm elixir-min mix deps.get && mix deps.compile && iex --sname a -S mix
