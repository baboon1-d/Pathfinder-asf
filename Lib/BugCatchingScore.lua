-- Daily contest rules: https://wiki.pokemonrevolution.net/Bug_Catching_Area
-- Base HP: current PROProtocol/Resources/PokemonData.json (not encounter HP).
local M = {}
local bonus = {50, 75, 100, 130}
local data = {
    Caterpie={1,45}, Ledyba={1,40}, Paras={1,35}, Spinarak={1,40},
    Venonat={1,60}, Wurmple={1,45},
    Combee={2,30}, Illumise={2,65}, Kricketot={2,37}, Scatterbug={2,38},
    Volbeat={2,65}, Yanma={2,65},
    Burmy={3,40}, Dwebble={3,50}, Joltik={3,50}, Nincada={3,31},
    Cutiefly={4,40}, Heracross={4,80}, Larvesta={4,55}, Pinsir={4,65}, Scyther={4,70}, Grubbin={3,47},
}

local function integer(n, low, high)
    return type(n) == "number" and n == math.floor(n) and n >= low and n <= high
end

function M.species(name)
    local p = data[name]
    if p then return {tier=p[1], baseHP=p[2], bonus=bonus[p[1]]} end
end

-- Wild EV=0 assumption. Rounding often leaves several possible IVs, especially
-- at low levels. Use MAX HP, never current HP after False Swipe or damage.
function M.hpIV(name, level, maxHP)
    local p = M.species(name)
    if not p then return nil, "unknown species/base HP" end
    if not integer(level, 1, 100) or not integer(maxHP, 1, 10000) then
        return nil, "invalid level/max HP"
    end
    local low, high
    for iv=0,31 do
        local hp = math.floor((2 * p.baseHP + iv) * level / 100) + level + 10
        if hp == maxHP then low = low or iv; high = iv end
    end
    if not low then return nil, "HP does not fit base HP + wild EV=0" end
    return {min=low, max=high}
end

-- Rank observed wild HP within the possible EV=0 HP span for THIS species and
-- level, not raw HP across different species/levels. 1 = highest HP bucket;
-- it can include several IVs, so it does NOT prove that the actual IV is 31.
function M.hpRank(name, level, maxHP)
    local range, reason = M.hpIV(name, level, maxHP)
    if not range then return nil, reason end
    local p = M.species(name)
    local lowHP = math.floor(2 * p.baseHP * level / 100) + level + 10
    local topHP = math.floor((2 * p.baseHP + 31) * level / 100) + level + 10
    local span = topHP - lowHP
    return {min=range.min, max=range.max, topHP=topHP,
        weight=span == 0 and 1 or (maxHP-lowHP)/span, isTop=maxHP == topHP}
end

function M.score(name, level, totalIV, shiny)
    local p = M.species(name)
    if not p then return nil, "unknown contest tier" end
    if not integer(level, 1, 100) or not integer(totalIV, 0, 186) then
        return nil, "invalid level/total IV"
    end
    return (math.min(level, 25) + totalIV + p.bonus) * (shiny and 1.5 or 1)
end

-- The other FIVE IVs remain unknown (0..155), NOT inferred from HP IV.
function M.bounds(name, level, hpIV, shiny)
    if not hpIV or not integer(hpIV.min, 0, 31)
            or not integer(hpIV.max, hpIV.min, 31) then return nil end
    local low = M.score(name, level, hpIV.min, shiny)
    local high = M.score(name, level, hpIV.max + 155, shiny)
    if low and high then return {min=low, max=high} end
end

return M
