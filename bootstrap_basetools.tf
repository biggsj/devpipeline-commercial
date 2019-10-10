variable "dockeree_license_url" {
  description = "URL associated with DockerEE license.  A 1-month trial can be obtained from https://hub.docker.com/editions/enterprise/docker-ee-trial"
}

variable "dockeree_license_file" {
  description = "Path to the file containing the DockerEE license, this is provided along with the dockeree_url when obtaining a license."
}

variable "docker_host_ami" {
  description = "The Amazon Machine Image for bootstrapping Docker hosts."
}

variable "bootstrapper_host_type" {
  description = "The EC2 type to use for a potentially transient host to bootstrap builds for services like Bitbucket, Bamboo and Jenkins."
  default     = "t3.large"
}

resource "aws_instance" "bootstrapper" {
  ami                    = var.docker_host_ami
  instance_type          = var.bootstrapper_host_type
  subnet_id              = aws_subnet.core.id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.core.id]
  tags = {
    Name    = "${var.project_name} BootStrapper"
    Role    = "BootStrapper"
    Project = var.project_name
  }

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "centos"
    private_key = file(var.private_key_file)
    agent       = false
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir /tmp/bamboo_server_build",
    ]
  }

  provisioner "file" {
    source      = var.dockeree_license_file
    destination = "/tmp/docker_subscription.lic"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chown centos /etc/yum/vars",
      "echo ${var.dockeree_license_url}/centos > /etc/yum/vars/dockerurl",
      "sudo yum install -y yum-utils device-mapper-persistent-data lvm2",
      "sudo -E yum-config-manager --add-repo \"${var.dockeree_license_url}/centos/docker-ee.repo\"",
      "sudo yum -y install docker-ee",
      "sudo systemctl enable docker",
      "sudo systemctl start docker",
      "sudo docker container run --rm -it --name ucp -v /var/run/docker.sock:/var/run/docker.sock -v /tmp/docker_subscription.lic:/config/docker_subscription.lic docker/ucp:3.2.1 install --host-address ${self.private_ip} --admin-username ${var.admin_username} --admin-password ${var.admin_password} --force-minimums",
    ]
  }
}

