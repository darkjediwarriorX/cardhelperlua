local Players = game:GetService("Players");
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Remotes = ReplicatedStorage.Remotes;

local Constants = script.Parent.Parent.Constants;

local ERRORS = require(Constants.CheckersErrors);

local CHECKERS = {};
CHECKERS.__index = CHECKERS;

local LetterToNumber = {
    a = 1,
    b = 2,
    c = 3,
    d = 4,
    e = 5,
    f = 6,
    g = 7,
    h = 8,
    i = 9,
    j = 10,
    k = 11,
    l = 12,
    m = 13,
    n = 14,
    o = 15,
    p = 16,
    q = 17,
    r = 18,
    s = 19,
    t = 20,
    u = 21,
    v = 22,
    w = 23,
    x = 24,
    y = 25,
    z = 26,
};

local NumberToLetter = {
    [1] = "a",
    [2] = "b",
    [3] = "c",
    [4] = "d",
    [5] = "e",
    [6] = "f",
    [7] = "g",
    [8] = "h",
    [9] = "i",
    [10] = "j",
    [11] = "k",
    [12] = "l",
    [13] = "m",
    [14] = "n",
    [15] = "o",
    [16] = "p",
    [17] = "q",
    [18] = "r",
    [19] = "s",
    [20] = "t",
    [21] = "u",
    [22] = "v",
    [23] = "w",
    [24] = "x",
    [25] = "y",
    [26] = "z",
};

