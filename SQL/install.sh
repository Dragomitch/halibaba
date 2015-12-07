#!/bin/bash
DIR=`dirname $0`
echo '' > $DIR/install.sql

# List of files
scripts=()
scripts+=('src/global_create.sql')
scripts+=('src/global_signin.sql')
scripts+=('src/global_estimate_details.sql')
scripts+=('src/global_list_estimate_requests.sql')
scripts+=('src/clients_signup.sql')
scripts+=('src/clients_list_estimates.sql')
scripts+=('src/clients_submit_estimate_request.sql')
scripts+=('src/clients_approve_estimate.sql')
scripts+=('src/houses_signup.sql')
scripts+=('src/houses_modify_options.sql')
scripts+=('src/houses_add_options.sql')
scripts+=('src/houses_valid_estimates_nbr.sql')
scripts+=('src/houses_submit_estimate.sql')
scripts+=('src/view_all_submitted_estimates.sql')
scripts+=('src/triggers_estimate_insert.sql')
scripts+=('src/triggers_estimate_requests_update.sql')
scripts+=('src/triggers_options_update.sql')
scripts+=('src/users_prod.sql')

for script in ${scripts[*]} ; do

  if [ ! -e $DIR/$script ] ; then
    echo -e "Le fichier $DIR/$script n'existe pas.\nLe fichier d'installation n'a pas été généré."
    exit 1
  fi

  cat $DIR/$script >> $DIR/install.sql
  echo -e '\n' >> $DIR/install.sql
done

echo "Le fichier d'installation a bien été généré!"
exit 0
