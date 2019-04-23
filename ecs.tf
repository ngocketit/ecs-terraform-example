resource "aws_ecs_cluster" "main" {
  name  = "${var.project_name}-ecs-cluster-${var.env}"
}

resource "aws_ecs_service" "ecs-service-sinatra" {
  name            = "${var.project_name}-ecs-service-sinatra-${var.env}"
  iam_role        = "${aws_iam_role.ecs-service-role.arn}"
  cluster         = "${aws_ecs_cluster.main.id}"
  task_definition = "${aws_ecs_task_definition.ecs-task-definition-sinatra.family}"
  desired_count   = 2
  depends_on      = ["aws_iam_role_policy_attachment.ecs-service-role-attachment"]

  load_balancer {
    target_group_arn  = "${aws_alb_target_group.ecs-target-group-sinatra.arn}"
    container_port    = 8000
    container_name    = "ecs-app-sinatra"
  }
}

resource "aws_ecs_service" "ecs-service-node" {
  name            = "${var.project_name}-ecs-service-node-${var.env}"
  iam_role        = "${aws_iam_role.ecs-service-role.arn}"
  cluster         = "${aws_ecs_cluster.main.id}"
  task_definition = "${aws_ecs_task_definition.ecs-task-definition-node.family}"
  desired_count   = 2
  depends_on      = ["aws_iam_role_policy_attachment.ecs-service-role-attachment"]

  load_balancer {
    target_group_arn  = "${aws_alb_target_group.ecs-target-group-node.arn}"
    container_port    = 8000
    container_name    = "ecs-app-node"
  }
}

resource "aws_ecs_task_definition" "ecs-task-definition-sinatra" {
  family = "${var.project_name}-ecs-task-sinatra-${var.env}"
  container_definitions = "${file("container-definition-sinatra.json")}"
}

resource "aws_ecs_task_definition" "ecs-task-definition-node" {
  family = "${var.project_name}-ecs-task-node-${var.env}"
  container_definitions = "${file("container-definition-node.json")}"
}
