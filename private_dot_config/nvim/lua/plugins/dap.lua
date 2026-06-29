-- Debug Adapter Protocol: nvim-dap + UI + virtual text, wired for C/C++/Rust
-- via codelldb (installed through Mason).
return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      { "rcarriga/nvim-dap-ui", dependencies = { "nvim-neotest/nvim-nio" } },
      "theHamsta/nvim-dap-virtual-text",
    },
    keys = {
      { "<F5>", function() require("dap").continue() end, desc = "Debug: continue / start" },
      { "<F10>", function() require("dap").step_over() end, desc = "Debug: step over" },
      { "<F11>", function() require("dap").step_into() end, desc = "Debug: step into" },
      { "<F12>", function() require("dap").step_out() end, desc = "Debug: step out" },
      { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Debug: toggle breakpoint" },
      { "<leader>dB", function() require("dap").set_breakpoint() end, desc = "Debug: set breakpoint" },
      {
        "<leader>dl",
        function() require("dap").set_breakpoint(nil, nil, vim.fn.input "Log point message: ") end,
        desc = "Debug: log point",
      },
      { "<leader>dc", function() require("dap").continue() end, desc = "Debug: continue" },
      { "<leader>dr", function() require("dap").repl.toggle() end, desc = "Debug: toggle REPL" },
      { "<leader>dL", function() require("dap").run_last() end, desc = "Debug: run last" },
      { "<leader>dt", function() require("dap").terminate() end, desc = "Debug: terminate" },
      { "<leader>du", function() require("dapui").toggle() end, desc = "Debug: toggle UI" },
      { "<leader>de", function() require("dapui").eval() end, desc = "Debug: eval", mode = { "n", "v" } },
      { "<leader>dh", function() require("dap.ui.widgets").hover() end, desc = "Debug: hover", mode = { "n", "v" } },
      {
        "<leader>df",
        function()
          local w = require "dap.ui.widgets"
          w.centered_float(w.frames)
        end,
        desc = "Debug: frames",
      },
      {
        "<leader>ds",
        function()
          local w = require "dap.ui.widgets"
          w.centered_float(w.scopes)
        end,
        desc = "Debug: scopes",
      },
    },
    config = function()
      local dap = require "dap"
      local dapui = require "dapui"

      dapui.setup()
      require("nvim-dap-virtual-text").setup {}

      -- Breakpoint signs
      vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticError", linehl = "", numhl = "" })
      vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DiagnosticWarn", linehl = "Visual", numhl = "" })

      -- Auto open/close the UI around a debug session
      dap.listeners.before.attach.dapui_config = function() dapui.open() end
      dap.listeners.before.launch.dapui_config = function() dapui.open() end
      dap.listeners.before.event_terminated.dapui_config = function() dapui.close() end
      dap.listeners.before.event_exited.dapui_config = function() dapui.close() end

      -- codelldb adapter (path from the Mason install) ----------------------
      local codelldb = vim.fn.stdpath "data" .. "/mason/bin/codelldb"
      dap.adapters.codelldb = {
        type = "server",
        port = "${port}",
        executable = {
          command = codelldb,
          args = { "--port", "${port}" },
        },
      }

      -- C / C++ / Rust configurations ---------------------------------------
      local lldb_cfg = {
        {
          name = "Launch (codelldb)",
          type = "codelldb",
          request = "launch",
          program = function()
            return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
          end,
          cwd = "${workspaceFolder}",
          stopOnEntry = false,
          args = {},
        },
      }
      dap.configurations.c = lldb_cfg
      dap.configurations.cpp = lldb_cfg
      dap.configurations.rust = lldb_cfg
    end,
  },
}
