use poker::models::game::GameParams;
use poker::models::player::Player;

/// TODO: Read the GameREADME.md file to understand the rules of coding this game.
/// TODO: What should happen when everyone leaves the game? Well, the pot should be
/// transferred to the last player. May be reconsidered.
///
/// TODO: for each function that requires

/// Interface functions for each action of the smart contract
#[starknet::interface]
trait IActions<TContractState> {
    /// Initializes the game with a game format. Returns a unique game id.
    /// game_params as Option::None initializes a default game.
    ///
    /// TODO: Might require a function that lets and admin eject a player
    fn initialize_game(ref self: TContractState, game_params: Option<GameParams>) -> u64;
    fn join_game(ref self: TContractState, game_id: u64);
    fn leave_game(ref self: TContractState);

    /// ********************************* NOTE *************************************************
    ///
    ///                             TODO: NOTE
    /// These functions must require that the caller is already in a game.
    /// When calling all_in, for other raises, create a separate pot.
    fn check(ref self: TContractState);
    fn call(ref self: TContractState);
    fn fold(ref self: TContractState);
    fn raise(ref self: TContractState, no_of_chips: u256);
    fn all_in(ref self: TContractState);
    fn buy_chips(ref self: TContractState, no_of_chips: u256); // will call
    fn get_dealer(self: @TContractState) -> Option<Player>;
}


// dojo decorator
#[dojo::contract]
pub mod actions {
    use starknet::{ContractAddress, get_caller_address};
    use dojo::model::{ModelStorage, ModelValueStorage};
    use dojo::event::EventStorage;
    // use dojo::world::{WorldStorage, WorldStorageTrait};

    use poker::models::{
        base::{GameErrors, Id}, card::Card, deck::Deck, game::{Game, GameMode, GameParams},
        hand::{Hand}, player::Player,
    };

    use poker::traits::{deck::DeckTrait, game::GameTrait, hand::HandTrait};

    pub const GAME: felt252 = 'GAME';
    pub const DECK: felt252 = 'DECK';
    pub const MAX_NO_OF_CHIPS: u128 = 100000; /// for test, 1 chip = 1 usd.

    #[abi(embed_v0)]
    impl ActionsImpl of super::IActions<ContractState> {
        fn initialize_game(ref self: ContractState, game_params: Option<GameParams>) -> u64 {
            // Get the caller address
            let caller: ContractAddress = get_caller_address();

            let game_id: u64 = self.generate_id(GAME);

            // Initialize a new player or get existing player
            let mut world = self.world_default();
            let mut player: Player = world.read_model(caller);

            // Ensure the player is not already in a game
            let (is_locked, _) = player.locked;
            assert(!is_locked, GameErrors::PLAYER_ALREADY_LOCKED);
            let mut deck_ids: Array<u64> = array![self.generate_id(DECK)];
            if let Option::Some(params) = game_params {
                // say the maximum number of decks is 10.
                let deck_len = params.no_of_decks;
                assert(deck_len > 0 && deck_len <= 10, GameErrors::INVALID_GAME_PARAMS);
                for _ in 0..deck_len - 1 {
                    deck_ids.append(self.generate_id(DECK));
                };
            }
            // Create the game with the player
            let (game, decks) = GameTrait::initialize_game(
                ref player, game_params, game_id, deck_ids,
            );

            player.in_round = true;
            // Save updated player and game state
            world.write_model(@player);
            world.write_model(@game);

            // Save available decks
            for deck in decks {
                world.write_model(@deck);
            };

            game_id
        }

        fn join_game(
            ref self: ContractState, game_id: u64,
        ) { // check the game in_progress and has_ended values
        // if has_ended, panic
        // if in progress, then further checks in the gameparams are done, based on the game mode
        // and round in progress. optimize code as good as possible
        // init a player (check if the player exists, if not, create a new one)
        // call the internal function player_in_game
        // check the number of chips
        // for each join, check the max no. of players allowed in the game params of the game_id, if
        // reached, start the session.
        // starting the session involves changing some variables in the game and dealing cards,
        // basically initializing the game.
        // set player_in_round to true
        }

        fn leave_game(ref self: ContractState) { // assert if the player exists
        // extract game_id
        // assert if the game exists
        // assert player.locked == true
        // Check if the player is in the game
        // Check if the player has enough chips to leave the game
        }

        fn check(ref self: ContractState) {}

        fn call(ref self: ContractState) {}

        fn fold(ref self: ContractState) {}

        fn raise(ref self: ContractState, no_of_chips: u256) {}

        fn all_in(ref self: ContractState) { //
        // deduct all available no. of chips
        }

        fn buy_chips(ref self: ContractState, no_of_chips: u256) { // use a crate here
        // a package would be made for all transactions and nfts out of this contract package.
        }

        fn get_dealer(self: @ContractState) -> Option<Player> {
            Option::None
        }
    }


    #[generate_trait]
    impl InternalImpl of InternalTrait {
        /// Use the default namespace "poker". This function is handy since the ByteArray
        /// can't be const.
        fn world_default(self: @ContractState) -> dojo::world::WorldStorage {
            self.world(@"poker")
        }

        fn generate_id(self: @ContractState, target: felt252) -> u64 {
            let mut world = self.world_default();
            let mut game_id: Id = world.read_model(target);
            let mut id = game_id.nonce + 1;
            game_id.nonce = id;
            world.write_model(@game_id);
            id
        }

        /// This function makes all assertions on if player is meant to call this function.
        fn before_play(
            self: @ContractState, caller: ContractAddress,
        ) { // Check the chips available in the player model
        // check if player is locked to a session
        // check if the player is even in the game (might have left along the way)...call the below
        // function
        // check if it's player's turn
        }

