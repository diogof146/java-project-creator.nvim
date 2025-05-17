-- java-project-creator/init.lua
-- A Neovim plugin for creating Java projects
-- and Maven projects

-- Check if nui.nvim is available
local has_nui, nui = pcall(require, "nui.menu")
local has_nui_input = pcall(require, "nui.input")
local has_nui_popup = pcall(require, "nui.popup")

local utils = require("java-project-creator.utils")

local M = {}

-- Configuration with default values
M.config = {
  base_path = vim.fn.getcwd(),     -- Default to current directory
  default_java_version = "11",     -- Default Java version
  default_group_id = "com.example", -- Default group ID for Maven projects
  default_artifact_id = "app",     -- Default artifact ID for Maven projects
  default_version = "1.0-SNAPSHOT", -- Default version for Maven projects
  maven_cmd = "mvn",               -- Command to execute Maven
  -- Keybinding options
  keymaps = {
    new_java_project = "<localleader>njp",
    new_maven_project = "<localleader>nmp",
  },
}

-- Helper function to safely join paths
local function safe_path_join(...)
  local path_sep = vim.fn.has("win32") == 1 and "\\" or "/"
  local result = ""
  for i, part in ipairs({ ... }) do
    if i > 1 and result ~= "" then
      result = result .. path_sep
    end
    result = result .. part
  end
  return result
end

-- Helper function to escape paths properly
local function escape_path(path)
  -- Escape spaces and other special characters in paths
  if vim.fn.has("win32") == 1 then
    -- Windows path escaping
    return '"' .. path .. '"'
  else
    -- Unix/macOS path escaping - escape spaces and special characters
    return '"' .. path .. '"'
  end
end

-- Setup function to be called by the user
function M.setup(opts)
  opts = opts or {}

  -- Merge user config with defaults
  for k, v in pairs(opts) do
    if type(v) == "table" and type(M.config[k]) == "table" then
      -- For nested tables like keymaps, merge them instead of replacing
      for subk, subv in pairs(v) do
        M.config[k][subk] = subv
      end
    else
      M.config[k] = v
    end
  end

  -- Setup safe Java filetype handling to prevent errors
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "java",
    callback = function()
      -- Only setup basic Java support if jdtls isn't properly loaded
      local has_jdtls, _ = pcall(require, "jdtls")
      if not has_jdtls then
        -- Basic Java settings that don't depend on jdtls
        vim.bo.shiftwidth = 4
        vim.bo.tabstop = 4
        vim.bo.expandtab = true
      end
    end,
    once = false, -- Apply every time a Java file is opened
    group = vim.api.nvim_create_augroup("java_project_creator", { clear = true }),
  })

  -- Create user commands
  vim.api.nvim_create_user_command("JavaCreateProject", function(args)
    M.create_java_project(args.args)
  end, {
    nargs = "?",
    desc = "Create a new Java project",
    complete = "dir",
  })

  vim.api.nvim_create_user_command("MavenCreateProject", function(args)
    M.create_maven_project(args.args)
  end, {
    nargs = "?",
    desc = "Create a new Maven project",
    complete = "dir",
  })

  -- Set up keymappings
  vim.api.nvim_set_keymap(
    "n",
    M.config.keymaps.new_java_project,
    ':lua require("java-project-creator").start_java_project()<CR>',
    { noremap = true, silent = true, desc = "Create new Java project" }
  )

  vim.api.nvim_set_keymap(
    "n",
    M.config.keymaps.new_maven_project,
    ':lua require("java-project-creator").start_maven_project()<CR>',
    { noremap = true, silent = true, desc = "Create new Maven project" }
  )
end

-- NUI integration for project creation
function M.start_java_project()
  if not has_nui or not has_nui_input or not has_nui_popup then
    utils.print_status("nui.nvim is required for the interactive menu. Using prompt fallback.", false)
    local project_name = vim.fn.input("Enter project name: ")
    local package_name = vim.fn.input("Enter package name: ")

    if project_name and project_name ~= "" then
      M.create_java_project(project_name, package_name)
    end
    return
  end

  local Input = require("nui.input")
  local input = Input({
    position = "50%",
    size = {
      width = 40,
    },
    border = {
      style = "rounded",
      text = {
        top = " New Java Project ",
        top_align = "center",
      },
    },
    win_options = {
      winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
    },
  }, {
    prompt = "Project name: ",
    on_submit = function(value)
      if value and value ~= "" then
        -- Now ask for package name
        local package_input = Input({
          position = "50%",
          size = {
            width = 40,
          },
          border = {
            style = "rounded",
            text = {
              top = " Package Name ",
              top_align = "center",
            },
          },
          win_options = {
            winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
          },
        }, {
          prompt = "Package name: ",
          on_submit = function(package_name)
            M.create_java_project(value, package_name)
          end,
        })

        package_input:mount()
      end
    end,
  })

  input:mount()
