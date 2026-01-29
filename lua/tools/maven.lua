local M = {}

local function read_file(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local s = f:read("*a")
  f:close()
  return s
end

local function write_file(path, contents)
  local f = assert(io.open(path, "w"))
  f:write(contents)
  f:close()
end

local function file_exists(path)
  return vim.uv.fs_stat(path) ~= nil
end

local function dir_exists(path)
  local st = vim.uv.fs_stat(path)
  return st and st.type == "directory"
end

local function mkdirp(path)
  vim.fn.mkdir(path, "p")
end

local function trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function add_module_to_parent_pom(pom_path, module_dir)
  local xml = read_file(pom_path)
  if not xml then
    vim.notify("Parent pom.xml not found at: " .. pom_path, vim.log.levels.ERROR)
    return false
  end

  -- Already present?
  if xml:match("<module>%s*" .. vim.pesc(module_dir) .. "%s*</module>") then
    vim.notify("Module already listed in parent pom.xml: " .. module_dir)
    return true
  end

  if xml:find("<modules>") then
    -- Insert before </modules>
    xml = xml:gsub("</modules>", "    <module>" .. module_dir .. "</module>\n  </modules>", 1)
  else
    -- Create a <modules> block after </packaging> if present, else after <version>, else after <artifactId>
    local inserted = false
    local function try_insert(after_tag)
      if inserted then return end
      local pat = "(</" .. after_tag .. "%s*>)"
      if xml:find(pat) then
        xml = xml:gsub(pat,
          "%1\n  <modules>\n    <module>" .. module_dir .. "</module>\n  </modules>", 1)
        inserted = true
      end
    end

    try_insert("packaging")
    try_insert("version")
    try_insert("artifactId")

    if not inserted then
      vim.notify("Could not find a good insertion point in pom.xml", vim.log.levels.ERROR)
      return false
    end
  end

  write_file(pom_path, xml)
  return true
end

local function prune_missing_modules(pom_path, root)
  local xml = read_file(pom_path)
  if not xml then
    vim.notify("Could not read parent pom.xml", vim.log.levels.ERROR)
    return
  end

  local removed = {}
  local function repl(module_name)
    local mod = trim(module_name)
    local mod_path = root .. "/" .. mod
    if not dir_exists(mod_path) then
      table.insert(removed, mod)
      return "" -- remove the whole <module>...</module> line/block
    end
    return "<module>" .. mod .. "</module>"
  end

  -- remove missing modules (preserve existing ones)
  local new_xml = xml:gsub("<module>%s*([^<]+)%s*</module>", repl)

  if #removed > 0 then
    write_file(pom_path, new_xml)
    vim.notify("Pruned missing modules from parent pom.xml:\n- " .. table.concat(removed, "\n- "))
  else
    vim.notify("No missing <module> entries found.")
  end
end

local function run_cmd(cmd, cwd, on_exit)
  vim.notify("Running: " .. table.concat(cmd, " "))
  vim.fn.jobstart(cmd, {
    cwd = cwd,
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if data and #data > 1 then
        vim.notify(table.concat(data, "\n"))
      end
    end,
    on_stderr = function(_, data)
      if data and #data > 1 then
        vim.notify(table.concat(data, "\n"), vim.log.levels.WARN)
      end
    end,
    on_exit = function(_, code)
      if on_exit then on_exit(code) end
    end,
  })
end

local function infer_groupid_from_parent(pom_path)
  local xml = read_file(pom_path)
  if not xml then return "com.example" end

  -- Prefer the project's groupId if present, else parent groupId
  local gid = xml:match("<groupId>%s*([^<%s]+)%s*</groupId>")
  return gid or "com.example"
end

-- If user types artifactId with dots, using it as a folder name is awkward + easy to break parent reactor.
-- We'll keep artifactId as typed, but use a safe module directory name for <module>.
local function compute_module_dir(artifactId)
  local dir = artifactId:gsub("%.", "-")
  return dir
end

function M.new_module()
  local root = vim.fs.root(0, { "pom.xml", ".git" })
  if not root then
    vim.notify("Not in a Maven project (no pom.xml found in parents).", vim.log.levels.ERROR)
    return
  end

  local parent_pom = root .. "/pom.xml"
  if not file_exists(parent_pom) then
    vim.notify("Parent pom.xml not found at: " .. parent_pom, vim.log.levels.ERROR)
    return
  end

  -- Optional safety: remove broken module entries first (from earlier attempts)
  vim.ui.select({ "Skip", "Prune missing <module> entries first (recommended)" }, {
    prompt = "MavenNewModule: quick cleanup?",
  }, function(choice)
    if choice and choice:match("Prune") then
      prune_missing_modules(parent_pom, root)
    end

    local default_gid = infer_groupid_from_parent(parent_pom)

    vim.ui.input({ prompt = "New module artifactId (e.g. employee-db): " }, function(artifactId)
      if not artifactId or artifactId == "" then return end

      vim.ui.input({ prompt = "groupId (default: " .. default_gid .. "): " }, function(gid)
        gid = (gid and gid ~= "") and gid or default_gid

        local module_dir = compute_module_dir(artifactId)
        local target_dir = root .. "/" .. module_dir

        if dir_exists(target_dir) then
          vim.notify("Target module directory already exists: " .. target_dir, vim.log.levels.ERROR)
          return
        end

        -- Generate in a temp folder so Maven does NOT parse your parent reactor pom.xml
        local tmp = vim.fn.tempname()
        mkdirp(tmp)

        local archetype_dir = tmp

        local cmd = {
          "mvn", "-B",
          "archetype:generate",
          "-DinteractiveMode=false",
          "-DarchetypeGroupId=org.apache.maven.archetypes",
          "-DarchetypeArtifactId=maven-archetype-quickstart",
          "-DarchetypeVersion=1.4",
          "-DgroupId=" .. gid,
          "-DartifactId=" .. artifactId,
        }

        run_cmd(cmd, archetype_dir, function(code)
          if code ~= 0 then
            vim.notify("Module generation failed (exit " .. code .. "). Parent pom.xml was NOT modified.", vim.log.levels.ERROR)
            return
          end

          local generated_path = tmp .. "/" .. artifactId
          if not dir_exists(generated_path) then
            vim.notify("Expected generated module directory not found: " .. generated_path, vim.log.levels.ERROR)
            return
          end

          -- Move generated module into project root, using module_dir
          local ok = os.execute(string.format('mv %q %q', generated_path, target_dir))
          if ok ~= true and ok ~= 0 then
            vim.notify("Failed to move module into project: " .. target_dir, vim.log.levels.ERROR)
            return
          end

          -- Now (and only now) add it to <modules> in parent pom
          if not add_module_to_parent_pom(parent_pom, module_dir) then
            vim.notify("Failed to update parent pom.xml. Module dir exists though: " .. target_dir, vim.log.levels.ERROR)
            return
          end

          vim.notify("Created module: " .. module_dir .. " (artifactId=" .. artifactId .. ")\nAdded to parent pom.xml")

          -- Open the new module pom.xml
          local mod_pom = target_dir .. "/pom.xml"
          if file_exists(mod_pom) then
            vim.schedule(function()
              vim.cmd("edit " .. vim.fn.fnameescape(mod_pom))
            end)
          end
        end)
      end)
    end)
  end)
end

function M.prune_modules()
  local root = vim.fs.root(0, { "pom.xml", ".git" })
  if not root then
    vim.notify("Not in a Maven project (no pom.xml found in parents).", vim.log.levels.ERROR)
    return
  end
  local parent_pom = root .. "/pom.xml"
  prune_missing_modules(parent_pom, root)
end

return M
