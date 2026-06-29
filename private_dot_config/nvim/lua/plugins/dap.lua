return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      { "rcarriga/nvim-dap-ui", dependencies = { "nvim-neotest/nvim-nio" } },
      "theHamsta/nvim-dap-virtual-text",
    },
    keys = {
      { "<F5>", function() require("dap").continue() end, desc = "debug: continue/start" },
      { "<F10>", function() require("dap").step_over() end, desc = "debug: step over" },
      { "<F11>", function() require("dap").step_into() end, desc = "debug: step into" },
      { "<F12>", function() require("dap").step_out() end, desc = "debug: step out" },
      { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "debug: toggle breakpoint" },
      {
        "<leader>dB",
        function()
          require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
        end,
        desc = "debug: conditional breakpoint",
      },
      {
        "<leader>dp",
        function()
          require("dap").set_breakpoint(nil, nil, vim.fn.input("Log point message: "))
        end,
        desc = "debug: log point",
      },
      { "<leader>dc", function() require("dap").continue() end, desc = "debug: continue" },
      { "<leader>dr", function() require("dap").repl.toggle() end, desc = "debug: toggle REPL" },
      { "<leader>dl", function() require("dap").run_last() end, desc = "debug: run last" },
      { "<leader>dt", function() require("dap").terminate() end, desc = "debug: terminate" },
      { "<leader>du", function() require("dapui").toggle() end, desc = "debug: toggle UI" },
      {
        "<leader>de",
        function() require("dapui").eval() end,
        mode = { "n", "v" },
        desc = "debug: eval expression",
      },
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")

      dapui.setup()
      require("nvim-dap-virtual-text").setup()

      -- auto open/close the UI
      dap.listeners.before.attach.dapui_config = function() dapui.open() end
      dap.listeners.before.launch.dapui_config = function() dapui.open() end
      dap.listeners.before.event_terminated.dapui_config = function() dapui.close() end
      dap.listeners.before.event_exited.dapui_config = function() dapui.close() end

      -- codelldb (installed via Mason)
      dap.adapters.codelldb = {
        type = "server",
        port = "${port}",
        executable = {
          command = vim.fn.stdpath("data") .. "/mason/bin/codelldb",
          args = { "--port", "${port}" },
        },
      }

      local lldb_cfg = {
        {
          name = "Launch file",
          type = "codelldb",
          request = "launch",
          program = function()
            return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
          end,
          cwd = "${workspaceFolder}",
          stopOnEntry = false,
          -- NOTE: codelldb defaults to runInTerminal, which can't run under
          -- --headless. For headless DAP testing only, add: terminal = "console".
          -- Kept as default (integrated terminal) for normal interactive use.
        },
      }
      dap.configurations.c = lldb_cfg
      dap.configurations.cpp = lldb_cfg
      dap.configurations.rust = lldb_cfg
    end,
  },
}
