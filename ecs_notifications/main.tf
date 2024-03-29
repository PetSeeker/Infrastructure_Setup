provider "aws" {
    alias = "us-east-1"
    region = "us-east-1"
}

resource "aws_security_group" "noti-api_sg" {
    name        = "Notifications API Security Group"
    description = "Allow all inbound traffic"
    vpc_id      = var.vpc_id

    ingress {
        description = "Allow http traffic from load balancer"
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = var.public_subnet_cidrs
    }

    ingress {
        description = "Allow http traffic from load balancer"
        from_port   = 8002
        to_port     = 8002
        protocol    = "tcp"
        cidr_blocks = var.public_subnet_cidrs
    }

    ingress {
        description = "Allow ssh traffic from bastion host"
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = var.public_subnet_cidrs
    }

     egress {
      from_port   = 0
      to_port     = 65535
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
      Name = "Notifications API Security Group"
    }
}

resource "aws_ecrpublic_repository" "ecr_repo" {

    provider = aws.us-east-1
    repository_name = "noti-man-repo"

    catalog_data {
        architectures     = ["x86-64", "x86"]
        operating_systems = ["Linux"]
    }

    tags = {
        env = "production"
    }
}

data "aws_ami" "amazon_linux_2" {
    most_recent = true

    filter {
      name   = "virtualization-type"
      values = ["hvm"]
    }

    filter {
      name   = "owner-alias"
      values = ["amazon"]
    }

    filter {
      name   = "name"
      values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
    }

    owners = ["amazon"]
}

resource "aws_launch_template" "ecs_lt" {
    name_prefix   = "ecs-template"
    image_id      = data.aws_ami.amazon_linux_2.id
    instance_type = "t3.micro"
    iam_instance_profile {
      name = "ecsInstanceRole"
    }
    key_name               = "petseeker23"
    vpc_security_group_ids = [aws_security_group.noti-api_sg.id]

    block_device_mappings {
        device_name = "/dev/xvda"
        ebs {
            volume_size = 30
            volume_type = "gp2"
        }
    }

    tag_specifications {
    resource_type = "instance"
        tags = {
            "Name" = "ecs-noti-man-instance"
        }
    }
    user_data = filebase64("${path.module}/ecs.sh")
}

resource "aws_autoscaling_group" "ecs_asg" {
    vpc_zone_identifier = var.private_subnet_ids
    desired_capacity    = 1
    max_size            = 1
    min_size            = 1

    launch_template {
        id      = aws_launch_template.ecs_lt.id
        version = "$Latest"
    }

    tag {
        key                 = "Name"
        value               = "ecs-noti-man-asg"
        propagate_at_launch = true
    }

}

resource "aws_lb_listener" "ecs_alb_listener" {
    load_balancer_arn = var.load_balancer_arn
    port              = 8002
    protocol          = "HTTP"

    default_action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.ecs_tg.arn
    }
}

resource "aws_lb_target_group" "ecs_tg" {
    name        = "ecs-noti-man-tg"
    port        = 8002
    protocol    = "HTTP"
    vpc_id      = var.vpc_id

    health_check {
        path = "/health"
    }
}

resource "aws_ecs_cluster" "ecs_cluster" {
    name = "noti-man-cluster"
}

resource "aws_ecs_capacity_provider" "ecs_capacity_provider" {
    name = "noti-man-cp"

    auto_scaling_group_provider {
        auto_scaling_group_arn = aws_autoscaling_group.ecs_asg.arn

        managed_scaling {
            maximum_scaling_step_size = 1000
            minimum_scaling_step_size = 1
            status                    = "ENABLED"
            target_capacity           = 1
        }
    }
}

resource "aws_ecs_cluster_capacity_providers" "example" {
    cluster_name = aws_ecs_cluster.ecs_cluster.name

    capacity_providers = [aws_ecs_capacity_provider.ecs_capacity_provider.name]

    default_capacity_provider_strategy {
        base              = 1
        weight            = 100
        capacity_provider = aws_ecs_capacity_provider.ecs_capacity_provider.name
    }
}

resource "aws_ecs_task_definition" "ecs_task_definition" {
  family = "noti-man-task"
  memory = 128
  cpu    = 256

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([
    {
      name      = "noti-man-container"
      image     = "${aws_ecrpublic_repository.ecr_repo.repository_uri}:latest"
      essential = true

      portMappings = [
        {
          containerPort = 8002
          hostPort      = 8002
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          "name"  = "DB_DATABASE",
          "value" = tostring(var.db_name)
        },
        {
          "name"  = "DB_USER",
          "value" = tostring(var.db_username)
        },
        {
          "name"  = "DB_PASSWORD",
          "value" = tostring(var.db_password)
        },
        {
          "name"  = "DB_HOST",
          "value" = tostring(var.db_host)
        },
        {
          "name"  = "AWS_ACCESS_KEY_ID",
          "value" = "AKIA2LVMNRX3TCQ2L7XN"
        },
        {
          "name"  = "AWS_SECRET_ACCESS_KEY",
          "value" = "HTuUKpL3OZhwr8ddIq0GJjNMn+B1E7+RdiISWz3u"
        },
        {
          "name"  = "AWS_REGION",
          "value" = "eu-north-1"
        },
        {
          "name"  = "SOURCE_EMAIL",
          "value" = "petseeker2@gmail.com"
        },
        {
          "name"  = "SENDGRID_API_KEY",
          "value" = "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"
        },
        {
          "name"  = "DB_PORT",
          "value" = tostring(var.db_port)
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "ecs_service" {
    name            = "noti-man-service"
    cluster         = aws_ecs_cluster.ecs_cluster.id
    task_definition = aws_ecs_task_definition.ecs_task_definition.arn
    desired_count   = 1
    scheduling_strategy = "REPLICA"
    launch_type           = "EC2"
    load_balancer {
        target_group_arn = aws_lb_target_group.ecs_tg.arn
        container_name   = "noti-man-container"
        container_port   = 8002
    }

    depends_on = [aws_autoscaling_group.ecs_asg]
}