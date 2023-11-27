local PIECE = {};
PIECE.__index = PIECE;
--
function PIECE.new(side: string)
    local self = {};
    setmetatable(self, PIECE);

    self.Side = side;
    self.Opponent = side == "White" and "Black" or "White";
    self.Type = "Knight";
    self.MovementMask = {
        {-3, 1}, {-3, -1},
        {3, 1}, {3, -1},
        {1, 3}, {1, -3},
        {-1, 3}, {-1, -3},
    }

    self.AttackMask = self.MovementMask;

    return self;
end