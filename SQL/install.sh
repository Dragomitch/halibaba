#!/bin/bash
DIR=`dirname $0`
echo '' > $DIR/install.sql

# List of files
scripts=()
scripts+=('install-unit-test.sql')
scripts+=('src/global_create.sql')
scripts+=('src/clients_signup.sql')
scripts+=('src/clients_list_estimates.sql')
scripts+=('src/clients_submit_estimate_request.sql')
scripts+=('src/clients_approve_estimate.sql')
scripts+=('src/houses_signup.sql')
scripts+=('src/houses_add_options.sql')
scripts+=('src/houses_waiting_for_approval_estimates_nbr.sql')
scripts+=('src/houses_submit_estimate.sql')
scripts+=('src/houses_submit_hiding_estimate.sql')
scripts+=('src/houses_submit_secret_estimate.sql')
scripts+=('src/triggers_estimate_requests_update.sql')
scripts+=('src/triggers_options_update.sql')
scripts+=('src/view_all_valid_estimates.sql')

for script in ${scripts[*]} ; do

  if [ ! -e $DIR/$script ] ; then
    echo -e "Le fichier $DIR/src/$script n'existe pas.\nLe fichier d'installation n'a pas été généré."
    exit 1
  fi

  cat $DIR/$script >> $DIR/install.sql
  echo -e '\n' >> $DIR/install.sql
done

echo "Le fichier d'installation a bien été généré!"
exit 0
