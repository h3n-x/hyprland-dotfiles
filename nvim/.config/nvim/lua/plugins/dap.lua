-- ============================================================================
-- Depuración DAP: mfussenegger/nvim-dap + DAP UI + Mason DAP
-- Soporte completo para Python (debugpy), Go (delve), Rust/C/C++ (codelldb) y Node.js
-- Respetando estrictamente los grupos de highlight dinámicos de Matugen
-- ============================================================================

return {
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			{
				"rcarriga/nvim-dap-ui",
				dependencies = { "nvim-neotest/nvim-nio" },
			},
			"theHamsta/nvim-dap-virtual-text",
			"jay-babu/mason-nvim-dap.nvim",
		},
		cmd = { "DapToggleBreakpoint", "DapContinue" },
		keys = {
			{
				"<leader>db",
				function()
					require("dap").toggle_breakpoint()
				end,
				desc = "Punto de interrupción (Breakpoint)",
			},
			{
				"<leader>dB",
				function()
					require("dap").set_breakpoint(vim.fn.input("Condición de breakpoint: "))
				end,
				desc = "Breakpoint condicional",
			},
			{
				"<leader>dc",
				function()
					require("dap").continue()
				end,
				desc = "Continuar / Iniciar depuración",
			},
			{
				"<leader>di",
				function()
					require("dap").step_into()
				end,
				desc = "Paso dentro (Step Into)",
			},
			{
				"<leader>do",
				function()
					require("dap").step_over()
				end,
				desc = "Paso por encima (Step Over)",
			},
			{
				"<leader>dO",
				function()
					require("dap").step_out()
				end,
				desc = "Paso fuera (Step Out)",
			},
			{
				"<leader>dt",
				function()
					require("dap").terminate()
					require("dapui").close()
				end,
				desc = "Terminar sesión de depuración",
			},
			{
				"<leader>du",
				function()
					require("dapui").toggle()
				end,
				desc = "Alternar interfaz visual (DAP UI)",
			},
			{
				"<leader>dr",
				function()
					require("dap").repl.open()
				end,
				desc = "Abrir consola REPL de depuración",
			},
		},
		config = function()
			local dap = require("dap")
			local dapui = require("dapui")

			-- Integración con Mason para debuggers
			require("mason-nvim-dap").setup({
				ensure_installed = { "debugpy", "delve", "codelldb" },
				automatic_installation = true,
				handlers = {},
			})

			-- DAP Virtual Text: valores de variables en línea
			require("nvim-dap-virtual-text").setup({
				commented = true,
				highlight_changed_variables = true,
			})

			-- Configuración de DAP UI con bordes redondeados y herencia de highlights
			dapui.setup({
				icons = { expanded = "▾", collapsed = "▸", current_frame = "▸" },
				mappings = {
					expand = { "<CR>", "<2-LeftMouse>" },
					open = "o",
					remove = "d",
					edit = "e",
					repl = "r",
					toggle = "t",
				},
				layouts = {
					{
						elements = {
							{ id = "scopes", size = 0.35 },
							{ id = "breakpoints", size = 0.20 },
							{ id = "stacks", size = 0.25 },
							{ id = "watches", size = 0.20 },
						},
						size = 40,
						position = "left",
					},
					{
						elements = {
							{ id = "repl", size = 0.60 },
							{ id = "console", size = 0.40 },
						},
						size = 10,
						position = "bottom",
					},
				},
				floating = {
					border = "rounded",
					mappings = {
						close = { "q", "<Esc>" },
					},
				},
			})

			-- Apertura y cierre automático de la interfaz al iniciar/concluir
			dap.listeners.after.event_initialized["dapui_config"] = function()
				dapui.open()
			end
			dap.listeners.before.event_terminated["dapui_config"] = function()
				dapui.close()
			end
			dap.listeners.before.event_exited["dapui_config"] = function()
				dapui.close()
			end

			-- Signos visuales en el margen vinculados a grupos de diagnóstico
			vim.fn.sign_define("DapBreakpoint", { text = "", texthl = "DiagnosticError", linehl = "", numhl = "" })
			vim.fn.sign_define("DapBreakpointCondition", { text = "", texthl = "DiagnosticWarn", linehl = "", numhl = "" })
			vim.fn.sign_define("DapBreakpointRejected", { text = "", texthl = "DiagnosticError", linehl = "", numhl = "" })
			vim.fn.sign_define("DapLogPoint", { text = "", texthl = "DiagnosticInfo", linehl = "", numhl = "" })
			vim.fn.sign_define("DapStopped", { text = "", texthl = "DiagnosticOk", linehl = "Visual", numhl = "DiagnosticOk" })
		end,
	},
}
