locals {
  common_tags = {
    Environment = "Blue-Green"
    ManagedBy   = "Terraform"
  }
}

# ------------------------------------------------------------------------------
# Target Groups
# ------------------------------------------------------------------------------

resource "aws_lb_target_group" "blue" {
  name     = "${var.prefix}-blue-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.existing.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = merge(local.common_tags, {
    Name = "${var.prefix}-blue-tg"
  })
}

resource "aws_lb_target_group" "green" {
  name     = "${var.prefix}-green-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.existing.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = merge(local.common_tags, {
    Name = "${var.prefix}-green-tg"
  })
}

# ------------------------------------------------------------------------------
# Application Load Balancer
# ------------------------------------------------------------------------------

resource "aws_lb" "main" {
  name               = "${var.prefix}-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [data.aws_security_group.lb.id]
  subnets            = [data.aws_subnet.public1.id, data.aws_subnet.public2.id]

  tags = merge(local.common_tags, {
    Name = "${var.prefix}-lb"
  })
}

# ------------------------------------------------------------------------------
# ALB HTTP Listener with Weighted Target Groups
# ------------------------------------------------------------------------------

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "forward"

    forward {
      target_group {
        arn    = aws_lb_target_group.blue.arn
        weight = var.blue_weight
      }

      target_group {
        arn    = aws_lb_target_group.green.arn
        weight = var.green_weight
      }
    }
  }
}

# ------------------------------------------------------------------------------
# Launch Templates
# ------------------------------------------------------------------------------

resource "aws_launch_template" "blue" {
  name   = "${var.prefix}-blue-template-"
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_type

  vpc_security_group_ids = [
    data.aws_security_group.http.id,
    data.aws_security_group.ssh.id
  ]

  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Blue Environment</h1>" > /var/www/html/index.html
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = merge(local.common_tags, {
      Name = "${var.prefix}-blue-instance"
    })
  }

  tags = merge(local.common_tags, {
    Name = "${var.prefix}-blue-template"
  })
}

resource "aws_launch_template" "green" {
  name   = "${var.prefix}-green-template-"
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_type

  vpc_security_group_ids = [
    data.aws_security_group.http.id,
    data.aws_security_group.ssh.id
  ]

  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Green Environment</h1>" > /var/www/html/index.html
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = merge(local.common_tags, {
      Name = "${var.prefix}-green-instance"
    })
  }

  tags = merge(local.common_tags, {
    Name = "${var.prefix}-green-template"
  })
}

# ------------------------------------------------------------------------------
# Auto Scaling Groups
# ------------------------------------------------------------------------------

resource "aws_autoscaling_group" "blue" {
  name                = "${var.prefix}-blue-asg"
  vpc_zone_identifier = [data.aws_subnet.public1.id, data.aws_subnet.public2.id]
  target_group_arns   = [aws_lb_target_group.blue.arn]

  min_size         = 1
  max_size         = 2
  desired_capacity = 1

  launch_template {
    id      = aws_launch_template.blue.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.prefix}-blue-asg-instance"
    propagate_at_launch = true
  }

  depends_on = [aws_lb_listener.http]
}

resource "aws_autoscaling_group" "green" {
  name                = "${var.prefix}-green-asg"
  vpc_zone_identifier = [data.aws_subnet.public1.id, data.aws_subnet.public2.id]
  target_group_arns   = [aws_lb_target_group.green.arn]

  min_size         = 1
  max_size         = 2
  desired_capacity = 1

  launch_template {
    id      = aws_launch_template.green.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.prefix}-green-asg-instance"
    propagate_at_launch = true
  }

  depends_on = [aws_lb_listener.http]
}