#!/bin/bash

set -e

echo "Deploying PRIMARY region..."
cd primary
terraform init
terraform plan
terraform apply -auto-approve
cd ..

echo "Deploying DR region..."
cd dr
terraform init
terraform plan
terraform apply -auto-approve
cd ..
