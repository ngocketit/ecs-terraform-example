resource "aws_iam_role" "codedeploy" {
  name = "${var.project_name}-ecs-codedeploy-${var.env}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "codedeploy.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "codedeploy" {
  name   = "${var.project_name}-ecs-codedeploy-${var.env}"
  path   = "/"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecs:*"
      ],
      "Resource": [
        "*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:*"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "AWSCodeDeployRole" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
  role       = aws_iam_role.codedeploy.name
}

resource "aws_iam_role_policy_attachment" "custom" {
  policy_arn = aws_iam_policy.codedeploy.arn
  role       = aws_iam_role.codedeploy.name
}

resource "aws_codedeploy_app" "task1" {
  compute_platform = "ECS"
  name             = "${var.project_name}-ecs-task1-${var.env}"
}

resource "aws_codedeploy_app" "task2" {
  compute_platform = "ECS"
  name             = "${var.project_name}-ecs-task2-${var.env}"
}

resource "aws_codedeploy_deployment_group" "task1" {
  app_name               = aws_codedeploy_app.task1.name
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  deployment_group_name  = "${var.project_name}-ecs-task1-${var.env}"
  service_role_arn       = aws_iam_role.codedeploy.arn

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.main.name
    service_name = aws_ecs_service.ecs-service-1.name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [aws_alb_listener.ecs-alb-listener.arn]
      }

      target_group {
        name = aws_alb_target_group.ecs-target-group-1.name
      }

      target_group {
        name = aws_alb_target_group.ecs-target-group-1-green.name
      }
    }
  }
}

resource "aws_codedeploy_deployment_group" "task2" {
  app_name               = aws_codedeploy_app.task2.name
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  deployment_group_name  = "${var.project_name}-ecs-task2-${var.env}"
  service_role_arn       = aws_iam_role.codedeploy.arn

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.main.name
    service_name = aws_ecs_service.ecs-service-2.name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [aws_alb_listener.ecs-alb-listener.arn]
      }

      target_group {
        name = aws_alb_target_group.ecs-target-group-2.name
      }

      target_group {
        name = aws_alb_target_group.ecs-target-group-2-green.name
      }
    }
  }
}
