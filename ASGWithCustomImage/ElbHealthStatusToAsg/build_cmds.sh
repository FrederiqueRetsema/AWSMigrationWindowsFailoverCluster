# build_cmds.sh
# =============
# Tag id comes from the command git log -1 --pretty=%H 

GIT_TAG="26073a623f61f5329651458673a080bfca31556d"
REPO_NAME="frederiquer/elb_health_status_to_asg"

docker image build -t $REPO_NAME:$GIT_TAG .
docker tag $REPO_NAME:$GIT_TAG $REPO_NAME:latest
docker image push $REPO_NAME:$GIT_TAG
docker image push $REPO_NAME:latest
