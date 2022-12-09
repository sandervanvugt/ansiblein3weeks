#!/bin/bash
# PRERELEASE VERSION - NEEDS TESTING

grep Ubuntu /etc/os-release || (echo this script only works on Ubuntu && exit 3)

echo if you have no currently running minikube on Ubuntu, use Ctrl-C to stop this script
echo next use ./minikube-docker-setup.sh to setup docker on Ubuntu and after doing so, run this script again.
echo if you have minikibe, press enter to continue
read

cat <<EOF | sudo tee kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  # Find the latest tag here: https://github.com/ansible/awx-operator/releases
  # verify the version if this script fails
  - github.com/ansible/awx-operator/config/default?ref=1.1.1
  #- awx-demo.yaml

# Set the image tags to match the git version from above
images:
  - name: docker.io/ansible/awx-operator
    newTag: 1.1.1

# Specify a custom namespace in which to install AWX
namespace: awx
EOF

curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash
sudo mv kustomize /usr/local/bin/
kustomize build . | kubectl apply -f -

cat <<EOFD | sudo tee .yaml
---
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx-demo
spec:
  service_type: nodeport
  # default nodeport_port is 30080
  nodeport_port: 30080
EOFD

grep -i -e 's/#-.*/-.*/' kustomization.yaml
kustomize build . | kubectl apply -f -

AWX_URL=$(minikube service -n awx awx-demo-service --url)
AWX_ADMIN_PASSWORD=$(kubectl get secret awx-demo-admin-password -o jsonpath="{.data.password}" | base64 --decode)

echo you can now connect to AWS using $AWX_URL
echo provide the username admin and the password $AWX_ADMIN_PASSWORD

