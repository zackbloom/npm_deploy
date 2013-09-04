#!/bin/bash

# Install CouchDB 1.2.1

yes | yum install epel-release
yes | yum install libicu-devel openssl-devel curl-devel make gcc erlang js-devel libtool which

cd /tmp

if [ ! -e /usr/local/bin/couchdb ]; then 
	if [ ! -e apache-couchdb-1.2.1 ]; then
		wget http://www.eng.lsu.edu/mirrors/apache/couchdb/1.2.1/apache-couchdb-1.2.1.tar.gz
		tar xvf apache-couchdb-1.2.1.tar.gz
	fi

	cd apache-couchdb-1.2.1
	./configure --with-erlang=/usr/lib64/erlang/usr/include && make -j4 && make install
fi

mkdir /mnt/couchdb
adduser -r --home /usr/local/var/lib/couchdb -M --shell /bin/bash --comment "CouchDB Administrator" couchdb
chown -R couchdb: /usr/local/var/lib/couchdb /usr/local/var/log/couchdb /usr/local/var/run/couchdb /mnt/couchdb

if [ ! -e /etc/init.d/couchdb ]; then
	ln -s /usr/local/etc/rc.d/couchdb /etc/init.d/couchdb
fi

chkconfig --add couchdb
chkconfig --level 345 couchdb on

/etc/init.d/couchdb start

# Install NPM

yes | yum install git nodejs

cd /usr/local/var/lib
git clone https://github.com/isaacs/npmjs.org.git
cd npmjs.org

npm install -g json
npm install


# Install the config
cp ~/npm_deploy/couchdb_local.ini /usr/local/etc/couchdb/local.ini

# We need to let CDB know to start as root so it can bind port 80
cp ~/npm_deploy/couchdb_init.ini /usr/local/etc/default/couchdb

/etc/init.d/couchdb restart
# If this fails with eaddrinuse it means beam is binding on port 80, kill it!

echo "Waiting for the database to start..."
sleep 10

# Install the NPM db and app
curl -X PUT http://localhost/registry

couchapp push registry/app.js http://localhost/registry
couchapp push www/app.js http://localhost/registry

# Add a script to replicate the npm repo
cp ~/npm_deploy/couch_repl.sh /usr/local/etc/couchdb

# This needs to run on boot after couchdb has started (and any time after it is restarted):
/usr/local/etc/couchdb/couch_repl.sh
# Not sure how to make sure this runs after couch has started without using something like upstart

# We need to build all the views in the scratch db and copy them to the app db
npm config set npmjs.org:couch 'http://admin:password@localhost/registry'
npm run pull
npm run load

# After this first run, we should be able to use `npm run copy` to do this
curl 'http://admin:password@localhost/registry/_design/scratch' \
	-X COPY \
	-H destination:_design/app

curl 'http://admin:password@localhost/_users' \
	-X POST \
	-H 'Content-Type:application/json' \
	-d '{
	    "_id": "org.couchdb.user:hs",
	    "name": "hs",
	    "type": "user",
	    "roles": [],
	    "password": "password"
	}'


curl 'http://admin:password@localhost/registry/_security' \
	-X PUT \
	-H 'Content-Type:application/json' \
	-d '{
	    "_id": "_security",
	    "members": {
	        "names": ["hs"]
	    }
	}'	
