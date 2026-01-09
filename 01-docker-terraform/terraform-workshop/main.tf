terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.6.0"
    }
  }

}

provider "google" {
  # credentials = "./keys/week-1-service-account.json"
  # Or run `export GOOGLE_APPLICATION_CREDENTIALS=./keys/week-1-service-account.json`
  credentials = file(var.credentials)
  project     = var.project
  region      = var.region

}

resource "google_storage_bucket" "demo-bucket" {
  name                     = var.gcs_bucket_name
  location                 = var.location
  force_destroy            = true
  public_access_prevention = "enforced"
  # Required to avoid constraint error
  uniform_bucket_level_access = true
  storage_class               = var.gcs_storage_class

  lifecycle_rule {
    condition {
      age = 1
    }
    action {
      type = "AbortIncompleteMultipartUpload"
    }
  }
}

resource "google_bigquery_dataset" "demo_dataset" {
  dataset_id    = var.bq_dataset_name
  friendly_name = "test"
  description   = "This is a test description"
  location      = var.location
}