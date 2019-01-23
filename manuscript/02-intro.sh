# If MacOS
brew tap jenkins-x/jx

# If MacOS
brew install jx

# If Lunux
mkdir -p ~/.jx/bin

# If Lunux
curl -L https://github.com/jenkins-x/jx/releases/download/v1.3.634/jx-linux-amd64.tar.gz \
    | tar xzv -C ~/.jx/bin

# If Lunux
export PATH=$PATH:~/.jx/bin

# If Lunux
echo 'export PATH=$PATH:~/.jx/bin' \
    >> ~/.bashrc

# If Windows
choco install jenkins-x

jx create cluster help

jx install --help | grep "provider="

# If GKE
PROJECT=[...]

# If GKE
jx create cluster gke \
    -n jx-rocks \
    -p $PROJECT \
    -z us-east1-b \
    -m n1-standard-2 \
    --min-num-nodes 3 \
    --max-num-nodes 5 \
    --default-admin-password admin \
    --default-environment-prefix jx-rocks

# If EKS
export AWS_ACCESS_KEY_ID=[...]

# If EKS
export AWS_SECRET_ACCESS_KEY=[...]

# If EKS
export AWS_DEFAULT_REGION=us-west-2

# If EKS
jx create cluster eks -n jx-rocks \
    -r $AWS_DEFAULT_REGION \
    --node-type t2.medium \
    --nodes 3 \
    --nodes-min 3 \
    --nodes-max 6 \
    --default-admin-password admin \
    --default-environment-prefix jx-rocks

# If EKS
ASG_NAME=$(aws autoscaling \
    describe-auto-scaling-groups \
    | jq -r ".AutoScalingGroups[] \
    | select(.AutoScalingGroupName \
    | startswith(\"eksctl-jx-rocks-nodegroup\")) \
    .AutoScalingGroupName")

# If EKS
echo $ASG_NAME

# If EKS
aws autoscaling \
    create-or-update-tags \
    --tags \
    ResourceId=$ASG_NAME,ResourceType=auto-scaling-group,Key=k8s.io/cluster-autoscaler/enabled,Value=true,PropagateAtLaunch=true \
    ResourceId=$ASG_NAME,ResourceType=auto-scaling-group,Key=kubernetes.io/cluster/jx-rocks,Value=true,PropagateAtLaunch=true

# If EKS
IAM_ROLE=$(aws iam list-roles \
    | jq -r ".Roles[] \
    | select(.RoleName \
    | startswith(\"eksctl-jx-rocks-nodegroup-0-NodeInstanceRole\")) \
    .RoleName")

# If EKS
echo $IAM_ROLE

# If EKS
aws iam put-role-policy \
    --role-name $IAM_ROLE \
    --policy-name jx-rocks-AutoScaling \
    --policy-document https://raw.githubusercontent.com/vfarcic/k8s-specs/master/scaling/eks-autoscaling-policy.json

# If EKS
helm install stable/cluster-autoscaler \
    --name aws-cluster-autoscaler \
    --namespace kube-system \
    --set autoDiscovery.clusterName=jx-rocks \
    --set awsRegion=us-west-2 \
    --set sslCertPath=/etc/kubernetes/pki/ca.crt \
    --set rbac.create=true \
    --wait

# If AKS
jx create cluster aks \
    -c jxrocks \
    -n jxrocks-group \
    -l eastus \
    -s Standard_B2s \
    --nodes 3 \
    --default-admin-password admin \
    --default-environment-prefix jx-rocks

jx compliance run

jx compliance status

jx compliance logs -f

jx compliance results

jx compliance delete

# If existing cluster
LB_IP=[...]

# If existing cluster and you already have a domain
DOMAIN=[...]

# If existing cluster and you do NOT have a domain
DOMAIN=jenkinx.$LB_IP.nip.io

# If existing cluster
jx install --help | grep "provider="

# If existing cluster
PROVIDER=[...]

# If existing cluster
kubectl get ns

# If existing cluster
INGRESS_NS=[...]

# If existing cluster
kubectl -n $INGRESS_NS get deployments

# If existing cluster
INGRESS_DEP=nginx-ingress-controller

# If existing cluster
TILLER_NS=[...]

# If existing cluster
jx install \
    --provider $PROVIDER \
    --external-ip $LB_IP \
    --domain $DOMAIN \
    --default-admin-password admin \
    --ingress-namespace $INGRESS_NS \
    --ingress-deployment $INGRESS_DEP \
    --tiller-namespace $TILLER_NS \
    --default-environment-prefix jx-rocks

kubectl -n jx get pods

jx console

GH_USER=[...]

hub delete -y \
  $GH_USER/environment-jx-rocks-staging

hub delete -y \
  $GH_USER/environment-jx-rocks-production

rm -rf ~/.jx/environments/$GH_USER/environment-jx-rocks-*

rm -f ~/.jx/jenkinsAuth.yaml

# If GKE
gcloud container clusters \
    delete jx-rocks \
    --zone us-east1-b \
    --quiet

# If GKE
gcloud compute disks delete \
    $(gcloud compute disks list \
    --filter="-users:*" \
    --format="value(id)")

# If EKS
LB_ARN=$(aws elbv2 \
    describe-load-balancers | jq -r \
    ".LoadBalancers[0].LoadBalancerArn")

# If EKS
echo $LB_ARN

# If EKS
aws elbv2 delete-load-balancer \
    --load-balancer-arn $LB_ARN

# If EKS
IAM_ROLE=$(aws iam list-roles \
    | jq -r ".Roles[] \
    | select(.RoleName \
    | startswith(\"eksctl-jx-rocks-nodegroup-0-NodeInstanceRole\")) \
    .RoleName")

# If EKS
echo $IAM_ROLE

# If EKS
aws iam delete-role-policy \
    --role-name $IAM_ROLE \
    --policy-name jx-rocks-AutoScaling

# If EKS
eksctl delete cluster -n jx-rocks

# If AKS
az group delete \
    --name jxrocks-group \
    --yes

# If AKS
kubectl config delete-cluster jxrocks

# If AKS
kubectl config delete-context jxrocks

# If AKS
kubectl config unset \
    users.clusterUser_jxrocks-group_jxrocks

# If existing cluster
jx uninstall \
  --context $(kubectl config current-context) \
  -b