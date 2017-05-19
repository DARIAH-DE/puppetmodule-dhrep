#!/bin/bash
for f in `ls /var/log/nginx/*.log.$(date +%Y-%m-%d)`; do 
  sed -i -e 's/\([0-9]\{1,3\}\)\.\([0-9]\{1,3\}\)\.\([0-9]\{1,3\}\)\.\([0-9]\{1,3\}\)/\1\.\2\.0\.0/' ${f};
done

