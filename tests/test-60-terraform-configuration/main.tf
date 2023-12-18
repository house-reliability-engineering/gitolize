variable content {
  type     = string
  nullable = false
}

variable filename {
  type     = string
  nullable = false
}

resource "local_file" "test-file" {
  content = var.content
  filename = var.filename
}
