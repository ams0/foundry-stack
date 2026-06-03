variable "enable_apim_products" {
  description = "Master flag. When false, the module is a no-op."
  type        = bool
  default     = false
}

variable "api_management_name" {
  description = "Name of the APIM instance to attach products to."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group containing the APIM instance."
  type        = string
}

variable "products" {
  description = <<-EOT
    Products to provision in APIM. Each product:
      - is created (or updated if name matches an existing product)
      - has the listed APIs attached
      - is exposed to the listed groups (default ["Developers"] so signed-in
        portal users can see and subscribe to it)
      - optionally gets a pre-baked subscription whose primary_key is emitted
        as a sensitive output keyed by product name + subscription name

    Fields:
      name                            APIM product_id (kebab-case)
      display_name                    Title shown in the portal
      description                     Card text
      api_names                       APIM api names to attach
      allowed_groups                  Groups that can see / subscribe. APIM group IDs are
                                      lowercase: ["developers"], ["administrators"], ["guests"].
      subscription_required           Default true
      approval_required               Default false
      subscriptions_limit             Per-user subscription limit. Default 10
      published                       Default true
      subscriptions                   List of pre-baked subscriptions to create:
        - display_name (required), subscription_id (optional, derived if empty)
  EOT
  type = list(object({
    name                  = string
    display_name          = string
    description           = optional(string, "")
    api_names             = optional(list(string), [])
    allowed_groups        = optional(list(string), ["developers"])
    subscription_required = optional(bool, true)
    approval_required     = optional(bool, false)
    subscriptions_limit   = optional(number, 10)
    published             = optional(bool, true)
    subscriptions = optional(list(object({
      display_name    = string
      subscription_id = optional(string, "")
    })), [])
  }))
  default = []
}
