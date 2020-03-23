#if [ -z "$DOCKER_HOST" ]; then
#   echo "ERROR: no DOCKER_HOST defined"
#   exit 1
#fi

#echo "*****************************************"
#echo "building on $DOCKER_HOST"
#echo "*****************************************"

# set the definitions
INSTANCE=tracksys
NAMESPACE=uvadave

# we need these because the asset precompile phase seems to want to talk to the database
DBARGS="--build-arg DBHOST --build-arg DBNAME --build-arg DBUSER --build-arg DBPASSWD"

# build the image
docker build -f package/Dockerfile $DBARGS -t $NAMESPACE/$INSTANCE .

# return status
exit $?
