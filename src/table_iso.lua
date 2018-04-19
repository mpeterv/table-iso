local table_iso = {}

table_iso.version = "0.1.0"

local function add_table_values(table_values, t)
   if type(t) ~= "table" or table_values[t] then
      return
   end

   local id = #table_values + 1
   table_values[id] = t
   table_values[t] = id

   for key, value in pairs(t) do
      add_table_values(table_values, key)
      add_table_values(table_values, value)
   end
end

local function reverse_postorder(table_values)
   local graph = {}

   for _, t in ipairs(table_values) do
      for k, v in pairs(t) do
         if type(k) == "table" then
            graph[k] = graph[k] or {}
            graph[k][t] = true
         end

         if type(v) == "table" then
            graph[v] = graph[v] or {}
            graph[v][t] = true
         end
      end
   end

   local postorder = {}
   local visited = {}

   local function visit(t)
      if visited[t] then
         return
      end

      visited[t] = true

      for including_table in pairs(graph[t] or {}) do
         visit(including_table)
      end

      table.insert(postorder, t)
   end

   for _, t in ipairs(table_values) do
      visit(t)
   end

   local new_table_values = {}

   for index = #postorder, 1, -1 do
      local id = #postorder - index + 1
      local value = postorder[index]
      new_table_values[id] = value
      new_table_values[value] = id
   end

   return new_table_values
end

-- Returns a table mapping all unique tables within `t` to consecutive positive integer ids and back.
local function get_table_values(t)
   local table_values = {}
   add_table_values(table_values, t)
   return reverse_postorder(table_values)
end

local function intersect(set1, set2)
   if not set1 then
      set1 = {}

      for key in pairs(set2) do
         set1[key] = true
      end
   else
      for key in pairs(set1) do
         if not set2[key] then
            set1[key] = true
         end
      end
   end

   return set1
end

