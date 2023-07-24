
resource "google_compute_network" "vpc_network" {
  name = "my-vpc-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "frontend_subnet" {
  name          = "frontend-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = "us-west1"
  network       = google_compute_network.vpc_network.name
}

resource "google_compute_subnetwork" "backend_subnet" {
  name          = "backend-subnet"
  ip_cidr_range = "10.0.2.0/24"
  region        = "us-west1"
  network       = google_compute_network.vpc_network.name
}

resource "google_compute_subnetwork" "database_subnet" {
  name          = "database-subnet"
  ip_cidr_range = "10.0.3.0/24"
  region        = "us-west1"
  network       = google_compute_network.vpc_network.name
}

resource "google_compute_router" "vpc_router" {
  name    = "vpc-router"
  region  = "us-west1"
  network = google_compute_network.vpc_network.name
}

resource "google_compute_router_nat" "vpc_router_nat" {
  name        = "vpc-router-nat"
  router      = google_compute_router.vpc_router.name
  nat_ip_allocate_option = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

resource "google_compute_firewall" "public_internet_access" {
  name    = "public-internet-access"
  network = google_compute_network.vpc_network.name
  allow {
    protocol = "icmp"
  }
  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "private_internet_access" {
  name    = "private-internet-access"
  network = google_compute_network.vpc_network.name
  allow {
    protocol = "icmp"
  }
  source_ranges = [google_compute_subnetwork.frontend_subnet.ip_cidr_range]
}

resource "google_compute_firewall" "database_access" {
  name    = "database-access"
  network = google_compute_network.vpc_network.name
  allow {
    protocol = "tcp"
    ports    = ["3306"]
  }
  source_ranges = [google_compute_subnetwork.backend_subnet.ip_cidr_range]
}

resource "google_compute_instance" "public_instance" {
  name         = "public-instance"
  machine_type = "e2-small"
  zone         = "us-west1-a"
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }
  network_interface {
    network = google_compute_network.vpc_network.name
    subnetwork = google_compute_subnetwork.frontend_subnet.name
    access_config {
      // public ip
    }
  }
}

resource "google_compute_instance" "private_instance" {
  name         = "private-instance"
  machine_type = "e2-small"
  zone         = "us-west1-a"
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }
  network_interface {
    network = google_compute_network.vpc_network.name
    subnetwork = google_compute_subnetwork.backend_subnet.name
  }
}

resource "google_sql_database_instance" "main" {
  name             = "my-database-instance"
  database_version = "MYSQL_8_0"
  region           = "us-west1"
  settings {
    tier = "db-f1-micro"
  }
  deletion_protection  = "false"
}
resource "google_sql_database" "database" {
  name     = "my-database"
  instance = google_sql_database_instance.main.name
}


resource "google_sql_user" "users" {
  name     = "admin"
  instance = google_sql_database_instance.main.name
  host     = "admin "
  password = "adminadmin"
}
