
################################################################################
# CREATING JENKINS SECUIRTY  GROUP
################################################################################

resource "aws_security_group" "jenkins_sg" {
  name        = "${var.component_name}-jenkins-sg"
  description = "Allow access jenkins ingress access"
  vpc_id      = local.vpc_id

  tags = {
    Name = "${var.component_name}-jenkins-sg"
  }
}

resource "aws_security_group_rule" "ingress_access_on_http" {

  security_group_id = aws_security_group.jenkins_sg.id
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "egress_access_from_everywhere" {
  security_group_id = aws_security_group.jenkins_sg.id
  type              = "egress"
  to_port           = 0
  protocol          = "-1"
  from_port         = 0
  cidr_blocks       = ["0.0.0.0/0"]
}

################################################################################
# CREATING SONARQUBE SECUIRTY  GROUP
################################################################################

resource "aws_security_group" "sonarqube_sg" {
  name        = "${var.component_name}-sonarqube-sg"
  description = "Allow access sonarqube ingress access"
  vpc_id      = local.vpc_id

  tags = {
    Name = "${var.component_name}-sonarqube-sg"
  }
}

resource "aws_security_group_rule" "ingress_sonarqube_access_on_http" {

  security_group_id = aws_security_group.sonarqube_sg.id
  type              = "ingress"
  from_port         = 9000
  to_port           = 9000
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "egress_access_saonrqube_from_everywhere" {
  security_group_id = aws_security_group.sonarqube_sg.id
  type              = "egress"
  to_port           = 0
  protocol          = "-1"
  from_port         = 0
  cidr_blocks       = ["0.0.0.0/0"]
}
