locals {
  enabled = var.enable_developer_portal

  # Notification names APIM ships with. Each can have additional recipients added.
  notification_types = toset([
    "AccountClosedPublisher",
    "BCC",
    "NewApplicationNotificationMessage",
    "NewIssuePublisherNotificationMessage",
    "PurchasePublisherNotificationMessage",
    "QuotaLimitApproachingPublisherNotificationMessage",
    "RequestPublisherNotificationMessage",
  ])

  # Cross-product of (notification, email) for recipient creation.
  notification_recipients = local.enabled ? {
    for pair in setproduct(local.notification_types, var.notification_emails) :
    "${pair[0]}|${pair[1]}" => { notification = pair[0], email = pair[1] }
  } : {}
}

# --- Sign-in: require auth for portal access ---
# portalsettings/signin + portalsettings/signup are built-in singletons that
# ship with every APIM instance, so we PATCH them via azapi_update_resource
# rather than trying to create from scratch (azurerm 4.x removed the wrappers).

resource "azapi_update_resource" "signin_settings" {
  count = local.enabled ? 1 : 0

  type        = "Microsoft.ApiManagement/service/portalsettings@2024-05-01"
  resource_id = "${var.api_management_id}/portalsettings/signin"

  body = {
    properties = {
      enabled = var.require_signin
    }
  }
}

# --- Sign-up: keep off for an Entra-ID-only portal ---

resource "azapi_update_resource" "signup_settings" {
  count = local.enabled ? 1 : 0

  type        = "Microsoft.ApiManagement/service/portalsettings@2024-05-01"
  resource_id = "${var.api_management_id}/portalsettings/signup"

  body = {
    properties = {
      enabled = var.enable_signup
      termsOfService = {
        enabled         = var.enable_signup && var.terms_of_service != ""
        consentRequired = var.enable_signup && var.terms_of_service != ""
        text            = var.terms_of_service
      }
    }
  }
}

# --- Entra ID identity provider (optional) ---

resource "azurerm_api_management_identity_provider_aad" "this" {
  count = local.enabled && var.entra_identity_provider != null ? 1 : 0

  api_management_name = var.api_management_name
  resource_group_name = var.resource_group_name
  client_id           = var.entra_identity_provider.client_id
  client_secret       = var.entra_identity_provider.client_secret
  allowed_tenants     = var.entra_identity_provider.allowed_tenants
  signin_tenant       = coalesce(var.entra_identity_provider.signin_tenant, var.entra_identity_provider.allowed_tenants[0])
}

# --- Notification recipients ---

resource "azurerm_api_management_notification_recipient_email" "this" {
  for_each = local.notification_recipients

  api_management_id = var.api_management_id
  notification_type = each.value.notification
  email             = each.value.email
}

# --- Portal publish is a manual step ---
#
# Publishing a portal revision via the API requires the developer portal's
# content store to be initialized first, which is gated to admin-mode UI on
# first open. There's no documented programmatic way to trigger that
# bootstrap, so this module deliberately does NOT publish.
#
# To publish:
#   1. Open APIM > Developer portal > Portal overview in the Azure portal
#   2. Click "Developer portal" — this opens admin mode and provisions the
#      content store on first load
#   3. Click "Publish" in the admin UI top bar (or the floppy/checkmark icon)
#
# After the first manual publish, subsequent publishes can be automated via
# az CLI or an ARM deployment script if you really need it — see the README.
