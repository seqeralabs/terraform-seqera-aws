run "complete_eks_plan" {
    command = plan

    module {
        source = "./examples/complete_eks"
    }
}

run completes_public_ec2_plan {
    command = plan

    module {
        source = "./examples/complete_public_ec2"
    }
}

run "test_eks" {
    command = apply

    module {
        source = "./examples/complete_eks"
    }

    plan_options {
        target = [
            module.terraform-seqera-module.module.vpc,
            module.terraform-seqera-module.module.eks
        ]
    }
}

run "test_db" {
    command = apply

    module {
        source = "./examples/complete_eks"
    }

    plan_options {
        target = [
            module.terraform-seqera-module.module.vpc,
            module.terraform-seqera-module.module.db
        ]
    }
}

run "test_redis" {
    command = apply

    module {
        source = "./examples/complete_eks"
    }

    plan_options {
        target = [
            module.terraform-seqera-module.module.vpc,
            module.terraform-seqera-module.module.redis
        ]
    }
}

run "test_ec2" {
    command = apply

    module {
        source = "./examples/complete_public_ec2"
    }

    plan_options {
        target = [
            module.terraform-seqera-module.module.vpc,
            module.terraform-seqera-module.module.ec2_instance
        ]
    }
}