# Дипломный практикум в Yandex.Cloud
  * [Цели:](#цели)
  * [Этапы выполнения:](#этапы-выполнения)
     * [Создание облачной инфраструктуры](#создание-облачной-инфраструктуры)
     * [Создание Kubernetes кластера](#создание-kubernetes-кластера)
     * [Создание тестового приложения](#создание-тестового-приложения)
     * [Подготовка cистемы мониторинга и деплой приложения](#подготовка-cистемы-мониторинга-и-деплой-приложения)
     * [Установка и настройка CI/CD](#установка-и-настройка-cicd)
  * [Что необходимо для сдачи задания?](#что-необходимо-для-сдачи-задания)
  * [Как правильно задавать вопросы дипломному руководителю?](#как-правильно-задавать-вопросы-дипломному-руководителю)

**Перед началом работы над дипломным заданием изучите [Инструкция по экономии облачных ресурсов](https://github.com/netology-code/devops-materials/blob/master/cloudwork.MD).**

---
## Цели:

1. Подготовить облачную инфраструктуру на базе облачного провайдера Яндекс.Облако.
2. Запустить и сконфигурировать Kubernetes кластер.
3. Установить и настроить систему мониторинга.
4. Настроить и автоматизировать сборку тестового приложения с использованием Docker-контейнеров.
5. Настроить CI для автоматической сборки и тестирования.
6. Настроить CD для автоматического развёртывания приложения.

---
## Этапы выполнения:
### Создание облачной инфраструктуры

Для начала необходимо подготовить облачную инфраструктуру в ЯО при помощи [Terraform](https://www.terraform.io/).

Особенности выполнения:

- Бюджет купона ограничен, что следует иметь в виду при проектировании инфраструктуры и использовании ресурсов;
Для облачного k8s используйте региональный мастер(неотказоустойчивый). Для self-hosted k8s минимизируйте ресурсы ВМ и долю ЦПУ. В обоих вариантах используйте прерываемые ВМ для worker nodes.

Предварительная подготовка к установке и запуску Kubernetes кластера.

1. Создайте сервисный аккаунт, который будет в дальнейшем использоваться Terraform для работы с инфраструктурой с необходимыми и достаточными правами. Не стоит использовать права суперпользователя
```hcl
resource "yandex_iam_service_account" "service-diplom" {
    folder_id = var.yandex_folder_id
    name = "service-diplom"

}
```
2. Подготовьте [backend](https://www.terraform.io/docs/language/settings/backends/index.html) для Terraform:  
   а. Рекомендуемый вариант: S3 bucket в созданном ЯО аккаунте(создание бакета через TF)
   б. Альтернативный вариант:  [Terraform Cloud](https://app.terraform.io/)  
```hcl
resource "yandex_storage_bucket" "bucket-diplom" {
    bucket = "diplome-bucket"
    access_key = yandex_iam_service_account_static_access_key.service-diplom.access_key
    secret_key = yandex_iam_service_account_static_access_key.service-diplom.secret_key

    anonymous_access_flags {
      read = false
      list = false
    }
  
}

```
3. Создайте VPC с подсетями в разных зонах доступности.
```hcl

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

```
4. Убедитесь, что теперь вы можете выполнить команды `terraform destroy` и `terraform apply` без дополнительных ручных действий.
<details><summary>Решение:</summary>  

```
Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create
 <= read (data resources)

Terraform will perform the following actions:

  # data.template_file.inventory will be read during apply
  # (config refers to values not yet known)
 <= data "template_file" "inventory" {
      + id       = (known after apply)
      + rendered = (known after apply)
      + template = <<-EOT
            [all]
            ${hosts_control}
            ${hosts_work}
            
            [kube_control_plane]
            ${list_master}
            
            [etcd]
            ${list_master}
            
            [kube_node]
            ${list_work}
            
            [k8s_cluster:children]
            kube_control_plane
            kube_node
        EOT
      + vars     = {
          + "hosts_control" = (known after apply)
          + "hosts_work"    = (known after apply)
          + "list_master"   = "master-0"
          + "list_work"     = <<-EOT
                work-0
                work-1
            EOT
        }
    }

  # null_resource.inventory-rend will be created
  + resource "null_resource" "inventory-rend" {
      + id       = (known after apply)
      + triggers = {
          + "template" = (known after apply)
        }
    }

  # yandex_compute_instance.master[0] will be created
  + resource "yandex_compute_instance" "master" {
      + created_at                = (known after apply)
      + folder_id                 = (known after apply)
      + fqdn                      = (known after apply)
      + gpu_cluster_id            = (known after apply)
      + hostname                  = (known after apply)
      + id                        = (known after apply)
      + maintenance_grace_period  = (known after apply)
      + maintenance_policy        = (known after apply)
      + metadata                  = {
          + "ssh-keys" = <<-EOT
                ubuntu:ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN0idgJXK3owvfPns39Jo7dqIPtd4M/rKZSF+QbdNq/P maksim@DESKTOP-KV1P3C1
            EOT
        }
      + name                      = "master-0"
      + network_acceleration_type = "standard"
      + platform_id               = "standard-v1"
      + service_account_id        = (known after apply)
      + status                    = (known after apply)
      + zone                      = "ru-central1-a"

      + boot_disk {
          + auto_delete = true
          + device_name = (known after apply)
          + disk_id     = (known after apply)
          + mode        = (known after apply)

          + initialize_params {
              + block_size  = (known after apply)
              + description = (known after apply)
              + image_id    = "fd8clogg1kull9084s9o"
              + name        = (known after apply)
              + size        = 25
              + snapshot_id = (known after apply)
              + type        = "network-hdd"
            }
        }

      + network_interface {
          + index              = (known after apply)
          + ip_address         = (known after apply)
          + ipv4               = true
          + ipv6               = (known after apply)
          + ipv6_address       = (known after apply)
          + mac_address        = (known after apply)
          + nat                = true
          + nat_ip_address     = (known after apply)
          + nat_ip_version     = (known after apply)
          + security_group_ids = (known after apply)
          + subnet_id          = (known after apply)
        }

      + resources {
          + core_fraction = 20
          + cores         = 2
          + memory        = 4
        }

      + scheduling_policy {
          + preemptible = true
        }
    }

  # yandex_compute_instance.work[0] will be created
  + resource "yandex_compute_instance" "work" {
      + created_at                = (known after apply)
      + folder_id                 = (known after apply)
      + fqdn                      = (known after apply)
      + gpu_cluster_id            = (known after apply)
      + hostname                  = (known after apply)
      + id                        = (known after apply)
      + labels                    = {
          + "index" = "0"
        }
      + maintenance_grace_period  = (known after apply)
      + maintenance_policy        = (known after apply)
      + metadata                  = {
          + "ssh-keys" = <<-EOT
                ubuntu:ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN0idgJXK3owvfPns39Jo7dqIPtd4M/rKZSF+QbdNq/P maksim@DESKTOP-KV1P3C1
            EOT
        }
      + name                      = "work-0"
      + network_acceleration_type = "standard"
      + platform_id               = "standard-v1"
      + service_account_id        = (known after apply)
      + status                    = (known after apply)
      + zone                      = "ru-central1-a"

      + boot_disk {
          + auto_delete = true
          + device_name = (known after apply)
          + disk_id     = (known after apply)
          + mode        = (known after apply)

          + initialize_params {
              + block_size  = (known after apply)
              + description = (known after apply)
              + image_id    = "fd8clogg1kull9084s9o"
              + name        = (known after apply)
              + size        = 25
              + snapshot_id = (known after apply)
              + type        = "network-hdd"
            }
        }

      + network_interface {
          + index              = (known after apply)
          + ip_address         = (known after apply)
          + ipv4               = true
          + ipv6               = (known after apply)
          + ipv6_address       = (known after apply)
          + mac_address        = (known after apply)
          + nat                = true
          + nat_ip_address     = (known after apply)
          + nat_ip_version     = (known after apply)
          + security_group_ids = (known after apply)
          + subnet_id          = (known after apply)
        }

      + resources {
          + core_fraction = 20
          + cores         = 2
          + memory        = 4
        }

      + scheduling_policy {
          + preemptible = true
        }
    }

  # yandex_compute_instance.work[1] will be created
  + resource "yandex_compute_instance" "work" {
      + created_at                = (known after apply)
      + folder_id                 = (known after apply)
      + fqdn                      = (known after apply)
      + gpu_cluster_id            = (known after apply)
      + hostname                  = (known after apply)
      + id                        = (known after apply)
      + labels                    = {
          + "index" = "1"
        }
      + maintenance_grace_period  = (known after apply)
      + maintenance_policy        = (known after apply)
      + metadata                  = {
          + "ssh-keys" = <<-EOT
                ubuntu:ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN0idgJXK3owvfPns39Jo7dqIPtd4M/rKZSF+QbdNq/P maksim@DESKTOP-KV1P3C1
            EOT
        }
      + name                      = "work-1"
      + network_acceleration_type = "standard"
      + platform_id               = "standard-v1"
      + service_account_id        = (known after apply)
      + status                    = (known after apply)
      + zone                      = "ru-central1-b"

      + boot_disk {
          + auto_delete = true
          + device_name = (known after apply)
          + disk_id     = (known after apply)
          + mode        = (known after apply)

          + initialize_params {
              + block_size  = (known after apply)
              + description = (known after apply)
              + image_id    = "fd8clogg1kull9084s9o"
              + name        = (known after apply)
              + size        = 25
              + snapshot_id = (known after apply)
              + type        = "network-hdd"
            }
        }

      + network_interface {
          + index              = (known after apply)
          + ip_address         = (known after apply)
          + ipv4               = true
          + ipv6               = (known after apply)
          + ipv6_address       = (known after apply)
          + mac_address        = (known after apply)
          + nat                = true
          + nat_ip_address     = (known after apply)
          + nat_ip_version     = (known after apply)
          + security_group_ids = (known after apply)
          + subnet_id          = (known after apply)
        }

      + resources {
          + core_fraction = 20
          + cores         = 2
          + memory        = 4
        }

      + scheduling_policy {
          + preemptible = true
        }
    }

  # yandex_iam_service_account.service-diplom will be created
  + resource "yandex_iam_service_account" "service-diplom" {
      + created_at = (known after apply)
      + folder_id  = "b1gfqjnr717cnd3hdl42"
      + id         = (known after apply)
      + name       = "service-diplom"
    }

  # yandex_iam_service_account_static_access_key.service-diplom will be created
  + resource "yandex_iam_service_account_static_access_key" "service-diplom" {
      + access_key                   = (known after apply)
      + created_at                   = (known after apply)
      + description                  = "Статичный ключ для хранилища бакета"
      + encrypted_secret_key         = (known after apply)
      + id                           = (known after apply)
      + key_fingerprint              = (known after apply)
      + output_to_lockbox_version_id = (known after apply)
      + secret_key                   = (sensitive value)
      + service_account_id           = "ajeuv877ta6v60dla4ee"
    }

  # yandex_resourcemanager_folder_iam_member.izmenenie will be created
  + resource "yandex_resourcemanager_folder_iam_member" "izmenenie" {
      + folder_id = "b1gfqjnr717cnd3hdl42"
      + id        = (known after apply)
      + member    = (known after apply)
      + role      = "editor"
    }

  # yandex_resourcemanager_folder_iam_member.prosmotr will be created
  + resource "yandex_resourcemanager_folder_iam_member" "prosmotr" {
      + folder_id = "b1gfqjnr717cnd3hdl42"
      + id        = (known after apply)
      + member    = (known after apply)
      + role      = "viewer"
    }

  # yandex_storage_bucket.bucket-diplom will be created
  + resource "yandex_storage_bucket" "bucket-diplom" {
      + access_key            = (known after apply)
      + bucket                = "diplome-bucket"
      + bucket_domain_name    = (known after apply)
      + default_storage_class = (known after apply)
      + folder_id             = (known after apply)
      + force_destroy         = false
      + id                    = (known after apply)
      + secret_key            = (sensitive value)
      + website_domain        = (known after apply)
      + website_endpoint      = (known after apply)

      + anonymous_access_flags {
          + list = false
          + read = false
        }
    }

  # yandex_vpc_network.subnet will be created
  + resource "yandex_vpc_network" "subnet" {
      + created_at                = (known after apply)
      + default_security_group_id = (known after apply)
      + folder_id                 = (known after apply)
      + id                        = (known after apply)
      + labels                    = (known after apply)
      + name                      = "subnet"
      + subnet_ids                = (known after apply)
    }

  # yandex_vpc_subnet.subnet[0] will be created
  + resource "yandex_vpc_subnet" "subnet" {
      + created_at     = (known after apply)
      + folder_id      = (known after apply)
      + id             = (known after apply)
      + labels         = (known after apply)
      + name           = "subnet-ru-central1-a"
      + network_id     = (known after apply)
      + v4_cidr_blocks = [
          + "192.168.10.0/24",
        ]
      + v6_cidr_blocks = (known after apply)
      + zone           = "ru-central1-a"
    }

  # yandex_vpc_subnet.subnet[1] will be created
  + resource "yandex_vpc_subnet" "subnet" {
      + created_at     = (known after apply)
      + folder_id      = (known after apply)
      + id             = (known after apply)
      + labels         = (known after apply)
      + name           = "subnet-ru-central1-b"
      + network_id     = (known after apply)
      + v4_cidr_blocks = [
          + "192.168.20.0/24",
        ]
      + v6_cidr_blocks = (known after apply)
      + zone           = "ru-central1-b"
    }

  # yandex_vpc_subnet.subnet[2] will be created
  + resource "yandex_vpc_subnet" "subnet" {
      + created_at     = (known after apply)
      + folder_id      = (known after apply)
      + id             = (known after apply)
      + labels         = (known after apply)
      + name           = "subnet-ru-central1-d"
      + network_id     = (known after apply)
      + v4_cidr_blocks = [
          + "192.168.30.0/24",
        ]
      + v6_cidr_blocks = (known after apply)
      + zone           = "ru-central1-d"
    }

Plan: 13 to add, 0 to change, 0 to destroy.


```
</details>  

![push](https://github.com/chinchanchonTom/devops-diplom-yandexcloud/blob/main/test/img/Screenshot_66.png)    
[account-service](https://github.com/chinchanchonTom/devops-diplom-yandexcloud/blob/main/test/Terraform/account-service.tf)    
[bucket](https://github.com/chinchanchonTom/devops-diplom-yandexcloud/blob/main/test/Terraform/bucket.tf)    
[provider](https://github.com/chinchanchonTom/devops-diplom-yandexcloud/blob/main/test/Terraform/provider.tf)    
[variable](https://github.com/chinchanchonTom/devops-diplom-yandexcloud/blob/main/test/Terraform/variable.tf)    
[vm](https://github.com/chinchanchonTom/devops-diplom-yandexcloud/blob/main/test/Terraform/vm.tf)    
[vpc](https://github.com/chinchanchonTom/devops-diplom-yandexcloud/blob/main/test/Terraform/vpc.tf)    
[Terraform](https://github.com/chinchanchonTom/devops-diplom-yandexcloud/tree/main/test/Terraform)  - ссылка на всю директорию с проектом (Пристсвуют пустые файлы)  

5. В случае использования [Terraform Cloud](https://app.terraform.io/) в качестве [backend](https://www.terraform.io/docs/language/settings/backends/index.html) убедитесь, что применение изменений успешно проходит, используя web-интерфейс Terraform cloud.

Ожидаемые результаты:

1. Terraform сконфигурирован и создание инфраструктуры посредством Terraform возможно без дополнительных ручных действий.
![alt text](https://github.com/chinchanchonTom/devops-diplom-yandexcloud/blob/main/test/img/image.png) 

2. Полученная конфигурация инфраструктуры является предварительной, поэтому в ходе дальнейшего выполнения задания возможны изменения.

Предоставил выше всю конфигурацию после окончания работы с Terraform

---
### Создание Kubernetes кластера

На этом этапе необходимо создать [Kubernetes](https://kubernetes.io/ru/docs/concepts/overview/what-is-kubernetes/) кластер на базе предварительно созданной инфраструктуры.   Требуется обеспечить доступ к ресурсам из Интернета.

Это можно сделать двумя способами:

1. Рекомендуемый вариант: самостоятельная установка Kubernetes кластера.  
   а. При помощи Terraform подготовить как минимум 3 виртуальных машины Compute Cloud для создания Kubernetes-кластера. Тип виртуальной машины следует выбрать самостоятельно с учётом требовании к производительности и стоимости. Если в дальнейшем поймете, что необходимо сменить тип инстанса, используйте Terraform для внесения изменений.  
   б. Подготовить [ansible](https://www.ansible.com/) конфигурации, можно воспользоваться, например [Kubespray](https://kubernetes.io/docs/setup/production-environment/tools/kubespray/)  
   в. Задеплоить Kubernetes на подготовленные ранее инстансы, в случае нехватки каких-либо ресурсов вы всегда можете создать их при помощи Terraform.
2. Альтернативный вариант: воспользуйтесь сервисом [Yandex Managed Service for Kubernetes](https://cloud.yandex.ru/services/managed-kubernetes)  
  а. С помощью terraform resource для [kubernetes](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/kubernetes_cluster) создать **региональный** мастер kubernetes с размещением нод в разных 3 подсетях      
  б. С помощью terraform resource для [kubernetes node group](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/kubernetes_node_group)
  
Ожидаемый результат:

1. Работоспособный Kubernetes кластер.
Создал на основе кубспрей + файлы для invrntory взял из созданого тераформом для этого 

1.Скачал с Репозитория kubespray  
2.Установил зависимости при помощи pip3 install -r requirements.txt  
3.Скопировал пример sample в mycluster 
4.Добавил файл с хостами  
5.Запустил ansible-playbook -i inventory/mycluster/inventory-.ini cluster.yml -b -v

```
PLAY RECAP ***************************************************************************************************************************************************
control-0                  : ok=756  changed=153  unreachable=0    failed=0    skipped=1280 rescued=0    ignored=8
worker-0                   : ok=512  changed=94   unreachable=0    failed=0    skipped=781  rescued=0    ignored=0
worker-1                   : ok=512  changed=94   unreachable=0    failed=0    skipped=780  rescued=0    ignored=0

```

2. В файле `~/.kube/config` находятся данные для доступа к кластеру.

При разворачивании кластера кофигурация сохранилась в /etc/kubernetes/admin.conf. Создал mkdir ~/.kube/ и через нано скопировал туда конфиг   

![config](https://github.com/chinchanchonTom/devops-diplom-yandexcloud/blob/main/test/img/Screenshot_19.png) 

3. Команда `kubectl get pods --all-namespaces` отрабатывает без ошибок.
![kubectl get pods](https://github.com/chinchanchonTom/devops-diplom-yandexcloud/blob/main/test/img/Screenshot_1.png) 
---
### Создание тестового приложения

Для перехода к следующему этапу необходимо подготовить тестовое приложение, эмулирующее основное приложение разрабатываемое вашей компанией.

Способ подготовки:

1. Рекомендуемый вариант:  
   а. Создайте отдельный git репозиторий с простым nginx конфигом, который будет отдавать статические данные.  
   б. Подготовьте Dockerfile для создания образа приложения.  
2. Альтернативный вариант:  
   а. Используйте любой другой код, главное, чтобы был самостоятельно создан Dockerfile.

Ожидаемый результат:

1. Git репозиторий с тестовым приложением и Dockerfile.


Создал отдельный репозиторий и загрузил туда версию приложения V1.0.0 

https://github.com/chinchanchonTom/diplom

2. Регистри с собранным docker image. В качестве регистри может быть DockerHub или [Yandex Container Registry](https://cloud.yandex.ru/services/container-registry), созданный также с помощью terraform. 

Выбрал docker hub 

Скриншот того что что собралось и запушилось 
![push](https://github.com/chinchanchonTom/devops-diplom-yandexcloud/blob/main/test/img/photo_2024-08-27_19-58-05.jpg)   

![photo](https://github.com/chinchanchonTom/devops-diplom-yandexcloud/blob/main/test/img/Screenshot_333.png)   

---
### Подготовка cистемы мониторинга и деплой приложения

Уже должны быть готовы конфигурации для автоматического создания облачной инфраструктуры и поднятия Kubernetes кластера.  
Теперь необходимо подготовить конфигурационные файлы для настройки нашего Kubernetes кластера.

Цель:
1. Задеплоить в кластер [prometheus](https://prometheus.io/), [grafana](https://grafana.com/), [alertmanager](https://github.com/prometheus/alertmanager), [экспортер](https://github.com/prometheus/node_exporter) основных метрик Kubernetes.
2. Задеплоить тестовое приложение, например, [nginx](https://www.nginx.com/) сервер отдающий статическую страницу.

Способ выполнения:
1. Воспользоваться пакетом [kube-prometheus](https://github.com/prometheus-operator/kube-prometheus), который уже включает в себя [Kubernetes оператор](https://operatorhub.io/) для [grafana](https://grafana.com/), [prometheus](https://prometheus.io/), [alertmanager](https://github.com/prometheus/alertmanager) и [node_exporter](https://github.com/prometheus/node_exporter). Альтернативный вариант - использовать набор helm чартов от [bitnami](https://github.com/bitnami/charts/tree/main/bitnami).

 

2. Если на первом этапе вы не воспользовались [Terraform Cloud](https://app.terraform.io/), то задеплойте и настройте в кластере [atlantis](https://www.runatlantis.io/) для отслеживания изменений инфраструктуры. Альтернативный вариант 3 задания: вместо Terraform Cloud или atlantis настройте на автоматический запуск и применение конфигурации terraform из вашего git-репозитория в выбранной вами CI-CD системе при любом комите в main ветку. Предоставьте скриншоты работы пайплайна из CI/CD системы.

Ожидаемый результат:
1. Git репозиторий с конфигурационными файлами для настройки Kubernetes.

Воспользовался helm prometeus + grafa и развернул на своем кластере
![helm](https://github.com/chinchanchonTom/devops-diplom-yandexcloud/blob/main/test/img/Screenshot_2.png) 
![kubectl](https://github.com/chinchanchonTom/devops-diplom-yandexcloud/blob/main/test/img/Screenshot_3.png)  

2. Http доступ к web интерфейсу grafana.  

![grafana](https://github.com/chinchanchonTom/devops-diplom-yandexcloud/blob/main/test/img/Screenshot_5.png)

3. Дашборды в grafana отображающие состояние Kubernetes кластера.

![grafana](https://github.com/chinchanchonTom/devops-diplom-yandexcloud/blob/main/test/img/Screenshot_18.png)

4. Http доступ к тестовому приложению.
 
![grafana](https://github.com/chinchanchonTom/devops-diplom-yandexcloud/blob/main/test/img/Screenshot_6.png)


---
### Установка и настройка CI/CD

Осталось настроить ci/cd систему для автоматической сборки docker image и деплоя приложения при изменении кода.

Цель:

1. Автоматическая сборка docker образа при коммите в репозиторий с тестовым приложением.
2. Автоматический деплой нового docker образа.

Можно использовать [teamcity](https://www.jetbrains.com/ru-ru/teamcity/), [jenkins](https://www.jenkins.io/), [GitLab CI](https://about.gitlab.com/stages-devops-lifecycle/continuous-integration/) или GitHub Actions.

Ожидаемый результат:

1. Интерфейс ci/cd сервиса доступен по http.

![gitlab](https://github.com/chinchanchonTom/devops-diplom-yandexcloud/blob/main/test/img/Screenshot_17.png)
20

2. При любом коммите в репозиторие с тестовым приложением происходит сборка и отправка в регистр Docker образа.

```yml
build:
  stage: build
  script:
    - hostname
    - docker login -u "$CI_REGISTRY_USER" -p "$CI_PASSWORD" $CI_REGISTRY
    - docker build -t "$CI_IMAGE_REGISTRY:$CI_COMMIT_SHORT_SHA" ./docker
    - docker push "$CI_IMAGE_REGISTRY:$CI_COMMIT_SHORT_SHA"
  
  rules:
    - if: $CI_COMMIT_BRANCH -> правило что бы пушилось при каждом изменении в репозиторий 

```

3. При создании тега (например, v1.0.0) происходит сборка и отправка с соответствующим label в регистри, а также деплой соответствующего Docker образа в класте Kubernetes.

```yml
deploy:
  stage: deploy
  script:
    - docker login -u "$CI_REGISTRY_USER" -p "$CI_PASSWORD" $CI_REGISTRY
    - docker build -t "$CI_IMAGE_REGISTRY:$CI_COMMIT_SHORT_SHA" ./docker
    - docker push "$CI_IMAGE_REGISTRY"
    - kubectl create deployment --namespace default dimlome-$CI_COMMIT_SHORT_SHA --image=$CI_IMAGE_REGISTRY:$CI_COMMIT_SHORT_SHA
  
  rules:
    - if: $CI_COMMIT_TAG -> правило что бы пушилось при каждом изменении тэга

```
![gitlab](https://github.com/chinchanchonTom/devops-diplom-yandexcloud/blob/main/test/img/Screenshot_9.png)  
![gitlab](https://github.com/chinchanchonTom/devops-diplom-yandexcloud/blob/main/test/img/Screenshot_8.png)  


---
## Что необходимо для сдачи задания?

1. Репозиторий с конфигурационными файлами Terraform и готовность продемонстрировать создание всех ресурсов с нуля.
2. Пример pull request с комментариями созданными atlantis'ом или снимки экрана из Terraform Cloud или вашего CI-CD-terraform pipeline.
3. Репозиторий с конфигурацией ansible, если был выбран способ создания Kubernetes кластера при помощи ansible.
4. Репозиторий с Dockerfile тестового приложения и ссылка на собранный docker image.
5. Репозиторий с конфигурацией Kubernetes кластера.
6. Ссылка на тестовое приложение и веб интерфейс Grafana с данными доступа.
7. Все репозитории рекомендуется хранить на одном ресурсе (github, gitlab)

