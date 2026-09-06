# Kiểm toán cấu hình Neovim — 2026-09-07

## Phạm vi

Đã đọc cấu hình plugin, các integration, ftplugin, helper, core options/keymap/autocmd và tài liệu. Danh mục có 57 plugin khai báo trực tiếp; bài thử setup có 74 mục gồm dependency. Icon file được giữ. Không cập nhật hàng loạt phiên bản hoặc sửa lazy-lock.json trong lần kiểm toán này.

## Các sửa đổi trong lần kiểm toán toàn bộ

| Nhóm | Lỗi / bất hợp lý | Sửa đổi |
| --- | --- | --- |
| Debug/test | Phím debug test tải DAP nhưng chưa tạo mapping Neotest | Đưa nd/nD sang lazy keys của Neotest; DAP vẫn tải lúc debug |
| Test | Chạy toàn dự án lấy CWD; file test dùng đường dẫn tương đối | Dùng project root và tên file tuyệt đối |
| Completion/AI | Tab nhận ghost text AI dù menu LSP đang mở | Ưu tiên menu, snippet, rồi AI; Ctrl-y nhận completion |
| Go | Timer InsertLeave sửa import sau khi gõ, trùng formatter | Giữ completion gopls và goimports lúc lưu; bỏ timer |
| LSP | Restart dùng edit trễ, có thể tác động file đang xem khác hoặc lỗi khi có sửa chưa lưu | Chụp client/buffer, đợi dừng rồi start lại đúng buffer; gộp lần restart lặp |
| TypeScript | Phím import/fix thuộc plugin đã tắt | Nối Ti/Ta/Tu/Tf vào source actions của ts_ls; bỏ quảng cáo phím Tr không hoạt động |
| Java | on_attach dùng buffer cũ khi client được tái sử dụng | Dùng buffer thực nhận trong callback; kiểm tra buffer hợp lệ |
| Plugin tải trễ | Đổi cửa sổ trước timer khiến config chạy trong file khác | Thực hiện setup trong nvim_buf_call của buffer nguồn, giữ focus |
| Python | Callback venv chạy sau khi buffer đã đóng/đổi loại | Kiểm tra lại buffer và filetype trước callback |
| Treesitter | Timer tồn tại tới hạn sau khi wipe buffer; cài parser xong thử bật trên buffer phụ | Dọn timer; chỉ bật lại trên file thường đang hiển thị |
| Terminal | Setup đổi shell/shellcmdflag toàn cục; chọn cửa sổ có thể sang tab khác | Chỉ cấu hình shell cho terminal; chọn cửa sổ editor trong tab hiện tại; kích thước nguyên |
| AI | Nhấn nhiều lần khi chờ ACP có thể mở nhiều bộ chọn | Hủy yêu cầu tùy chọn cũ khi có yêu cầu mới |
| Git/AI | Tạo prompt commit đọc Git đồng bộ không giới hạn, sai CWD | Dùng project root và giới hạn chờ 1,5 giây |
| UI | Chế độ tắt animation vẫn có notify trượt và nạp smear-cursor | Notify static; smear-cursor chỉ tải theo yêu cầu khi animation tắt |
| Statusline | Diagnostics xuất hiện ở cả section mặc định và section tùy chỉnh | Hiển thị một lần |
| Keymap | mini.bracketed ghi đè quyền quản lý quickfix; đóng buffer phụ thuộc global Snacks | Giữ mapping quickfix của core; require Snacks khi đóng buffer |
| Health/docs | Thiếu trạng thái buffer; tài liệu TS/formatter cũ | Bổ sung root/format/LSP/plugin state và sửa tài liệu |

## Kiểm tra

