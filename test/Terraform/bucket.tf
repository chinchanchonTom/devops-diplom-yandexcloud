resource "yandex_storage_bucket" "bucket-diplom" {
    bucket = "diplome-bucket"
    access_key = yandex_iam_service_account_static_access_key.service-diplom.access_key
    secret_key = yandex_iam_service_account_static_access_key.service-diplom.secret_key

    anonymous_access_flags {
      read = false
      list = false
    }
  
}