## WebParticipacionCiudadana

Herramienta de participación ciudadana para que las ciudadanas puedan participar en los procesos de participación definidos y publicados en la Web.

## Server configuration

Docker & Docker Compose is needed, then clone this repository:

```
git clone https://github.com/openpoke/decidim-navarra
```

or update:
```
cd decidim_navarra
git pull
```

Ensure the `.env` file has these values defined:

```bash
DATABASE_URL=postgres://xxxxx:xxxxx@db/xxxxx
POSTGRES_USER=XXXXXX
POSTGRES_PASSWORD=XXXXXX
POSTGRES_DB=XXXXXX
SECRET_KEY_BASE=XXXXXX
MAPS_PROVIDER=here
MAPS_API_KEY=XXXXXX
EMAIL=XXXXXX
SMTP_USERNAME=XXXXXX
SMTP_PASSWORD=XXXXXX
SMTP_ADDRESS=XXXXXX
SMTP_DOMAIN=XXXXXX
SMTP_PORT=XXXXXX
DECIDIM_ENV=production
```

## Deploy

### Pull from Github Repository

This instance uses Docker Compose to deploy the application into the port 3015.

First, you need to make sure you are logged into the Github Docker registry (ghcr.io).

1. Go to your personal Github account, into tokens settings https://github.com/settings/tokens
2. Generate a new token (Classic)
3. Ensure you check the permission "read:packages" and "No expiration".
4. In the server, login into docker, introduce your username and the token generated:
  ```bash
  docker login ghcr.io --username github-username
  ```
5. You should stay logged permanently, you should not need to repeat this process.

If you want to update the image (anything in the code has change), execute:

`docker pull ghcr.io/openpoke/decidim-navarra:main` (or `staging`)

To re-deploy the image this should suffice:

`docker compose up -d`

### Zero Downtime with docker compose

It is possible to redeploy with zero downtime by using the docker plugin https://github.com/wowu/docker-rollout

#### Install plugin

 For production or when using `sudo`, install the plugin to `/usr/local/lib/docker/cli-plugins/` so it's available for all users.
  ```bash
  # production only
  sudo mkdir -p /usr/local/lib/docker/cli-plugins
  sudo curl https://raw.githubusercontent.com/wowu/docker-rollout/main/docker-rollout -o /usr/local/lib/docker/cli-plugins/docker-rollout
  sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-rollout
  ```

#### Zero-downtime deploy

Just execute:

```
docker rollout app --wait-after-healthy 15
```

### Locally building the Docker image

This instance uses Docker Compose to deploy the application with Traefik as a proxy.

> If you want to locally build the docker image, change the line `image: ghcr.io/openpoke/decidim-navarra:${GIT_REF:-main}` for `image: decidim-${DECIDIM_ENV:-production}` first!

You need to build and tag the image:

1. Ensure you have the ENV value `DECIDIM_ENV=staging` or `DECIDIM_ENV=production`
2. Run:
   `./build.sh`
3. Deploy:
  `docker compose up -d`

## Backups

Database is backup every day using https://github.com/tiredofit/docker-db-backup (see docker-compose.yml for details)

Backups are stored in:

- `backups/*`