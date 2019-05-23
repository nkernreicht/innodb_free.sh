#!/bin/bash

########################################################################
# Syntax: innodb-free [$database-name] [$number of tables to optimize]
########################################################################
#
# This script finds the tables for a selected database which have the highest amount of
# data allocated by InnoDB that has not been freed yet. It then optimizes those tables
# in order to help reduce disk space.
#
########################################################################

# Grab the options provided via commandline.

while getopts ":d:n:" opt; do
        case ${opt} in
                d ) d=${OPTARG}
                ;;
                n ) n=${OPTARG}
                ;;
		* ) echo 'Usage: innodb-free.sh -d [$database-name] -n [$number of tables to optimize]' & exit
		;;
        esac
done
shift $((OPTIND -1))

db=${d}
optimizenum=${n}


# If the DB is not defined, generate an error.

	if [[ "$db" = "" ]]; then
	echo "Error: No database selected."
	fi

# If the optimize number isn't defined. Default to 10.
	if [[ "$optimizenum" = "" ]]; then
	optimizenum="10"
	fi

### Find the top tables with the highest amount of allocated, but not free space in InnoDB.
mysql $db -e "select table_name,data_free from information_schema.tables where table_schema = database() order by data_free desc limit $optimizenum ;" |

### Now that the top tables have been collected, strip the table names only from the output.
awk '$2 !~ /data_free/ {print $1}' | 

### Optimize them.
while read topfree;
	do mysql $db -e "optimize table $topfree;";
done
