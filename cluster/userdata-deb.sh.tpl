MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="//"

--//
Content-Type: text/x-shellscript; charset="us-ascii"
#!/bin/bash 
set -xe

{{/* # Configure SSM in case things don't work - DEBIAN
mkdir /tmp/ssm
pushd /tmp/ssm
wget https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_amd64/amazon-ssm-agent.deb
dpkg -i amazon-ssm-agent.deb
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent
popd */}}

{{/* # install k8s things - DEBIAN
apt-get --allow-releaseinfo-change update
apt-get install -y apt-transport-https ca-certificates curl
curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get install -y kubelet=1.23.0-00 kubeadm=1.23.0-00 kubectl=1.23.0-00 */}}

# Bootstrap and join the cluster
/etc/eks/bootstrap.sh ${cluster_name} --b64-cluster-ca '${cluster_auth_base64}' --apiserver-endpoint '${endpoint}' ${bootstrap_extra_args} --kubelet-extra-args "${kubelet_extra_args}"

--//--
