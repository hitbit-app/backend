# HitBit [![Build Status](https://travis-ci.org/hitbit-app/backend.svg?branch=master)](https://travis-ci.org/hitbit-app/backend)

## Up and running

### Development environment with docker

* Install [docker](https://docs.docker.com/install/) and [docker-compose](https://docs.docker.com/compose/install/)

* Run `make run`

### Development environment (debian)

* Install [Elixir](https://elixir-lang.org/install.html)

* Install PostgreSQL:
    ```bash
    sudo apt install postgresql postgresql-client
    ```
* Create postgres user:
    ```bash
    sudo -u postgres psql
    ```
    ```sql
    CREATE USER "psql-username" WITH ENCRYPTED PASSWORD 'psql-password';
    ALTER USER "psql-username" CREATEDB;
    ```

* Run `make dev`

---

Now you can visit [`localhost:4000/graphiql`](http://localhost:4000/graphiql) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

  * Official website: http://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Mailing list: http://groups.google.com/group/phoenix-talk
  * Source: https://github.com/phoenixframework/phoenix
