resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-ecs-cluster-${var.env}"
}

resource "aws_ecs_service" "ecs-service-1" {
  name            = "${var.project_name}-ecs-service-1-${var.env}"
  iam_role        = aws_iam_role.ecs-service-role.arn
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.ecs-task-definition-1.family
  desired_count   = 2
  depends_on      = [aws_iam_role_policy_attachment.ecs-service-role-attachment]

  load_balancer {
    target_group_arn = aws_alb_target_group.ecs-target-group-1.arn
    container_port   = 8000
    container_name   = "ecs-app-1"
  }

  deployment_controller {
    type = "CODE_DEPLOY"
  }
}

resource "aws_ecs_service" "ecs-service-2" {
  name            = "${var.project_name}-ecs-service-2-${var.env}"
  iam_role        = aws_iam_role.ecs-service-role.arn
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.ecs-task-definition-2.family
  desired_count   = 2
  depends_on      = [aws_iam_role_policy_attachment.ecs-service-role-attachment]

  load_balancer {
    target_group_arn = aws_alb_target_group.ecs-target-group-2.arn
    container_port   = 8000
    container_name   = "ecs-app-2"
  }

  deployment_controller {
    type = "CODE_DEPLOY"
  }
}

resource "aws_ecs_task_definition" "ecs-task-definition-1" {
  family                = "${var.project_name}-ecs-task-1-${var.env}"
  container_definitions = file("container-definition-1.json")
}

resource "aws_ecs_task_definition" "ecs-task-definition-2" {
  family                = "${var.project_name}-ecs-task-2-${var.env}"
  container_definitions = file("container-definition-2.json")
}
