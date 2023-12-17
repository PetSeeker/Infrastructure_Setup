# Define the VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/24"

  tags = {
    Name = "Project VPC"
  }
}


# Define the public subnets
resource "aws_subnet" "public_subnets" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = element(var.public_subnet_cidrs, count.index)
  availability_zone = element(var.azs, count.index)
  ipv6_cidr_block   = null

  tags = {
    Name = "Public Subnet ${count.index + 1}"
  }
}

# Define the private subnets
resource "aws_subnet" "private_subnets" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = element(var.private_subnet_cidrs, count.index)
  availability_zone = element(var.azs, count.index)
  ipv6_cidr_block   = null

  tags = {
    Name = "Private Subnet ${count.index + 1}"
  }
}

resource "aws_security_group" "bastion-host_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Bastion Host Security Group"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Internet Gateway"
  }
}

# Create a public route table
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Public Route Table"
  }
}

# Configure the public route table routes
resource "aws_route" "public_route" {
  count                  = length(aws_subnet.public_subnets)
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.my_igw.id
}

# Associate each public subnet with the public route table
resource "aws_route_table_association" "public_route_assoc" {
  count        = length(aws_subnet.public_subnets)
  subnet_id    = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_route_table.id

}

# Create a public Elastic IP for each NAT Gateway
resource "aws_eip" "my_nat_eip" {
  count = length(aws_subnet.private_subnets)
  depends_on = [aws_internet_gateway.my_igw]

  tags = {
    Name = "NAT EIP ${count.index + 1}"
  }
}

# Create a NAT Gateway with the Elastic IP for each private subnet
resource "aws_nat_gateway" "my_nat_gateway" {
  count         = length(aws_subnet.private_subnets)
  allocation_id = aws_eip.my_nat_eip[count.index].id
  subnet_id     = aws_subnet.public_subnets[count.index].id

  tags = {
    Name = "NAT Gateway ${count.index + 1}"
  }

  depends_on = [aws_internet_gateway.my_igw]
}

# Create a private route table for each private subnet
resource "aws_route_table" "private_route_table" {
    count  = length(aws_subnet.private_subnets)
    vpc_id = aws_vpc.main.id

    tags = {
        Name = "Private Route Table ${count.index + 1}"
    }
}

# Configure the private route table routes for each private subnet
resource "aws_route" "private_route" {
  count                  = length(aws_subnet.private_subnets)
  route_table_id         = aws_route_table.private_route_table[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.my_nat_gateway[count.index].id
}

# Associate each private subnet with the private route table
resource "aws_route_table_association" "private_route_assoc" {
  count        = length(aws_subnet.private_subnets)
  subnet_id    = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private_route_table[count.index].id
}

# Create a VPC endpoint for S3
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.eu-north-1.s3"

  tags = {
    Name = "S3 Endpoint"
  }
}

resource "aws_vpc_endpoint_route_table_association" "s3_route_assoc" {
  count = length(aws_subnet.private_subnets)
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
  route_table_id = aws_route_table.private_route_table[count.index].id
}

resource "aws_security_group" "lb_sg" {
  name = "Load Balancer Security Group"
  vpc_id = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Security Group"
  }
}

resource "aws_lb" "ecs_alb" {
    name               = "ecs-alb"
    internal           = false
    load_balancer_type = "application"
    security_groups    = [aws_security_group.lb_sg.id]
    subnets            =  aws_subnet.public_subnets[*].id

    tags = {
        Name = "ecs-alb"
    }
}

# resource "aws_key_pair" "deployer" {
#     key_name   = "PetSeeker"
#     public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD3F6tyPEFEzV0LX3X8BsXdMsQz1x2cEikKDEY0aIj41qgxMCP/iteneqXSIFZBp5vizPvaoIR3Um9xK7PGoW8giupGn+EPuxIA4cDM4vzOqOkiMPhz5XK0whEjkVzTo4+S0puvDZuwIsdiW9mxhJc7tgBNL0cYlWSYVkz4G/fslNfRPW5mYAM49f4fhtxPb5ok4Q2Lg9dPKVHO/Bgeu5woMc7RY0p1ej6D4CKFE6lymSDJpW0YHX/wqE9+cfEauh7xZcG0q9t2ta6F6fmX0agvpFyZo8aFbXeUBr7osSCJNgvavWbM/06niWrOvYX2xwWdhXmXSrbX8ZbabVohBK41 davideti042@gmail.com"
# }

# data "aws_iam_policy_document" "ecs_agent" {
#     statement {
#         actions = [
#             "sts:AssumeRole"
#         ]

#         principals {
#             type = "Service"
#             identifiers = [
#             "ecs.amazonaws.com"
#             ]
#         }

#     }
# }

# resource "aws_iam_role" "ecs_agent" {
#     name               = "ecs-agent"
#     assume_role_policy = data.aws_iam_policy_document.ecs_agent.json
# }

# resource "aws_iam_role_policy_attachment" "ecs_agent" {
#     role       = aws_iam_role.ecs_agent.name
#     policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
# }

# resource "aws_iam_instance_profile" "ecs_agent" {
#     name = "ecs-agent"
#     role = aws_iam_role.ecs_agent.name
# }