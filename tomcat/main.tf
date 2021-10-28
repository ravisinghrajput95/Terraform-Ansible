provider "aws" {
  profile = "${var.aws_profile}"
  region = "${var.aws_region}"
}


# key pair

resource "aws_key_pair" "auth" {
  key_name  = "MyKey"
  public_key = "${file(var.public_key_path)}"
}


# server

resource "aws_instance" "dev" {
  instance_type = "${var.dev_instance_type}"
  ami = "${var.dev_ami}"
  tags= {
    Name = "wordpress-instance"
  }

  key_name = "${aws_key_pair.auth.id}"
  vpc_security_group_ids = ["${aws_security_group.web.id}"]
  #subnet_id = "${aws_subnet.public.id}"
  
  connection {

    private_key = "${file(var.private_key)}"
    user        = "${var.ansible_user}"
    host = self.public_ip
  }
  provisioner "remote-exec" {
    inline = ["sudo yum update -y && sudo yum install python -y"]
  }
  
  provisioner "local-exec" {
      command = <<EOD
cat <<EOF > aws_hosts 
[dev] 
${aws_instance.dev.public_ip} 
EOF
EOD
  }

  provisioner "local-exec" {
    command = " export ANSIBLE_HOST_KEY_CHECKING=False && aws ec2 wait instance-status-ok --instance-ids ${aws_instance.dev.id} && ansible-playbook -i aws_hosts tomcat.yml"
  }
}
resource "aws_security_group" "web" {
  name        = "default-web-example"
  description = "Security group for web that allows web traffic from internet"
  #vpc_id      = "${aws_vpc.my-vpc.id}"

  ingress {
 from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags= {
                            Name = "web-example-default-vpc"
  }
}
