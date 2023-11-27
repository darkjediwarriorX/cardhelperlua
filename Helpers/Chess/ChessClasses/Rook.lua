local PIECE = {};
PIECE.__index = PIECE;
--
function PIECE.new(side: string)
    local self = {};
    setmetatable(self, PIECE);

    self.Side = side;
    self.Opponent = side == "White" and "Black" or "White";
    self.Type = "Rook";
    self.MovementMask = {}

    for x=-8, 8 do
        if x == 0 then continue end
        table.insert(self.MovementMask, {x, 0});
        table.insert(self.MovementMask, {0, x});
    end

    self.AttackMask = self.MovementMask;

    return self;
end