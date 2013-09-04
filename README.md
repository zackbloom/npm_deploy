Install an npm mirror on CentOS
===============================

- Edit `couchdb_local.ini` to:
  - Use a password other than 'password'
  - Use subdomains on your domain (and forward the DNS to the server)
- Edit `setup.sh` to use your new password
- Run `setup.sh`

If couchdb 1.2.1 is in the yum repo, you should really install it from there.
