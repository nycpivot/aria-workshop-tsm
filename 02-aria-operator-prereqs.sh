#!/bin/bash

read -p "AWS Access Key: " aws_access_key
read -p "AWS Secret Access Key: " aws_secret_access_key
read -p "AWS Default Region (us-east-1): " aws_region_code

if [[ -z $aws_region_code ]]
then
    aws_region_code=us-east-1
fi

sudo apt update
yes | sudo apt upgrade

#DOCKER
yes | sudo apt install docker.io
sudo systemctl enable docker
sudo systemctl start docker

sudo usermod -aG docker $USER

#these required to gcloud CLI
#https://cloud.google.com/sdk/docs/install#deb
#yes | sudo apt-get install apt-transport-https ca-certificates gnupg curl sudo

#MISC TOOLS
sudo snap install jq
sudo snap install tree
sudo snap install helm --classic
sudo apt install unzip

sudo apt install python-is-python3
alias python=python3

yes | sudo apt install python3-pip
pip3 install yq

wget https://releases.hashicorp.com/terraform/0.13.0/terraform_0.13.0_linux_amd64.zip
unzip terraform_0.13.0_linux_amd64.zip
sudo mv terraform /usr/local/bin
rm terraform_0.13.0_linux_amd64.zip

#AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm awscliv2.zip

#AWS AUTHENTICATOR
curl -Lo aws-iam-authenticator https://github.com/kubernetes-sigs/aws-iam-authenticator/releases/download/v0.5.9/aws-iam-authenticator_0.5.9_linux_amd64
sudo mv aws-iam-authenticator /usr/local/bin
chmod +x /usr/local/bin/aws-iam-authenticator

#AWS EKSCTL
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
chmod +x /usr/local/bin/eksctl

aws configure set aws_access_key_id $aws_access_key
aws configure set aws_secret_access_key $aws_secret_access_key
aws configure set default.region $aws_region_code

#GCLOUD CLI - NO THANKS, WHAT A FREAKIN' HASSLE - CODE BELOW WON'T WORK
#https://cloud.google.com/sdk/docs/install#deb
# echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list

# curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -

# sudo apt-get update && sudo apt-get install google-cloud-cli

# gcloud auth login
# gcloud config set project pa-mjames


#AZ CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
az login
az account set --subscription nycpivot


#KUBECTL
sudo snap install kubectl --classic --channel=1.25/stable
kubectl version

#ISTIO
curl -sL https://istio.io/downloadIstioctl | sh -
export PATH=$PATH:$HOME/.istioctl/bin

#TMC CLI
server_name=prod-2.nsxservicemesh.vmware.com
tsm_token=$(aws secretsmanager get-secret-value --secret-id aria-workshop | jq -r .SecretString | jq -r .\"tsm-token\")

#wget https://prod-2.nsxservicemesh.vmware.com/allspark-static/binaries/tsm-cli-linux.tgz
wget https://tsmcli.s3.us-west-2.amazonaws.com/tsm-cli-linux.tgz

sudo tar xf tsm-cli-linux.tgz -C /usr/local/bin/

tsm login -s $server_name -t $tsm_token


#DEMO-MAGIC
wget https://raw.githubusercontent.com/paxtonhare/demo-magic/master/demo-magic.sh
sudo mv demo-magic.sh /usr/local/bin/demo-magic.sh
chmod +x /usr/local/bin/demo-magic.sh

sudo apt install pv #required for demo-magic

#GITHUB CLI
type -p curl >/dev/null || (sudo apt update && sudo apt install curl -y)
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
&& sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
&& sudo apt update \
&& sudo apt install gh -y

git_token=$(aws secretsmanager get-secret-value --secret-id tap-workshop | jq -r .SecretString | jq -r .\"github-token\")

echo $git_token > git-token.txt

#CLONE DEMO PROJECT
git clone https://github.com/nycpivot/acme-fitness-demo.git

#SAVE AWS DETAILS
aws_account_id=$(aws secretsmanager get-secret-value --secret-id tap-workshop | jq -r .SecretString | jq -r .\"aws-account-id\")

echo
echo export AWS_ACCOUNT_ID=$aws_account_id >> .bashrc
echo
echo export AWS_REGION=$aws_region_code >> .bashrc
echo

echo
echo "***REBOOTING***"
echo

sudo reboot
