Create a deployment of an EC2 instance using Terraform with specific parameters:
T2.Micro
12GB Storage
London Region
Access to SSH and RDP from a single IP address
Address to https from anywhere

STEPS

#1 Create a VPC
#2 Create IGW
#3 Create a custom RT
#4 Create a subnet
#5 Associate the subnet with the RT
#6 Create a security group
#7 Create a network interface with an IP in the subnet that was created in step 4
#8 Assign an elastic IP to the network interface created in step 7
#9 Launch an  EC2 instance
