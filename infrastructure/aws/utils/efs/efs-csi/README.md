# AWS EFS CSI Provisioner and Persistent Volume for Cribl Configs

Adds a Kubernetes Storage Class using the [AWS EFS CSI Driver](https://github.com/kubernetes-sigs/aws-efs-csi-driver) and creates a Persistent Volume in the Cluster Namespace for Cribl Configs. This Volume can then be used in the Cribl Stream Leader Helm Chart by specifying the Storage Class name defined here ([see values.yaml for the Leader Chart](https://github.com/criblio/helm-charts/blob/master/helm-chart-sources/logstream-leader/values.yaml)).



## Example

```terraform
module "efs_csi_driver" {
  source           = "./infrastructure/aws/utils/efs/efs-csi"
  eks_cluster_name = "your-cluster-name"
  efs_id           = "efs_id"
  efs_ap_id        = "efs_ap_id"
}
```

## Inputs

* `eks_cluster_name` - The name of the EKS cluster.
* `efs_id` - The EFS ID
* `efs_ap_id` - The EFS Access Point ID
* `k8s_pv_name` - (Optional) The Persistent Volume name. Defaults to `cribl-stream-efs-pv`
* `storage_class_name` (Optional) The Storage Class name. Defaults to `efs-sc`.
* `capacity` (Optional) The requested capacity of the Persistent Volume for configurations. Defaults to `25Gi`

## Outputs

None