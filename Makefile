dev-docker-compose := docker-compose -f docker-compose.yml -f docker-compose.dev.yml
test-docker-compose := docker-compose -f docker-compose.yml -f docker-compose.test.yml
start-phoenix := up --abort-on-container-exit --exit-code-from phoenix-app

docker-repo := emilianobovetti/hitbit

all: docker-build-prod

deps:
	mix deps.get

.env: deps
	mix app.gen.dotenv

config/%.secret.exs: deps
	mix app.gen.secret $*

.PHONY: clean
clean:
	mix clean
	rm -rf _build deps

.PHONY: dev
dev: deps config/dev.secret.exs
	mix ecto.setup
	mix phx.server

.PHONY: docker-build-cached-%
docker-build-cached-%:
	docker pull $(docker-repo):$* || true
	docker build . \
		--target $* \
		--build-arg MIX_ENV=$* \
		--tag $(docker-repo):$* \
		--cache-from $(docker-repo):$*

.PHONY: docker-build-%
docker-build-%:
	docker build . \
		--target $* \
		--build-arg MIX_ENV=$* \
		--tag $(docker-repo):$*

.PHONY: run
run: docker-build-dev
	$(dev-docker-compose) $(start-phoenix)

.PHONY: test
test: docker-build-test
	$(test-docker-compose) $(start-phoenix)

.PHONY: schema.graphql
schema.graphql:
	mix absinthe.schema.sdl --schema GraphQL.Schema

.PHONY: travis-test
travis-test: docker-build-cached-test
	$(test-docker-compose) $(start-phoenix)

.PHONY: heroku-release
heroku-release: config/prod.secret.exs
	heroku container:login
	heroku container:push web --arg MIX_ENV=prod -a hitbit-app
	heroku container:release web -a hitbit-app
