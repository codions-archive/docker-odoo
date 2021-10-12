# Codions - Docker image for Odoo 


```bash
$ docker run --name odoo --net host -d -e PG_USER=odoo -e PG_PASSWORD=odoo codions/odoo:12.0
```

Other parameters:

* PG_HOST=localhost
* PG_PORT=5432
* PG_USER=odoo
* PG_PASSWORD=odoo
* PORT=8069
* LONGPOLLING_PORT=8072
* WORKERS=3
* ODOO_PASSWORD=senha_admin
* DISABLE_LOGFILE=0
* ODOO_VERSION=12.0

Example: Switching the port on which Odoo will listen to:

```bash
$ docker run --name odoo --net host -d -e PG_USER=odoo -e PG_PASSWORD=odoo -e PORT=8050 codions/odoo:12.0
```

Credits
-------
This project is based on [Trust-Code/docker-odoo](https://github.com/Trust-Code/docker-odoo)