end

function M.start_maven_project()
  if not has_nui or not has_nui_input or not has_nui_popup then
    utils.print_status("nui.nvim is required for the interactive menu. Using prompt fallback.", false)
    local project_name = vim.fn.input("Enter project name (Artifact ID): ")
    if project_name and project_name ~= "" then
      M.create_maven_project(project_name)
    end
    return
  end

  local Input = require("nui.input")
  local project_name_input = Input({
    position = "50%",
    size = {
      width = 40,
    },
    border = {
      style = "rounded",
      text = {
        top = " New Maven Project ",
        top_align = "center",
      },
    },
    win_options = {
      winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
    },
  }, {
    prompt = "Project name (Artifact ID): ",
    on_submit = function(value)
      if value and value ~= "" then
        local artifact_id = value

        -- Now ask for group ID
        local group_id_input = Input({
          position = "50%",
          size = {
            width = 40,
          },
          border = {
            style = "rounded",
            text = {
              top = " Group ID ",
              top_align = "center",
            },
          },
          win_options = {
            winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
          },
        }, {
          prompt = "Group ID: ",
          default_value = M.config.default_group_id,
          on_submit = function(group_id)
            -- Ask for package name (which might differ from group ID)
            local package_name_input = Input({
              position = "50%",
              size = {
                width = 40,
              },
              border = {
                style = "rounded",
                text = {
                  top = " Package Name ",
                  top_align = "center",
                },
              },
              win_options = {
                winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
              },
            }, {
              prompt = "Package name: ",
              default_value = group_id,
              on_submit = function(package_name)
                -- Finally ask for version
                local version_input = Input({
                  position = "50%",
                  size = {
                    width = 40,
                  },
                  border = {
                    style = "rounded",
                    text = {
                      top = " Version ",
                      top_align = "center",
                    },
                  },
                  win_options = {
                    winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
                  },
                }, {
                  prompt = "Version: ",
                  default_value = M.config.default_version,
                  on_submit = function(version)
                    M.create_maven_project_with_values(artifact_id, group_id, package_name, version)
                  end,
                })

                version_input:mount()
              end,
            })

            package_name_input:mount()
          end,
        })

        group_id_input:mount()
      end
    end,
  })

  project_name_input:mount()
end

