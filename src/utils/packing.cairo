use gol2::utils::constants::{LOW_ARRAY_LEN, HIGH_ARRAY_LEN, BOARD_SQUARED};
use alexandria_math::pow;

/// The game board is a 15x15 grid of cells:
///   0   1   2   3   4  ... 14  
///  15  16  17  18  19  ... 29  
///  ... ... ... ... ... ... ...
///  210 211 212 213 214 ... 224 

/// Cells can be alive or dead, imagined as a bit array:
/// [1, 1, 1, 0, 0, 0, 0, 0, ..., 0] 
///  ^0th cell is alive           ^224th cell is dead

/// This bit array represents a 225 bit integer, which is stored in the contract as a felt252
/// Cell array: [1, 1, 1, 0, 0,..., 0, 0] translates to binary: 0b00...000111, which is felt: 7

/// Translate a bit array into a felt252.
fn pack_cells(cells: Array<felt252>) -> felt252 {
    let mut mask = 0x1;
    let mut result = 0;
    let mut i = cells.len();

    loop {
        if i == 0 {
            break result;
        }
        result += *cells.at(cells.len() - i) * mask;
        mask *= 2;
        i -= 1;
    }
}


/// Create a cell (bit) array from a game state felt.
fn unpack_game(game: felt252) -> Array<felt252> {
    let game_int: u256 = game.into();
    assert(game_int.high < pow(2, HIGH_ARRAY_LEN.into()), 'GoL2: Game too big to unpack');
    let mut cell_array = array![];
    let mut mask: u256 = 0x1;
    let mut i: usize = 0;
    loop {
        if i == BOARD_SQUARED {
            break;
        }
        cell_array.append(if game_int & mask != 0 {
            1
        } else {
            0
        });
        mask *= 2;
        i += 1;
    };
    cell_array
}

/// Create a game state from a cell (bit) array
fn pack_game(cells: Array<felt252>) -> felt252 {
    assert(cells.len() == BOARD_SQUARED, 'GoL2: Invalid cell array length');
    pack_cells(cells)
}

/// Toggle a cell index alive and return the new game state.
fn revive_cell(cell_index: usize, current_state: felt252) -> felt252 {
    let current_state_int: u256 = current_state.into();
    let activated_bit: u256 = if cell_index < LOW_ARRAY_LEN.into() {
        u256 { low: pow(2, cell_index.into()), high: 0 }
    } else {
        u256 { low: 0, high: pow(2, (cell_index - LOW_ARRAY_LEN).into()) }
    };

    let updated: u256 = current_state_int | activated_bit;
    updated.try_into().unwrap()
}
