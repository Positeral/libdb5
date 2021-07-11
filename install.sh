#!/bin/bash

echo "Installing Berkeley DB 5.3.28"
rm -rf libdb5/
git clone https://github.com/Positeral/libdb5.git

cd libdb5/build_unix && ../dist/configure \
	--prefix=/usr \
	--enable-compat185 \
	--enable-cxx && make

make docdir=/usr/share/doc/db-5.3.28 install

chown -R $USER:$USER \
	/usr/bin/db_* \
	/usr/include/db{,_185,_cxx}.h \
	/usr/lib/libdb*.{so,a,la} \
	/usr/share/doc/db-5.3.28

cd ../..
rm -rf libdb5/
exit 0
