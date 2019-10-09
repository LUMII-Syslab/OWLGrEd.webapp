function string.scoreForAbbreviation(self, abbreviation)
  if abbreviation:len() == 0 then -- deduct some points for all remaining letters
    return 0.9
  end
  if abbreviation:len() > self:len() then
    return 0.0
  end
  
  for i = abbreviation:len(), 1, -1 do -- search for steadily smaller portions of the abbreviation
    local sub_abbreviation = abbreviation:sub(1, i)
    local match_location = self:lower():find(sub_abbreviation:lower()) -- ignore case
    
    if match_location and (match_location + abbreviation:len() - 1 <= self:len()) then
      local next_string       = self:sub(match_location + sub_abbreviation:len())
      local next_abbreviation = abbreviation:sub(i + 1)
            
      -- search what is left of the string with the rest of the abbreviation
      local remaining_score   = next_string:scoreForAbbreviation(next_abbreviation)

      if remaining_score > 0 then
        local score = self:len() - next_string:len()
        
        -- ignore skipped characters if is first letter of a word
        if match_location > 1 then -- if some letters were skipped
          local j = 1
          
          if self:sub(match_location - 1, match_location - 1):find("%s") then
            for j = match_location - 2, 1, -1 do
              if self:sub(j, j):find("%s") then
                score = score - 1.0
              else
                score = score - 0.15
              end
            end
          elseif self:sub(match_location, match_location):find("%L") then
            for j = match_location - 1, 1, -1 do
              if self:sub(j, j):find("%L") then
                score = score - 1.0
              else
                score = score - 0.15
              end
            end
          else 
            score = score - (match_location - 1)
          end
        end
   
        score = score + remaining_score * next_string:len()
        score = score / self:len()
        return score
      end
    end
  end
  return 0.0
end