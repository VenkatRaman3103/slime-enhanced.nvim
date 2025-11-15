local M = {}
local last_custom_commands = nil -- can be string or table

M.config = {
    target = "tmux",
    default_config = {
        socket_name = "default",
        target_pane = ":.1",
    },
    dont_ask_default = true,
    bracketed_paste = true,
    cell_delimiter = "# %%",
    keymaps = {
        send = "<leader>ss",
        send_cell_and_switch = "<leader>so",
        send_cell_no_switch = "<leader>sr",
        pick_target = "<leader>rt",
        send_custom = "<leader>sc",
        set_custom = "<leader>sC",
    }
}

-- Send to tmux helper
local function tmux_send(target, command)
    -- compress multi-line commands into: cmd1 && cmd2 && cmd3
    local lines = vim.split(command, "\n", { trimempty = true })
    local joined = table.concat(lines, " && ")

    local send_cmd = string.format([[tmux send-keys -t %s "%s" Enter]], target, joined)
    vim.fn.system(send_cmd)
end

-- FIXED, CLEAN, ROBUST command parser
local function parse_commands(input)
    -- No multiple command delimiter: return one string
    if not input:match(";;") then
        return vim.trim(input)
    end

    local parts = vim.split(input, ";;", { trimempty = true })
    local cmds = {}

    for _, p in ipairs(parts) do
        local trimmed = vim.trim(p)
        if trimmed ~= "" then
            table.insert(cmds, trimmed)
        end
    end

    return cmds
end

function M.setup(user_config)
    user_config = user_config or {}
    M.config = vim.tbl_deep_extend("force", M.config, user_config)

    vim.g.slime_target = M.config.target
    vim.g.slime_default_config = M.config.default_config
    vim.g.slime_dont_ask_default = M.config.dont_ask_default and 1 or 0
    vim.g.slime_bracketed_paste = M.config.bracketed_paste and 1 or 0
    vim.g.slime_cell_delimiter = M.config.cell_delimiter
    vim.g.slime_paste_file = vim.fn.tempname()

    M.setup_functions()
    M.setup_autocmds()
    M.setup_commands()
    M.setup_keymaps()
end

function M.slime_send_and_switch()
    vim.fn["slime#send_cell"]()

    local config = vim.b.slime_config or vim.g.slime_default_config
    local target_pane = config.target_pane

    local session, window_pane = target_pane:match("([^:]+):?(.*)")
    if not window_pane then
        window_pane = session
        session = nil
    end

    local switch_cmd
    if session then
        switch_cmd = string.format(
            "tmux select-window -t %s && tmux select-pane -t %s",
            target_pane:gsub("%.%d+$", ""),
            target_pane
        )
    else
        switch_cmd = string.format("tmux select-pane -t %s", target_pane)
    end

    vim.fn.system(switch_cmd)
    vim.cmd("redraw")
end

function M.pick_target()
    local ok, pickers = pcall(require, "telescope.pickers")
    if not ok then
        vim.notify("Telescope is required for SlimePickTarget", vim.log.levels.ERROR)
        return
    end

    local finders = require("telescope.finders")
    local conf = require("telescope.config").values
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")

    local layout_config = {
        height = 0.5,
        width = 0.6,
        prompt_position = "top",
    }

    local sessions = vim.fn.systemlist("tmux list-sessions -F '#S'")

    pickers.new({}, {
        prompt_title = "",
        prompt_prefix = "enter session > ",
        finder = finders.new_table({ results = sessions }),
        sorter = conf.generic_sorter({}),
        layout_strategy = "horizontal",
        layout_config = layout_config,

        attach_mappings = function(prompt_bufnr, map)
            actions.select_default:replace(function()
                local selection = action_state.get_selected_entry()
                actions.close(prompt_bufnr)
                local session = selection[1]

                local windows = vim.fn.systemlist(
                    string.format("tmux list-windows -t %s -F '#W'", session)
                )

                pickers.new({}, {
                    prompt_title = "",
                    prompt_prefix = "enter window > ",
                    finder = finders.new_table({ results = windows }),
                    sorter = conf.generic_sorter({}),
                    layout_strategy = "horizontal",
                    layout_config = layout_config,

                    attach_mappings = function(prompt_bufnr2, _)
                        actions.select_default:replace(function()
                            local win_entry = action_state.get_selected_entry()
                            actions.close(prompt_bufnr2)
                            local window = win_entry[1]
                            local full_window = string.format("%s:%s", session, window)

                            local panes = vim.fn.systemlist(
                                string.format("tmux list-panes -t %s -F '#{pane_index}:#{pane_current_command}'",
                                    full_window)
                            )

                            pickers.new({}, {
                                prompt_title = "",
                                prompt_prefix = "enter pane > ",
                                finder = finders.new_table({ results = panes }),
                                sorter = conf.generic_sorter({}),
                                layout_strategy = "horizontal",
                                layout_config = layout_config,

                                attach_mappings = function(prompt_bufnr3, _)
                                    actions.select_default:replace(function()
                                        local pane_entry = action_state.get_selected_entry()
                                        actions.close(prompt_bufnr3)

                                        local pane_index = pane_entry[1]:match("^(%d+):")
                                        if pane_index then
                                            local target = string.format("%s.%s", full_window, pane_index)
                                            vim.g.slime_default_config.target_pane = target
                                            vim.b.slime_config = {
                                                socket_name = "default",
                                                target_pane = target,
                                            }
                                            vim.notify("Slime target set: " .. target)
                                        else
                                            vim.notify("Failed to parse target pane", vim.log.levels.ERROR)
                                        end
                                    end)
                                    return true
                                end
                            }):find()
                        end)
                        return true
                    end
                }):find()
            end)
            return true
        end
    }):find()
