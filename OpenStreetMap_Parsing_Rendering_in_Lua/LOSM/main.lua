--
-- Playing with LÖVE and OSM
-- Leandro Motta Barros
--

-- The global table of nodes, indexed by their IDs
Nodes = { }

-- The global table of ways, indexed by their IDs
Ways = { }

-- The global table of relations, indexed by their IDs
Relations = { }

-- The global table with the bounds of the file. After reading OSM
-- data, should have the following keys: minLat, minLon, maxLat,
-- maxLon.
FileBounds = { }

-- Stores the bounds of what is being viewed right now. In addition to
-- the fields present in 'FileBounds', this one contains these other
-- fields: deltaLat, deltaLon.
ViewBounds = { }

-- The window width, in pixels
WinWidth = 0

-- The window height, in pixels
WinHeight = 0

-- The mouse position at the previous frame
PrevMousePos = { }



-- Updates ViewBounds.deltaLat and ViewBounds.deltaLon based on the
-- other members of ViewBounds.
function UpdateViewBoundDeltas()
   ViewBounds.deltaLat = ViewBounds.maxLat - ViewBounds.minLat
   ViewBounds.deltaLon = ViewBounds.maxLon - ViewBounds.minLon
end



-- Parses the .osm file 'osmFile' and fills the global tables 'Nodes',
-- 'Ways', 'Relations' and 'Bounds' with the data read from
-- it. Assumes reasonably correct input; not much error detection is
-- performed. By the way, this is not a real XML parser, this is just
-- a quick hack that can read .osm files.
function ParseOSM(osmFile)

   -- Are we inside a <node>...</node>?
   local inNode = false

   -- Are we inside a <way>...</way>?
   local inWay = false

   -- The temporary variable holding the ID of the thing being processed
   local theID = { }

   -- The temporary variable holding a node with tags
   local theNode = { }

   -- The temporary variable holding a way
   local theWay = { }

   -- The temporary variable holding a relation
   local theRelation = { }


   -- Returns the value of the XML "property" 'prop' on string 's'.
   local function getXMLProperty(s, prop)
      return string.match(s, '[^%w]*'..prop..'="(.-)".*')
   end


   -- This table contain the regular expressions used to identify the
   -- "types" of lines in a .osm file, and the functions used to
   -- handle their processing. Put more common patters in the
   -- beginning of the table; this should make things faster.
   local patternsAndHandlers = {

      -- Node reference in way
      {
         '<nd.*ref="(.*)".*/>$',
         function(captures)
            if not inWay then
               return false, "Cannot deal with node reference outside a way"
            end

            table.insert(theWay.nodes, tonumber(captures[1]))

            return true
         end
      },

      -- Node without tags
      {
         '<node(.*)/>$',
         function(captures)
            local s = captures[1]
            local id = tonumber(getXMLProperty(s, 'id'))
            local node = {
               lat = tonumber(getXMLProperty(s, 'lat')),
               lon = tonumber(getXMLProperty(s, 'lon')),
               tags = { },
            }
            Nodes[id] = node

            return true
         end
      },

      -- Start of node with tags
      {
         '<node(.*)[^/]>$',
         function(captures)
            inNode = true
            local s = captures[1]
            theID = tonumber(getXMLProperty(s, 'id'))
            if Nodes[theID] ~= nil then
               return false, "There is already a node with id="..tostring(theID)
            end

            theNode = {
               lat = tonumber(getXMLProperty(s, 'lat')),
               lon = tonumber(getXMLProperty(s, 'lon')),
               tags = { },
            }

            return true
         end
      },

      -- Tag
      {
         '<tag(.*)/>$',
         function(captures)
            local s = captures[1]

            local k = getXMLProperty(s, "k")
            local v = getXMLProperty(s, "v")

            -- Node tag
            if inNode then
               theNode.tags[k] = v

            -- Way tag
            elseif inWay then
               theWay.tags[k] = v

            -- Relation tag
            elseif inRelation then
               theRelation.tags[k] = v

            -- Houston, we have a problem
            else
               return false, "Found a tag in an invalid element"
            end

            return true
         end
      },

      -- Start of way (always with tags -- or nodes, at least)
      {
         '<way(.*)[^/]>$',
         function(captures)
            inWay = true
            local s = captures[1]
            theID = tonumber(getXMLProperty(s, 'id'))

            if Ways[theID] ~= nil then
               return false, "There is already a way with id="..tostring(theID)
            end

            theWay = {
               nodes = { },
               tags = { },
            }

            return true
         end
      },

      -- End of way
      {
         '</way>$',
         function(captures)
            if not inWay then
               return false, "I cannot end a way that wasn't started"
            end

            inWay = false
            Ways[theID] = theWay
            theWay = { }

            return true
         end
      },


      -- End of node with tags
      {
         '</node>$',
         function(captures)
            if not inNode then
               return false, "I cannot end a node that wasn't started"
            end

            inNode = false
            Nodes[theID] = theNode
            theNode = { }

            return true
         end
      },

      -- Relation member
      {
         '<member(.*)/>$',
         function(captures)
            if not inRelation then
               return false,
               "Cannot add a member to something that is not a relation"
            end

            local s = captures[1]

            local type = getXMLProperty(s, "type")
            local ref = tonumber(getXMLProperty(s, "ref"))
            local role = getXMLProperty(s, "role")

            table.insert(theRelation.members, { type, ref, role })

            return true
         end
      },

      -- Start of relation
      {
         '<relation(.*)[^/]>$',
         function(captures)
            inRelation = true
            local s = captures[1]

            theID = tonumber(getXMLProperty(s, 'id'))

            if Relations[theID] ~= nil then
               return false, "There is already a relation with id="..tostring(theID)
            end


            theRelation = {
               members = { },
               tags = { },
            }

            return true
         end
      },


      -- End of relation
      {
         '</relation>$',
         function(captures)
            if not inRelation then
               return false, "I cannot end a relation that wasn't started"
            end

            inRelation = false
            Relations[theID] = theRelation
            theRelation = { }

            return true
         end
      },

      -- The OSM file bounds
      {
         '<bounds(.*)/>$',
         function(captures)
            local s = captures[1]
            FileBounds.minLat = tonumber(getXMLProperty(s, 'minlat'))
            FileBounds.minLon = tonumber(getXMLProperty(s, 'minlon'))
            FileBounds.maxLat = tonumber(getXMLProperty(s, 'maxlat'))
            FileBounds.maxLon = tonumber(getXMLProperty(s, 'maxlon'))
            return true
         end
      },

      -- The XML header
      {
         '<%?xml.*version="(.*)".*encoding="(.*)".*%?>$',
         function(captures)
            if captures[1] ~= "1.0" then
               return false, "I can't handle XML version "..captures[1]
                  ..". I only know XML 1.0."
            elseif captures[2] ~= "UTF-8" then
               return false, "I can't handle encoding "..captures[2]
                  ..". I only know UTF-8."
            else
               return true
            end
         end
      },

      -- The opening root element 'osm'
      {
         '<osm.*version="(.-)".*>$',
         function(captures)
            if captures[1] ~= "0.6" then
               return false, "I can't handle OSM version "..captures[1]
                  ..". I only know OSM version 0.6."
            else
               return true
            end
         end
      },

      -- The closing root element 'osm'
      {
         '</osm>$',
         function(captures)
            return true
         end
      },

      -- Catch-all case, for error detection
      {
         '.*',
         function(captures)
            return false, "I don't understand this line at all."
         end
      },
   }


   -- The ParseOSM() function itself
   local lineNum = 0
   for line in io.lines(osmFile) do
      lineNum = lineNum + 1
      for k, v in ipairs(patternsAndHandlers) do
         local pattern = v[1]
         local handler = v[2]
         assert(pattern, "patternsAndHandlers["
                ..tostring(k).."[1] does not contain a valid pattern.")
         assert(type(handler) == "function", "patternsAndHandlers["
                ..tostring(k).."[2] does not contain a valid function.")

         local captures = { string.match(line, pattern) }
         if #captures > 0 then
            local status, msg = handler(captures)
            if status then
               break
            else
               print("I found an error while processing line number "
                     ..tostring(lineNum)..":")
               print(line)
               print(msg)
               return false
            end
         end
      end
   end

   -- Initialize ViewBounds with the values as FileBounds adjusted to
   -- have the same aspect ratio as the window
   ViewBounds.minLat = FileBounds.minLat
   ViewBounds.minLon = FileBounds.minLon
   ViewBounds.maxLat = FileBounds.maxLat
   ViewBounds.maxLon = FileBounds.maxLon
   UpdateViewBoundDeltas()

   local winAspectRatio = WinWidth / WinHeight
   local viewAspectRatio = ViewBounds.deltaLat / ViewBounds.deltaLon

   if viewAspectRatio > winAspectRatio then
      local newDeltaLon = ViewBounds.deltaLat * winAspectRatio
      local amountToMove = (ViewBounds.deltaLon - newDeltaLon) / 2

      ViewBounds.minLon = ViewBounds.minLon + amountToMove
      ViewBounds.maxLon = ViewBounds.maxLon - amountToMove
   elseif viewAspectRatio < winAspectRatio then
      local newDeltaLat = ViewBounds.deltaLon / winAspectRatio
      local amountToMove = (ViewBounds.deltaLat - newDeltaLat) / 2

      ViewBounds.minLat = ViewBounds.minLat + amountToMove
      ViewBounds.maxLat = ViewBounds.maxLat - amountToMove
   end

   -- Update deltas
   UpdateViewBoundDeltas()

   -- Voilà
   return true

