resource "aws_security_group" "sgforfrontend" {
  vpc_id      = aws_vpc.Ecsvpcstrapi.id
  description = "This is for frontend react application"
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
    Name = "Sg-for-nginx-rm"
  }
  depends_on = [ data.aws_network_interface.interface_tags ]

}

data "aws_ami" "ubuntu1" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
  depends_on = [ aws_security_group.sgforfrontend ]
}


resource "aws_instance" "ec2forfrontreact" {
  ami                         = data.aws_ami.ubuntu1.id
  availability_zone           = "us-west-2a"
  instance_type               = var.instance_type
  vpc_security_group_ids      = [aws_security_group.sgforfrontend.id]
  subnet_id                   = aws_subnet.publicsubnets[0].id
  key_name                    = aws_key_pair.keypairfornginx.key_name
  associate_public_ip_address = true
  ebs_block_device {
    device_name           = "/dev/sdh"
    volume_size           = 20
    volume_type           = "gp2"
    delete_on_termination = true
  }
  user_data = <<-EOF
    #!/bin/bash
    sudo apt update
  EOF

  tags = {
    Name = "ec2forfrontreact-rm"
  }

  provisioner "file" {
    source      = "./Dockerfile"
    destination = "/tmp/Dockerfile"
    connection {
      type = "ssh"
      user = "ubuntu"
      private_key = tls_private_key.fornginx.private_key_pem
      host = self.public_ip
    }
  }
  provisioner "remote-exec" {
    connection {
      type = "ssh"
      user = "ubuntu"
      private_key = tls_private_key.fornginx.private_key_pem
      host = self.public_ip
    }
    inline = [
        
        "sudo apt update",
		    "export DEBIAN_FRONTEND=noninteractive",
        "sudo apt install docker.io -y ",
        "sudo usermod -aG docker ubuntu",
        "sudo chmod 777 /var/run/docker.sock",
        "echo ${data.aws_network_interface.interface_tags.association[0].public_ip} > /tmp/public_ip.txt",
        "cd /tmp",
        "sudo docker build --build-arg PUBLIC_IP=$(cat /tmp/public_ip.txt) -t maheshryali/frontendreact:latest .",
        "echo ${var.docker_password} | docker login --username ${var.docker_username} --password-stdin",
        "docker image push maheshryali/frontendreact:latest"
    ]
  }
  depends_on = [
    data.aws_ami.ubuntu1
  ]
}
