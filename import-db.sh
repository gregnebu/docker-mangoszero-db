#!/bin/bash

file_env 'MYSQL_MANGOS_PASSWORD'
if [ -z "$MYSQL_MANGOS_PASSWORD" ]; then
	export MYSQL_MANGOS_PASSWORD="$(pwgen -1 32)"
	echo "GENERATED MANGOS PASSWORD: $MYSQL_MANGOS_PASSWORD"
fi

#Write generated password into shared file if using docker-compose
echo "$MYSQL_MANGOS_PASSWORD" > /tmp/password.txt

mysql=( mysql --protocol=socket -uroot -hlocalhost --socket=/var/run/mysqld/mysqld.sock -p"${MYSQL_ROOT_PASSWORD}" );

"${mysql[@]}" <<-EOSQL
	SET @@SESSION.SQL_LOG_BIN=0;
	CREATE DATABASE realmd DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
	CREATE DATABASE mangos DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
	CREATE DATABASE characters DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
	GRANT ALL ON realmd.* TO 'mangos'@'%' IDENTIFIED BY '${MYSQL_MANGOS_PASSWORD}';
	GRANT ALL ON mangos.* TO 'mangos'@'%';
	GRANT ALL ON characters.* TO 'mangos'@'%';
	FLUSH PRIVILEGES;
EOSQL

SRCPATH="/tmp"

echo "Import Realmd DB"
cat $SRCPATH/database/Realm/Setup/realmdLoadDB.sql | "${mysql[@]}" realmd

echo "Import Characters DB"
cat $SRCPATH/database/Character/Setup/characterLoadDB.sql | "${mysql[@]}" characters

echo "Import World DB"
cat $SRCPATH/database/World/Setup/mangosdLoadDB.sql | "${mysql[@]}" mangos
for fFile in $SRCPATH/database/World/Setup/FullDB/*.sql; do
	cat "${fFile}" | "${mysql[@]}" mangos
done

echo "Create Realm"
cat $SRCPATH/database/Tools/updateRealm.sql | "${mysql[@]}" realmd
