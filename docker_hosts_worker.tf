variable "docker_host_worker_type" {
  description = "The EC2 type to use for Docker worker hosts."
}

resource "aws_instance" "docker-worker" {
  count                  = 1
  ami                    = var.docker_host_ami
  instance_type          = var.docker_host_worker_type
  subnet_id              = aws_subnet.core.id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.core.id]
  tags = {
    Name    = "${var.project_name} Docker Worker ${count.index}"
    Role    = "DockerWorker"
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
      "sudo chown centos /etc/yum/vars",
      "echo ${var.dockeree_license_url}/centos > /etc/yum/vars/dockerurl",
      "sudo yum install -y yum-utils device-mapper-persistent-data lvm2",
      "sudo -E yum-config-manager --add-repo \"${var.dockeree_license_url}/centos/docker-ee.repo\"",
      "sudo yum -y install docker-ee",
      "sudo systemctl enable docker",
      "sudo systemctl start docker",
      "sudo yum install -y epel-release",
      "sudo yum install -y jq",
      "curl -sk -d '{\"username\":\"${var.admin_username}\",\"password\":\"${var.admin_password}\"}' https://${aws_instance.docker-ucp[0].private_ip}/auth/login | jq -r .auth_token > /tmp/ucp_auth_token",
      "curl -sk -H \"Authorization: Bearer $(cat /tmp/ucp_auth_token)\" https://${aws_instance.docker-ucp[0].private_ip}/swarm | jq -r .JoinTokens.Worker > /tmp/ucp_worker_join_token",
      "sudo docker swarm join --token $(cat /tmp/ucp_worker_join_token) ${aws_instance.docker-ucp[0].private_ip}:2377",
    ]
  }

  depends_on = [aws_instance.docker-ucp]
}

