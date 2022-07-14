// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {IETSTargetTagger} from '../../../../node_modules/ets/packages/contracts-core/contracts/interfaces/IETSTargetTagger.sol';
import {ICollectModule} from '../../../interfaces/ICollectModule.sol';
import {ModuleBase} from '../ModuleBase.sol';
import {FollowValidationModuleBase} from '../FollowValidationModuleBase.sol';

import 'hardhat/console.sol';

/**
 * @title FreeCollectAndTagModule
 * @author Lens Protocol
 *
 * @notice This is a simple Lens CollectModule implementation, inheriting from the ICollectModule interface.
 *
 * This module works by allowing all collects.
 */
contract FreeCollectAndTagModule is FollowValidationModuleBase, ICollectModule {
    constructor(address hub) ModuleBase(hub) {}

    mapping(uint256 => mapping(uint256 => bool)) internal _followerOnlyByPublicationByProfile;

    /**
     * @dev There is nothing needed at initialization.
     */
    function initializePublicationCollectModule(
        uint256 profileId,
        uint256 pubId,
        bytes calldata data
    ) external override onlyHub returns (bytes memory) {
        (bool followerOnly, string[] memory tags) = abi.decode(data, (bool, string[]));
        if (followerOnly) _followerOnlyByPublicationByProfile[profileId][pubId] = true;
        console.log('initializePublicationCollectModule');
        for (uint256 i; i < tags.length; ++i) {
            console.log(tags[i]);
        }
        return data;
    }

    /**
     * @dev Processes a collect by:
     *  1. Ensuring the collector is a follower, if needed
     */
    function processCollect(
        uint256 referrerProfileId,
        address collector,
        uint256 profileId,
        uint256 pubId,
        bytes calldata data
    ) external view override {
        string[] memory tags = abi.decode(data, (string[]));
        for (uint256 i; i < tags.length; ++i) {
            console.log('processCollect', tags[i]);
        }

        if (_followerOnlyByPublicationByProfile[profileId][pubId])
            _checkFollowValidity(profileId, collector);
    }
}
