#if [ -z "$DOCKER_HOST" ]; then
#   echo "ERROR: no DOCKER_HOST defined"
#   exit 1
#fi

# set the definitions
INSTANCE=tracksys
NAMESPACE=uvadave

docker run -ti -p 8080:8080 $NAMESPACE/$INSTANCE /bin/bash -l
