resource "yandex_vpc_network" "subnet" {
    name = "subnet"
  
}

resource "yandex_vpc_subnet" "subnet" {
    count       = 3
    name        = "subnet-${var.subnet[count.index]}"
    zone        = "${var.subnet[count.index]}"
    network_id  = "${yandex_vpc_network.subnet.id}" 
    v4_cidr_blocks = [ "${var.cidr.test[count.index]}" ]
  
}