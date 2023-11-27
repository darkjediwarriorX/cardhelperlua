local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Remotes = ReplicatedStorage.Remotes;

local Assets = script.Parent.Parent

local PIECES = {};
for _, piece in script.Parent.ChessClasses:GetChildren() do
    PIECES[piece.Name] = require(piece);
end

local BOARD = {};
BOARD.__index = BOARD;

function BOARD.new(player1: Player, player2: Player, board: Model)
    local self = {};
    setmetatable(self, BOARD);

    local p = {player1, player2};
    local index = math.random(1, #p);

    self.Board = board or workspace.ChessBoard;
    self.Board = self.Board.Board;

    self.Player1 = p[index];
    table.remove(p, index);
    self.Player2 = p[1];

    self.GridHistory = {};
    self.Grid = self:Setup();

    self.Turn = "White";
    self.Pieces = {};

    self.Hooks = {
        ChessEvent = Remotes.ChessEvent.OnServerEvent:Connect(function(player: Player, pieceFrom: any?, pieceTo: any?)
            if (self.Turn == "White" and player == self.Player1) or (self.Turn == "Black" and player == self.Player2) then
                local success = self:AttemptMove(pieceFrom, pieceTo, self.Turn);
                if success then
                    self.Turn = self.Turn == "White" and "Black" or "White";
                    local gameOver, winner, outcome = self:GetOutcome();

                    self:UpdateBoard();

                    if gameOver then
                        self:Destroy();
                        print("Winner:", winner, "Outcome:", outcome);
                    end
                else
                    print("Invalid Move");
                end
            end
        end);
    };

    self:UpdateBoard();

    return self;
end;

function BOARD:UpdateBoard()
    local oldPieces = self.Pieces;
    local pieces = {};
    local playerGrid = {};

    local boardCF = self.Board.CFrame * CFrame.new(0.4 * 4 + 0.2, 0.05, -0.4 * 4 + 0.2);

    for x, yInfo in self.Grid do
        for y, data in yInfo do
            if data then
                local piece = Assets[data.Type]:Clone();
                local color = piece.Side == "White" and BrickColor.new("Khaki") or BrickColor.new("Black");
                piece:PivotTo(boardCF * CFrame.new(0.4 * (x - 1), 0, 0.4 * (y - 1)) * CFrame.Angles(0, math.rad(piece.Side == "Black" and 180 or 0), 0));
                piece.Parent = self.Board;
                table.insert(pieces, piece);
                if not playerGrid[x] then
                    playerGrid[x] = {};
                end
                playerGrid[x][y] = {Type = data.Type, Side = data.Side}; 
            end
        end
    end

    if oldPieces then
        for _, piece in oldPieces do
            piece:Destroy();
        end
    end

    for _, player in {self.Player1, self.Player2} do
        Remotes.ChessEvent:FireClient(player, "update", playerGrid);
    end

    self.Pieces = pieces;
end

function BOARD:Setup()
    local grid = {};

    for x=1, 8 do
        for y=1, 8 do
            local side;
            local piece;
            if y <= 2 then
                side = "White";
            elseif y >= 7 then
                side = "Black";
            end
            if y == 2 or y == 7 then
                piece = "Pawn";
            else
                if x == 1 or x == 8 then
                    piece = "Rook";
                elseif x == 2 or x == 7 then
                    piece = "Knight";
                elseif x == 3 or x == 6 then
                    piece = "Bishop";
                else
                    if (side == "White" and x == 4) or (side == "Black" and x == 5) then
                        piece = "Queen";
                    else
                        piece = "King";
                    end
                end
            end
            if not grid[x] then
                grid[x] = {};
            end
            if piece and side then
                grid[x][y] = PIECES[piece].new(side);
            end
        end
    end

    return grid;
end;

function BOARD:Push(pieceFrom: {[number]: number}, pieceTo: {[number]: number})
    for x, data in self.Grid do
        self.GridHistory[x] = data;
    end

    local piece = self.Grid[pieceFrom[1]][pieceFrom[2]];
    self.Grid[pieceFrom[1]][pieceFrom[2]] = nil;
    self.Grid[pieceTo[1]][pieceTo[2]] = piece;
end

function BOARD:Pop()
    for x, data in self.GridHistory do
        self.Grid[x] = data;
    end
end

function BOARD:IsInBounds(coordinates: {[number]: number})
    return coordinates[1] >= 1 and coordinates[1] <= 8 and
           coordinates[2] >= 1 and coordinates[2] <= 8;
end

function BOARD:IsPathBlocked(pieceFrom: {[number]: number}, pieceTo: {[number]: number}, side: string)
    local enemy = side == "White" and "Black" or "White";
    local isBlocked = false;

    local xMag, yMag = math.abs(pieceFrom.X - pieceTo.X), math.abs(pieceFrom.Y - pieceTo.Y);
    local foundPiece = false; 

    for x=1, xMag do
        for y=1, yMag do
            if self.Grid[pieceFrom.X + x][pieceFrom.Y + y] then
                if not foundPiece and self.Grid[pieceFrom.X + x][pieceFrom.Y + y].Side == enemy then
                    foundPiece = true;
                    continue;
                end;
                isBlocked = true;
                break;
            end
        end
    end

    return isBlocked;
end

function BOARD:GetAttackMovement(coordinate: {[number]: number}, movement: {[number]: {[number]: number}}, forward: number, isKnight: boolean)
    local side = forward == 1 and "White" or "Black";
    local attackMovement = {};
    local fromPos = Vector2.new(coordinate.X, coordinate.Y);

    for _, move in movement do
        local toPos = fromPos + (move * Vector2.new(0, forward));
        if (not self:IsPathBlocked(coordinate, toPos, side) or isKnight) then
            table.insert(attackMovement, {X = toPos.X, Y = toPos.Y});
        end
    end

    return attackMovement;
end

function BOARD:GetAvailableMovement(coordinate: Vector2, movement: {[number]: {[number]: number}}, forward: number, isKnight: boolean)
    local movement = {};
    local side = forward == 1 and "White" or "Black";

    for _, move in movement do
        local toPos = coordinate + (move * Vector2.new(0, forward));
        if not self:IsPathBlocked(coordinate, toPos, side) then
            table.insert(movement, {X = toPos.X, Y = toPos.Y});
        end
    end

    return movement;
end

function BOARD:CreateAttackGrid(side: string)
    local grid = {};

    for x=1, 8 do
        for y=1, 8 do
            if self.Grid[x][y] and self.Grid[x][y].Side == side then
                for _, coordinate in self:GetAttackMovement({x, y}, self.Grid[x][y].AttackMask, side == "White" and 1 or -1, self.Grid[x][y].Type == "Knight") do
                    grid[coordinate.X] = grid[coordinate.X] or {};
                    grid[coordinate.X][coordinate.Y] = true;
                end
            end
        end
    end

    return grid;
end

--[[

git config --global user.email "you@example.com"
  git config --global user.name "Your Name"
]]

function BOARD:GetPieceByType(side: string, type: string)
    for x, yInfo in self.Grid do
        for y, data in yInfo do
            if data and data.Side == side and data.Type == type then
                return {X = x, Y = y};
            end
        end
    end
end

function BOARD:GetPieceByCoords(coords: Vector2)
    return self.Grid[coords.X][coords.Y];
end

function BOARD:InCheck(side: string)
    local opponent = side == "White" and "Black" or "White";

    local attacks = self:CreateAttackGrid(opponent);
    local pos = self:GetPieceByType(side, "King");

    return attacks[pos.X] and attacks[pos.Y];
end

function BOARD:AttemptMove(pieceFrom, pieceTo, side: string)
    self:Push(pieceFrom, pieceTo);
    if self:InCheck(side) then
        self:Pop();
        return false;
    else
        return true;
    end
end

-- chess

function BOARD:GetPieces(side: string)
    local pieces = {};

    for x, yInfo in self.Grid do
        for y, data in yInfo do
            if data and data.Side == side then
                table.insert(pieces, {X = x, Y = y});
            end
        end
    end

    return pieces;
end

function BOARD:GetOutcome()
    local winner;
    local outcomeType;
    local gameOver = false;

    local attackBlack, attackWhite = self:GetAttackGrid("Black"), self:GetAttackGrid("White");
    local kingBlack, kingWhite = self:GetPieceByType("Black", "King"), self:GetPieceByType("White", "King");

    local blackInCheck, whiteInCheck = self:IsInCheck("Black") and self:IsInCheck("White");

    local whitePieces, blackPieces = self:GetPieces("White"), self:GetPieces("Black");

    if #whitePieces <= 1 and #blackPieces <= 1 then
        gameOver = true;
        winner = "Draw";
        outcomeType = "Draw";
    else
        local blackKingMoves, whiteKingMoves = self:GetAvailableMovement(kingBlack, self:GetPieceByCoords(kingBlack).MovementMask, -1), self:GetAvailableMovement(kingWhite, self:GetPieceByCoords(kingWhite).MovementMask, 1);
        local canBlackMove, canWhiteMove = false, false;

        for _, coord in blackKingMoves do
            if not (attackWhite[coord.X] and attackWhite[coord.X][coord.Y]) then
                canBlackMove = true;
                break;
            end
        end

        for _, coord in whiteKingMoves do
            if not (attackBlack[coord.X] and attackBlack[coord.X][coord.Y]) then
                canWhiteMove = true;
                break;
            end
        end

        if not canBlackMove and #blackPieces <= 1 and not blackInCheck then
            gameOver = true;
            winner = "White";
            outcomeType = "Stalemate";
        elseif not canWhiteMove and #whitePieces <= 1 and not whiteInCheck then
            gameOver = true;
            winner = "Black";
            outcomeType = "Stalemate";
        elseif not canBlackMove and blackInCheck then
            gameOver = true;
            winner = "White";
            outcomeType = "Checkmate";
        elseif not canWhiteMove and whiteInCheck then
            gameOver = true;
            winner = "Black";
            outcomeType = "Checkmate";
        end
    end

    return gameOver, winner, outcomeType;
end

return BOARD;