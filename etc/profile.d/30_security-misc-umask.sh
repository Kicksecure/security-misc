if [ "$(id -u)" -eq 0 ]
then
    umask 077
else
    umask 022
fi