end



--
-- Project the given coordinates to window coordinates. The current
-- implementation does not do a real cartographic projection: it
-- simply uses the longitude and latitude as x and y coordinates
-- directly.
--
function Project(lat, lon)
   local xScale = WinWidth / ViewBounds.deltaLon
   local yScale = WinHeight / ViewBounds.deltaLat

   return (lon - ViewBounds.minLon) * xScale,
          WinHeight - ((lat - ViewBounds.minLat) * yScale)
end



-- Draw a way. The current color, current line style and current
-- everything else is used
function DrawWay(way)
   local points = { }

   for k, v in pairs(way.nodes) do
      local node = Nodes[v]
      local x, y = Project(node.lat, node.lon)
      table.insert(points, x)
      table.insert(points, y)
   end

   love.graphics.line(points)
end



-- Called by LÖVE when the program is loaded. Initializes a few things
-- and parses the input .osm file.
function love.load()

   if #arg ~= 2 then
      print("You must pass the .osm file as a command-line parameter.")
      love.event.push("q")
      return
   end

   WinWidth = love.graphics.getWidth()
   WinHeight = love.graphics.getHeight()
   PrevMousePos = { love.mouse.getPosition() }

   if not ParseOSM(arg[2]) then
      love.event.push("q")
   end
end



