docker_build(
   'rel-cluster',
   context='.',
   dockerfile="./df/Dockerfile.rel",
   live_update=[
      sync('./lib/', '/app/lib/'),
      sync('./df/', '/app/df/')
   ]
)
docker_build('elix-cluster', '.', dockerfile="./df/Dockerfile.ex")

k8s_yaml('./k8/sa.yml')
k8s_yaml(['./k8/runner.yml','./k8/myapp.yml'])

