pragma solidity >=0.7.0 < 0.8.9;

contract matching_pennies {
    
    struct Player {
        address addr;
        bytes32 hashed_choice;
        bool choice;
        bool have_chosen;
        bool revealed_choice;
        bool is_winner;
        bool have_ended;
    }
    
    uint256 timestamp;
    uint bank;
    mapping(uint256 => Player) public players;
    uint256 public player_count = 0;
    bool winner_decided;
    
    function check_timeout() private {
        if(block.timestamp > timestamp + 5 minutes) {
            delete players[1];
            delete players[2];
            player_count = 0;
            winner_decided = false;
            require(false, "time limit exceeded");
        }
    }
    
    function join_game() public payable {
        require(msg.value == 1 ether, "you need to send exactly 1 ether to join");
        if(player_count < 2) {
            if (player_count>=1 && players[1].addr==msg.sender) { revert("You have already joined the game"); }
            if (player_count == 1 && block.timestamp > timestamp + 5 minutes) {
                delete players[1];
                player_count = 0;
                bank = 0;
                require(false, "time limit exceeded");
            } else {
                timestamp = block.timestamp;
                player_count += 1;
                Player memory player;
                player.addr = msg.sender;
                players[player_count] = player;
                bank += msg.value;
            }
        } else { revert("game is full"); }

    }
    
    function make_choice(bytes32 hashed_choice) public {
        check_timeout();
        if(msg.sender == players[1].addr && players[1].have_chosen == false) {
            players[1].hashed_choice = hashed_choice;
            players[1].have_chosen = true;
        } else if (msg.sender == players[2].addr && players[2].have_chosen == false) {
            players[2].hashed_choice = hashed_choice;
            players[2].have_chosen = true;
        } else { revert("you have already chosen"); }
        
        timestamp = block.timestamp;
    }
    
    function calculate_winner() private {
        if(players[1].choice == players[2].choice) {
            players[1].is_winner = true;
        } else { 
            players[2].is_winner = true; 
        } 
        winner_decided = true;
    }
    
    function reveal_choice(bool original_choice, string memory nonce) public {
        require(players[1].have_chosen==true && players[2].have_chosen==true, "all players must choose first");
        check_timeout();
        if(msg.sender == players[1].addr && players[1].revealed_choice == false) {
            require(
                keccak256(abi.encodePacked(original_choice, nonce)) == players[1].hashed_choice, 
                "you gave a different choice than your original"
            );
            players[1].choice = original_choice;
            players[1].revealed_choice = true;
        } else if (msg.sender == players[2].addr && players[2].revealed_choice == false) {
            require(
                keccak256(abi.encodePacked(original_choice, nonce)) == players[2].hashed_choice, 
                "you gave a different choice than your original"
            );
            players[2].choice = original_choice;
            players[2].revealed_choice = true;
        } else { revert("you have already revealed your choice"); }
        
        if(players[1].revealed_choice == true && players[2].revealed_choice == true) { calculate_winner(); }
        
        timestamp = block.timestamp;
    }
    
    
    function endgame() public payable {
        require(winner_decided == true, "winner has not been decided yet");
        check_timeout();
        
        if(msg.sender == players[1].addr && players[1].have_ended == false) {
            players[1].have_ended = true;
            if(players[1].is_winner == true) {
                uint amount = bank;
                bank = 0;
                players[1].have_ended = true;
                payable(msg.sender).transfer(amount);
            }
        } else if(msg.sender == players[2].addr && players[2].have_ended == false) {
            players[2].have_ended = true;
            if(players[2].is_winner == true) {
                uint amount = bank;
                bank = 0;
                players[1].have_ended = true;
                payable(msg.sender).transfer(amount);
            }
        }

        if(players[1].have_ended == true && players[2].have_ended == true) {
            delete players[1];
            delete players[2];
            player_count = 0;
            winner_decided = false;
        }
    }
    
}
