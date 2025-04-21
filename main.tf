resource "aws_launch_template" "web_server_as" {
  name_prefix   = "myproject-"
  image_id      = "ami-067198c5ae913ba30"
  instance_type = "t2.micro"
  key_name      = "TF"

  vpc_security_group_ids = [aws_security_group.web_server.id]

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "DevOps"
    }
  }
}

resource "aws_lb" "web_alb" {
  name               = "web-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_server.id]
  subnets            = ["subnet-04f223be1fe9d6975", "subnet-0f3a92bbccb9d94a7"]

  tags = {
    Name = "terraform-alb"
  }
}

resource "aws_lb_target_group" "web_tg" {
  name     = "web-tg"
  port     = 8000
  protocol = "HTTP"
  vpc_id   = "vpc-xxxxxxxx" # <-- Replace with your actual VPC ID
  target_type = "instance"

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399"
  }
}

resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

resource "aws_autoscaling_group" "web_server_asg" {
  name                      = "web-server-asg"
  min_size                  = 1
  max_size                  = 3
  desired_capacity          = 2
  health_check_type         = "EC2"
  health_check_grace_period = 300
  target_group_arns         = [aws_lb_target_group.web_tg.arn]
  vpc_zone_identifier       = ["subnet-04f223be1fe9d6975", "subnet-0f3a92bbccb9d94a7"]

  launch_template {
    id      = aws_launch_template.web_server_as.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "DevOps"
    propagate_at_launch = true
  }
}

