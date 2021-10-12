#!/usr/bin/env bash

if [ $UID -eq 0 ]; then

  echo "Iniciando o entrypoint com root"

  # Quando atualizando é bom deixar o log aparecer no terminal
  if [ $DISABLE_LOGFILE == 1 ]; then
    export LOG_FILE=False
  fi

  cd /opt/odoo
  chown odoo:odoo /etc/odoo/odoo.conf
  exec env su odoo "$0" -- "$@"

fi

export PATH="/opt/odoo:$PATH"
export PATH="/opt/odoo/odoo:$PATH"

echo "Iniciando o entrypoint com odoo"
cd /opt/odoo

# Monta o addons_path
directories=$(ls -d -1 $PWD/**)
path=","
for directory in $directories; do
  if [ -d $directory ]; then
    if [ $directory != "/opt/odoo/odoo" ]; then
      path="$path""$directory",
    fi
  fi
done
export ADDONS_PATH="$path"

# Modifica as variáveis do odoo.conf baseado em variáveis de ambiente
conf=$(cat odoo.conf | envsubst)
echo "$conf" > /etc/odoo/odoo.conf

exec "$@"
echo "Finalizou o entrypoint"
