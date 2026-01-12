variable "credentials" {
  description = "Credentials"
  default     = "./keys/week-1-service-account.json"
}

variable "project" {
  description = "Project name"
  default     = "dezc-dev"
}

variable "region" {
  description = "Project region"
  default     = "us-west1"
}

variable "zone" {
  description = "Project zone"
  default     = "us-west1-a"
}

variable "location" {
  description = "Project location"
  default     = "us-west1"
}

variable "bq_dataset_name" {
  description = "BigQuery dataset name"
  default     = "example_dataset"
}

variable "gcs_bucket_name" {
  description = "Storage bucket name"
  default     = "dezc-dev-terra-bucket"
}

variable "gcs_kestra_bucket_name" {
  description = "Storage bucket name"
  default     = "dezc-dev-kestra-bucket"
}

variable "gcs_storage_class" {
  description = "Bucket storage class"
  default     = "STANDARD"
}

variable "vm_name" {
  description = "Kestra orchestrator VM name"
  default     = "kestra_vm"
}