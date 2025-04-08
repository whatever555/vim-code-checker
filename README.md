# vim-code-checker 📦

## Overview

# Vim Code Checker (BETA)

This is a Vim plugin that provides functionality for running code checks using external commands. It can be used to check, explain, or ask questions about code.


https://github.com/user-attachments/assets/3b449b54-3812-4cf7-aa00-37ac61702004



## Prerequisites/Dependencies

You need to install the `emurph-code-checker` package globally using npm. You can do this by running the following command:

```bash
npm install -g emurph-code-checker
```

You must have node/npm installed on your system to use this plugin.
[More information on installing npm plugins](https://thedeadweb.eu/?q=how%20to%20install%20npm%20plugins&style=vim)

If you want to run the code checker locally, you will need to install ollama.
[More information on installing Ollama](https://thedeadweb.eu/?q=getting%20started%20with%20ollama&style=vim)

## Features

- Run code checks with different modes: 'check', 'explain', and 'question'.
- Can be used on visual selection, or complete file.
- Displays results in a quickfix list for easy viewing.

## Usage

1. Install plugin for vim.
   - Use your favorite plugin manager (e.g., vim-plug, Vundle, etc.) to install the plugin.
   - Example using vim-plug: `vim Plug 'whatever555/vim-code-checker' `
   - [Guide on how to install vim plugins](https://thedeadweb.eu/?q=A%20detailed%20and%20comprehensive%20guide%20on%20how%20to%20install%20vim%20plugins%20&style=vim)
2. Commands to run checks:

- `:CodeCheck` runs code check without any additional information.
- `:CodeCheckExplain` requests detailed explanation of the issues found.
- `:CodeCheckAskQuestion <args>` asks a question about specific issues, where `<args>` is your query.

3. Use visual mode to select text and apply commands (e.g., `gv`, then `:CodeCheck`), or just run command without any code selected to query entire file.

## Configuration
You can configure the plugin by adding the following lines to your `.vimrc` or `init.vim` file:

### To use ollama
```vim
let g:code_checker_provider = 'ollama'
```
### To use open-router (Default) 
```vim
let g:code_checker_provider = 'open-router'
```

## Setting environment variables (Required for open-router)
Create a `.env` file in your home directory or the directory where you run Vim. Add the following lines to the `.env` file:
Tip: Add the `.env` file to your `.gitignore` file to avoid committing it to version control. [More information on .env files](https://thedeadweb.eu/?q=understanding%20.env%20files&style=vim) 

```
"An api key is required to use open-router
OPEN_ROUTER_API_KEY=<your_api_key>
OPEN_ROUTER_MODEL=<your_openrouter_model>

"Set your ollama model if you are using ollama
OLLAMA_MODEL=<your_ollama_model>
```

## Example

If you have selected some code in Vim:
`:CodeCheckAskQuestion What does this error mean?`
This will ask the tool to explain what the highlighted error means


## Known Issues/Future Improvements
 - The plugin currently does not handle errors from the code checker gracefully. If the command fails, it may not provide useful feedback to the user
 - The plugin is not optimized for token usage. This can cause a cost issue for remote connections, and can impact performace on local models. It is advised to use google flash models for open-router, as they seem to be the most cost effective. 
 - The plugin does not yet handle large files well. If the file is too large, it may cause the code checker to fail or take a long time to run.
 - The plugin is still in beta mode, so make sure to check for updates as often as possible (botht the npm package and the vim plugin)
  - The plugin has a strict dependency on the npm code checker. If the npm package is updated, the plugin may not work until it is updated as well.
  - The plugin is not yet optimized. There are many areas where performance can be improved.
