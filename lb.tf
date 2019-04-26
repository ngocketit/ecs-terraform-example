resource "aws_autoscaling_group" "ecs-autoscaling-group" {
  name                        = "${var.project_name}-ecs-autoscaling-${var.env}"
  max_size                    = "${var.ecs-instance-max-size}"
  min_size                    = "${var.ecs-instance-min-size}"
  desired_capacity            = "${var.ecs-instance-desired-size}"
  vpc_zone_identifier         = ["${aws_subnet.public.0.id}", "${aws_subnet.public.1.id}"]
  launch_configuration        = "${aws_launch_configuration.ecs-launch-configuration.name}"
  health_check_type           = "ELB"
  target_group_arns           = ["${aws_alb_target_group.ecs-target-group-1.arn}", "${aws_alb_target_group.ecs-target-group-2.arn}"]
}

resource "aws_launch_configuration" "ecs-launch-configuration" {
  name                        = "${var.project_name}-ecs-launch-config-${var.env}"
  image_id                    = "${var.ecs-instance-image-id}"
  instance_type               = "${var.ecs-instance-type}"
  iam_instance_profile        = "${aws_iam_instance_profile.ecs-instance-profile.name}" 
  associate_public_ip_address = "true"
  key_name                    = "${aws_key_pair.ecs-instance.key_name}"
  security_groups             = ["${aws_security_group.trusted-networks.id}", "${aws_security_group.ecs-instance.id}"]
  lifecycle {
    create_before_destroy = true
  }

  user_data                   = <<EOF
    #!/bin/bash
    echo ECS_CLUSTER=${aws_ecs_cluster.main.name} >> /etc/ecs/ecs.config
    start ecs
EOF
}

resource "aws_alb" "ecs-loadbalancer" {
  name                = "${var.project_name}-ecs-lb-${var.env}"
  security_groups     = ["${aws_security_group.ecs-loadbalancer.id}"]
  subnets             = ["${aws_subnet.public.*.id[0]}", "${aws_subnet.public.*.id[1]}"]
  tags   = "${merge(local.common_tags, map("Name", "${var.project_name}-ecs-${var.env}"))}"
}

resource "aws_alb_target_group" "ecs-target-group-1" {
  name                = "${var.project_name}-ecs-1-${var.env}"
  # This port doesn't really matter since ECS will map it to the correct ones
  port                = "8000"
  protocol            = "HTTP"
  vpc_id              = "${aws_vpc.main.id}"
  depends_on          = ["aws_alb.ecs-loadbalancer"]
  tags   = "${merge(local.common_tags, map("Name", "${var.project_name}-ecs-${var.env}"))}"

  health_check {
    healthy_threshold   = "5"
    unhealthy_threshold = "2"
    interval            = "30"
    matcher             = "200"
    path                = "/task2/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = "5"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_alb_target_group" "ecs-target-group-2" {
  name                = "${var.project_name}-ecs-2-${var.env}"
  # This port doesn't really matter since ECS will map it to the correct ones
  port                = "8000"
  protocol            = "HTTP"
  vpc_id              = "${aws_vpc.main.id}"
  depends_on          = ["aws_alb.ecs-loadbalancer"]
  tags   = "${merge(local.common_tags, map("Name", "${var.project_name}-ecs-${var.env}"))}"

  health_check {
    healthy_threshold   = "5"
    unhealthy_threshold = "2"
    interval            = "30"
    matcher             = "200"
    path                = "/task1/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = "5"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_alb_listener" "ecs-alb-listener" {
  load_balancer_arn = "${aws_alb.ecs-loadbalancer.arn}"
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    target_group_arn = "${aws_alb_target_group.ecs-target-group-2.arn}"
    type             = "forward"
  }
}

resource "aws_alb_listener_rule" "ecs-alb-listener-rule-1" {
  listener_arn = "${aws_alb_listener.ecs-alb-listener.arn}"
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = "${aws_alb_target_group.ecs-target-group-1.arn}"
  }

  condition {
    field  = "path-pattern"
    values = ["/task2/*"]
  }
}

resource "aws_alb_listener_rule" "ecs-alb-listener-rule-2" {
  listener_arn = "${aws_alb_listener.ecs-alb-listener.arn}"
  priority     = 101

  action {
    type             = "forward"
    target_group_arn = "${aws_alb_target_group.ecs-target-group-2.arn}"
  }

  condition {
    field  = "path-pattern"
    values = ["/task1/*"]
  }
}
