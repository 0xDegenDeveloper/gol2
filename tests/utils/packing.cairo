use gol2::utils::{
    packing::{pack_cells, pack_game, unpack_game, revive_cell}, constants::{HIGH_ARRAY_LEN}
};
use alexandria_math::pow;

#[test]
fn test_pack_cells() {
    let cells = array![0];
    let packed = pack_cells(cells);
    assert(packed == 0, 'Packed cells invalid');
    let cells = array![1];
    let packed = pack_cells(cells);
    assert(packed == 1, 'Packed cells invalid1');
    let cells = array![0, 0, 0, 0, 1, 0, 0, 0, 0];
    let packed = pack_cells(cells);
    assert(packed == 16, 'Packed cells invalid2');
    let cells = array![1, 0, 0, 1, 1, 0, 1]; // 1 + 8 + 16 + 64 = 89
    let packed = pack_cells(cells);
    assert(packed == 89, 'Packed cells invalid3')
}

#[test]
fn test_unpack_game() {
    let acorn: felt252 = 39132555273291485155644251043342963441664;
    let game: felt252 = 16;
    let unpacked: Array<felt252> = unpack_game(acorn);
    let unpacked_game: Array<felt252> = unpack_game(game);

    assert(unpacked.len() == 225, 'Unpacked acorn incorrect length');
    assert(unpacked_game.len() == 225, 'Unpacked game incorrect length');

    let mut i = 0;
    loop {
        if i >= 225 {
            break ();
        } else {
            let cell = *unpacked.at(i);
            let cell2 = *unpacked_game.at(i);
            if i == 128 || i == 129 || i == 132 || i == 133 || i == 134 || i == 116 || i == 99 {
                assert(cell == 1, 'Acorn cell should be alive');
            } else {
                if i == 4 {
                    assert(cell == 0, 'Acorn cell should be dead');
                    assert(cell2 == 1, 'Game cell should be alive');
                } else {
                    assert(cell == 0, 'Acorn cell should be dead');
                    assert(cell2 == 0, 'Acorn cell should be dead');
                }
            }
        }
        i += 1;
    }
}

#[test]
fn test_pack_game() {
    let mut cell_array: Array<felt252> = array![];
    let mut i: usize = 0;
    loop {
        if i >= 225 {
            break ();
        }
        cell_array.append(if i == 4 {
            1
        } else {
            0
        });

        i += 1;
    };

    let packed: felt252 = pack_game(cell_array);
    assert(packed == 16, 'Packed game incorrect');
}

#[test]
fn test_pack_game_acorn() {
    /// Unpacked acorn game state
    let unpacked: Array<felt252> = unpack_game(39132555273291485155644251043342963441664);
    assert(unpacked.clone().len() == 225, 'Unpacked game incorrect length');

    /// Recreate acorn bit array
    let mut acorn: Array<felt252> = array![];
    let mut i: usize = 0;
    loop {
        if i >= 225 {
            break ();
        } else {
            acorn
                .append(
                    if i == 128
                        || i == 129
                        || i == 132
                        || i == 133
                        || i == 134
                        || i == 116
                        || i == 99 {
                        1
                    } else {
                        0
                    }
                );

            /// Check unpacked matches acorn (done in this loop to fit steps in 1 test)
            assert(*unpacked.at(i) == *acorn.at(i), 'Array mismatch');
            i += 1;
        }
    };
    assert(acorn.len() == 225, 'Acorn incorrect length');
    /// Pack acorn bit array and check against original game state
    assert(pack_game(acorn) == 39132555273291485155644251043342963441664, 'Packed game incorrect');
}

#[test]
fn test_maximum_packed_game() {
    /// 225 cells, all alive
    let mut game: Array<felt252> = array![];
    let mut i: usize = 0;
    loop {
        if i >= 225 {
            break ();
        }
        game.append(1);
        i += 1;
    };

    /// Max game state as felt
    let packed_game: felt252 = pack_game(game);
    assert(
        packed_game == 53919893334301279589334030174039261347274288845081144962207220498431,
        'Packed game incorrect'
    );

    /// Max game state as integer
    let packed_game_as_int: u256 = packed_game.into();
    assert(
        packed_game_as_int.low == 340282366920938463463374607431768211455,
        'Packed game incorrect (low)'
    );
    assert(
        packed_game_as_int.high == 158456325028528675187087900671, 'Packed game incorrect (high)'
    );
}

#[test]
fn test_maximum_unpacked_game() {
    let game_id: felt252 =
        53919893334301279589334030174039261347274288845081144962207220498431; // 2^225 - 1
    let mut unpacked_game: Array<felt252> = unpack_game(game_id);
    assert(unpacked_game.len() == 225, 'Unpacked game incorrect length');
    loop {
        let cell = unpacked_game.pop_front();
        if cell.is_none() {
            break ();
        }
        assert(cell.unwrap() == 1, 'Unpacked game incorrect');
    };
}

#[test]
#[should_panic(expected: ('GoL2: Invalid cell array length',))]
fn test_overloaded_packed_game() {
    let mut game: Array<felt252> = array![];
    let mut i: usize = 0;
    loop {
        if i >= 226 {
            break ();
        } else {
            game.append(1);
        }
        i += 1;
    };

    /// Max game state as felt
    let packed_game: felt252 = pack_game(game);
}


#[test]
#[should_panic(expected: ('GoL2: Invalid cell array length',))]
fn test_underloaded_packed_game() {
    let mut game: Array<felt252> = array![];
    let mut i: usize = 0;
    loop {
        if i >= 224 {
            break ();
        } else {
            game.append(1);
        }
        i += 1;
    };

    /// Max game state as felt
    let packed_game: felt252 = pack_game(game);
}

#[test]
#[should_panic(expected: ('GoL2: Game too big to unpack',))]
fn test_overloaded_unpacked_game() {
    let game_id: felt252 = 53919893334301279589334030174039261347274288845081144962207220498431 + 1;
    let mut unpacked_game: Array<felt252> = unpack_game(game_id);
}

#[test]
fn test_revive_cell() {
    let state: felt252 = 39132555273291485155644251043342963441664;
    /// Revive 0th cell (top left; lowest bit in binary representation)
    let revived: felt252 = revive_cell(0, state);
    assert(revived == state + 1, 'Revived cell incorrect');
    /// Revive 1st cell (top left + 1 to right; 2nd lowest bit in binary representation)
    let revived: felt252 = revive_cell(1, state);
    assert(revived == state + 2, 'Revived cell incorrect');
    /// Revive last cell (bottom right; 225th bit in binary representation)
    let revived: felt252 = revive_cell(224, state);
    let POW_2_224: u256 = u256 { low: 0, high: pow(2, HIGH_ARRAY_LEN.into() - 1) };
    assert(revived == state + POW_2_224.try_into().unwrap(), 'Revived cell incorrect');
}
