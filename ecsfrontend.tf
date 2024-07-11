resource "aws_security_group" "sgforreactrm" {
  vpc_id      = aws_vpc.Ecsvpcstrapi.id
  description = "This is for strapy application"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {

    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Sg-strapi-rm"
  }
  depends_on = [ aws_instance.ec2forfrontreact ]

}
resource "aws_ecs_task_definition" "strapiecstaskdefinition" {
    family = "strapiecstaskdefinition-rm"
    network_mode             = "awsvpc"
    cpu = "256"
    memory = "512"
    
    container_definitions = jsonencode([
        {
            name = "strapicontainer"
            image = "maheshryali/frontendreact:latest"
            essential = true
            portMappings = [
                {
                    containerPort = 3000
                    hostPort = 3000
                }
            ]
        }
    ])
    requires_compatibilities = ["FARGATE"]
    execution_role_arn = aws_iam_role.Ecstaskdefnitionrole.arn
    task_role_arn = aws_iam_role.Ecstaskdefnitionrole.arn
    depends_on = [ 
        aws_security_group.sgforreactrm
     ]
}
resource "aws_ecs_service" "ecs_service_reactrm" {
    name = "React-ecs-service-rm"
    cluster = aws_ecs_cluster.strapiecscluster.id
    task_definition = aws_ecs_task_definition.strapiecstaskdefinition.arn
    desired_count = 1
    enable_ecs_managed_tags = true  
    wait_for_steady_state   = true
    capacity_provider_strategy {
      capacity_provider = "FARGATE_SPOT"
      weight = 1
    }
    network_configuration {
      subnets = [aws_subnet.publicsubnets[0].id, aws_subnet.publicsubnets[1].id]
      security_groups = [aws_security_group.sgforreactrm.id]
      assign_public_ip = true
    }
    depends_on = [ aws_ecs_task_definition.strapiecstaskdefinition ]
  
}

data "aws_network_interface" "interface_tags1" {
  depends_on = [aws_ecs_service.ecs_service_reactrm]
  filter {
    name   = "tag:aws:ecs:serviceName"
    values = ["React-ecs-service-rm"]
  }
}



resource "aws_route53_record" "subdomain" {
  zone_id = var.Hostedzoneid  
  name    = "maheshr.contentecho.in"  
  type    = "A"
  ttl     = 300

  records = [aws_instance.ec2fornginxreact.public_ip]
  depends_on = [ aws_instance.ec2fornginxreact ]
}





