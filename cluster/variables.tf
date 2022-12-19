variable "aws_auth_users" {
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))
  default = [
    {
      userarn  = "arn:aws:iam::012345678901:user/your-name"
      username = "you"
      groups   = ["system:masters"]
    }
  ]
}

variable "cluster_name" {
  type = string
}