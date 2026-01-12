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

resource "google_storage_bucket" "kestra-bucket" {
  name                     = var.gcs_kestra_bucket_name
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

resource "google_compute_instance" "demo_vm" {
  name         = "kestra-vm"
  machine_type = "e2-standard-2"
  zone         = var.zone

  boot_disk {
    auto_delete = true
    device_name = "test"

    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/ubuntu-2204-jammy-v20251218"
      size  = 10
    }

    mode = "READ_WRITE"
  }

  can_ip_forward      = false
  deletion_protection = false
  enable_display      = false

  network_interface {
    access_config {
      network_tier = "PREMIUM"
    }

    queue_count = 0
    stack_type  = "IPV4_ONLY"
    subnetwork  = "projects/dezc-dev/regions/us-west1/subnetworks/dezc-vpc"
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
    preemptible         = false
    provisioning_model  = "STANDARD"
  }

  # # NOTE: Need to add the `Service Account User` role for this to work
  # service_account {
  #   # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
  #   # TODO: Add this back
  #   email = var.service_account
  #   scopes = [
  #     "https://www.googleapis.com/auth/devstorage.read_only",
  #     "https://www.googleapis.com/auth/logging.write",
  #     "https://www.googleapis.com/auth/monitoring.write",
  #     "https://www.googleapis.com/auth/service.management.readonly",
  #     "https://www.googleapis.com/auth/servicecontrol",
  #     "https://www.googleapis.com/auth/trace.append"
  #   ]
  # }

  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_secure_boot          = false
    enable_vtpm                 = true
  }
}

resource "google_compute_network" "private_network" {  
  project = var.project
  name = "dezc-vpc"
}

resource "google_compute_global_address" "private_ip_address" {  
  project = var.project
  name          = "private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.private_network.id
}

# NOTE: Service account must have `Compute Network Admin` role
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.private_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

# NOTE: Service account must have `Cloud SQL Admin` role
# TODO: Test Kestra setup -> reinstall Docker and launch Kestra
resource "google_sql_database_instance" "demo_db" {
  project = var.project
  name                = "kestra-db"
  database_version    = "POSTGRES_15"
  region              = var.region
  deletion_protection = false

  depends_on = [google_service_networking_connection.private_vpc_connection]

  settings {
    # Second-generation instance tiers are based on the machine
    # type. See argument reference below.
    tier              = "db-f1-micro"
    edition           = "ENTERPRISE"
    availability_type = "ZONAL"
    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = google_compute_network.private_network.self_link
      enable_private_path_for_google_cloud_services = true
    }
  }
}