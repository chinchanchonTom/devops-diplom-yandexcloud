### work and master nodes 

resource "yandex_compute_instance" "master" {
    count = 1
    name        = "master-${count.index}"
    zone        = "${var.subnet[count.index]}"

    resources {
      cores         = 2
      core_fraction = 20
      memory        = 4
    }   
    scheduling_policy {
      preemptible = true
    }
    network_interface {
      subnet_id = "${yandex_vpc_subnet.subnet[count.index].id}"
      nat = true
    }
    boot_disk {
      initialize_params {
        image_id = "fd8clogg1kull9084s9o"
        type = "network-hdd"
        size = "25"
      }
    }
    metadata = {
        ssh-keys = "ubuntu:${file("~/.ssh/id_ed25519.pub")}"
    }
  
}

resource "yandex_compute_instance" "work" {
    count = 2
    name = "work-${count.index}"
    zone = "${var.subnet[count.index]}"
    scheduling_policy {
      preemptible = true
    }
    labels = {
      index = "${count.index}"
    }
    resources {
      cores = 2
      core_fraction = 20
      memory = 4
    }
    network_interface {
      subnet_id = "${yandex_vpc_subnet.subnet[count.index].id}"
      nat = true
    }

    boot_disk {
      initialize_params {
        image_id = "fd8clogg1kull9084s9o"
        type = "network-hdd"
        size = "25"
      }
    }
    metadata = {
      ssh-keys = "ubuntu:${file("~/.ssh/id_ed25519.pub")}"
    }
  
}