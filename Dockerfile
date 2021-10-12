FROM ubuntu:18.04

ENV DEBIAN_FRONTEND noninteractive
ENV TERM=xterm
ENV ODOO_VERSION 12.0

ENV PG_HOST localhost
ENV PG_PORT 5432
ENV PG_USER odoo
ENV PG_PASSWORD odoo
ENV PG_DATABASE False
ENV ODOO_PASSWORD senha_admin
ENV PORT 8069
ENV LOG_FILE /var/log/odoo/odoo.log
ENV LONGPOLLING_PORT 8072
ENV WORKERS 3
ENV DISABLE_LOGFILE 0
ENV USE_SPECIFIC_REPO 0
ENV TIME_CPU 600
ENV TIME_REAL 720

ARG CACHEBUST=1

# Avoid ERROR: invoke-rc.d: policy-rc.d denied execution of start.
RUN echo "#!/bin/sh\nexit 0" > /usr/sbin/policy-rc.d

RUN apt-get update

ADD conf/apt-requirements /opt/sources/
ADD conf/pip-requirements /opt/sources/

WORKDIR /opt/sources/
RUN apt-get install -y --no-install-recommends $(grep -v '^#' apt-requirements)

RUN curl -sL https://deb.nodesource.com/setup_10.x | bash - && \
    apt-get install -y nodejs && \
    curl -L https://www.npmjs.com/install.sh | sh && \
    npm install -g less && npm cache clean --force

# Cleaning the Installation
RUN apt-get autoremove -y && \
    apt-get autoclean

RUN locale-gen en_US en_US.UTF-8 pt_BR pt_BR.UTF-8 && \
    dpkg-reconfigure locales

ENV LC_ALL pt_BR.UTF-8

ADD conf/brasil-requirements /opt/sources/
RUN pip3 install setuptools && pip3 install --no-cache-dir --upgrade pip
RUN pip3 install --no-cache-dir -r pip-requirements && \
    pip3 install --no-cache-dir -r brasil-requirements

ADD https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.bionic_amd64.deb /opt/sources/wkhtmltox.deb
RUN dpkg -i wkhtmltox.deb && rm wkhtmltox.deb

WORKDIR /opt/odoo
RUN mkdir private

# Odoo Settings

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

WORKDIR /opt/odoo

RUN wget https://github.com/odoo/odoo/archive/${ODOO_VERSION}.zip -O odoo.zip && \
    wget https://github.com/oca/web/archive/${ODOO_VERSION}.zip -O web.zip && \
    wget https://github.com/oca/server-ux/archive/${ODOO_VERSION}.zip -O server-ux.zip && \
    wget https://github.com/oca/reporting-engine/archive/${ODOO_VERSION}.zip -O reporting-engine.zip && \
    wget https://github.com/oca/account-financial-reporting/archive/${ODOO_VERSION}.zip -O account-financial-reporting.zip && \
    wget https://github.com/oca/mis-builder/archive/${ODOO_VERSION}.zip -O mis-builder.zip && \
    # Custom
    wget https://github.com/Trust-Code/odoo-brasil/archive/${ODOO_VERSION}.zip -O odoo-brasil.zip && \
    wget https://github.com/Trust-Code/trustcode-addons/archive/${ODOO_VERSION}.zip -O trustcode-addons.zip

RUN unzip -q odoo.zip && rm odoo.zip && mv odoo-${ODOO_VERSION} odoo && \
    unzip -q web.zip && rm web.zip && mv web-${ODOO_VERSION} web && \
    unzip -q server-ux.zip && rm server-ux.zip && mv server-ux-${ODOO_VERSION} server-ux && \
    unzip -q reporting-engine.zip && rm reporting-engine.zip && mv reporting-engine-${ODOO_VERSION} reporting-engine && \
    unzip -q account-financial-reporting.zip && rm account-financial-reporting.zip && mv account-financial-reporting-${ODOO_VERSION} account-financial-reporting && \
    unzip -q mis-builder.zip && rm mis-builder.zip && mv mis-builder-${ODOO_VERSION} mis-builder && \
    # Odoo Brazil
    unzip -q odoo-brasil.zip && rm odoo-brasil.zip && mv odoo-brasil-${ODOO_VERSION} odoo-brasil && \
    unzip -q trustcode-addons.zip && rm trustcode-addons.zip && mv trustcode-addons-${ODOO_VERSION} trustcode-addons

RUN cd odoo && find . -name "*.po" -not -name "pt_BR.po" -not -name "pt.po"  -type f -delete && \
    find . -path "*l10n_*" -delete && \
    rm -R debian && rm -R doc && rm -R setup && cd ..

RUN pip install --no-cache-dir pytrustnfe3 python3-cnab python3-boleto pycnab240 python-sped

ADD conf/odoo.conf /etc/odoo/
RUN chown -R odoo:odoo /opt && \
    chown -R odoo:odoo /etc/odoo/odoo.conf

ADD bin/autoupdate /opt/odoo
ADD bin/entrypoint.sh /opt/odoo
RUN chown odoo:odoo /opt/odoo/autoupdate && \
    chmod +x /opt/odoo/autoupdate && \
    chmod +x /opt/odoo/entrypoint.sh

WORKDIR /opt/odoo

VOLUME ["/opt/", "/etc/odoo"]
ENTRYPOINT ["/opt/odoo/entrypoint.sh"]
CMD ["/usr/bin/supervisord"]

