resource "aws_security_group" "trusted-networks" {
  name   = "${var.project_name}-trusted-${var.env}"
  vpc_id = aws_vpc.main.id
  tags   = merge(local.common_tags, map("Name", "${var.project_name}-trusted-${var.env}"))

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.trusted_networks]
  }

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.trusted_networks]
  }

  # ICMP
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.trusted_networks]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "ecs-instance" {
  key_name   = "${var.project_name}-ecs-instance-${var.env}"
  public_key = file("${path.module}/instance-public.key")
}

resource "aws_security_group" "ecs-loadbalancer" {
  name   = "${var.project_name}-ecs-loadbalancer-${var.env}"
  vpc_id = aws_vpc.main.id
  tags   = merge(local.common_tags, map("Name", "${var.project_name}-ecs-loadbalancer-${var.env}"))

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ecs-instance" {
  name   = "${var.project_name}-ecs-instance-${var.env}"
  vpc_id = aws_vpc.main.id
  tags   = merge(local.common_tags, map("Name", "${var.project_name}-ecs-instance-${var.env}"))

  ingress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs-loadbalancer.id]
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.trusted_networks]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 instance role
resource "aws_iam_role" "ecs-instance-role" {
  name               = "${var.project_name}-ecs-instance-role-${var.env}"
  path               = "/"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs-instance-role-attachment" {
  role       = aws_iam_role.ecs-instance-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

# ECS role
resource "aws_iam_role" "ecs-service-role" {
  name               = "${var.project_name}-ecs-service-${var.env}"
  path               = "/"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs-service-role-attachment" {
  role       = aws_iam_role.ecs-service-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}

resource "aws_iam_instance_profile" "ecs-instance-profile" {
  name = "${var.project_name}-ecs-instance-profile-${var.env}"
  path = "/"
  role = aws_iam_role.ecs-instance-role.name
}

