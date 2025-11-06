resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0" # Ubuntu 22.04 in eu-west-1
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.web_public.id
  security_groups = [aws_security_group.web_sg.name]

  tags = { Name = "Webserver-HR" }

  user_data = <<-EOF
              #!/bin/bash
              apt update -y
              apt install -y nginx
              echo "<h1>Hello World from HR Webserver</h1>" > /var/www/html/index.html
              systemctl enable nginx
              systemctl start nginx
              EOF
}
