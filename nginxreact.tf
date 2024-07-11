resource "aws_security_group" "sgforreact" {
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
    Name = "Sg-for-react-rm"
  }
  depends_on = [ data.aws_network_interface.interface_tags1 ]

}
data "aws_ami" "ubuntu2" {
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
  depends_on = [ aws_security_group.sgfornginx ]
}


resource "aws_instance" "ec2fornginxreact" {
  ami                         = data.aws_ami.ubuntu2.id
  availability_zone           = "us-west-2a"
  instance_type               = var.instance_type
  vpc_security_group_ids      = [aws_security_group.sgfornginx.id]
  subnet_id                   = aws_subnet.publicsubnets[0].id
  key_name                    = aws_key_pair.keypairfornginx.key_name
  associate_public_ip_address = true
  ebs_block_device {
    device_name           = "/dev/sdh"
    volume_size           = 20
    volume_type           = "gp2"
    delete_on_termination = true
  }
  tags = {
    Name = "ec2forreact-rm"
  }

  user_data = <<-EOF
    #!/bin/bash
    set -e
    sudo apt-get update
    sudo apt-get install -y nginx

    # Configure Nginx site
    sudo tee /etc/nginx/sites-available/strapi > /dev/null <<'EOT'
    server {
        listen 80;
        server_name maheshr.contentecho.in;

        location / {
            proxy_pass http://${data.aws_network_interface.interface_tags1.association[0].public_ip}:3000;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }
    }
    EOT

    # Enable and configure the site
    sudo ln -s /etc/nginx/sites-available/strapi /etc/nginx/sites-enabled/
    sudo rm /etc/nginx/sites-enabled/default

    # Restart Nginx to apply changes
    sudo systemctl restart nginx
  EOF
  depends_on = [ 
    data.aws_ami.ubuntu2
  ]
}



