local core = ScootsProgressBar.core
local options = ScootsProgressBar.options
local frames = ScootsProgressBar.frames
local interface
local utility = ScootsProgressBar.utility
local lookup = ScootsProgressBar.lookup

interface = {
    ['build'] = function()
        if(interface.built ~= nil) then
            return
        end
        
        frames.cursorIntercept = CreateFrame('Frame', 'ScootsProgressBar-CursorIntercept', UIParent)
        frames.cursorIntercept:SetPoint('TOPLEFT', frames.main, 'TOPLEFT', 0, 0)
        frames.cursorIntercept:SetPoint('BOTTOMRIGHT', frames.main, 'BOTTOMRIGHT', 0, 0)
        frames.cursorIntercept:SetFrameLevel(frames.main:GetFrameLevel() + 1)
		frames.cursorIntercept:RegisterForDrag('LeftButton')
        
		frames.main:SetMovable(true)
        
        frames.cursorIntercept:SetScript('OnMouseUp', function(self, mouseButton)
            if(mouseButton == 'LeftButton') then
                if(IsShiftKeyDown() and options.get('freetimer-enabled')) then
                    core.startTimer()
                else
                    core.cycleActive()
                    
                    if(options.get('tooltip-display') == 'visible') then
                        frames.main:GetScript('OnLeave')()
                        frames.main:GetScript('OnEnter')()
                    end
                end
            elseif(mouseButton == 'RightButton') then
                if(IsShiftKeyDown() and options.get('freetimer-enabled')) then
                    core.stopTimer()
                else
                    options.open()
                end
            end
        end)

		frames.cursorIntercept:SetScript('OnDragStart', function(self)
			if(options.get('allow-dragging')) then
                frames.main.isDragging = true
				frames.main:StartMoving()
			end
		end)
        
		frames.cursorIntercept:SetScript('OnDragStop', function(self)
            frames.main.isDragging = nil
			frames.main:StopMovingOrSizing()
		end)
        
		frames.cursorIntercept:SetScript('OnEnter', function(self)
            if(options.get('show-text') == 'hover') then
                for key, _ in pairs(frames.bars) do
                    frames.bars[key].text:Show()
                end
            end
            
            if(options.get('tooltip-display') ~= 'none') then
                GameTooltip:SetOwner(UIParent, 'ANCHOR_CURSOR_RIGHT')
                
                GameTooltip:AddDoubleLine(ScootsProgressBar.title, ScootsProgressBar.version, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 0.6, 0.98, 0.6)
                GameTooltip:AddLine(' ', nil, nil, nil, true)
                
                core.attachTooltipInfo()
                
                if(utility.isBarValid('freetimer') or utility.getActiveBar() == 'freetimer') then
                    GameTooltip:AddLine(' ', nil, nil, nil, true)
                    utility.addTooltipDoubleLine('Shift + left click', 'Start timer')
                    utility.addTooltipDoubleLine('Shift + right click', 'Stop timer')
                end
                
                GameTooltip:AddLine(' ', nil, nil, nil, true)
                
                if(options.get('mode') == 'single' and utility.countActiveBars() > 1) then
                    utility.addTooltipDoubleLine('Left click', 'Show next bar')
                end
                
                utility.addTooltipDoubleLine('Right click', 'Open options menu')
                
                GameTooltip:Show()
            end
		end)
        
		frames.cursorIntercept:SetScript('OnLeave', function(self)
            if(options.get('show-text') == 'hover') then
                for key, _ in pairs(frames.bars) do
                    frames.bars[key].text:Hide()
                end
            end
            
            if(options.get('tooltip-display') ~= 'none') then
                core.tooltipFontStrings = nil
                GameTooltip_Hide(self)
            end
		end)
        
        frames.overlay = CreateFrame('Frame', 'ScootsProgressBar-Overlay', frames.main)
        frames.overlay:SetAllPoints()
        frames.overlay:SetFrameLevel(frames.main:GetFrameLevel() + 1)
        
        interface.attachBordersToFrame(frames.overlay)
        
        frames.overlay.segments = {}
        
        for _, optionKey in ipairs({
            'pos-anchor',
            'strata',
            'width',
            'clamp-to-screen',
            'show-text',
            'text-size',
            'non-interactive',
            'borders',
            'overall-opacity',
        }) do
            interface.applyVisualGeneralOption(optionKey)
        end
        
        interface.built = true
    end,
    ['mainFrameInterfaceLoop'] = function(self)
        if(self.isDragging) then
            local _, _, anchor, x, y = self:GetPoint()
            
            options.set('pos-x', tonumber(string.format('%.1f', x)), true)
            options.set('pos-y', tonumber(string.format('%.1f', y)), true)
            options.set('pos-anchor', anchor, true)
        end
    end,
    ['applyVisualGeneralOption'] = function(key)
        if(key == 'pos-x' or key == 'pos-y' or key == 'pos-anchor') then
            frames.main:ClearAllPoints()
            frames.main:SetPoint(options.get('pos-anchor'), UIParent, options.get('pos-anchor'), options.get('pos-x'), options.get('pos-y'))
            
            return true
        end
        
        if(key == 'width' or key == 'height') then
            interface.applyDimensions()
        
            if(interface.built) then
                interface.renderBarValues()
                interface.setBarPositions()
                interface.setBorderPositions()
                interface.drawSegments()
            end
        
            return true
        end
        
        if(key == 'clamp-to-screen') then
            frames.main:SetClampedToScreen(options.get('clamp-to-screen'))
            return true
        end
        
        if(key == 'show-text') then
            for _, bar in pairs(frames.bars) do
                if(options.get('show-text') == 'always') then
                    bar.text:Show()
                else
                    bar.text:Hide()
                end
            end

            return true
        end
        
        if(key == 'text-size') then
            for _, bar in pairs(frames.bars) do
                local font = bar.text:GetFont()
                bar.text:SetFont(font, options.get('text-size'), 'OUTLINE')
            end

            return true
        end
        
        if(key == 'text-alignment') then
            for _, bar in pairs(frames.bars) do
                bar.text:SetJustifyH(options.get('text-alignment'))
            end

            return true
        end
        
        if(key == 'text-colour') then
            local colour = options.get('text-colour')
        
            for _, bar in pairs(frames.bars) do
                bar.text:SetTextColor(colour.r, colour.g, colour.b, colour.a)
            end

            return true
        end
        
        if(key == 'strata') then
            frames.main:SetFrameStrata(options.get('strata'))
            
            if(options.get('strata') == 'BACKGROUND' or options.get('strata') == 'LOW' or options.get('strata') == 'MEDIUM') then
                frames.cursorIntercept:SetFrameStrata('HIGH')
            else
                frames.cursorIntercept:SetFrameStrata(options.get('strata'))
            end
            
            return true
        end
        
        if(key == 'segments') then
            interface.drawSegments()
            return true
        end
        
        if(key == 'non-interactive') then
            frames.cursorIntercept:EnableMouse(not options.get('non-interactive'))
            return true
        end
        
        if(key == 'borders' or key == 'side-borders') then
            interface.setBorderPositions()
            interface.setBarTexturePositions()
            interface.applyDimensions()
            
            if(interface.built) then
                interface.drawSegments()
                interface.renderBarValues()
            end
            
            return true
        end
        
        if(key == 'multi-mode-sizing') then
            interface.applyDimensions()
            interface.setBarPositions()
            return true
        end
        
        if(key == 'use-flat-texture') then
            interface.setBarTextures()
            return true
        end
        
        if(key == 'overall-opacity') then
            frames.main:SetAlpha(math.min(1, math.max(0, tonumber(options.get('overall-opacity')) / 100)))
            return true
        end
        
        if(key == 'hide-blizzard') then
            interface.applyHideBlizzard()
            return
        end
        
        if(key == 're-anchor-stance-bar') then
            interface.reAnchorStanceBar()
            
            if(not options.get('re-anchor-stance-bar')) then
                UIParent_ManageFramePositions()
            end
            
            return
        end
        
        return false
    end,
    ['getBar'] = function(key)
        local bar = frames.bars[key]
    
        if(bar == nil) then
            bar = CreateFrame('Frame', 'ScootsProgressBar-Bar-' .. (key:gsub('^%l', string.upper)), frames.main)
            bar:SetFrameLevel(frames.main:GetFrameLevel() + 1)
            bar:Hide()
            
            local barTexture
            
            if(options.get('use-flat-texture')) then
                barTexture = 'Interface\\Buttons\\WHITE8x8'
            else
                barTexture = 'Interface\\TargetingFrame\\UI-TargetingFrame-LevelBackground'
            end
            
            frames.bars[key] = bar
            
            bar.background = bar:CreateTexture(nil, 'BACKGROUND')
            bar.background:SetTexture(barTexture, true)
            bar.background:SetHorizTile(true)
            
            bar.progress = bar:CreateTexture(nil, 'BACKGROUND')
            bar.progress:SetTexture(barTexture, true)
            bar.progress:SetHorizTile(true)
            
            if(key == 'experience') then
                bar.pending = bar:CreateTexture(nil, 'BACKGROUND')
                bar.pending:SetTexture(barTexture, true)
                bar.pending:SetHorizTile(true)
            end
        
            interface.attachBordersToFrame(bar)
            
            bar.text = bar:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
            bar.text:SetPoint('LEFT', bar, 'LEFT', 0, 2)
            bar.text:SetPoint('RIGHT', bar, 'RIGHT', 0, -2)
            bar.text:SetJustifyH(options.get('text-alignment'))
            
            local font = bar.text:GetFont()
            bar.text:SetFont(font, options.get('text-size'), 'OUTLINE')
            
            local colour = options.get('text-colour')
            bar.text:SetTextColor(colour.r, colour.g, colour.b, colour.a)
            
            if(options.get('show-text') ~= 'always') then
                bar.text:Hide()
            end
            
            interface.setBarTexturePositions(key)
            interface.setBorderPositions(key)
        end
        
        return bar
    end,
    ['applyDimensions'] = function()
        if(options.get('mode') == 'single' or options.get('multi-mode-sizing') == 'compress') then
            frames.main:SetSize(options.get('width'), options.get('height'))
        else
            local mainHeight = 0
            
            for key, _ in pairs(core.definedBars) do
                if(utility.isBarValid(key)) then
                    bar = interface.getBar(key)
                    bar:SetSize(options.get('width'), options.get('height'))
                    
                    mainHeight = mainHeight + options.get('height')
                end
            end
            
            if(mainHeight == 0) then
                bar = interface.getBar(utility.getNextActiveBar())
                bar:SetSize(options.get('width'), options.get('height'))
                mainHeight = options.get('height')
            end
            
            if(options.get('mode') == 'multi' and options.get('borders') == 'frame') then
                mainHeight = mainHeight + 2
            end
            
            frames.main:SetSize(options.get('width'), mainHeight)
        end
    end,
    ['attachBordersToFrame'] = function(parent)
        parent.borderTop = parent:CreateTexture(nil, 'ARTWORK')
        parent.borderTop:SetTexture('Interface\\AddOns\\ScootsProgressBar\\Textures\\Border-Top', true)
        parent.borderTop:SetHorizTile(true)
        parent.borderTop:SetVertTile(false)
        parent.borderTop:SetHeight(8)
        
        parent.borderBottom = parent:CreateTexture(nil, 'ARTWORK')
        parent.borderBottom:SetTexture('Interface\\AddOns\\ScootsProgressBar\\Textures\\Border-Bottom', true)
        parent.borderBottom:SetHorizTile(true)
        parent.borderBottom:SetVertTile(false)
        parent.borderBottom:SetHeight(8)
        
        parent.borderLeftTop = parent:CreateTexture(nil, 'ARTWORK')
        parent.borderLeftTop:SetTexture('Interface\\AddOns\\ScootsProgressBar\\Textures\\Border-LeftTop')
        parent.borderLeftTop:SetPoint('TOPLEFT', parent, 'TOPLEFT', -1, 1)
        parent.borderLeftTop:SetSize(8, 8)
        
        parent.borderLeftBottom = parent:CreateTexture(nil, 'ARTWORK')
        parent.borderLeftBottom:SetTexture('Interface\\AddOns\\ScootsProgressBar\\Textures\\Border-LeftBottom')
        parent.borderLeftBottom:SetPoint('BOTTOMLEFT', parent, 'BOTTOMLEFT', -1, -1)
        parent.borderLeftBottom:SetSize(8, 8)
        
        parent.borderLeft = parent:CreateTexture(nil, 'ARTWORK')
        parent.borderLeft:SetTexture('Interface\\AddOns\\ScootsProgressBar\\Textures\\Border-Left', true)
        parent.borderLeft:SetHorizTile(false)
        parent.borderLeft:SetVertTile(true)
        parent.borderLeft:SetWidth(8)
        parent.borderLeft:SetPoint('TOPLEFT', parent, 'TOPLEFT', -1, -3.7)
        parent.borderLeft:SetPoint('BOTTOMLEFT', parent, 'BOTTOMLEFT', -1, 3.7)
        
        parent.borderRightTop = parent:CreateTexture(nil, 'ARTWORK')
        parent.borderRightTop:SetTexture('Interface\\AddOns\\ScootsProgressBar\\Textures\\Border-RightTop')
        parent.borderRightTop:SetPoint('TOPRIGHT', parent, 'TOPRIGHT', 1, 1)
        parent.borderRightTop:SetSize(8, 8)
        
        parent.borderRightBottom = parent:CreateTexture(nil, 'ARTWORK')
        parent.borderRightBottom:SetTexture('Interface\\AddOns\\ScootsProgressBar\\Textures\\Border-RightBottom')
        parent.borderRightBottom:SetPoint('BOTTOMRIGHT', parent, 'BOTTOMRIGHT', 1, -1)
        parent.borderRightBottom:SetSize(8, 8)
        
        parent.borderRight = parent:CreateTexture(nil, 'ARTWORK')
        parent.borderRight:SetTexture('Interface\\AddOns\\ScootsProgressBar\\Textures\\Border-Right', true)
        parent.borderRight:SetHorizTile(false)
        parent.borderRight:SetVertTile(true)
        parent.borderRight:SetWidth(8)
        parent.borderRight:SetPoint('TOPRIGHT', parent, 'TOPRIGHT', 1, -3.7)
        parent.borderRight:SetPoint('BOTTOMRIGHT', parent, 'BOTTOMRIGHT', 1, 3.7)
    end,
    ['setBorderPositions'] = function(key)
        local parent
    
        if(key == nil) then
            parent = frames.overlay
        else
            parent = interface.getBar(key)
        end
        
        local xOffset = 0
        
        local show
        
        if(options.get('borders') == 'none') then
            show = false
        elseif(key == nil and options.get('borders') == 'frame') then
            show = true
        elseif(key ~= nil and options.get('borders') == 'each-bar') then
            show = true
        else
            show = false
        end
        
        if(show) then
            parent.borderTop:Show()
            parent.borderBottom:Show()
        else
            parent.borderTop:Hide()
            parent.borderBottom:Hide()
        end
        
        if(show and options.get('side-borders')) then
            parent.borderLeft:Show()
            parent.borderLeftTop:Show()
            parent.borderLeftBottom:Show()
            parent.borderRight:Show()
            parent.borderRightTop:Show()
            parent.borderRightBottom:Show()
            
            xOffset = 7
        else
            parent.borderLeft:Hide()
            parent.borderLeftTop:Hide()
            parent.borderLeftBottom:Hide()
            parent.borderRight:Hide()
            parent.borderRightTop:Hide()
            parent.borderRightBottom:Hide()
        end
        
        parent.borderTop:ClearAllPoints()
        parent.borderTop:SetPoint('TOPLEFT', parent, 'TOPLEFT', xOffset, 1)
        parent.borderTop:SetPoint('TOPRIGHT', parent, 'TOPRIGHT', 0 - xOffset, 1)
        
        parent.borderBottom:ClearAllPoints()
        parent.borderBottom:SetPoint('BOTTOMLEFT', parent, 'BOTTOMLEFT', xOffset, -1)
        parent.borderBottom:SetPoint('BOTTOMRIGHT', parent, 'BOTTOMRIGHT', 0 - xOffset, -1)
        
        --
    
        if(key == nil) then
            if(options.get('mode') == 'multi') then
                interface.applyDimensions()
            else
                if(interface.built) then
                    interface.setBarTexturePositions(core.active)
                end
            end
            
            for barKey, _ in pairs(frames.bars) do
                interface.setBorderPositions(barKey)
            
                if(interface.built) then
                    interface.setBarTexturePositions(barKey)
                end
            end
        end
    end,
    ['drawSegments'] = function()
        local multiplier = ((options.get('mode') == 'single' or options.get('borders') ~= 'each-bar') and 1) or utility.countActiveBars()
        local segmentsRequired = (options.get('segments') - 1) * multiplier
        
        for index = 1, math.max(segmentsRequired, #frames.overlay.segments) do
            if(index <= segmentsRequired) then
                if(frames.overlay.segments[index] == nil) then
                    local segment = {
                        ['top'] = frames.overlay:CreateTexture(nil, 'BORDER'),
                        ['mid'] = frames.overlay:CreateTexture(nil, 'BORDER'),
                        ['bot'] = frames.overlay:CreateTexture(nil, 'BORDER'),
                    }
                    
                    segment.top:SetTexture('Interface\\AddOns\\ScootsProgressBar\\Textures\\Segment-Top')
                    segment.top:SetSize(8, 8)
                    
                    segment.bot:SetTexture('Interface\\AddOns\\ScootsProgressBar\\Textures\\Segment-Bottom')
                    segment.bot:SetSize(8, 8)
                    
                    segment.mid:SetTexture('Interface\\AddOns\\ScootsProgressBar\\Textures\\Segment-Middle')
                    segment.mid:SetWidth(8)
                
                    table.insert(frames.overlay.segments, segment)
                end
            else
                frames.overlay.segments[index].top:Hide()
                frames.overlay.segments[index].mid:Hide()
                frames.overlay.segments[index].bot:Hide()
            end
        end
        
        if(options.get('segments') == 1) then
            return
        end
        
        local xOffset = 0
        local width = options.get('width')
        
        if(options.get('side-borders')) then
            width = width - 4
            xOffset = 2
        end
        
        local spacing = width / options.get('segments')
        local segmentWidth = frames.overlay.segments[1].top:GetWidth()
        
        if(options.get('mode') ~= 'multi' or options.get('borders') ~= 'each-bar') then
            for index = 1, segmentsRequired do
                interface.positionSegment(frames.overlay.segments[index], frames.overlay, index, spacing, segmentWidth, xOffset)
            end
        else
            for barIndex = 1, multiplier do
                for index = 1, (options.get('segments') - 1) do
                    local key = utility.getActiveBarAtIndex(barIndex)
                    local offset = (barIndex - 1) * (options.get('segments') - 1)
                    
                    interface.positionSegment(frames.overlay.segments[index + offset], interface.getBar(key), index, spacing, segmentWidth, xOffset)
                end
            end
        end
    end,
    ['positionSegment'] = function(segment, parent, index, spacing, segmentWidth, xOffset)
        local fromLeft = ((spacing * index) - (segmentWidth / 2)) + xOffset
        
        if(options.get('borders') == 'none') then
            segment.top:Hide()
            segment.mid:Show()
            segment.bot:Hide()
            
            segment.mid:ClearAllPoints()
            segment.mid:SetPoint('TOPLEFT', parent, 'TOPLEFT', fromLeft, 1)
            segment.mid:SetPoint('BOTTOMLEFT', parent, 'BOTTOMLEFT', fromLeft, -1)
        else
            segment.top:Show()
            segment.mid:Show()
            segment.bot:Show()
            
            segment.top:ClearAllPoints()
            segment.top:SetPoint('TOPLEFT', parent, 'TOPLEFT', fromLeft, 1)
            
            segment.bot:ClearAllPoints()
            segment.bot:SetPoint('BOTTOMLEFT', parent, 'BOTTOMLEFT', fromLeft, -1)
            
            segment.mid:ClearAllPoints()
            segment.mid:SetPoint('TOPLEFT', segment.top, 'TOPLEFT', 0, -3)
            segment.mid:SetPoint('BOTTOMLEFT', segment.bot, 'BOTTOMLEFT', 0, 3)
        end
    end,
    ['hideAllExcept'] = function(key)
        for barKey, bar in pairs(frames.bars) do
            if(barKey == key) then
                bar:Show()
            else
                bar:Hide()
            end
        end
    end,
    ['showAllEnabled'] = function()
        local enabledBars = utility.countActiveBars()
        local activeBar = utility.getActiveBar()
    
        for key, bar in pairs(frames.bars) do
            if(utility.isBarValid(key) or (enabledBars == 1 and key == activeBar)) then
                bar:Show()
            else
                bar:Hide()
            end
        end
    end,
    ['applyColours'] = function(key)
        local bar = frames.bars[key]
        
        if(bar == nil or (not utility.isBarValid(key) and utility.getActiveBar() ~= key)) then
            return
        end
        
        local colour
        local bgColour = options.get(key .. '-background-colour')
        
        if(key == 'experience') then
            if((core.values[key].rested or 0) == 0) then
                colour = options.get(key .. '-colour')
            else
                colour = options.get(key .. '-rested-colour')
            end
            
            local pendingColour = options.get(key .. '-pendingrested-colour')
            bar.pending:SetVertexColor(pendingColour.r, pendingColour.g, pendingColour.b, pendingColour.a)
        elseif(key == 'reputation') then
            if(core.values[key].name == nil) then
                colour = {['r'] = 0, ['g'] = 0, ['b'] = 0, ['a'] = 0}
            else
                colour = options.get(table.concat({key, lookup.reputationStandingMap[core.values[key].standingId], 'colour'}, '-'))
            end
        elseif(key == 'wintergrasp' and core.values[key].certain and core.values[key].inProgress) then
            colour = options.get(key .. '-inprogress-colour')
        elseif(key == 'dungeonspeedrun') then
            if(core.values[key].success) then
                colour = options.get(key .. '-success-colour')
            elseif(core.values[key].failed) then
                colour = options.get(key .. '-failed-colour')
            else
                colour = options.get(key .. '-colour')
            end
        elseif(key == 'freetimer' and core.values[key].percent == 100) then
            colour = options.get(key .. '-finished-colour')
        else
            colour = options.get(key .. '-colour')
        end
        
        bar.background:SetVertexColor(bgColour.r, bgColour.g, bgColour.b, bgColour.a)
        bar.progress:SetVertexColor(colour.r, colour.g, colour.b, colour.a)
    end,
    ['renderBarValues'] = function(key)
        if(key == nil) then
            if(options.get('mode') == 'single' and core.active) then
                interface.renderBarValues(core.active)
            elseif(options.get('mode') == 'multi') then
                for key, _ in pairs(core.definedBars) do
                    interface.renderBarValues(key)
                end
            end
            
            return
        end
        
        if(frames.bars[key] == nil) then
            return
        end
        
        if(not utility.isBarValid(key) and (utility.countActiveBars() > 1 or utility.getActiveBar() ~= key)) then
            return
        end
        
        if(core.values[key] == nil) then
            core.updateFunctionMap[key](key)
        end
        
        local width = options.get('width')
        
        if(options.get('side-borders')) then
            width = width - 3
        end
        
        local percent = math.min(100, math.max(0, core.values[key].percent or 0))
        local progressWidth = width * (percent / 100)
        local backgroundWidth
        
        if(key == 'experience') then
            local pendingWidth
            
            if((percent + core.values[key].restedPercent) < 100) then
                pendingWidth = width * ((core.values[key].restedPercent or 0) / 100)
                backgroundWidth = width * (1 - (((percent or 0) + (core.values[key].restedPercent or 0)) / 100))
            else
                pendingWidth = width * (1 - ((percent or 0) / 100))
                backgroundWidth = 0
            end
            
            if(pendingWidth > 0) then
                frames.bars[key].pending:Show()
                frames.bars[key].pending:SetWidth(pendingWidth)
            else
                frames.bars[key].pending:Hide()
            end
        else
            backgroundWidth = width * (1 - (percent / 100))
        end
        
        if(progressWidth > 0) then
            frames.bars[key].progress:Show()
            frames.bars[key].progress:SetWidth(progressWidth)
        else
            frames.bars[key].progress:Hide()
        end
        
        if(backgroundWidth > 0) then
            frames.bars[key].background:Show()
            frames.bars[key].background:SetWidth(backgroundWidth)
        else
            frames.bars[key].background:Hide()
        end
        
        if(key == 'reputation' and core.values[key].standingId ~= nil) then
            interface.setBarTexturePositions(key)
        end
        
        frames.bars[key].text:SetText(core.translateFormat(key))
    end,
    ['setBarPositions'] = function()
        if(options.get('mode') == 'single') then
            for _, bar in pairs(frames.bars) do
                bar:ClearAllPoints()
                bar:SetAllPoints()
            end
        else
            local barCount = utility.countActiveBars()
            local prev
            local topPad = 0
            local barHeight = options.get('height')
            
            if(options.get('multi-mode-sizing') == 'compress') then
                barHeight = barHeight / barCount
            end
            
            if(options.get('borders') == 'frame') then
                topPad = -1
            end
            
            for _, data in ipairs(core.barOrder) do
                if(utility.isBarValid(data.key)) then
                    local bar = interface.getBar(data.key)
                    bar:ClearAllPoints()
                
                    bar:SetSize(options.get('width'), barHeight)
                    
                    if(prev == nil) then
                        bar:SetPoint('TOPLEFT', frames.main, 'TOPLEFT', 0, topPad)
                        bar:SetPoint('TOPRIGHT', frames.main, 'TOPRIGHT', 0, topPad)
                    else
                        bar:SetPoint('TOPLEFT', prev, 'BOTTOMLEFT', 0, 0)
                        bar:SetPoint('TOPRIGHT', prev, 'BOTTOMRIGHT', 0, 0)
                    end
                    
                    prev = bar
                end
            end
        end
    end,
    ['setBarTextures'] = function()
        local barTexture
        
        if(options.get('use-flat-texture')) then
            barTexture = 'Interface\\Buttons\\WHITE8x8'
        else
            barTexture = 'Interface\\TargetingFrame\\UI-TargetingFrame-LevelBackground'
        end
        
        for key, bar in pairs(frames.bars) do
            bar.background:SetTexture(barTexture, true)

            bar.progress:SetTexture(barTexture, true)
            
            if(key == 'experience') then
                bar.pending:SetTexture(barTexture, true)
            end
        end
    end,
    ['setBarTexturePositions'] = function(key)
        if(key == nil) then
            for barKey, _ in pairs(frames.bars) do
                if(utility.isBarValid(barKey) or utility.getActiveBar() == barKey) then
                    interface.setBarTexturePositions(barKey)
                end
            end
            
            return
        end
    
        local bar = interface.getBar(key)
        
        local fromTop, fromBottom, fromLeft, fromRight = 0, 0, 0, 0
        
        if(options.get('borders') ~= 'none') then
            if(options.get('mode') == 'single' or options.get('borders') == 'each-bar') then
                fromTop = -2
                fromBottom = 2
            elseif(options.get('borders') == 'frame') then
                if(key == utility.getFirstActiveBar()) then
                    fromTop = -2
                end
                
                if(key == utility.getLastActiveBar()) then
                    fromBottom = 2
                end
            end
            
            if(options.get('side-borders')) then
                fromLeft = 1.5
                fromRight = -1.5
            end
        end
        
        bar.background:ClearAllPoints()
        bar.progress:ClearAllPoints()
        
        if(key ~= 'reputation' or core.values[key] == nil or (core.values[key].standingId or 4) > 3) then
            bar.background:SetPoint('TOPRIGHT', bar, 'TOPRIGHT', fromRight, fromTop)
            bar.background:SetPoint('BOTTOMRIGHT', bar, 'BOTTOMRIGHT', fromRight, fromBottom)
            
            bar.progress:SetPoint('TOPLEFT', bar, 'TOPLEFT', fromLeft, fromTop)
            bar.progress:SetPoint('BOTTOMLEFT', bar, 'BOTTOMLEFT', fromLeft, fromBottom)
        else
            bar.background:SetPoint('TOPLEFT', bar, 'TOPLEFT', fromLeft, fromTop)
            bar.background:SetPoint('BOTTOMLEFT', bar, 'BOTTOMLEFT', fromLeft, fromBottom)
            
            bar.progress:SetPoint('TOPRIGHT', bar, 'TOPRIGHT', fromRight, fromTop)
            bar.progress:SetPoint('BOTTOMRIGHT', bar, 'BOTTOMRIGHT', fromRight, fromBottom)
        end
    end,
    ['applyHideBlizzard'] = function()
        if(options.get('hide-blizzard')) then
            lookup.appliedHideBlizzard = true
            
            MainMenuExpBar:UnregisterAllEvents()
            MainMenuExpBar:Hide()
            
            MainMenuExpBar_Update = function() end
            
            ReputationWatchBar:UnregisterAllEvents()
            ReputationWatchBar:RegisterEvent('CVAR_UPDATE')
            ReputationWatchBar:Hide()
            
            ReputationWatchBar_Update = function() end
        elseif(lookup.appliedHideBlizzard == true) then
            MainMenuExpBar:RegisterEvent('PLAYER_ENTERING_WORLD')
            MainMenuExpBar:RegisterEvent('PLAYER_XP_UPDATE')
            MainMenuExpBar:Show()
            
            MainMenuExpBar_Update = lookup.blizzardMainMenuExpBar_Update
            MainMenuExpBar_Update()
            
            TextStatusBar_UpdateTextString(MainMenuExpBar)
            
            --
            
            ReputationWatchBar:RegisterEvent('UPDATE_FACTION')
            ReputationWatchBar:RegisterEvent('PLAYER_LEVEL_UP')
            ReputationWatchBar:RegisterEvent('ENABLE_XP_GAIN')
            ReputationWatchBar:RegisterEvent('DISABLE_XP_GAIN')
            ReputationWatchBar:Show()
            
            ReputationWatchBar_Update = lookup.blizzardReputationWatchBar_Update
            ReputationWatchBar_Update()
        end
    end,
    ['reAnchorStanceBar'] = function()
        if(options.get('re-anchor-stance-bar')) then
            ShapeshiftBarFrame:SetPoint('BOTTOMLEFT', frames.main, 'TOPLEFT', 24, 0)
            PossessBarFrame:SetPoint('BOTTOMLEFT', frames.main, 'TOPLEFT', 24, 0)
        else
            ShapeshiftBarFrame:SetPoint('BOTTOMLEFT', MainMenuBar, 'TOPLEFT', 30, 0)
            PossessBarFrame:SetPoint('BOTTOMLEFT', MainMenuBar, 'TOPLEFT', 30, 0)
        end
    end,
}

for funcName, func in pairs(interface) do
    ScootsProgressBar.interface[funcName] = func
end

interface = ScootsProgressBar.interface