        /// This function performs all default actions immediately a player joins the game.
        /// May call the previous function. (should not, actually)
        fn player_in_game(
            self: @ContractState, caller: ContractAddress,
        ) { // Check if player is already in the game
            // Check if player is locked (already in a game), check the player struct.
            // The above two checks seem similar, but they differ in the error messages they return.
            // Check if player has enough chips to join the game

            let world: dojo::world::WorldStorage = self.world_default();
            let player: Player = world.read_model(caller);
            let (is_locked, game_id) = player.locked;
            let game: Game = world.read_model(game_id);

            // Player can't be locked and not in a game
            // true is serialized as 1 => a non existing player can't be locked
            assert(is_locked, GameErrors::PLAYER_NOT_IN_GAME);
            assert(
                player.chips >= game.params.min_amount_of_chips, GameErrors::PLAYER_OUT_OF_CHIPS,
            );
        }

        fn after_play(
            self: @ContractState, caller: ContractAddress,
        ) { // check if player has more chips, prompt 'OUT OF CHIPS'
        // resolve players -- set the next player in game
        // but before setting the next player, check the player you wish to set, if the player is
        // still in round.
        // This after play has more to do -- it keeps close track of each round, and when it should
        // call the `resolve_round()` function
        }

        fn extract_current_game_id(self: @ContractState, player: @Player) -> u64 {
            // Extract current game id from the player
            let (is_locked, game_id) = *player.locked;

            // Assert player is actually locked in a game
            assert(is_locked, GameErrors::PLAYER_NOT_IN_GAME);

            // Make an assertion that the id isn't zero
            assert(game_id != 0, GameErrors::PLAYER_NOT_IN_GAME);

            // Return the id
            game_id
        }

        fn _get_dealer() -> Option<Player> {
            Option::None
        }

        fn _deal_hands(
            ref self: @ContractState, ref players: Array<Player>,
        ) { // deal hands for each player in the array
            assert(!players.is_empty(), 'Players cannot be empty');

            let first_player = players.at(0);
            let game_id = self.extract_current_game_id(first_player);

            for player in players.span() {
                let current_game_id = self.extract_current_game_id(player);
                assert(current_game_id == game_id, 'Players in different games');
            };

            let mut world = self.world_default();
            let game: Game = world.read_model(game_id);
            // TODO: Check the number of decks, and deal card from each deck equally
            let deck_ids: Array<u64> = game.deck;

            // let mut deck: Deck = world.read_model(game_id);
            let mut current_index: usize = 0;
            for mut player in players.span() {
                let mut hand: Hand = world.read_model(*player.id);
                hand.new_hand();

                for _ in 0_u8..2_u8 {
                    let index = current_index % deck_ids.len();
                    let deck_id: u64 = *deck_ids.at(index);
                    let mut deck: Deck = world.read_model(deck_id);
                    hand.add_card(deck.deal_card());

                    world.write_model(@deck); // should work, ;)
                    current_index += 1;
                };

                world.write_model(@hand);
                world.write_model(player);
            };
        }

        fn _resolve_hands(
            self: @ContractState, ref players: Array<Player>,
        ) { // after each round, resolve all players hands by removing all cards from each hand
            // and perhaps re-initialize and shuffle the deck.
            // Extract current game_id from each player (ensuring all players are in the same game)
            // TODO: Fix this function
            let mut game_id: u64 = 0;
            let players_len = players.len();

            assert(players_len > 0, 'Players array is empty');

            // Extract game_id from the first player for comparison
            let first_player = players.at(0);
            let (is_locked, player_game_id) = first_player.locked;

            // Assert the first player is in a game
            assert(*is_locked, GameErrors::PLAYER_NOT_IN_GAME);
            assert(*player_game_id != 0, GameErrors::PLAYER_NOT_IN_GAME);

            game_id = *player_game_id;

            // Verify all players are in the same game
            let mut i: u32 = 1;
            while i < players_len {
                let player = players.at(i);
                let (player_is_locked, player_game_id) = player.locked;

                // Assert the player is in a game
                assert(*player_is_locked, GameErrors::PLAYER_NOT_IN_GAME);
                // Assert all players are in the same game
                assert(*player_game_id == game_id, 'Players in different games');

                i += 1;
            };

            // Get the world storage
            let mut world = self.world_default();

            // Read the game from the world using game_id
            let mut game: Game = world.read_model(game_id);

            // Read and reset the deck from the game
            let mut decks: Array<u64> = game.deck;

            // Re-initialize the deck with the same game_id, for each deck in decks
            for deck_id in decks {
                let mut deck: Deck = world.read_model(deck_id);
                deck.new_deck();
                deck.shuffle();
                world.write_model(@deck); // should work, I guess.
            };

            // Clear each player's hand and update it in the world
            let mut j: u32 = 0;
            while j < players_len {
                // Get player reference and create a mutable copy
                let mut player = *players.at(j);

                // Clear the player's hand by creating a new empty hand
                let player_address = player.id;
                let mut hand: Hand = world.read_model(player_address);
                hand.new_hand();

                world.write_model(@hand);
                j += 1;
            };
        }

        fn _resolve_round(ref self: ContractState, game_id: u64) {// should call resolve_hands()
        // should write back the player and the game to the world
        // all players should be set back in the next round
        // increment number of rounds,
        // emit an event that a game_id round is open for others to join, only if necessary game
        // param checks have been cleared.
        }
    }
}
