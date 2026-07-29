variable "aws_region" {
  description = "Regiao AWS onde o ambiente do workshop sera provisionado."
  type        = string
  default     = "sa-east-1"
}

variable "workshop_prefix" {
  description = "Prefixo de nomenclatura aplicado a todos os recursos AWS."
  type        = string
  default     = "gtavares-workshop"
}

variable "aws_account_id" {
  description = <<-EOT
    ID da conta AWS utilizado para compor nomes de bucket globalmente unicos.
    Se nao for informado, sera resolvido automaticamente via
    data "aws_caller_identity".
  EOT
  type        = string
  default     = null
}