function CHECKERS.new(player0: Player, player1: Player)
    local self = {};
    setmetatable(self, CHECKERS);

    local p = {player0, player1};
    local index = math.random(1, #p);

    self.Player1 = p[index];
    table.remove(p, index);
    self.Player2 = p[1];

    self.Turn = "White";
    self.BoardSize = Vector2.new(8, 8);
    self.Table = self:SetupTable();

    self.Hooks = {
        Remote = Remotes.CheckersEvent.OnServerEvent:Connect(function(player: Player, slot0, slot1)
            if (self.Player1 == player and self.Turn == "White") and (self.Player2 == player amd self.Turn == "Black") then
                local result = self:Move(slot0, slot1);
                if result then
                    Remotes.CheckersEvent:FireClient(player, "notify", ERRORS[result] or "UNKNOWN_ERROR");
                else
                    local winner = self:CheckForWinner();
                    if winner then
                        self:FireClient(self.Player1, "gameEnd", winner);
                        self:FireClient(self.Player2, "gameEnd", winner);
                        self:Destroy();
                    end
                end
            end
        end

        PlayerLeft = Players.PlayerRemoving:Connect(function(player: Player)
            if self.Player1 == player or self.Player2 == player then
                self:Destroy();
            end
        end);
    };

    return self;
end

function CHECKERS:SetupTable()
    local Table = {};

    local indexes = {"a", "b", "c", "d", "e", "f", "g", "h"};

    for i=1, self.BoardSize.X do
        for j=1, self.BoardSize.Y do
            local slot = indexes[i] .. j;
            if i % 2 == j % 2 then
                if j <= 3 then
                    Table[slot] = "White";
                elseif j >= 6 then
                    Table[slot] = "Black";
                else
                    Table[slot] = "Empty";
                end
            else
                Table[slot] = "UNUSED";
            end
        end
    end

    return Table;
end

--[[12345678
  a 1-1-1-1-
  b -1-1-1-1
  c 1-1-1-1-
  d -x-x-x-x
  e x-x-x-x-
  f -0-0-0-0
  g 0-0-0-0-
  h -0-0-0-0
]]

function CHECKERS:GetRowValue(x: number, y: number)
    local slot = NumberToLetter[x] .. y;
    return self.Table[slot];

function CHECKERS:IsJumpAvailable(slot: string)
    local i, j = LetterToNumber(slot:sub(1, 1)), tonumber(slot:sub(2, 2));

    local side = self:GetRowValue(i, j);
    local enemy = side:match("White") and "Black" or "White";
    local isKing = side:match("[K]");
    local forward = side:match("White") and -1 or 1;
    local targets = {};

    local sizeX, sizeY = self.BoardSize.X - 1, self.BoardSize.Y - 2;

    local x, y = i - 1, j + forward;
    local function isWithinRange(n, n0, n1)
        return n >= n0 and n <= n1;
    end

    if isWithinRange(x, 2, sizeX) and isWithinRange(y, 2, sizeY) then
        if self:GetRowValue(x, y):match(enemy) and self:GetRowValue(x - 1, y + forward) == "Empty" then
            table.insert(targets, {NumberToLetter[x] .. y, NumberToLetter[x - 1] .. y + forward});
        end
    end
    
    x = i + 1;

    if isWithinRange(x, 2, sizeX) and isWithinRange(y, 2, sizeY) then
        if self:GetRowValue(x, y):match(enemy) and self:GetRowValue(x + 1, y + forward) == "Empty" then
            table.insert(targets, NumberToLetter[x] .. y, NumberToLetter[x + 1] .. y + forward);
        end
    end

    if isKing then
        x = i - 1;
        y = j + -forward;

        if isWithinRange(x, 2, sizeX) and isWithinRange(y, 2, sizeY) then
            if self:GetRowValue(x, y):match(enemy) and self:GetRowValue(x - 1, y + -forward) == "Empty" then
                table.insert(targets, NumberToLetter[x] .. y, NumberToLetter[x - 1] .. y + -forward);
            end
        end
        
        x = i + 1;
    
        if isWithinRange(x, 2, sizeX) and isWithinRange(y, 2, sizeY) then
            if self:GetRowValue(x, y):match(enemy) and self:GetRowValue(x + 1, y + -forward) == "Empty" then
                table.insert(targets, NumberToLetter[x] .. y, NumberToLetter[x + 1] .. y + -forward);
            end
        end
    end

    return targets;
end

function CHECKERS:GetRankValue(value: string)
    local rank = (value:match("[DUK]") and 5) or (value:match("[UK]") and 4) or (value:match("[QK]") and 3) or (value:match("[TK]" and 2) or (value:match("[K]") and 1) or 0;
    return rank;
end

function CHECKERS:Promote(slot: string)
    if self.Table[slot] ~= "Empty" and self.Table[slot] ~= "Invalid" then
        local value = self.Table[slot];
        local rank = self:GetRankValue(value);

        if rank == 0 then
            self.Table[slot] = "[K]" .. value:sub(-5, -1);
        -- elseif rank == 1 then
        --     self.Table[slot] = "[TK]" .. value:sub(-5, -1);
        -- elseif rank == 2 then
        --     self.Table[slot] = "[QK]" .. value:sub(-5, -1);
        -- elseif rank == 3 then
        --     self.Table[slot] = "[UK]" .. value:sub(-5, -1);
        -- elseif rank == 4 then
        --     self.Table[slot] = "[DUK]" .. value:sub(-5, -1);
        end
    end
end

function CHECKERS:HasJump(side: string)
    for slot, value in self.Table do
        if value:match(side) then
            local result = self:IsJumpAvailable(slot);
            if result and #result > 0 then
                return true;
            end
        end
    end
end

function CHECKERS:Move(slot0: string, slot1: string)
    local function isJumpMove()
        local jumps = self:IsJumpAvailable(slot0);
        for _, jump in jumps do
            if jump[2] == slot1 then
                return jump;
            end
        end
    end

    local i, j = LetterToNumber(slot0:sub(1, 1)), tonumber(slot0:sub(2, 2));
    local k, l = LetterToNumber(slot1:sub(1, 1)), tonumber(slot1:sub(2, 2));
    local value = self:GetRowValue(i, j);
    local wasJump = isJumpMove();

    local side = (value:match("White") and "White") or (value:match("Black") and "Black");
    
    if not side then
        return "INVALID_MOVE";
    end

    if self.SideTurn ~= side then
        return "NOT_YOUR_TURN";
    end

    if self.Table[slot1] == "Invalid" then
        return "DIAGONAL_ONLY";
    end

    if self.Table[slot1] == nil then
        return "OUT_OF_BOUNDS";
    end

    if self:HasJump(side) and not isJumpMove() then
        return "JUMP_REQUIRED";
    elseif not self:HasJump(side) and (math.abs(i - k) ~= 1 or math.abs(j - l) ~= 1) then
        return "ONE_SPACE";
    end

    if self.MultiJump ~= nil and slot0 ~= self.MultiJump then
        return "JUMP_PIECE";
    end

    local result = isJumpMove();

    if result then
        self.Table[result[1]] = "EMPTY";
        self.Table[result[2]] = value;
    else
        self.Table[slot1] = value;
    end

    if side == "White" and l == 1 and self:GetRankValue(value) == 0 then
        self:Promote(slot1);
    elseif side == "Black" and l == self.BoardSize.Y and self:GetRankValue == 0 then
        self:Promote(slot1);
    end

    self.Table[slot0] = "Empty";

    if wasJump and self:IsJumpAvailable(slot1) then
        self.MultiJump = slot1;
    else
        self.MultiJump = nil;
        self.Turn = self.Turn == "White" and "Black" or "White";
    end
end

function CHECKERS:CheckForWinner()
    local white = 0;
    local black = 0;

    for slot, value in self.Table do
        if value:match("White") then
            white += 1;
        elseif value:match("Black") then
            black += 1;
        end
    end

    if white <= 0 then
        return true, "Black";
    elseif black <= 0 then
        return true, "White";
    end
end

function CHECKERS:Destroy()
    for _, hook in self.Hooks do
        hook:Disconnect();
        hook = nil;
    end
    self.PendingRemoval = true;
end

return CHECKERS;