end

function M.send_cell_no_switch()
    vim.fn["slime#send_cell"]()
end

function M.setup_functions()
    _G.SlimeSendAndSwitch = M.slime_send_and_switch
end

function M.setup_autocmds()
    vim.api.nvim_create_autocmd("FileType", {
        pattern = "markdown",
        callback = function()
            vim.b.slime_cell_delimiter = "```"

            vim.b.slime_get_cell = function()
                local pos = vim.api.nvim_win_get_cursor(0)[1]
                local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

                local start = pos
                while start > 1 and not lines[start]:match("^```") do
                    start = start - 1
                end

                local finish = pos
                while finish < #lines and not lines[finish]:match("^```%s*$") do
                    finish = finish + 1
                end

                if start < finish then
                    local out = {}
                    for i = start + 1, finish - 1 do
                        table.insert(out, lines[i])
                    end
                    return table.concat(out, "\n")
                end

                return ""
            end
        end
    })
end

function M.setup_commands()
    vim.api.nvim_create_user_command("SlimePickTarget", M.pick_target, {})
    vim.api.nvim_create_user_command("SlimeSendCellNoSwitch", M.send_cell_no_switch, {})
    vim.api.nvim_create_user_command("SlimeSendAndSwitch", M.slime_send_and_switch, {})

    vim.api.nvim_create_user_command("SlimeSendCustom", M.send_custom_command, {})
    vim.api.nvim_create_user_command("SlimeSetCustom", M.set_custom_command, {})
end

function M.setup_keymaps()
    local k = M.config.keymaps

    vim.keymap.set("n", k.send, "<Plug>SlimeSend")
    vim.keymap.set("x", k.send, "<Plug>SlimeSend")
    vim.keymap.set("n", k.send_cell_and_switch, M.slime_send_and_switch)
    vim.keymap.set("n", k.send_cell_no_switch, M.send_cell_no_switch)
    vim.keymap.set("n", k.pick_target, M.pick_target)

    vim.keymap.set("n", k.send_custom, M.send_custom_command)
    vim.keymap.set("n", k.set_custom, M.set_custom_command)
end

function M.send_custom_command()
    local cmds = last_custom_commands

    if cmds == nil then
        local input = vim.fn.input("Command (or multiple with ';;') > ")
        if input == nil or input == "" then
            vim.notify("No command entered.", vim.log.levels.WARN)
            return
        end

        cmds = parse_commands(input)
        last_custom_commands = cmds
    end

    local config = vim.b.slime_config or vim.g.slime_default_config
    local target = config.target_pane

    if type(cmds) == "string" then
        tmux_send(target, cmds)
    else
        for _, c in ipairs(cmds) do
            tmux_send(target, c)
        end
    end
end

function M.set_custom_command()
    local input = vim.fn.input("Set new command(s) > ")
    if input == nil or input == "" then
        vim.notify("No command entered.", vim.log.levels.WARN)
        return
    end

    last_custom_commands = parse_commands(input)

    if type(last_custom_commands) == "string" then
        vim.notify("Saved command: " .. last_custom_commands)
    else
        vim.notify("Saved commands: " .. table.concat(last_custom_commands, " | "))
    end
end

return M
