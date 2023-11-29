run "complete_eks" {

    module {
        source = "./examples/complete_eks"
    }
}

run completes_public_ec2 {
    
    module {
        source = "./examples/complete_public_ec2"
    }
}