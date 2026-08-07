---@brief
---
--- https://github.com/microsoft/pyright
---
--- `pyright`, a static type checker and language server for python

local dn_extra_paths = {
    "/home/dn/cheetah/src/py_packages/dn_logging",
    "/home/dn/cheetah/src/py_packages/alarm_agent",
    "/home/dn/cheetah/src/py_packages/auth_logger",
    "/home/dn/cheetah/src/py_packages/auto_gen_cli",
    "/home/dn/cheetah/src/py_packages/bootstrap_purveyor",
    "/home/dn/cheetah/src/py_packages/cli",
    "/home/dn/cheetah/src/py_packages/cm_agent",
    "/home/dn/cheetah/src/py_packages/cm_api",
    "/home/dn/cheetah/src/py_packages/cmc_cli",
    "/home/dn/cheetah/src/py_packages/cmd_orm",
    "/home/dn/cheetah/src/py_packages/cmd_orm_gen",
    "/home/dn/cheetah/src/py_packages/config_manager",
    "/home/dn/cheetah/src/py_packages/connection",
    "/home/dn/cheetah/src/py_packages/controller_listener",
    "/home/dn/cheetah/src/py_packages/core_handler",
    "/home/dn/cheetah/src/py_packages/corm",
    "/home/dn/cheetah/src/py_packages/counters_client",
    "/home/dn/cheetah/src/py_packages/cpu_usage_monitor",
    "/home/dn/cheetah/src/py_packages/ctrl_interface_agent",
    "/home/dn/cheetah/src/py_packages/datapath_agent",
    "/home/dn/cheetah/src/py_packages/dbcleaner",
    "/home/dn/cheetah/src/py_packages/db_manager",
    "/home/dn/cheetah/src/py_packages/deployment_api",
    "/home/dn/cheetah/src/py_packages/dev_utils",
    "/home/dn/cheetah/src/py_packages/diagnostic_manager",
    "/home/dn/cheetah/src/py_packages/disk_usage_manager",
    "/home/dn/cheetah/src/py_packages/dn_cli_api",
    "/home/dn/cheetah/src/py_packages/dn_common",
    "/home/dn/cheetah/src/py_packages/dn_jag_api",
    "/home/dn/cheetah/src/py_packages/dn_ldap",
    "/home/dn/cheetah/src/py_packages/dn_logging",
    "/home/dn/cheetah/src/py_packages/dn_log_manager",
    "/home/dn/cheetah/src/py_packages/dn_model",
    "/home/dn/cheetah/src/py_packages/dn_netconf",
    "/home/dn/cheetah/src/py_packages/dnos_si_agent",
    "/home/dn/cheetah/src/py_packages/dn_probes",
    "/home/dn/cheetah/src/py_packages/dn_pyaaa",
    "/home/dn/cheetah/src/py_packages/dn_syslog_pipe",
    "/home/dn/cheetah/src/py_packages/dn_threads",
    "/home/dn/cheetah/src/py_packages/docker_expose",
    "/home/dn/cheetah/src/py_packages/eem",
    "/home/dn/cheetah/src/py_packages/element_manager",
    "/home/dn/cheetah/src/py_packages/em_si",
    "/home/dn/cheetah/src/py_packages/fabric_agent",
    "/home/dn/cheetah/src/py_packages/fe_agent",
    "/home/dn/cheetah/src/py_packages/ftp_manager",
    "/home/dn/cheetah/src/py_packages/generate_dn_cli_api",
    "/home/dn/cheetah/src/py_packages/generate_dn_services",
    "/home/dn/cheetah/src/py_packages/gi_agent",
    "/home/dn/cheetah/src/py_packages/gicli",
    "/home/dn/cheetah/src/py_packages/gi_discovery",
    "/home/dn/cheetah/src/py_packages/gi_rest_server",
    "/home/dn/cheetah/src/py_packages/gi_scripts",
    "/home/dn/cheetah/src/py_packages/gi_slm_api",
    "/home/dn/cheetah/src/py_packages/gnmi",
    "/home/dn/cheetah/src/py_packages/golden_config_mode",
    "/home/dn/cheetah/src/py_packages/hypervisor_hooks",
    "/home/dn/cheetah/src/py_packages/hyperv_netns_mounter",
    "/home/dn/cheetah/src/py_packages/hyperv_routing_manager",
    "/home/dn/cheetah/src/py_packages/idim",
    "/home/dn/cheetah/src/py_packages/ike_agent",
    "/home/dn/cheetah/src/py_packages/inband_dhcp_manager",
    "/home/dn/cheetah/src/py_packages/interface_hendler_client",
    "/home/dn/cheetah/src/py_packages/ip_reachability",
    "/home/dn/cheetah/src/py_packages/ipsec_agent",
    "/home/dn/cheetah/src/py_packages/kernel_logger",
    "/home/dn/cheetah/src/py_packages/libcli",
    "/home/dn/cheetah/src/py_packages/libxray",
    "/home/dn/cheetah/src/py_packages/lldp_manager",
    "/home/dn/cheetah/src/py_packages/mgmt_interface_manager",
    "/home/dn/cheetah/src/py_packages/moninode",
    "/home/dn/cheetah/src/py_packages/nat_agent",
    "/home/dn/cheetah/src/py_packages/nat_ctl",
    "/home/dn/cheetah/src/py_packages/nb_ctrl_configurator",
    "/home/dn/cheetah/src/py_packages/ncc_discovery",
    "/home/dn/cheetah/src/py_packages/ncm_agent",
    "/home/dn/cheetah/src/py_packages/neighbour_syncer",
    "/home/dn/cheetah/src/py_packages/nfctl",
    "/home/dn/cheetah/src/py_packages/nm_mgmt_agent",
    "/home/dn/cheetah/src/py_packages/ntp_manager",
    "/home/dn/cheetah/src/py_packages/ntp_peerstats_parser",
    "/home/dn/cheetah/src/py_packages/oob_manager",
    "/home/dn/cheetah/src/py_packages/oper_manager",
    "/home/dn/cheetah/src/py_packages/orm_hooks",
    "/home/dn/cheetah/src/py_packages/orm_notifications",
    "/home/dn/cheetah/src/py_packages/policy_manager",
    "/home/dn/cheetah/src/py_packages/recovery_restart",
    "/home/dn/cheetah/src/py_packages/re_interfaces_agent",
    "/home/dn/cheetah/src/py_packages/rmon",
    "/home/dn/cheetah/src/py_packages/routing_manager",
    "/home/dn/cheetah/src/py_packages/service_instance_hooks",
    "/home/dn/cheetah/src/py_packages/session_monitor",
    "/home/dn/cheetah/src/py_packages/simp_agent",
    "/home/dn/cheetah/src/py_packages/snmp",
    "/home/dn/cheetah/src/py_packages/snmp_data",
    "/home/dn/cheetah/src/py_packages/snmp_responder",
    "/home/dn/cheetah/src/py_packages/snmp_trap_agent",
    "/home/dn/cheetah/src/py_packages/syncd",
    "/home/dn/cheetah/src/py_packages/syslog_relay",
    "/home/dn/cheetah/src/py_packages/sysmonitor",
    "/home/dn/cheetah/src/py_packages/system_events",
    "/home/dn/cheetah/src/py_packages/system_manager",
    "/home/dn/cheetah/src/py_packages/sztp_http_client",
    "/home/dn/cheetah/src/py_packages/techsupport_manager",
    "/home/dn/cheetah/src/py_packages/tengine",
    "/home/dn/cheetah/src/py_packages/terminal_connection_dispatcher",
    "/home/dn/cheetah/src/py_packages/test_utils",
    "/home/dn/cheetah/src/py_packages/transaction_agent",
    "/home/dn/cheetah/src/py_packages/transaction_api",
    "/home/dn/cheetah/src/py_packages/twamp_agent",
    "/home/dn/cheetah/src/py_packages/upgrade_mode",
    "/home/dn/cheetah/src/py_packages/users_manager",
    "/home/dn/cheetah/src/py_packages/vr_datapath_agent",
    "/home/dn/cheetah/src/py_packages/wb_fe_agent",
    "/home/dn/cheetah/src/py_packages/xray",
    "/home/dn/cheetah/src/py_packages/yang_orm",
    "/home/dn/cheetah/src/py_packages/yang_orm_gen",
    "/home/dn/cheetah/src/py_packages/",
    "/home/dn/cheetah/tests/suits",
    "/home/dn/cheetah/tests/shared",
    "/home/dn/cheetah/src/tests"

}

