resource "aws_cloudfront_origin_access_identity" "default" {
  comment = "Delos website access."
}

data "aws_cloudfront_cache_policy" "Managed-CachingOptimized" {
  name = "Managed-CachingOptimized"
}

locals {
  name = "${var.name}-${var.env}"
}

module "cdn" {
  source              = "terraform-aws-modules/cloudfront/aws"
  version             = "3.2.1"
  create_distribution = true


  comment             = local.name
  enabled             = true
  aliases             = [var.domain_name]
  default_root_object = "index.html"

  // Optimized for North America
  // See https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/PriceClass.html
  price_class = "PriceClass_100"

  create_origin_access_identity = false

  custom_error_response = [{
    error_code         = 404
    response_code      = 404
    response_page_path = "/errors/404.html"
    }, {
    error_code         = 403
    response_code      = 403
    response_page_path = "/errors/403.html"
  }]
  origin = {
    app = {
      domain_name = module.alb.lb_dns_name
      origin_id   = "ALB-compiler-explorer"
      custom_origin_config = {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "match-viewer"
        origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
      }
    }
  }

  default_cache_behavior = {
    target_origin_id       = "ALB-compiler-explorer"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods      = ["GET", "HEAD", "OPTIONS"]
    cached_methods       = ["GET", "HEAD"]
    compress             = true
    cache_policy_id      = data.aws_cloudfront_cache_policy.Managed-CachingOptimized.id
    use_forwarded_values = false

  }

  ordered_cache_behavior = [
    {
      path_pattern           = "/index.html"
      target_origin_id       = "ALB-compiler-explorer"
      viewer_protocol_policy = "redirect-to-https"

      allowed_methods      = ["GET", "HEAD", "OPTIONS"]
      cached_methods       = ["GET", "HEAD"]
      compress             = true
      cache_policy_id      = data.aws_cloudfront_cache_policy.Managed-CachingOptimized.id
      use_forwarded_values = false
    },
  ]

  viewer_certificate = {
    acm_certificate_arn = data.aws_acm_certificate.cert.arn
    ssl_support_method  = "sni-only"
  }
}

module "rds_cluster" {
  name                   = local.name
  source                 = "terraform-aws-modules/rds-aurora/aws"
  version                = "8.3.1"
  vpc_id                 = data.aws_vpc.current.id
  vpc_security_group_ids = [data.aws_security_group.rds_sg.id]

  engine                              = "aurora-postgresql"
  engine_version                      = "14.5"
  iam_database_authentication_enabled = true
  manage_master_user_password         = true
  master_username                     = "delos"
  database_name                       = "delos"


  instance_class = var.cluster_rds_instance_type
  instances      = { for i in range(2) : i => {} }

  db_subnet_group_name   = aws_db_subnet_group.default.name
  create_db_subnet_group = false
  create_security_group  = false

  deletion_protection     = lower(var.env) == "prod" ? true : false
  backup_retention_period = lower(var.env) == "prod" ? 7 : 1
  skip_final_snapshot     = true

}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 8.0"

  name = local.name

  load_balancer_type = "application"

  vpc_id          = data.aws_vpc.current.id
  subnets         = data.aws_subnets.public.ids
  security_groups = [data.aws_security_group.alb_sg.id]

  https_listeners = [
    {
      port               = 443
      protocol           = "HTTPS"
      certificate_arn    = data.aws_acm_certificate.cert.arn
      target_group_index = 0
    },
  ]

  # http_tcp_listeners = [
  #   {
  #     port     = 80
  #     protocol = "HTTP"
  #     #certificate_arn    = data.aws_acm_certificate.cert.arn
  #     target_group_index = 0
  #   },
  # ]

  target_groups = [
    {
      name             = "${local.name}-${var.container_name}"
      backend_protocol = "HTTP"
      backend_port     = var.container_port
      target_type      = "ip"
    },
  ]

}

module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "5.2.0"

  cluster_name = local.name

  # Capacity provider
  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 50
        base   = 20
      }
    }
    FARGATE_SPOT = {
      default_capacity_provider_strategy = {
        weight = 50
      }
    }
  }

  services = {
    ecsdemo-frontend = {
      cpu    = 1024
      memory = 4096

      # Container definition(s)
      container_definitions = {

        (var.container_name) = {
          cpu       = 512
          memory    = 1024
          essential = true
          image     = "public.ecr.aws/aws-containers/ecsdemo-frontend:776fd50"
          port_mappings = [
            {
              name          = var.container_name
              containerPort = var.container_port
              hostPort      = var.container_port
              protocol      = "tcp"
            }
          ]

          # Example image used requires access to write to root filesystem
          readonly_root_filesystem = false


          enable_cloudwatch_logging = true
          memory_reservation        = 100
        }
      }


      load_balancer = {
        service = {
          target_group_arn = element(module.alb.target_group_arns, 0)
          container_name   = var.container_name
          container_port   = var.container_port
        }
      }

      subnet_ids            = data.aws_subnets.private.ids
      create_security_group = false
      security_group_ids    = [data.aws_security_group.ecs_sg.id]
    }
  }
}

resource "aws_db_subnet_group" "default" {
  name       = "rds-${local.name}"
  subnet_ids = data.aws_subnets.database.ids

  tags = {
    Name = "rds-${local.name}"
  }
}