- `tests/audit.lua`: kiểm tra trùng quyền sở hữu phím khai báo, có chuẩn hóa leader và visual mode.
- `tests/startup.lua`: setup các plugin đã cài trong môi trường tách biệt, tắt cài đặt tự động; lần Insert đầu; fzf/rg thật; tìm từ; dashboard và mở kết quả; phím quan trọng sau khi tải plugin; 40 chu kỳ cửa sổ chat mô phỏng.
- `tests/terminal.lua`: chạy lệnh thật trong terminal của Neovim embedded, xác nhận output và shell toàn cục không đổi.
- `tests/regressions.lua`: restart giữ buffer chưa lưu sau đổi focus; shell toàn cục; Tab; debug-test key ownership; Go không tạo timer InsertLeave.
- `tests/performance.lua`: file lớn/minified; completion không quét cửa sổ phụ; LSP tải sau FileType đúng buffer, không giành focus.
- `tests/autoimport.lua`: TypeScript server thật tìm export chưa import, resolve và áp dụng import edit.
- `tests/upgrades.lua`: 13 kiểm tra project root, format, search scope, UI toggle, scratch, profiler.
- `tests/dashboard_pick.lua`: 12 trường hợp mở file, sửa chưa lưu, chọn swap, fallback và cleanup.
- `tests/dashboard_treesitter.lua`, `tests/config_validation.lua`: thứ tự Treesitter, schema Blink và cú pháp Lua.

## Giới hạn đã biết

Setup thành công không chứng minh mọi chức năng trên mọi dự án. Chưa chạy debug/test thật cho mọi ngôn ngữ, gửi prompt AI, hoặc kiểm tra hiệu năng trên project lớn của người dùng. Prompt commit vẫn có một bước đồng bộ tối đa 1,5 giây do API content resolver hiện tại. Thời gian RPC trong bài thử bao gồm polling và không phải số FPS/độ trễ UI chính xác. Cấu hình typescript-tools được giữ ở trạng thái disabled, không tạo server thứ hai.

## Danh mục toàn bộ plugin khai báo trực tiếp

Tất cả các mục dưới đã được rà cấu hình; các mục được bật cũng nằm trong bài thử setup, cùng dependency. Các module Git, navigation, dooing, sessions và những tiện ích không có lỗi tái hiện được được giữ chức năng hiện tại.

