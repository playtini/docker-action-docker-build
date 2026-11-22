# Docker Image for the Docker Image Build Github Action

This is a the actual implementation of the [Flownative Github Action for building Docker images](https://github.com/flownative/action-docker-build).
The actual Github action refers to a pre-built image in its `Dockerfile`, so that the action image does not have to be
re-built on every use.

## Private Composer packages

Pass Composer credentials with the `composer_auth` input, for example the org secret:

```yaml
- uses: playtini/docker-action-docker-build@master
  with:
    composer_auth: ${{ secrets.COMPOSER_AUTH }}
```

The value is the content of an `auth.json` (`{"github-oauth":{"github.com":"<token>"}}`). It is handed to the
build as the BuildKit secret `composer_auth` (BuildKit is switched on only when the input is set), so it never
ends up in image layers or `docker history`. Read it in the Dockerfile with:

```dockerfile
RUN --mount=type=secret,id=composer_auth,env=COMPOSER_AUTH composer install --no-dev ...
```
