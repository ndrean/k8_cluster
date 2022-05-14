FROM elixir:1.13.4-alpine AS build

# docker build --build-arg MIX_ENV=prod
ARG MIX_ENV

# let the ENV variable (runtime) be the same as the build argument
# docker run -e (or --env_file)
ENV MIX_ENV=${MIX_ENV:-dev}



WORKDIR /app
COPY . ./
RUN mix local.hex --force && mix deps.get && mix deps.compile

# ENTRYPOINT ["./entrypoint.sh"]
CMD ["sh"]



# docker build  -t elixcluster -f Dockerfile.ex .
# docker network create erl-cluster
# docker run -it --rm --network erl-cluster --name bnode  elixcluster  iex --sname b -S mix