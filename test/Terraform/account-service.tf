// создание сервисного аккаунта 
resource "yandex_iam_service_account" "service-diplom" {
    folder_id = var.yandex_folder_id
    name = "service-diplom"
  
}

//Присвоение прав достаточного для пользования 

resource "yandex_resourcemanager_folder_iam_member" "prosmotr" {
    folder_id   = var.yandex_folder_id
    role        = "viewer"
    member      = "serviceAccount:${yandex_iam_service_account.service-diplom.id}"
  
}


resource "yandex_resourcemanager_folder_iam_member" "izmenenie" {
    folder_id   = var.yandex_folder_id
    role        = "editor"
    member      = "serviceAccount:${yandex_iam_service_account.service-diplom.id}"
  
}

resource "yandex_iam_service_account_static_access_key" "service-diplom" {
    service_account_id      = "ajeuv877ta6v60dla4ee"
    description             = "Статичный ключ для хранилища бакета"
}