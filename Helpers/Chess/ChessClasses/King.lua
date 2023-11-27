local PIECE = {};
PIECE.__index = PIECE;
--
function PIECE.new(side: string)
    local self = {};
    setmetatable(self, PIECE);

    self.Side = side;
    self.Opponent = side == "White" and "Black" or "White";
    self.Type = "King";
    self.MovementMask = {
        {-1, -1}, {0, -1}, {1, -1},
        {-1, 0},  {1, 0},
        {-1, 1},  {0, 1}, {1, 1},
    }

    self.AttackMask = self.MovementMask;

    return self;
end