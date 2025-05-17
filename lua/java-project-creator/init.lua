-- java-project-creator/init.lua
-- A Neovim plugin for creating Java projects with structures similar to Eclipse IDE
-- and Maven projects

-- Check if nui.nvim is available
local has_nui, nui = pcall(require, "nui.menu")
local has_nui_input = pcall(require, "nui.input")
local has_nui_popup = pcall(require, "nui.popup")

local utils = require("java-project-creator.utils")

local M = {}

-- Configuration with default values
M.config = {
  base_path = vim.fn.getcwd(), -- Default to current directory
  default_java_version = "11",  -- Default Java version
  default_group_id = "com.example", -- Default group ID for Maven projects
  default_artifact_id = "app", -- Default artifact ID for Maven projects
  default_version = "1.0-SNAPSHOT", -- Default version for Maven projects
  maven_cmd = "mvn", -- Command to execute Maven
  -- Keybinding options
  keymaps = {
    new_java_project = "<localleader>njp",
    new_maven_project = "<localleader>nmp"
  }
}

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
  
  -- Create user commands
  vim.api.nvim_create_user_command("JavaCreateProject", function(args)
    M.create_java_project(args.args)
  end, {
    nargs = "?",
    desc = "Create a new Java project with Eclipse-like structure",
    complete = "dir"
  })
  
  vim.api.nvim_create_user_command("MavenCreateProject", function(args)
    M.create_maven_project(args.args)
  end, {
    nargs = "?",
    desc = "Create a new Maven project",
    complete = "dir"
  })
  
  -- Set up keymappings
  vim.api.nvim_set_keymap('n', M.config.keymaps.new_java_project, 
    ':lua require("java-project-creator").start_java_project()<CR>', 
    { noremap = true, silent = true, desc = "Create new Java project" })
  
  vim.api.nvim_set_keymap('n', M.config.keymaps.new_maven_project, 
    ':lua require("java-project-creator").start_maven_project()<CR>', 
    { noremap = true, silent = true, desc = "Create new Maven project" })
end

-- NUI integration for project creation
function M.start_java_project()
  if not has_nui or not has_nui_input or not has_nui_popup then
    utils.print_status("nui.nvim is required for the interactive menu. Using prompt fallback.", false)
    local project_name = vim.fn.input("Enter project name: ")
    if project_name and project_name ~= "" then
      M.create_java_project(project_name)
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
    default_value = "JavaProject",
    on_submit = function(value)
      if value and value ~= "" then
        M.create_java_project(value)
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
    default_value = M.config.default_artifact_id,
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
                M.create_maven_project_with_values(artifact_id, group_id, version)
              end,
            })
            
            version_input:mount()
          end,
        })
        
        group_id_input:mount()
      end
    end,
  })
  
  project_name_input:mount()
end

-- Create a basic Java project with Eclipse-like structure
function M.create_java_project(project_name)
  project_name = project_name or "JavaProject"
  
  -- Create project directory structure
  local project_path = M.config.base_path .. "/" .. project_name
  local src_path = project_path .. "/src"
  local bin_path = project_path .. "/bin"
  local lib_path = project_path .. "/lib"
  
  -- Create directories
  utils.print_status("Creating project structure...", true)
  utils.create_directory(src_path)
  utils.create_directory(bin_path)
  utils.create_directory(lib_path)
  
  -- Create a sample .classpath file (Eclipse style)
  local classpath_content = [[<?xml version="1.0" encoding="UTF-8"?>
<classpath>
	<classpathentry kind="src" path="src"/>
	<classpathentry kind="con" path="org.eclipse.jdt.launching.JRE_CONTAINER/org.eclipse.jdt.internal.debug.ui.launcher.StandardVMType/JavaSE-]] .. M.config.default_java_version .. [["/>
	<classpathentry kind="output" path="bin"/>
</classpath>
]]
  utils.create_file(project_path .. "/.classpath", classpath_content)
  
  -- Create a sample .project file (Eclipse style)
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
  utils.create_file(project_path .. "/.project", project_content)
  
  -- Create a sample Main.java file
  local main_class_path = src_path .. "/Main.java"
  local main_class_content = [[
public class Main {
    public static void main(String[] args) {
        System.out.println("Hello from ]] .. project_name .. [[");
    }
}
]]
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
  utils.create_file(project_path .. "/.gitignore", gitignore_content)
  
  -- Print success message
  utils.print_status("Java project '" .. project_name .. "' created successfully at " .. project_path, true)
  
  -- Return the project path in case it's needed
  return project_path
end

-- Create Maven project with provided values
function M.create_maven_project_with_values(artifact_id, group_id, version)
  -- Project directory
  local project_path = M.config.base_path .. "/" .. artifact_id
  
  -- If Maven is available, use it to generate the project
  if vim.fn.executable(M.config.maven_cmd) == 1 then
    utils.print_status("Creating Maven project with " .. M.config.maven_cmd .. "...", true)
    
    local maven_cmd = M.config.maven_cmd .. 
                      " archetype:generate" .. 
                      " -DgroupId=" .. group_id .. 
                      " -DartifactId=" .. artifact_id .. 
                      " -Dversion=" .. version .. 
                      " -DarchetypeArtifactId=maven-archetype-quickstart" ..
                      " -DarchetypeVersion=1.4" ..
                      " -DinteractiveMode=false"
    
    vim.fn.system(maven_cmd)
    
    if vim.v.shell_error == 0 then
      utils.print_status("Maven project '" .. artifact_id .. "' created successfully at " .. project_path, true)
      return project_path
    else
      utils.print_status("Failed to create Maven project. Check your Maven installation.", false)
      return nil
    end
  else
    -- If Maven is not available, create a basic Maven project structure manually
    utils.print_status("Maven not found. Creating basic Maven structure manually...", true)
    
    -- Create directories
    local src_main_java_path = project_path .. "/src/main/java/" .. group_id:gsub("%.", "/")
    local src_main_resources_path = project_path .. "/src/main/resources"
    local src_test_java_path = project_path .. "/src/test/java/" .. group_id:gsub("%.", "/")
    local src_test_resources_path = project_path .. "/src/test/resources"
    
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
    utils.create_file(project_path .. "/pom.xml", pom_content)
    
    -- Create a sample App.java file
    local app_class_path = src_main_java_path .. "/App.java"
    local app_class_content = [[package ]] .. group_id .. [[;

/**
 * Hello world!
 */
public class App {
    public static void main(String[] args) {
        System.out.println("Hello World!");
    }
}
]]
    utils.create_file(app_class_path, app_class_content)
    
    -- Create a sample AppTest.java file
    local app_test_class_path = src_test_java_path .. "/AppTest.java"
    local app_test_class_content = [[package ]] .. group_id .. [[;

import static org.junit.Assert.assertTrue;
import org.junit.Test;

/**
 * Unit test for simple App.
 */
public class AppTest {
    /**
     * Rigorous Test :-)
     */
    @Test
    public void shouldAnswerWithTrue() {
        assertTrue(true);
    }
}
]]
    utils.create_file(app_test_class_path, app_test_class_content)
    
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
    utils.create_file(project_path .. "/.gitignore", gitignore_content)
    
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
    
    local version = vim.fn.input("Version [" .. M.config.default_version .. "]: ")
    version = version ~= "" and version or M.config.default_version
    
    M.create_maven_project_with_values(artifact_id, group_id, version)
  end
end

return M