local function set_python_path(path)
  path = path['args']
  local clients = vim.lsp.get_clients {
    bufnr = vim.api.nvim_get_current_buf(),
    name = 'pyright',
  }
  for _, client in ipairs(clients) do
    if client.settings then
      client.settings.python = vim.tbl_deep_extend('force', client.settings.python, { pythonPath = path })
    else
      client.config.settings = vim.tbl_deep_extend('force', client.config.settings, { python = { pythonPath = path } })
    end
    client.notify('workspace/didChangeConfiguration', { settings = nil })
  end
end

return {
  cmd = { 'pyright-langserver', '--stdio' },
  filetypes = { 'python' },
  root_markers = {
    'pyproject.toml',
    'setup.py',
    'setup.cfg',
    'requirements.txt',
    'Pipfile',
    'pyrightconfig.json',
    '.git',
  },
  settings = {
    python = {
      analysis = {
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
        diagnosticMode = "workspace",
        typeCheckingMode = "basic",
        extraPaths = dn_extra_paths,
        -- Disable diagnostics that overlap with Ruff
        -- Ruff handles: imports, formatting, linting, etc.
        -- Pyright focuses on: type checking
        disableOrganizeImports = true,  -- Ruff handles this
        ignore = { '*' },  -- Disable file-level diagnostics
      },
    },
  },
  on_attach = function(client, bufnr)
    vim.api.nvim_buf_create_user_command(bufnr, 'LspPyrightOrganizeImports', function()
      client:exec_cmd({
        command = 'pyright.organizeimports',
        arguments = { vim.uri_from_bufnr(bufnr) },
      })
    end, {
      desc = 'Organize Imports',
    })
    vim.api.nvim_buf_create_user_command(bufnr, 'LspPyrightSetPythonPath', set_python_path, {
      desc = 'Reconfigure pyright with the provided python path',
      nargs = 1,
      complete = 'file',
    })
  end,
}
