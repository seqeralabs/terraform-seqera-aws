provider "aws" {
  alias  = "us-west-1"
  region = "us-west-1"
}

provider "aws" {
  alias  = "us-west-2"
  region = "us-west-2"
}

run "complete_eks_plan" {
  command = plan

  providers = {
    aws = aws.us-west-1
  }

  module {
    source = "./examples/complete_eks"
  }
}

run "completes_public_ec2_plan" {
  command = plan

  providers = {
    aws = aws.us-west-2
  }

  module {
    source = "./examples/complete_public_ec2"
  }
}

run "test_eks" {
  command = apply

  providers = {
    aws = aws.us-west-1
  }

  module {
    source = "./examples/complete_eks"
  }
}

run "test_ec2" {
  command = apply

  providers = {
    aws = aws.us-west-2
  }

  module {
    source = "./examples/complete_public_ec2"
  }
}
