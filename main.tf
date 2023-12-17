provider "aws" {
    region = "eu-north-1"
}

module "vpc" {
    source = "./vpc"
}

module "rds_animals-man" {
    source = "./rds_animals-man"
    vpc_id = module.vpc.vpc_id
    private_subnet_ids = module.vpc.private_subnet_ids

    depends_on = [ module.vpc ]
}

module "ecs_animals-man" {
    source = "./ecs_animals-man"
    vpc_id = module.vpc.vpc_id
    public_subnet_ids = module.vpc.public_subnet_ids
    private_subnet_ids = module.vpc.private_subnet_ids
    load_balancer_arn = module.vpc.load_balancer_arn
    db_name = module.rds_animals-man.db_name
    db_password = module.rds_animals-man.db_password
    db_host = module.rds_animals-man.db_host
    db_username = module.rds_animals-man.db_username
    db_port = module.rds_animals-man.db_port
}

module "rds_profile-man" {
    source = "./rds_profile-man"
    vpc_id = module.vpc.vpc_id
    private_subnet_ids = module.vpc.private_subnet_ids

    depends_on = [ module.vpc ]
}

module "ecs_profile-man" {
    source = "./ecs_profile-man"
    vpc_id = module.vpc.vpc_id
    public_subnet_ids = module.vpc.public_subnet_ids
    private_subnet_ids = module.vpc.private_subnet_ids
    load_balancer_arn = module.vpc.load_balancer_arn
    db_name = module.rds_profile-man.db_name
    db_password = module.rds_profile-man.db_password
    db_host = module.rds_profile-man.db_host
    db_username = module.rds_profile-man.db_username
    db_port = module.rds_profile-man.db_port
}

module "rds_notifications" {
    source = "./rds_notifications"
    vpc_id = module.vpc.vpc_id
    private_subnet_ids = module.vpc.private_subnet_ids

    depends_on = [ module.vpc ]
}

module "ecs_notifications" {
    source = "./ecs_notifications"
    vpc_id = module.vpc.vpc_id
    public_subnet_ids = module.vpc.public_subnet_ids
    private_subnet_ids = module.vpc.private_subnet_ids
    load_balancer_arn = module.vpc.load_balancer_arn
    db_name = module.rds_notifications.db_name
    db_password = module.rds_notifications.db_password
    db_host = module.rds_notifications.db_host
    db_username = module.rds_notifications.db_username
    db_port = module.rds_notifications.db_port
}

module "rds_comments-ratings" {
    source = "./rds_comments-ratings"
    vpc_id = module.vpc.vpc_id
    private_subnet_ids = module.vpc.private_subnet_ids

    depends_on = [ module.vpc ]
}

module "ecs_comments-ratings" {
    source = "./ecs_comments-ratings"
    vpc_id = module.vpc.vpc_id
    public_subnet_ids = module.vpc.public_subnet_ids
    private_subnet_ids = module.vpc.private_subnet_ids
    load_balancer_arn = module.vpc.load_balancer_arn
    db_name = module.rds_comments-ratings.db_name
    db_password = module.rds_comments-ratings.db_password
    db_host = module.rds_comments-ratings.db_host
    db_username = module.rds_comments-ratings.db_username
    db_port = module.rds_comments-ratings.db_port
}
