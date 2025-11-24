resource "aws_autoscaling_group" "ecs_asg" {
  name_prefix = "${terraform.workspace}-ecs-asg"

  vpc_zone_identifier = [aws_subnet.public_a.id, aws_subnet.public_b.id]

  desired_capacity = 1
  min_size         = 1
  max_size         = 1

  launch_template {
    id      = aws_launch_template.ecs_ec2_template.id
    version = "$Latest"
  }
}