-- Called by LÖVE every frame, so that we can update things. Handles
-- mouse moves (panning on the map, specifically).
function love.update()
   local currMousePos = { love.mouse.getPosition() }
   local deltaMouse = {
      PrevMousePos[1] - currMousePos[1],
      PrevMousePos[2] - currMousePos[2]
   }

   if love.mouse.isDown("m") then
      local deltaXScreenPercent = deltaMouse[1] / WinWidth
      local deltaYScreenPercent = deltaMouse[2] / WinHeight
      local addToLon = ViewBounds.deltaLon * deltaXScreenPercent
      local addToLat = ViewBounds.deltaLat * -deltaYScreenPercent

      ViewBounds.minLat = ViewBounds.minLat + addToLat
      ViewBounds.maxLat = ViewBounds.maxLat + addToLat
      ViewBounds.minLon = ViewBounds.minLon + addToLon
      ViewBounds.maxLon = ViewBounds.maxLon + addToLon
   end

   PrevMousePos = currMousePos
end



-- Called by LÖVE every frame; this is the place where rendering occurs.
function love.draw()
   love.graphics.setColor(200, 200, 255, 127)

   for k, v in pairs(Nodes) do
      local x, y = Project(v.lat, v.lon)
      love.graphics.point(x, y)
   end

   love.graphics.setColor(200, 255, 200, 63)

   for k, v in pairs(Ways) do
      DrawWay(v)
   end


   local x1, y1 = Project(FileBounds.minLat, FileBounds.minLon)
   local x2, y2 = Project(FileBounds.maxLat, FileBounds.maxLon)

   local sx, sy = x2 - x1, y2 - y1
   love.graphics.setColor(255, 100, 100, 200)
   love.graphics.rectangle("line", x1, y1, sx, sy)


   x1, y1 = Project(ViewBounds.minLat, ViewBounds.minLon)
   x2, y2 = Project(ViewBounds.maxLat, ViewBounds.maxLon)

   sx, sy = x2 - x1, y2 - y1
   love.graphics.setColor(255, 255, 100, 200)
   love.graphics.rectangle("line", x1, y1, sx, sy)
end



-- Called by LÖVE whenever a mouse button (including the mouse wheel)
-- is pressed. Handles zooming.
function love.mousepressed(x, y, button)
   local scale = 1.1
   local aspectRatio = ViewBounds.deltaLon / ViewBounds.deltaLat

   local newDeltaLon = ViewBounds.deltaLon
   local newDeltaLat = ViewBounds.deltaLat

   if button == "wu" or button == "wd" then
      if button == "wu" then
         newDeltaLon = ViewBounds.deltaLon * scale
         newDeltaLat = ViewBounds.deltaLat * scale
      else
         newDeltaLon = ViewBounds.deltaLon / scale
         newDeltaLat = ViewBounds.deltaLat / scale
      end

      local addToLon = newDeltaLon - ViewBounds.deltaLon
      local addToLat = newDeltaLat - ViewBounds.deltaLat

      local tx, ty = x/WinWidth, y/WinHeight
      local ux, uy = 1 - tx, 1 - ty

      ViewBounds.minLon = ViewBounds.minLon + addToLon * tx
      ViewBounds.maxLon = ViewBounds.maxLon - addToLon * ux

      ViewBounds.minLat = ViewBounds.minLat + addToLat * uy
      ViewBounds.maxLat = ViewBounds.maxLat - addToLat * ty

      UpdateViewBoundDeltas()
   end
end
