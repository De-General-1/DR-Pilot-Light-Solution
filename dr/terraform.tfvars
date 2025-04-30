# vpc
region              = "us-east-1"
vpc_cidr            = "11.0.0.0/16"
vpc_name            = "dr-proj-us-east-1-vpc"
cidr_public_subnet  = ["11.0.1.0/24", "11.0.2.0/24"]
cidr_private_subnet = ["11.0.3.0/24", "11.0.4.0/24"]
availability_zones  = ["us-east-1a", "us-east-1b"]

# security group
alb_sg_name         = "dr-alb-sg"
ec2_sg_name         = "dr-ec2-sg"
db_sg_name          = "dr-database-sg"
security_group_cidr = "0.0.0.0/0"

# database
db_password       = "rootpassword"
db_username       = "root"
db_name           = "degendb"
db_instance_class = "db.t3.micro"
db_identifier     = "mysql-db"
db_subnet_name    = "secondary-subnet-group"
db_engine         = "mysql"
storage_type      = "gp2"

# alb
project_name = "dr-project"
#route53
domain_name = "degeneral.space"
alternative_names = ["www.degeneral.space"]

# EC2 VARIABLES
instance_name = "register-app-pilot-light"
key_name      = "web-keyPair"

# Database secret name:
db_secret_name = "prod/live/degeneral-secret"


primary-app-bucket-name = "degen-primary-app-bucket"

dr-app-bucket-name = "degen-dr-app-bucket"

snsEmail= "aboagyefafa12@gmail"