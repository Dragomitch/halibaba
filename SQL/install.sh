#!/bin/bash
DIR=`dirname $0`
echo '' > $DIR/install.sql

# List of files
scripts=()
scripts+=('create-tables.sql')
scripts+=('clients_signup.sql')
scripts+=('clients_submit_estimate_request.sql')
scripts+=('clients_approve_estimate.sql')
scripts+=('triggers_options_update.sql')
scripts+=('insert_data.sql')

for script in ${scripts[*]} ; do

  if [ ! -e $DIR/src/$script ] ; then
    echo -e "Le fichier $DIR/src/$script n'existe pas.\nLe fichier d'installation n'a pas été généré."
    exit 1
  fi

  cat $DIR/src/$script >> $DIR/install.sql
  echo -e '\n' >> $DIR/install.sql
done

echo "Le fichier d'installation a bien été généré!"
exit 0
