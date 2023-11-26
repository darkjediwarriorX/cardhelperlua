local POKER_HELPER = {};

function POKER_HELPER:GetHand(cards: {[number]: any?}): string, string
    local hand, high = "JUNK", nil;
    local suiteCount = {
        SPADES = 0,
        HEARTS = 0,
        CLUBS = 0,
        DIAMONDS = 0,
    };
    local cardCount = {

    };

    for _, card in cards do
        local divider = card:find("_");
        if not divider then continue end

        local suite = card:sub(1, divider - 1);
        local card = card:sub(divider + 1);

        suiteCount[suite] += 1;
        if not cardCount[card] then
            cardCount[card] = 0;
        end
        cardCount[card] += 1;
    end

    local hasFlush;
    for suite, count in suiteCount do
        if count >= 5 then
            hasFlush = true;
            break;
        end
    end

    
end

return POKER_HELPER;