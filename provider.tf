# Google Cloud Platform
provider "google" {
    credentials = file(key.json)
    project = "rational-autumn-393513"
    region = "us-west1"
    }
