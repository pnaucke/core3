data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

locals {
  user_data = <<-EOT
    #!/bin/bash
    yum update -y
    amazon-linux-extras enable nginx1
    yum install -y nginx gettext

    systemctl start nginx
    systemctl enable nginx

    # Website folder kopiëren
    mkdir -p /home/ec2-user/website
    cp -r /home/ec2-user/terraform/website/* /usr/share/nginx/html/

    # Optioneel placeholders vervangen in HTML
    for file in /usr/share/nginx/html/*.html; do
      envsubst < "$file" > "${file}.tmp"
      mv "${file}.tmp" "$file"
    done
  EOT
}

resource "aws_instance" "web1" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.web1_subnet.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = "Project1"
  user_data              = local.user_data
  tags = { Name = "web1" }
}

resource "aws_instance" "web2" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.web2_subnet.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = "Project1"
  user_data              = local.user_data
  tags = { Name = "web2" }
}
