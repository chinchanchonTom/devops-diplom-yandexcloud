data "template_file" "inventory" {
    template = file("./inventory.tpl")

    vars = {
      hosts_control = "${join("\n",formatlist("%s ansible_host=%s ansible_user=ubuntu", yandex_compute_instance.master.*.name, yandex_compute_instance.master.*.network_interface.0.nat_ip_address))}"
      hosts_work = "${join("\n",formatlist("%s ansible_host=%s ansible_user=ubuntu", yandex_compute_instance.work.*.name, yandex_compute_instance.work.*.network_interface.0.nat_ip_address))}"
      list_master  = "${join("\n", yandex_compute_instance.master.*.name)}"
      list_work   = "${join("\n", yandex_compute_instance.work.*.name)}"
       
    }
}

resource "null_resource" "inventory-rend" {
    provisioner "local-exec" {
        command = "echo '${data.template_file.inventory.rendered}' > ./kubespray/inventory/mycluster/inventory-${terraform.workspace}.ini"
      
    }
  triggers = {
    template = data.template_file.inventory.rendered
  }
}