#!/bin/bash

JMETER_HOME="/opt/jmeter"
JAVA_PARAMS="-Jjmeter.save.saveservice.thread_counts=true -Jjmeter.save.saveservice.subresults=false"
RUN_MASTER="$JMETER_HOME/bin/jmeter.sh -j log/jmeter_`date +"%Y-%m-%d_%H.%M.%S"`.log $JAVA_PARAMS "
REPORT_FILE=""
REPORT_FOLDER=""
SERVERS_NUM=0
THREAD_GROUP_NAME=""
LOG_IN=false
NON_GUI_MODE=true


function usage() {
    echo "Usage: $0 -p <environment_properties> -s <path to jmx script>."
    echo "Example: ./run_jmeter_hudson.sh -p properties/stag/mobile_environment.properties -s scripts_regression/mobile/mobile_hotel_search.jmx -t 20 -r 360 -d 3600 -e 5 -h 2 -i 50"
    echo "Optional arguments:"
    echo "  -t <THREADS-NUMBER> (number of threads that will be used on the test, default=1)."
    echo "  -r <RAMP-UP> (ramp up period between threads, in seconds, default=0)."
    echo "  -d <DURATION> (duration of the test, in seconds, default=1)."
    echo "  -e <DELAY> (delay between re-price and restart of a thread, in seconds, default=0)."
    echo "  -a (download all embedded resources, as default it will not download anything)."
    echo "    -g (start JMeter on GUI mode, default=false)."
    echo "  -J overrides JMeter system properties. -J[prop name]=[value] - defines a local JMeter property. Example: -J user.classpath=\"<path>\"."
    exit 1;
}

# Randomize lines in the markets files and save it in a new folder 
function randomize_markets() {
  # read csv file name from properties file
  props_file=$( sed 's/ = /=/g' $1 )
  # Change IFS variable to match a line jump instead of a space
  OLDIFS=$IFS
  IFS=$'\n'
  for prop in $props_file
  do
    # If the property is a csv file then randomize the lines inside it  
    if [[ $prop == *randomized*.csv ]]
    then
      randomized_csv_file=${prop/#*=}
      # Create the randomized folder in case it doesn't exist
      mkdir ${randomized_csv_file%\/*}
      # Remove the /randomized part from the path to get the original
      # csv file path
      original_csv_file=${randomized_csv_file/\/randomized}
      for row in `cat $original_csv_file` 
      do
        echo "$RANDOM $row"
      done | sort | 
      # If the OS is linux
      if [[ $(uname) == "Linux" ]]
      then 
        sed -r 's/^[0-9]+ //' 
      # If the OS is OSx (Mac's OS)
      else
        sed -E 's/^[0-9]+ //'
      fi > $randomized_csv_file
    fi
  done
  IFS=$OLDIFS
}

function add_params_master() {
    OPT_PARAMS_MASTER=$OPT_PARAMS_MASTER" "$1
}

function remove_jtl() {
    echo "Attempting to remove JTL file named: report/$ENVIRONMENT/$REPORT_FILE/$REPORT_FILE.jtl";
    if [ -e "report/$ENVIRONMENT/$REPORT_FILE/$REPORT_FILE.jtl" ]
    then 
        echo "Removing report/$ENVIRONMENT/$REPORT_FILE/$REPORT_FILE.jtl";
        rm "report/$ENVIRONMENT/$REPORT_FILE/$REPORT_FILE.jtl";
    else
        echo "Failed to remove $REPORT_FILE because it wasn't there";
    fi
}

function set_thread_group_name() {
    another_param="-Dthread.group.name=$THREAD_GROUP_NAME"
    add_params_master $another_param
}


if [ $# -le 2 ]
then
    usage;
fi

# Adding a : after the letter indicates that it needs an argument to work
while getopts "p:s:t:r:d:e:gJ:" optname
do
    case "$optname" in
        "p")
            if [ ! -e "$OPTARG" ]
                then
                    echo Wrong Properties Parameter filename.
                    usage;
            fi
            randomize_markets $OPTARG 
            add_params_master "-q $OPTARG"
            PROP_FILE=${OPTARG##*/}
            TEST_TYPE=${PROP_FILE%.*}
            if [[ $TEST_TYPE =~ "osa.*" ]] 
            then
              REPORT_FOLDER=${TEST_TYPE%_*}
            else
              REPORT_FOLDER=$TEST_TYPE
            fi
            PROP_FOLDER=${OPTARG%/*}
            ENVIRONMENT=${PROP_FOLDER#*/}
        ;;
          "s")
            if [ ! -e "$OPTARG" ]
              then
                echo Wrong Script Parameter filename.
                usage;
              fi
            add_params_master "-t $OPTARG"
            TEST_NAME=${OPTARG##*/}
            REPORT_FILE=${TEST_NAME%.*}
            REPORT_FILE=$REPORT_FOLDER"_"$REPORT_FILE
            add_params_master "-l report/$ENVIRONMENT/$REPORT_FILE/$REPORT_FILE.jtl"
            add_params_master "-Dreport.path=report/$ENVIRONMENT/$REPORT_FILE/"
            hostname=$(hostname)
            THREAD_GROUP_NAME=${hostname//./-}"."$TEST_TYPE"."${TEST_NAME%.*}".no-content"
        ;;
          "t")
            another_param=-Dnum.threads="$OPTARG"
            add_params_master $another_param
        ;;
          "r")
            another_param=-Dramp.up="$OPTARG"
            add_params_master $another_param
        ;;
          "d")
            another_param=-Dtest.duration="$OPTARG"
            add_params_master $another_param
        ;;
          "e")
            delay_in_sec=$[$OPTARG*1000]
            another_param=-Dthread.delay=$delay_in_sec
            add_params_master $another_param
        ;;
        "g")
            NON_GUI_MODE=false
        ;;
          "J")
            another_param="-J$OPTARG"
            add_params_master $another_param
        ;;
          "\?")
            echo "Unknown option $OPTARG"
        ;;
          ":")
            echo "No argument value for option $OPTARG"
        ;;
        *)
    esac
done

# Add the non-GUI param if the user did not specify GUI mode
if $NON_GUI_MODE
then
    add_params_master "-n"
fi

remove_jtl;

# Set the thread group name (needed to correctly store the data in Graphite)
set_thread_group_name

# Start the test

echo "Running test ..."
echo "bash $RUN_MASTER$OPT_PARAMS_MASTER"
bash $RUN_MASTER$OPT_PARAMS_MASTER 
exit 0
