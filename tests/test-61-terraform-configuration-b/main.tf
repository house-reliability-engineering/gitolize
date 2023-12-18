variable a-state-path {
  type     = string
  nullable = false
}

data "terraform_remote_state" "a" {
    backend = "local"
    config = {
        path = var.a-state-path
    }
}

output "proxied-output" {
    value = "test value"
}
