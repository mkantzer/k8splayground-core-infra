# Clean Up

Given the use of Operators that deploy and manage cluster-external infrastructure, it's possible/likely/assured that a simple `terraform destroy` may/will not remove all associated components. 
For example, the ALB controller is responsible for creating, modifying, and destroying ALBs. However, when the controller is removed from the cluster, there is no "clean up" stage: the pods simply exit, with the assumption that some new pod will take over management. Any load balancers are never entered into terraform state, so terraform does not know to remove them.

## Likely Orphans, Their Sources, and Possible Strategies

1. Load Balancers
   - Source: `aws-load-balancer-controller`
   - Strategy: The controllers are capable of "adopting" LBs: they don't really "hold state" the way terraform does. Rather, their reconciliation loop searches, modifies, adds, or removes LBs based purely on resource tags and `ingress` objects. We could "pre-create" our ALB(s) in the cluster terraform, tagged appropriately for adoption. 
2. DNS Entires
   - Source: `external-dns`
   - This one is actually not particularly likely: I can set `force_destroy` on the r53 zone, so terraform destroys all records in a zone when it deletes. 
3. EBS?

### Generalized Clean Up Strategies

1. **Just Do It Manually**: This is likely to be my primary method for now, as I wanna focus on other stuff.
2. **Dedicated External App**: Write a small golang app that runs in fargate or lambda on a schedule. It would query the list of active EKS clusters, query AWS services for orphanable resources, and then compare tags to see if any resources exist for clusters that do not. It would delete any that should no longer be. Possible downsides: what if it's buggy and deletes things it shouldn't? What if I use a controller that doesn't have configurable tags?
3. 
