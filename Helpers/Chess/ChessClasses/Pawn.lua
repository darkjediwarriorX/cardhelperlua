local PIECE = {};
PIECE.__index = PIECE;
--
function PIECE.new(side: string)
    local self = {};
    setmetatable(self, PIECE);

    self.Side = side;
    self.Opponent = side == "White" and "Black" or "White";
    self.Type = "Pawn";
    self.MovementMask = {
        {0, 1}
    }
    self.AttackMask = {
        {-1, 1},
        {1, 1},
    },

    return self;
end