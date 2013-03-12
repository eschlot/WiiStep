#!/bin/bash
if test $# -eq 2
then
nl='
'
echo \
"tell application \"Terminal\"${nl}\
    activate${nl}\
    set the_tab to do script \"$1 $2 && logout\"${nl}\
    set current settings of the_tab to settings set 6${nl}\
    set font name of current settings of the_tab to \"Menlo Regular\"${nl}\
    set font size of current settings of the_tab to 12${nl}\
    set number of rows of the_tab to 24${nl}\
    set number of columns of the_tab to 88${nl}\
    set font antialiasing of current settings of the_tab to true${nl}\
end tell${nl}" | osascript
sleep 0.5
while pgrep `basename "$1"` > /dev/null; do sleep 0.5; done
if [ -e "$2/wsinstall-fail" ]
then
exit -1
fi
else
echo "Usage: LaunchWSInstall.sh <wsinstall path> <project binary dir>"
fi
