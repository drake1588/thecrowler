# Environment variables used to customize the CROWler Docker Images

**DOCKER_POSTGRES_DB_HOST** (default value: localhost) - The hostname of the
PostgreSQL server to use for the CROWler.

**DOCKER_POSTGRES_DB_PORT** (default value: 5432) - The port of the PostgreSQL
server to use for the CROWler.

**DOCKER_POSTGRES_DB_NAME** (default value: SitesIndex) - The name of the database
to use for the CROWler.

**DOCKER_POSTGRES_USER** (default value: postgres) - The username to use to admin
to the database.

**DOCKER_POSTGRES_PASSWORD** (default value: postgres) - The password to use to
connect to the database.

**DOCKER_CROWLER_DB_USER** (default value: crowler) - The username to use to
connect to the database with read/write/exec permissions only. This is the
username the CROWler will use to connect to the database.

**DOCKER_CROWLER_DB_PASSWORD** (default value: changeme) - The password to use to
connect to the database with read/write/exec permissions only. This is the
password the CROWler will use to connect to the database.

**DOCKER_CROWLER_API_PORT** (default value: 8081) - The port the API will
listen on.

**DOCKER_SEARCH_API_PORT** (default value: 8080) - The port the Search API will
listen on.

**DOCKER_SELENIUM_IMAGE**
(default value: selenium/standalone-chromium:4.27.0-20241223) - This is for the
Selenium version to use in the VDI. Current version is 4.27.0 and the date is
the date you'll build the VDI image expressed as `yyyymmdd` (y = year, m =
month number, d = day number).

**DOCKER_DEFAULT_PLATFORM** (default value: linux/amd64) - The platform to use
to build the CROWler Docker images. This is useful if you are building the
CROWler on an architecture that is not `x86_64`.

For example:

```bash
DOCKER_DB_HOST='crowler-db'
DOCKER_POSTGRES_PASSWORD='your_postgres_password'
DOCKER_CROWLER_DB_USER='crowler'
DOCKER_CROWLER_DB_PASSWORD='your_crowler_password'

DOCKER_SELENIUM_IMAGE="selenium/standalone-chromium:4.27.0-20241223"

DOCKER_DEFAULT_PLATFORM="linux/arm64"
```