| Plugin | Module | Số key khai báo | Cách kích hoạt trong spec |
| --- | --- | ---: | --- |
| `olimorris/codecompanion.nvim` | `plugins.ai` | 20 | command/key/dependency |
| `github/copilot.vim` | `plugins.ai` | 0 | { "BufReadPost", "BufNewFile" } |
| `saghen/blink.cmp` | `plugins.completion` | 0 | { "ModeChanged *:i", "CmdlineEnter" } |
| `mfussenegger/nvim-dap` | `plugins.debug` | 9 | command/key/dependency |
| `nvim-neotest/neotest` | `plugins.debug` | 9 | command/key/dependency |
| `atiladefreitas/dooing` | `plugins.dooing` | 3 | command/key/dependency |
| `smjonas/inc-rename.nvim` | `plugins.editor` | 0 | command/key/dependency |
| `monaqa/dial.nvim` | `plugins.editor` | 8 | command/key/dependency |
| `nvim-neo-tree/neo-tree.nvim` | `plugins.editor` | 3 | command/key/dependency |
| `stevearc/oil.nvim` | `plugins.editor` | 2 | command/key/dependency |
| `folke/trouble.nvim` | `plugins.editor` | 6 | command/key/dependency |
| `stevearc/quicker.nvim` | `plugins.editor` | 2 | "qf" |
| `folke/flash.nvim` | `plugins.editor` | 3 | command/key/dependency |
| `sphamba/smear-cursor.nvim` | `plugins.editor` | 1 | deferred/custom init |
| `folke/todo-comments.nvim` | `plugins.editor` | 0 | deferred/custom init |
| `windwp/nvim-autopairs` | `plugins.editor` | 0 | "InsertEnter" |
| `gbprod/yanky.nvim` | `plugins.editor` | 8 | command/key/dependency |
| `kevinhwang91/nvim-ufo` | `plugins.editor` | 5 | deferred/custom init |
| `nvim-mini/mini.nvim` | `plugins.editor` | 0 | "VeryLazy" |
| `tpope/vim-surround` | `plugins.editor` | 0 | "VeryLazy" |
| `mg979/vim-visual-multi` | `plugins.editor` | 0 | "VeryLazy" |
| `folke/ts-comments.nvim` | `plugins.editor` | 0 | "VeryLazy" |
| `windwp/nvim-ts-autotag` | `plugins.editor` | 0 | { "html", "xml", "javascriptreact", "typescriptreact", "vue", "svelte", "astro", "php" } |
| `MeanderingProgrammer/render-markdown.nvim` | `plugins.editor` | 0 | deferred/custom init |
| `lewis6991/gitsigns.nvim` | `plugins.git` | 0 | deferred/custom init |
| `tpope/vim-fugitive` | `plugins.git` | 4 | command/key/dependency |
| `sindrets/diffview.nvim` | `plugins.git` | 3 | command/key/dependency |
| `NeogitOrg/neogit` | `plugins.git` | 1 | command/key/dependency |
| `linux-cultist/venv-selector.nvim` | `plugins.languages` | 1 | deferred/custom init |
| `ray-x/go.nvim` | `plugins.languages` | 9 | deferred/custom init |
| `mfussenegger/nvim-jdtls` | `plugins.languages` | 0 | deferred/custom init |
| `neovim/nvim-lspconfig` | `plugins.lsp` | 0 | deferred/custom init |
| `rachartier/tiny-code-action.nvim` | `plugins.lsp` | 0 | "LspAttach" |
| `folke/lazydev.nvim` | `plugins.lsp` | 0 | deferred/custom init |
| `b0o/SchemaStore.nvim` | `plugins.lsp` | 0 | { "json", "jsonc" } |
| `mason-org/mason.nvim` | `plugins.lsp` | 1 | command/key/dependency |
| `WhoIsSethDaniel/mason-tool-installer.nvim` | `plugins.lsp` | 0 | deferred/custom init |
| `stevearc/conform.nvim` | `plugins.lsp` | 1 | { "BufReadPre", "BufNewFile" } |
| `mfussenegger/nvim-lint` | `plugins.lsp` | 1 | deferred/custom init |
| `cbochs/grapple.nvim` | `plugins.navigation` | 6 | command/key/dependency |
| `ibhagwan/fzf-lua` | `plugins.search` | 15 | deferred/custom init |
| `MagicDuck/grug-far.nvim` | `plugins.search` | 2 | command/key/dependency |
| `folke/persistence.nvim` | `plugins.sessions` | 4 | deferred/custom init |
| `akinsho/toggleterm.nvim` | `plugins.terminal` | 6 | command/key/dependency |
| `stevearc/overseer.nvim` | `plugins.terminal` | 2 | command/key/dependency |
| `nvim-treesitter/nvim-treesitter` | `plugins.treesitter` | 0 | command/key/dependency |
| `catppuccin/nvim` | `plugins.ui` | 0 | startup |
| `nvim-tree/nvim-web-devicons` | `plugins.ui` | 0 | command/key/dependency |
| `Bekaboo/dropbar.nvim` | `plugins.ui` | 4 | deferred/custom init |
| `folke/snacks.nvim` | `plugins.ui` | 10 | command/key/dependency |
| `LunarVim/bigfile.nvim` | `plugins.ui` | 0 | "BufReadPre" |
| `nvim-lualine/lualine.nvim` | `plugins.ui` | 0 | "VeryLazy" |
| `akinsho/bufferline.nvim` | `plugins.ui` | 5 | "VeryLazy" |
| `rcarriga/nvim-notify` | `plugins.ui` | 0 | "VeryLazy" |
| `folke/noice.nvim` | `plugins.ui` | 0 | "VeryLazy" |
| `shellRaining/hlchunk.nvim` | `plugins.ui` | 2 | deferred/custom init |
| `folke/which-key.nvim` | `plugins.ui` | 0 | "VeryLazy" |
