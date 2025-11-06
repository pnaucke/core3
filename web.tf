locals {
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y nginx
    echo "<h1>Hello World from HR Webserver</h1>" > /usr/share/nginx/html/index.html
    systemctl enable nginx
    systemctl start nginx
  EOF
}

resource "aws_instance" "web1" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.subnet_web_public.id
  private_ip             = "10.0.1.10"
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = "Project1"
  user_data              = local.user_data
  tags = { Name = "web1" }
}
