## Wordpress with Docker
Basic Docker environment to execute Wordpress in localhost with SSL enabled

### Install and Run

- Create a `.env` file using `.env-example` as a model
- Start containers:

```bash
docker-compose up -d
```
- Access https://localhost and finish standard WP installation.

### Usage

Folders `wordpress/wp-content/plugins/custom` and `wordpress/wp-content/themes/custom` are mapped in Docker config and marked as exceptions in `.gitignore` to be used to start including customizations.