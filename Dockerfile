FROM ubuntu:20.04

ENV DEBIAN_FRONTEND noninteractive
ENV TERM=xterm

ENV PYTHONPATH=$PYTHONPATH:/opt/odoo/odoo
ENV PG_HOST=postgres
ENV PG_PORT=5432
ENV PG_USER=odoo
ENV PG_PASSWORD=secret
ENV PG_DATABASE=False
ENV ODOO_PASSWORD=secret
ENV PORT=8069
ENV LOG_FILE=/var/log/odoo/odoo.log
ENV LONGPOLLING_PORT=8072
ENV WORKERS=5
ENV DISABLE_LOGFILE=0
ENV USE_SPECIFIC_REPO=0
ENV TRUSTCODE_APPS=0
ENV TRUSTCODE_ENTERPRISE=0
ENV TRUSTCODE_ONLY=0
ENV TIME_CPU=6000
ENV TIME_REAL=7200
ENV DB_FILTER=False
ENV SENTRY_DSN=False
ENV SENTRY_ENABLED=False

# Avoid ERROR: invoke-rc.d: policy-rc.d denied execution of start.
RUN echo "#!/bin/sh\nexit 0" > /usr/sbin/policy-rc.d

# Dependências #

RUN apt-get update

ADD conf/apt-requirements /opt/sources/
ADD conf/pip-requirements /opt/sources/

WORKDIR /opt/sources/
RUN apt-get install -y --no-install-recommends $(grep -v '^#' apt-requirements)

RUN curl -sL https://deb.nodesource.com/setup_12.x | bash - && \
    apt-get install -y nodejs && \
    curl -L https://www.npmjs.com/install.sh | sh && \
    npm install -g less && npm cache clean --force

RUN locale-gen en_US en_US.UTF-8 pt_BR pt_BR.UTF-8 && \
    dpkg-reconfigure locales

ENV LC_ALL pt_BR.UTF-8

ADD conf/brasil-requirements /opt/sources/
RUN pip3 install setuptools && pip3 install --no-cache-dir --upgrade pip
RUN pip3 install --no-cache-dir -r pip-requirements && \
    pip3 install --no-cache-dir -r brasil-requirements

ADD https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.bionic_amd64.deb /opt/sources/wkhtmltox.deb
RUN dpkg -i wkhtmltox.deb && rm wkhtmltox.deb

RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ bionic"-pgdg main | tee  /etc/apt/sources.list.d/pgdg.list
RUN apt-get update && apt-get install -y postgresql-client-11

RUN mkdir /opt/odoo/
WORKDIR /opt/odoo/
RUN mkdir private

# Configurações Odoo #

ADD conf/supervisord.conf /etc/supervisor/supervisord.conf

RUN mkdir /var/log/odoo && \
    mkdir /opt/dados && \
    mkdir /var/log/supervisord && \
    touch /var/log/odoo/odoo.log && \
    touch /var/run/odoo.pid && \
    ln -s /opt/odoo/odoo/odoo-bin /usr/bin/odoo-server && \
    ln -s /etc/odoo/odoo.conf && \
    ln -s /var/log/odoo/odoo.log && \
    useradd --system --home /opt --shell /bin/bash --uid 1040 odoo && \
    chown -R odoo:odoo /opt && \
    chown -R odoo:odoo /var/log/odoo && \
    chown odoo:odoo /var/run/odoo.pid

# Limpeza da Instalação #

RUN apt-get autoremove -y && \
    apt-get autoclean

# Finalização do Container #

WORKDIR /opt/odoo

RUN wget https://github.com/odoo/odoo/archive/14.0.zip -O odoo.zip && \
    wget https://github.com/oca/web/archive/14.0.zip -O web.zip && \
    wget https://github.com/oca/account-reconcile/archive/14.0.zip -O account-reconcile.zip && \
    wget https://github.com/oca/server-ux/archive/14.0.zip -O server-ux.zip && \
    wget https://github.com/oca/reporting-engine/archive/14.0.zip -O reporting-engine.zip && \
    wget https://github.com/oca/account-financial-reporting/archive/14.0.zip -O account-financial-reporting.zip && \
    wget https://github.com/oca/mis-builder/archive/14.0.zip -O mis-builder.zip && \
    wget https://github.com/oca/commission/archive/14.0.zip -O commission.zip && \
    wget https://github.com/Trust-Code/helpdesk/archive/14.0.zip -O helpdesk.zip && \
    wget https://github.com/odoo/design-themes/archive/14.0.zip -O design-themes.zip && \
    wget https://github.com/Trust-Code/trustcode-addons/archive/14.0.zip -O trustcode-addons.zip && \
    wget https://github.com/Trust-Code/odoo-brasil/archive/14.0.zip -O odoo-brasil.zip && \
    wget https://github.com/code-137/odoo-apps/archive/14.0.zip -O code137-apps.zip

RUN unzip -q odoo.zip && rm odoo.zip && mv odoo-14.0 odoo && \
    unzip -q web.zip && rm web.zip && mv web-14.0 web && \
    unzip -q account-reconcile.zip && rm account-reconcile.zip && mv account-reconcile-14.0 account-reconcile && \
    unzip -q server-ux.zip && rm server-ux.zip && mv server-ux-14.0 server-ux && \
    unzip -q reporting-engine.zip && rm reporting-engine.zip && mv reporting-engine-14.0 reporting-engine && \
    unzip -q account-financial-reporting.zip && rm account-financial-reporting.zip && mv account-financial-reporting-14.0 account-financial-reporting && \
    unzip -q mis-builder.zip && rm mis-builder.zip && mv mis-builder-14.0 mis-builder && \
    unzip -q commission.zip && rm commission.zip && mv commission-14.0 commission && \
    unzip -q helpdesk.zip && rm helpdesk.zip && mv helpdesk-14.0 helpdesk && \
    unzip -q design-themes.zip && rm design-themes.zip && mv design-themes-14.0 design-themes && \
    unzip -q trustcode-addons.zip && rm trustcode-addons.zip && mv trustcode-addons-14.0 trustcode-addons && \
    unzip -q odoo-brasil.zip && rm odoo-brasil.zip && mv odoo-brasil-14.0 odoo-brasil && \
    unzip -q code137-apps.zip && rm code137-apps.zip && mv odoo-apps-14.0 code137-apps && \
    cd odoo && find . -name "*.po" -not -name "pt_BR.po" -not -name "pt.po"  -type f -delete && \
    find . -path "*l10n_*" -delete && \
    rm -R debian && rm -R doc && rm -R setup && cd ..

RUN pip install --no-cache-dir pytrustnfe3 python3-cnab python3-boleto pycnab240 python-sped

# Configurações Odoo #

ADD deploy/odoo.conf /etc/odoo/
RUN chown -R odoo:odoo /opt && \
    chown -R odoo:odoo /etc/odoo/odoo.conf

RUN mkdir /opt/.ssh && \
    chown -R odoo:odoo /opt/.ssh

ADD bin/autoupdate /opt/odoo
ADD bin/entrypoint.sh /opt/odoo
RUN chown odoo:odoo /opt/odoo/autoupdate && \
    chmod +x /opt/odoo/autoupdate && \
    chmod +x /opt/odoo/entrypoint.sh

WORKDIR /opt/odoo

VOLUME ["/opt/", "/etc/odoo"]
ENTRYPOINT ["/opt/odoo/entrypoint.sh"]
CMD ["/usr/bin/supervisord"]
