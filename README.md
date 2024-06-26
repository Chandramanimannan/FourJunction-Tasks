# FourJunction-Tasks
Task -1 

AWS Infrastructure

Write the following AWS infrastructure as code in terraform,

1. VPC

• Name: “ionginx-vpc”

• Public Subnet – 3

• Private Subnet – 3

• Internet Gateway – 1

• NAT Gateway – 1

2. EC2 Auto Scaling Group

• Minimum – 2

• Maximum – 4

• Subnets – Only Private Subnets

• NGINX on Ubuntu

• Don’t assign Public IPv4 to EC2 Instances

• Don’t allow SSH Access to EC2 Instance


Reference Links:

https://registry.terraform.io/providers/hashicorp/aws/latest/docs

https://registry.terraform.io/providers/hashicorp/aws/latest

https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record

https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group

https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/bedrock_provisioned_model_throughput


3. Route 53 A Record

• Pointing to the NAT Gateway and allow nginx to serve the default webpage.


Task - 2

Kubernetes Operations

Write a Kubernetes Deployment, Service and Ingress to run nginx server along with the
Kubernetes cli commands to perform the operation.

Reference Links:

https://kubernetes.io/docs/tasks/run-application/run-stateless-application-deployment/

https://minikube.sigs.k8s.io/docs/start/?arch=%2Fwindows%2Fx86-64%2Fstable%2F.exe+download#Service

https://v1-29.docs.kubernetes.io/docs/tasks/tools/install-kubectl-windows/#install-kubectl-binary-with-curl-on-windows

https://minikube.sigs.k8s.io/docs/drivers/hyperv/

https://minikube.sigs.k8s.io/docs/handbook/config/

https://platform9.com/learn/v1.0/tutorials/nginix-controller-via-yaml