-- Create a basic Java project
function M.create_java_project(project_name, package_name)
  project_name = project_name or "JavaProject"
  package_name = package_name or ""

  -- Create project directory structure - use safe_path_join
  local project_path = safe_path_join(M.config.base_path, project_name)
  local src_path = safe_path_join(project_path, "src")
  local bin_path = safe_path_join(project_path, "bin")
  local lib_path = safe_path_join(project_path, "lib")

  -- Create directories first
  utils.print_status("Creating project structure...", true)
  utils.create_directory(project_path)
  utils.create_directory(src_path)
  utils.create_directory(bin_path)
  utils.create_directory(lib_path)

  -- Create package directory path - using proper path handling for packages
  local package_path = src_path
  if package_name and package_name ~= "" then
    for part in string.gmatch(package_name, "[^%.]+") do
      package_path = safe_path_join(package_path, part)
      utils.create_directory(package_path)
    end
  end

  -- Create a sample .classpath file
  local classpath_content = [[<?xml version="1.0" encoding="UTF-8"?>
<classpath>
	<classpathentry kind="src" path="src"/>
	<classpathentry kind="con" path="org.eclipse.jdt.launching.JRE_CONTAINER/org.eclipse.jdt.internal.debug.ui.launcher.StandardVMType/JavaSE-]] ..
  M.config.default_java_version .. [["/>
	<classpathentry kind="output" path="bin"/>
</classpath>
]]
  utils.create_file(safe_path_join(project_path, ".classpath"), classpath_content)

  -- Create a sample .project file
  local project_content = [[<?xml version="1.0" encoding="UTF-8"?>
<projectDescription>
	<name>]] .. project_name .. [[</name>
	<comment></comment>
	<projects>
	</projects>
	<buildSpec>
		<buildCommand>
			<name>org.eclipse.jdt.core.javabuilder</name>
			<arguments>
			</arguments>
		</buildCommand>
	</buildSpec>
	<natures>
		<nature>org.eclipse.jdt.core.javanature</nature>
	</natures>
</projectDescription>
]]
  utils.create_file(safe_path_join(project_path, ".project"), project_content)

  -- Create a clean Main.java file in the package directory
  local main_class_path = safe_path_join(package_path, "Main.java")
  local main_class_content

  if package_name and package_name ~= "" then
    main_class_content = [[package ]]
        .. package_name
        .. [[;

/**
 * Main class for ]]
        .. project_name
        .. [[

 */
public class Main {
    public static void main(String[] args) {
        // Main method implementation
    }
}
]]
  else
    main_class_content = [[
/**
 * Main class for ]] .. project_name .. [[

 */
public class Main {
    public static void main(String[] args) {
        // Main method implementation
    }
}
]]
  end
  utils.create_file(main_class_path, main_class_content)

  -- Create a .gitignore file
  local gitignore_content = [[
# Compiled class files
*.class

# Log files
*.log

# BlueJ files
*.ctxt

# Mobile Tools for Java (J2ME)
.mtj.tmp/

# Package Files
*.jar
*.war
*.nar
*.ear
*.zip
*.tar.gz
*.rar

# VM crash logs
hs_err_pid*

# Eclipse specific files
/bin/
/.settings/

# OS specific files
.DS_Store
]]
  utils.create_file(safe_path_join(project_path, ".gitignore"), gitignore_content)

  -- Print success message
  utils.print_status("Java project '" .. project_name .. "' created successfully at " .. project_path, true)

  -- Return the project path in case it's needed
  return project_path
end

-- Create Maven project with provided values
function M.create_maven_project_with_values(artifact_id, group_id, package_name, version)
  package_name = package_name or group_id

  -- Project directory
  local project_path = safe_path_join(M.config.base_path, artifact_id)

  -- Create the project directory first to ensure it exists
  utils.create_directory(project_path)

  -- If Maven is available, use it to generate the project
  if vim.fn.executable(M.config.maven_cmd) == 1 then
    utils.print_status("Creating Maven project with " .. M.config.maven_cmd .. "...", true)

    -- On macOS/Unix, it's better to run Maven from the directory where we want the project
    local current_dir = vim.fn.getcwd()
    vim.fn.chdir(M.config.base_path)

    -- Use proper escaping for all values in the Maven command
    local maven_cmd = escape_path(M.config.maven_cmd)
        .. " archetype:generate"
        .. " -DgroupId="
        .. escape_path(group_id)
        .. " -DartifactId="
        .. escape_path(artifact_id)
        .. " -Dversion="
        .. escape_path(version)
        .. " -DarchetypeArtifactId=maven-archetype-quickstart"
        .. " -DarchetypeVersion=1.4"
        .. " -DinteractiveMode=false"

    vim.fn.system(maven_cmd)

    -- Change back to original directory
    vim.fn.chdir(current_dir)

    if vim.v.shell_error == 0 then
      -- Create clean Main.java if Maven generated the project successfully
      local pkg_path = ""
      for part in string.gmatch(package_name, "[^%.]+") do
        pkg_path = safe_path_join(pkg_path, part)
      end

      local src_main_java_path = safe_path_join(project_path, "src", "main", "java", pkg_path)
      local main_class_path = safe_path_join(src_main_java_path, "Main.java")
      local app_class_path = safe_path_join(src_main_java_path, "App.java")

      -- Only rewrite Main.java if App.java exists - we'll create Main.java and can optionally remove App.java
      if vim.fn.filereadable(app_class_path) == 1 then
        local main_class_content = [[package ]]
            .. package_name
            .. [[;

/**
 * Main application class for ]]
            .. artifact_id
            .. [[

 */
public class Main {
    public static void main(String[] args) {
        // Main application entry point
    }
}
]]
        utils.create_file(main_class_path, main_class_content)

        -- Optionally remove App.java - uncomment if you want to remove it
        -- vim.fn.delete(app_class_path)
      end

      utils.print_status("Maven project '" .. artifact_id .. "' created successfully at " .. project_path, true)
      return project_path
    else
      utils.print_status("Failed to create Maven project. Check your Maven installation.", false)
      return nil
    end
  else
    -- If Maven is not available, create a basic Maven project structure manually
    utils.print_status("Maven not found. Creating basic Maven structure manually...", true)

    -- Create directories properly with safe path handling
    local pkg_path = ""
    for part in string.gmatch(package_name, "[^%.]+") do
      if pkg_path == "" then
        pkg_path = part
      else
        pkg_path = safe_path_join(pkg_path, part)
      end
    end

    local src_main_java_path = safe_path_join(project_path, "src", "main", "java", pkg_path)
    local src_main_resources_path = safe_path_join(project_path, "src", "main", "resources")
    local src_test_java_path = safe_path_join(project_path, "src", "test", "java", pkg_path)
    local src_test_resources_path = safe_path_join(project_path, "src", "test", "resources")

    utils.create_directory(src_main_java_path)
    utils.create_directory(src_main_resources_path)
    utils.create_directory(src_test_java_path)
    utils.create_directory(src_test_resources_path)

    -- Create a pom.xml file
    local pom_content = [[<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
                      http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>]] .. group_id .. [[</groupId>
    <artifactId>]] .. artifact_id .. [[</artifactId>
    <version>]] .. version .. [[</version>

    <properties>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        <maven.compiler.source>]] .. M.config.default_java_version .. [[</maven.compiler.source>
        <maven.compiler.target>]] .. M.config.default_java_version .. [[</maven.compiler.target>
    </properties>

    <dependencies>
        <dependency>
            <groupId>junit</groupId>
            <artifactId>junit</artifactId>
            <version>4.13.2</version>
            <scope>test</scope>
        </dependency>
    </dependencies>
</project>
]]
    utils.create_file(safe_path_join(project_path, "pom.xml"), pom_content)

    -- Create a clean Main.java file
    local main_class_path = safe_path_join(src_main_java_path, "Main.java")
    local main_class_content = [[package ]]
        .. package_name
        .. [[;

/**
 * Main application class for ]]
        .. artifact_id
        .. [[

 */
public class Main {
    public static void main(String[] args) {
        // Main application entry point
    }
}
]]
    utils.create_file(main_class_path, main_class_content)

    -- Create a sample MainTest.java file
    local main_test_class_path = safe_path_join(src_test_java_path, "MainTest.java")
    local main_test_class_content = [[package ]]
        .. package_name
        .. [[;

import static org.junit.Assert.assertTrue;
import org.junit.Test;

/**
 * Unit test for Main class.
 */
public class MainTest {
    /**
     * Basic test method
     */
    @Test
    public void shouldAnswerWithTrue() {
        assertTrue(true);
    }
}
]]
    utils.create_file(main_test_class_path, main_test_class_content)

    -- Create a .gitignore file
    local gitignore_content = [[
# Maven specific
target/
pom.xml.tag
pom.xml.releaseBackup
pom.xml.versionsBackup
pom.xml.next
release.properties
dependency-reduced-pom.xml
buildNumber.properties
.mvn/timing.properties
.mvn/wrapper/maven-wrapper.jar

# IntelliJ IDEA
.idea/
*.iws
*.iml
*.ipr

# Eclipse
.classpath
.project
.settings/

# VS Code
.vscode/

# Compiled class files
*.class

# Log files
*.log

# Package files
*.jar
*.war
*.nar
*.ear
*.zip
*.tar.gz
*.rar

# OS specific files
.DS_Store
]]
    utils.create_file(safe_path_join(project_path, ".gitignore"), gitignore_content)

    utils.print_status("Maven project '" .. artifact_id .. "' created successfully at " .. project_path, true)
    return project_path
  end
end

-- Create a Maven project
function M.create_maven_project(project_name)
  project_name = project_name or M.config.default_artifact_id

  if has_nui and has_nui_input then
    -- If we have nui.nvim, use it via the start_maven_project function
    M.start_maven_project()
  else
    -- Prompt for Maven coordinates using basic vim.fn.input
    local group_id = vim.fn.input("Group ID [" .. M.config.default_group_id .. "]: ")
    group_id = group_id ~= "" and group_id or M.config.default_group_id

    local artifact_id = vim.fn.input("Artifact ID [" .. project_name .. "]: ")
    artifact_id = artifact_id ~= "" and artifact_id or project_name

    local package_name = vim.fn.input("Package name [" .. group_id .. "]: ")
    package_name = package_name ~= "" and package_name or group_id

    local version = vim.fn.input("Version [" .. M.config.default_version .. "]: ")
    version = version ~= "" and version or M.config.default_version

    M.create_maven_project_with_values(artifact_id, group_id, package_name, version)
  end
end

return M
