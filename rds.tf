# ---------------------------------------------
# RDS parameter group
# ---------------------------------------------
resource "aws_db_parameter_group" "mysql_standalone_parametergroup" {
  name   = "${var.project}-${var.environment}-mysql-standalone-parametergroup"
  family = "mysql8.0"

  parameter {
    name  = "character_set_database"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }
}


# ---------------------------------------------
# RDS option group
# ---------------------------------------------
resource "aws_db_option_group" "mysql_standalone_optiongroup" {
  name                 = "${var.project}-${var.environment}-mysql-standalone-optiongroup"
  engine_name          = "mysql"
  major_engine_version = "8.0"
}


# ---------------------------------------------
# RDS subnet group
# ---------------------------------------------
resource "aws_db_subnet_group" "mysql_standalone_subnetgroup" {
  name = "${var.project}-${var.environment}-mysql-standalone-subnetgroup"
  subnet_ids = [
    aws_subnet.private_subnet_1a.id,
    aws_subnet.private_subnet_1c.id
  ]

  tags = {
    Name    = "${var.project}-${var.environment}-mysql-standalone-subnetgroup"
    Project = var.project
    Env     = var.environment
  }
}


# ---------------------------------------------
# RDS instance
# ---------------------------------------------
resource "random_string" "db_password" {
  length  = 16
  special = false
}

resource "aws_db_instance" "mysql_standalone" {
  engine         = "mysql"
  engine_version = "8.0.20"

  identifier = "${var.project}-${var.environment}-mysql-standalone"

  username = "admin"
  password = random_string.db_password.result

  instance_class = "db.t2.micro"

  allocated_storage     = 20 // これは最小値 ここを変更すると、ストレージの拡張ができる
  max_allocated_storage = 50 // これは最大値 ここを変更すると、ストレージの拡張ができる
  storage_type          = "gp2"
  storage_encrypted     = false

  multi_az               = false
  availability_zone      = "ap-northeast-1a"
  db_subnet_group_name   = aws_db_subnet_group.mysql_standalone_subnetgroup.name // ここで指定した subnet group に属する subnet に配置される
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  publicly_accessible    = false
  port                   = 3306

  db_name                 = "tastylog"
  parameter_group_name = aws_db_parameter_group.mysql_standalone_parametergroup.name
  option_group_name    = aws_db_option_group.mysql_standalone_optiongroup.name

  backup_window              = "04:00-05:00" // backup の時間帯
  backup_retention_period    = 7 // backup の保持期間 (日数)
  maintenance_window         = "Mon:05:00-Mon:08:00" // メンテナンスの時間帯 backup と同じ時間帯にはしない
  auto_minor_version_upgrade = false // マイナーバージョンのアップグレードを自動で行うかどうか

  deletion_protection = false // インスタンスの削除を保護するかどうか 削除女時は、false にする必要がある
  skip_final_snapshot = true // インスタンスの削除時に最後のスナップショットを作成するかどうか

  apply_immediately = true // インスタンスの作成時にすぐに適用するかどうか (true にすると、インスタンスの作成に時間がかかる) false にすると、手動で適用する必要がある 適用とは、パラメータグループやオプショングループの変更をインスタンスに反映させること

  tags = {
    Name    = "${var.project}-${var.environment}-mysql-standalone"
    Project = var.project
    Env     = var.environment
  }
}
