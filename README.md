# java-project-creator.nvim

A Neovim plugin to easily create Java projects and Maven projects.

## Features

- 🚀 Quick project creation with sensible defaults for Java development  
- 📦 Maven project support with custom group/artifact IDs  
- 🖼️ Integration with [nui.nvim](https://github.com/MunifTanjim/nui.nvim) for a modern UI experience (optional)  
- ⌨️ Customizable keybindings for fast project creation  

## Installation

### Using `packer.nvim`

```lua
use {
  'diogof146/java-project-creator.nvim',
  requires = { 'MunifTanjim/nui.nvim' }, -- Optional but recommended for UI
  config = function()
    require('java-project-creator').setup({
      -- Your configuration options here (see below)
    })
  end
}
```

### Using `lazy.nvim`

```lua
{
  'diogof146/java-project-creator.nvim',
  dependencies = { 'MunifTanjim/nui.nvim' }, -- Optional but recommended for UI
  config = function()
    require('java-project-creator').setup({
      -- Your configuration options here (see below)
    })
  end
}
```

## Configuration

Here's an example configuration with all available options:

```lua
require('java-project-creator').setup({
  base_path = vim.fn.getcwd(),             -- Default path for new projects
  default_java_version = "17",             -- Java version to use (supports 8-21)
  default_group_id = "com.yourcompany",    -- Default Maven group ID
  default_artifact_id = "myapp",           -- Default Maven artifact ID
  default_version = "1.0-SNAPSHOT",        -- Default Maven version
  maven_cmd = "mvn",                       -- Maven command to use
  keymaps = {
    new_java_project = "<localleader>njp", -- Keymap for new Java project
    new_maven_project = "<localleader>nmp" -- Keymap for new Maven project
  }
})
```

## Usage

### Commands

The plugin provides two main commands:

- `:JavaCreateProject [name]` - Create a new Java project
- `:MavenCreateProject [name]` - Create a new Maven project  

### Keybindings

Default keybindings (can be customized):

- `<localleader>njp` - Start creating a new Java project  
- `<localleader>nmp` - Start creating a new Maven project  

## Project Structures

### Java Project

```
JavaProject/
├── src/
│   └── package/
│       └── Main.java        # Entry point of the application
├── bin/                     # Compiled classes directory
├── lib/                     # External libraries directory
├── .classpath               # Classpath file
├── .project                 # Project file
└── .gitignore               # Git ignore file
```

### Maven Project

```
MavenProject/
├── src/
│   ├── main/
│   │   ├── java/         # Main source code
│   │   └── resources/    # Main resources
│   └── test/
│       ├── java/         # Test source code
│       └── resources/    # Test resources
├── pom.xml              # Maven project file
└── .gitignore           # Git ignore file
```

## Dependencies

- `nui.nvim` (optional) – For interactive UI dialogs

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT

