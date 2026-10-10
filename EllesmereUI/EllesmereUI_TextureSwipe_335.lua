-- Texture cooldown swipe for 3.3.5. The native Cooldown model is a dark square
-- with no color, texture or shape, so this draws the sweep from a texture:
-- four ScrollFrames (the only clipping this client has) each show one quarter
-- of it, and the quarter being swept shows a wedge turned about the centre by
-- a zero-length Rotation animation, its texcoords turned back so the art stays
-- in place. One OnUpdate per swipe, only while it counts down.
local E = EllesmereUI
if not E then return end

local GetTime, cos, sin, rad = GetTime, math.cos, math.sin, math.rad
local WHITE = "Interface\\Buttons\\WHITE8X8"

-- Quarter k (1 = top right, then clockwise) spans [90(k-1), 90k] degrees from
-- 12 o'clock: { corner, corner at the centre, texcoords }.
local QUARTERS = {
    { "TOPRIGHT", "BOTTOMLEFT", .5, 1, 0, .5 },
    { "BOTTOMRIGHT", "TOPLEFT", .5, 1, .5, 1 },
    { "BOTTOMLEFT", "TOPRIGHT", 0, .5, .5, 1 },
    { "TOPLEFT", "BOTTOMRIGHT", 0, .5, 0, .5 },
}

-- The wedge's corner sits on the centre and spans 12 to 3 o'clock; turned
-- clockwise by phi it spans [phi, phi + 90]. Each corner gets the icon
-- texcoord of where it lands, so the art does not turn with it.
local function Turn(q, phi, w, h, size)
    local c, s = cos(rad(phi)), sin(rad(phi))
    local function UV(x, y)
        return .5 + (x * c + y * s) / w, .5 - (y * c - x * s) / h
    end
    local ulx, uly = UV(0, size)
    local llx, lly = UV(0, 0)
    local urx, ury = UV(size, size)
    local lrx, lry = UV(size, 0)
    q.wedge:SetTexCoord(ulx, uly, llx, lly, urx, ury, lrx, lry)
    q.turn:SetDegrees(-phi)
end

local function Paint(self, elapsed)
    local w, h = self:GetWidth(), self:GetHeight()
    if not w or w <= 0 or not h or h <= 0 then return end
    local theta, rev = 360 * elapsed, self.reverse
    for k = 1, 4 do
        local q, lo, hi = self.quarters[k], 90 * (k - 1), 90 * k
        local swept = hi <= theta
        if swept or lo >= theta then
            q.wedge:Hide()
            if swept == (rev and true or false) then q.full:Show() else q.full:Hide() end
        else
            q.full:Hide()
            Turn(q, rev and theta - 90 or theta, w, h, self.wedgeSize)
            q.wedge:Show()
        end
    end
end

local function OnUpdate(self)
    local d = self.duration or 0
    local elapsed = d > 0 and (GetTime() - self.start) / d or 1
    if elapsed >= 1 then return self:Stop() end
    Paint(self, elapsed < 0 and 0 or elapsed)
end

local function Layout(self)
    local w, h = self:GetWidth(), self:GetHeight()
    if not w or w <= 0 or not h or h <= 0 then return end
    self.wedgeSize = w + h
    for _, q in ipairs(self.quarters) do
        q.child:SetWidth(w / 2); q.child:SetHeight(h / 2)
        q.wedge:SetWidth(self.wedgeSize); q.wedge:SetHeight(self.wedgeSize)
    end
    if self:IsShown() and self.duration then OnUpdate(self) end
end

local methods = {}
function methods:SetArt(path)
    path = path or WHITE
    if self.art == path then return end
    self.art = path
    for _, q in ipairs(self.quarters) do q.full:SetTexture(path); q.wedge:SetTexture(path) end
end
function methods:SetTint(r, g, b, a)
    for _, q in ipairs(self.quarters) do
        q.full:SetVertexColor(r, g, b, a); q.wedge:SetVertexColor(r, g, b, a)
    end
end
function methods:Start(start, duration, reverse)
    self.start, self.duration, self.reverse = start, duration, reverse and true or false
    self:Show()
    self:SetScript("OnUpdate", OnUpdate)
    OnUpdate(self)
end
function methods:Stop()
    self:SetScript("OnUpdate", nil)
    self.start, self.duration = nil, nil
    self:Hide()
end

function E.CreateTextureSwipe(parent)
    local self = CreateFrame("Frame", nil, parent)
    for name, fn in pairs(methods) do self[name] = fn end
    self.quarters = {}
    for k, def in ipairs(QUARTERS) do
        local frame = CreateFrame("ScrollFrame", nil, self)
        frame:SetPoint(def[1], self, def[1])
        frame:SetPoint(def[2], self, "CENTER")
        local child = CreateFrame("Frame", nil, frame)
        frame:SetScrollChild(child)
        local full = child:CreateTexture(nil, "ARTWORK")
        full:SetAllPoints(frame)
        full:SetTexCoord(def[3], def[4], def[5], def[6])
        local wedge = child:CreateTexture(nil, "ARTWORK")
        wedge:SetPoint("BOTTOMLEFT", self, "CENTER", 0, 0)
        local group = wedge:CreateAnimationGroup()
        group:SetLooping("REPEAT")
        local turn = group:CreateAnimation("Rotation")
        turn:SetOrigin("BOTTOMLEFT", 0, 0)
        turn:SetDuration(0)
        turn:SetEndDelay(3600)
        group:Play()
        full:Hide(); wedge:Hide()
        self.quarters[k] = { frame = frame, child = child, full = full, wedge = wedge, turn = turn }
    end
    self:SetArt(WHITE)
    self:SetTint(0, 0, 0, .7)
    self:SetScript("OnSizeChanged", Layout)
    self:Hide()
    return self
end
