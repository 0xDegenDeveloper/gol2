use super::super::setup::deploy_mocks;
use openzeppelin::{
    upgrades::{
        UpgradeableComponent,
        interface::{IUpgradeable, IUpgradeableDispatcher, IUpgradeableDispatcherTrait}
    },
};
use gol2::{
    contracts::{gol::{IGoL2Dispatcher, IGoL2DispatcherTrait, GoL2}},
    utils::{
        constants::{
            INFINITE_GAME_GENESIS, DIM, FIRST_ROW_INDEX, LAST_ROW_INDEX, LAST_ROW_CELL_INDEX,
            FIRST_COL_INDEX, LAST_COL_INDEX, LAST_COL_CELL_INDEX, CREATE_CREDIT_REQUIREMENT,
            GIVE_LIFE_CREDIT_REQUIREMENT
        },
        test_contract::{ITestTraitDispatcher, ITestTraitDispatcherTrait}
    }
};
use starknet::{contract_address_const, class_hash_const};
use snforge_std::{
    declare, ContractClassTrait, start_prank, stop_prank, CheatTarget, spy_events, SpyOn, EventSpy,
    EventAssertions, get_class_hash,
};
use debug::PrintTrait;

#[test]
#[fork("GOERLI")]
fn test_upgrade_as_owner() {
    start_prank(CheatTarget::All(()), contract_address_const::<'admin'>());

    let (gol, _) = deploy_mocks();
    let hash_init = get_class_hash(gol.contract_address);
    let test_hash = declare('TestContract').class_hash;

    IUpgradeableDispatcher { contract_address: gol.contract_address }.upgrade(test_hash);
    let new_gol = ITestTraitDispatcher { contract_address: gol.contract_address };
    let upgraded_hash = get_class_hash(gol.contract_address);

    assert(hash_init != upgraded_hash, 'Hash not changed');
    assert(upgraded_hash == test_hash, 'Hash upgrade incorrect');
    assert(new_gol.x() == 123, 'Initializer failed');
    stop_prank(CheatTarget::All(()));
}

#[test]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_upgrade_as_non_owner() {
    let (gol, _) = deploy_mocks();
    let Upgrade = IUpgradeableDispatcher { contract_address: gol.contract_address };
    Upgrade.upgrade(declare('TestContract').class_hash);
}
