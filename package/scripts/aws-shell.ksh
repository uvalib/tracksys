if [ -z "$DOCKER_HOST" ]; then
   echo "ERROR: no DOCKER_HOST defined"
   exit 1
fi

$(aws ecr get-login --no-include-email --region $AWS_DEFAULT_REGION)

# set the definitions
INSTANCE=tracksys
NAMESPACE=115119339709.dkr.ecr.us-east-1.amazonaws.com/uvalib

docker run -ti -p 8080:8080 $NAMESPACE/$INSTANCE:latest /bin/bash -l
