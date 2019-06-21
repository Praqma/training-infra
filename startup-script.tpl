apt-get update
apt-get install -y docker.io python-pip
usermod -aG docker ubuntu
pip install docker-compose

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

apt-get install -y apt-transport-https
echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubectl

export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)"
echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
apt-get update && apt-get install -y google-cloud-sdk

curl -s https://raw.githubusercontent.com/ahmetb/kubectx/master/kubens > /usr/local/bin/kubens
chmod +x /usr/local/bin/kubens
sudo -u ubuntu curl -s https://raw.githubusercontent.com/jonmosco/kube-ps1/master/kube-ps1.sh > /home/ubuntu/.kube-ps1.sh
sudo -u ubuntu echo "source /home/ubuntu/.kube-ps1.sh" >> /home/ubuntu/.bashrc
sudo -u ubuntu echo "PS1='[\u@\h \W \$(kube_ps1)]\\$ '" >> /home/ubuntu/.bashrc
sudo -u ubuntu echo "kubeoff" >> /home/ubuntu/.bashrc
sudo -u ubuntu echo "source <(kubectl completion bash)" >> /home/ubuntu/.bashrc
sudo -u ubuntu echo "alias k=kubectl" >> /home/ubuntu/.bashrc
sudo -u ubuntu echo "complete -o default -F __start_kubectl k" >> /home/ubuntu/.bashrc

sudo -u ubuntu gcloud config configurations create training --activate
sudo -u ubuntu gcloud config set core/project ${project}
sudo -u ubuntu gcloud config set compute/region ${region}
sudo -u ubuntu gcloud config set compute/zone ${zone}
sudo -u ubuntu gcloud container clusters get-credentials ${cluster_name}

${extra_bootstrap_cmds}
