#!/bin/sh

if [ ! -n "$CRON" ]
then
    CRON="0  2  *  *  *"
fi

if [ -n "$VERSION" ]
then
    pip install elasticsearch-curator==$VERSION
fi
echo "$CRON    /usr/local/bin/curator /curator/actions.yml" > /etc/crontabs/root

VERSION=`/usr/local/bin/curator --version`
echo "Running $VERSION"
echo "Crontab added: $CRON"

crond -l 2 -f