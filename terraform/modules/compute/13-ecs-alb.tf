# Internal ALB para Blockchain Nodes
resource "aws_lb" "blockchain" {
  name               = "${local.name_prefix}-blockchain-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ecs.id]
  subnets            = [for s in aws_subnet.blockchain : s.id]

  tags = {
    Name = "${local.name_prefix}-blockchain-alb"
  }
}

resource "aws_lb_target_group" "blockchain" {
  name     = "${local.name_prefix}-blockchain-tg"
  port     = 9944
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 5
    matcher             = "200"
  }
}

resource "aws_lb_listener" "blockchain" {
  load_balancer_arn = aws_lb.blockchain.arn
  port              = "9944"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blockchain.arn
  }
}

resource "aws_lb_target_group_attachment" "blockchain_az1" {
  target_group_arn = aws_lb_target_group.blockchain.arn
  target_id        = aws_ecs_service.blockchain.id
  port             = 9944
}