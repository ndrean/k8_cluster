FROM elixir:1.13.4-alpine AS build

ARG MIX_ENV
ENV MIX_ENV=${MIX_ENV:-dev}

RUN apk --update --no-cache add bash curl

WORKDIR /app
COPY . ./
RUN mix local.hex --force && mix deps.get && mix deps.compile

CMD ["bash"]