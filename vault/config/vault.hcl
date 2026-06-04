ui = true
api_addr = "https://127.0.0.1:8200"
disable_mlock = true

storage "file"{
  path = "/vault/data"
}

listener "tcp" {
  address = "0.0.0.0:8200"
  tls_disable = "false"
  tls_cert_file = "/vault/tls/fullchain.pem"
  tls_key_file = "/vault/tls/privkey.pem"
}

seal "awskms" {
  region = "us-east-1"
  kms_key_id = "alias/vault-unseal"
}