-- Standard deep comparison algorithms don't recurse into table keys or consider structural identity.
-- Two tables `root1 and `root2` are considered structurally identical (isomorphic) iff there is a bijection `F`
-- between sets of tables found within the two tables with the following property:
-- let `F'` be `F` for tables and identity for other values; for each table `t` found within the first table for
-- each key-value pair `[k] = v` in `t` `F(t)` must have key-value pair `[F'(k)] = F'(v)` and have no other
-- key-value pairs. Additionally, `F(root1)` must be `root2`.
function table_iso.check_iso(root1, root2, opts)
   opts = opts or {}

   -- Gather some restrictions on which tables can be mapped to which.
   -- `candidates1` maps tables within `t1` to sets of candidates within `t2`, or to `nil` if mapping is not restricted.
   -- `candidates2` does the inverse.
   local candidates1 = {}
   local candidates2 = {}

   local forced_mappings = {}

   -- Ensure that `t1` is mapped to `t2`.
   -- Optionally restrict candidate sets accordingly.
   -- Arguments don't have to be tables, in which case their equality is checked.
   -- Returns `true` if mapping succeeded, `false` otherwise.
   local function force_mapping(t1, t2, do_restrict_candidates)
      if type(t1) ~= "table" or type(t2) ~= "table" then
         -- Handle NaN.
         return t1 ~= t1 and t2 ~= t2 or t1 == t2
      end

      if forced_mappings[t1] then
         return forced_mappings[t1] == t2
      end

      forced_mappings[t1] = t2

      if do_restrict_candidates then
         if candidates1[t1] and not candidates1[t1][t2] then
            return false
         end

         candidates1[t1] = {[t2] = true}

         if candidates2[t2] and not candidates2[t2][t1] then
            return false
         end

         candidates2[t2] = {[t1] = true}
      end

      local table_keys1 = {}
      local num_table_keys1 = 0
      local table_key_table_values1 = {}
      local num_table_key_table_values1 = 0

      local table_keys2 = {}
      local num_table_keys2 = 0
      local table_key_table_values2 = {}
      local num_table_key_table_values2 = 0

      for key1, value1 in pairs(t1) do
         if type(key1) == "table" then
            table_keys1[key1] = true
            num_table_keys1 = num_table_keys1 + 1

            if type(value1) == "table" then
               table_key_table_values1[value1] = true
               num_table_key_table_values1 = num_table_key_table_values1 + 1
            end
         elseif not force_mapping(value1, t2[key1], true) then
            -- Simple key in `t1` must have a mapping value in `t2`.
            return false
         end
      end

      for key2, value2 in pairs(t2) do
         if type(key2) == "table" then
            table_keys2[key2] = true
            num_table_keys2 = num_table_keys2 + 1

            if type(value2) == "table" then
               table_key_table_values2[value2] = true
               num_table_key_table_values2 = num_table_key_table_values2 + 1
            end
         elseif t1[key2] == nil then
            -- Simple key present only in `t2`, can't map.
            return false
         end
      end

      -- Tables within `table_keys1` and `table_keys2` must all map to each other in pairs.
      if num_table_keys1 ~= num_table_keys2 then
         return false
      end

      for v1 in pairs(table_keys1) do
         candidates1[v1] = intersect(candidates1[v1], table_keys2)
      end

      for v2 in pairs(table_keys2) do
         candidates2[v2] = intersect(candidates2[v2], table_keys1)
      end

      -- Same for table values of table keys.
      if num_table_key_table_values1 ~= num_table_key_table_values2 then
         return false
      end

      for v1 in pairs(table_key_table_values1) do
         candidates1[v1] = intersect(candidates1[v1], table_key_table_values2)
      end

      for v2 in pairs(table_key_table_values2) do
         candidates2[v2] = intersect(candidates2[v2], table_key_table_values1)
      end

      -- Check if any candidate sets reduced to less than 2 elements.
      for _, set1 in ipairs({table_keys1, table_key_table_values1}) do
         for v1 in pairs(set1) do
            local first_candidate = next(candidates1[v1])

            if not first_candidate then
               return false
            elseif not next(candidates1[v1], first_candidate) then
               if not force_mapping(v1, first_candidate, false) then
                  return false
               end
            end
         end
      end

      for _, set2 in ipairs({table_keys2, table_key_table_values2}) do
         for v2 in pairs(set2) do
            local first_candidate = next(candidates2[v2])

            if not first_candidate then
               return false
            elseif not next(candidates2[v2], first_candidate) then
               if not force_mapping(first_candidate, v2, false) then
                  return false
               end
            end
         end
      end

      return true
   end

   if not force_mapping(root1, root2) then
      return false
   end

   local table_values1 = get_table_values(root1)
   local table_values2 = get_table_values(root2)

   if #table_values1 ~= #table_values2 then
      return false
   end

   local ordered_candidates1 = {}
   local not_candidate_values2 = {}

   for _, value2 in ipairs(table_values2) do
      not_candidate_values2[value2] = true
   end

   for id1, value1 in ipairs(table_values1) do
      if candidates1[value1] then
         ordered_candidates1[id1] = {}

         for candidate in pairs(candidates1[value1]) do
            not_candidate_values2[candidate] = nil
            table.insert(ordered_candidates1[id1], candidate)
         end
      end
   end

   local ordered_not_canditate_values2 = {}

   for value2 in pairs(not_candidate_values2) do
      table.insert(ordered_not_canditate_values2, value2)
   end

   for id1, value1 in ipairs(table_values1) do
      if not candidates1[value1] then
         ordered_candidates1[id1] = ordered_not_canditate_values2
      end
   end

   local selected_candidate_indexes = {}

   for i = 1, #table_values1 do
      selected_candidate_indexes[i] = 1
   end

   local function verify_mapping()
      local used_values2 = {}

      for id1 = 1, #table_values1 do
         local t2 = ordered_candidates1[id1][selected_candidate_indexes[id1]]

         if used_values2[t2] then
            return false, id1
         end

         used_values2[t2] = true
      end

      for id1, t1 in ipairs(table_values1) do
         local t2 = ordered_candidates1[id1][selected_candidate_indexes[id1]]

         -- Index of the last mapping that is required to prove that the mapping is invalid.
         local min_bad_mapping_id
         local invalid

         for key1, value1 in pairs(t1) do
            local max_pair_mapping_id

            if type(key1) == "table" then
               local key1_id = table_values1[key1]
               key1 = ordered_candidates1[key1_id][selected_candidate_indexes[key1_id]]
               max_pair_mapping_id = key1_id
            end

            if type(value1) == "table" then
               local value1_id = table_values1[value1]
               value1 = ordered_candidates1[value1_id][selected_candidate_indexes[value1_id]]
               max_pair_mapping_id = max_pair_mapping_id and math.max(max_pair_mapping_id, value1_id) or value1_id
            end

            local value2 = t2[key1]

            -- Handle NaN.
            if value1 ~= value2 and (value1 == value1 or value2 == value2) then
               invalid = true

               if max_pair_mapping_id then
                  min_bad_mapping_id = min_bad_mapping_id and math.min(min_bad_mapping_id, max_pair_mapping_id) or
                     max_pair_mapping_id
               else
                  min_bad_mapping_id = nil
               end
            end
         end

         if invalid then
            return false, min_bad_mapping_id and math.max(id1, min_bad_mapping_id) or id1
         end
      end

      return true
   end

   local attempts = 0

   while true do
      attempts = attempts + 1
      local ok, bad_mapping_id = verify_mapping()

      if ok then
         return true, true
      end

      if opts.max_attempts and attempts > opts.max_attempts then
         return true, false
      end

      local have_next

      for id1 = bad_mapping_id + 1, #table_values1 do
         selected_candidate_indexes[id1] = 1
      end

      for id1 = bad_mapping_id, 1, -1 do
         if selected_candidate_indexes[id1] < #ordered_candidates1[id1] then
            selected_candidate_indexes[id1] = selected_candidate_indexes[id1] + 1
            have_next = true
            break
         else
            selected_candidate_indexes[id1] = 1
         end
      end

      if not have_next then
         return false
      end
   end
end

return table_iso
