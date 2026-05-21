data "azurerm_client_config" "current" {}

locals {
  enabled = var.enable_apim_policies

  effective_jwt_tenant_id = (
    var.enable_jwt_auth
    ? (var.jwt_tenant_id != "" ? var.jwt_tenant_id
      : (var.entra_tenant_id != "" ? var.entra_tenant_id
    : data.azurerm_client_config.current.tenant_id))
    : "not-configured"
  )

  effective_jwt_app_reg_id = (
    var.enable_jwt_auth
    ? (var.jwt_app_registration_id != "" ? var.jwt_app_registration_id : "not-configured")
    : "not-configured"
  )

  entra_login_endpoint = "https://login.microsoftonline.com/"

  # --- Backend pool derivation (mirrors llm-backend-pools.bicep logic) ---

  normalized_backends = [
    for b in var.llm_backends : {
      backend_id   = b.backend_id
      backend_type = b.backend_type
      endpoint     = b.endpoint
      priority     = b.priority
      weight       = b.weight
      model_names  = [for m in b.supported_models : m.name]
    }
  ]

  all_model_names = distinct(flatten([for b in local.normalized_backends : b.model_names]))

  # model_to_backends: { "<model>" = [ { backend_id, priority, weight, backend_type } ] }
  model_to_backends = {
    for m in local.all_model_names : m => [
      for b in local.normalized_backends : {
        backend_id   = b.backend_id
        backend_type = b.backend_type
        priority     = b.priority
        weight       = b.weight
      } if contains(b.model_names, m)
    ]
  }

  # Pools only for models served by 2+ backends.
  pool_configs = [
    for m, bs in local.model_to_backends : {
      model_name = m
      pool_name  = "${replace(m, ".", "")}-backend-pool"
      backends   = bs
    } if length(bs) > 1
  ]

  # Direct (single-backend) models — surfaced into the policy fragment config alongside pools.
  direct_backends = [
    for m, bs in local.model_to_backends : {
      pool_name        = bs[0].backend_id
      pool_type        = bs[0].backend_type
      supported_models = [m]
    } if length(bs) == 1
  ]

  pool_fragment_entries = concat(
    [
      for p in local.pool_configs : {
        pool_name        = p.pool_name
        pool_type        = length(p.backends) > 0 ? p.backends[0].backend_type : "mixed"
        supported_models = [p.model_name]
      }
    ],
    local.direct_backends,
  )

  # --- frag-set-backend-pools C# splice ---
  backend_pools_code = join("\n", [
    for i, pool in local.pool_fragment_entries :
    join("\n", [
      "// Pool: ${pool.pool_name} (Type: ${pool.pool_type})",
      "var pool_${i} = new JObject()",
      "{",
      "    { \"poolName\", \"${pool.pool_name}\" },",
      "    { \"poolType\", \"${pool.pool_type}\" },",
      "    { \"supportedModels\", new JArray(${join(", ", [for m in pool.supported_models : "\"${m}\""])}) }",
      "};",
      "backendPools.Add(pool_${i});",
    ])
  ])

  # --- frag-get-available-models C# splice ---
  flat_models = flatten([
    for b in var.llm_backends : [
      for m in b.supported_models : {
        backend_id      = b.backend_id
        backend_type    = b.backend_type
        name            = m.name
        sku             = m.sku
        capacity        = m.capacity
        model_format    = m.model_format
        model_version   = m.model_version
        retirement_date = m.retirement_date
      }
    ]
  ])

  model_deployments_code = join("\n", [
    for i, m in local.flat_models :
    join("\n", concat(
      [
        "// Model: ${m.name} from backend: ${m.backend_id}",
        "var deployment_${i} = new JObject()",
        "{",
        "    { \"id\", \"${m.backend_id}\" },",
        "    { \"type\", \"${m.backend_type}\" },",
        "    { \"name\", \"${m.name}\" },",
        "    { \"sku\", new JObject() { { \"name\", \"${m.sku}\" }, { \"capacity\", ${m.capacity} } } },",
        "    { \"properties\", new JObject() {",
        "        { \"model\", new JObject() { { \"format\", \"${m.model_format}\" }, { \"name\", \"${m.name}\" }, { \"version\", \"${m.model_version}\" } } },",
        "        { \"capabilities\", new JObject() { { \"chatCompletion\", \"true\" } } },",
        "        { \"provisioningState\", \"Succeeded\" }${m.retirement_date != "" ? "," : ""}",
      ],
      m.retirement_date != "" ? [
        "        { \"retirementDate\", \"${m.retirement_date}\" }",
      ] : [],
      [
        "    }}",
        "};",
        "modelDeployments.Add(deployment_${i});",
      ],
    ))
  ])

  # --- frag-metadata-config splice (per-model { backend, apiVersion, timeout, inferenceApiVersion? }) ---
  # First occurrence of each model wins; later duplicates are ignored.
  metadata_models_list = [
    for m in distinct([for x in local.flat_models : x.name]) :
    {
      name = m
      backend = element(
        concat(
          [for p in local.pool_fragment_entries : p.pool_name if contains(p.supported_models, m)],
          [""],
        ),
        0,
      )
      # Pick the first model entry matching this name to source apiVersion/timeout.
      meta = element(
        [for b in var.llm_backends : [for sm in b.supported_models : sm if sm.name == m]],
        0,
      )[0]
    }
  ]

  metadata_models_code = join(",\n", [
    for m in local.metadata_models_list :
    join("\n", concat(
      [
        "\t\t\t'${m.name}': {",
        "\t\t\t\t'backend': '${m.backend}',",
        "\t\t\t\t'apiVersion': '${m.meta.api_version}',",
        "\t\t\t\t'timeout': ${m.meta.timeout}${m.meta.inference_api_version != "" ? "," : ""}",
      ],
      m.meta.inference_api_version != "" ? [
        "\t\t\t\t'inferenceApiVersion': '${m.meta.inference_api_version}'",
      ] : [],
      [
        "\t\t\t}",
      ],
    ))
  ])

  policies_path = "${path.module}/policies"
  apis_path     = "${path.module}/apis"
}
