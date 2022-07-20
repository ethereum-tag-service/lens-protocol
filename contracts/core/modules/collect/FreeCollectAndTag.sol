// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {IETSTargetTagger} from '@ets/monorepo/packages/contracts-core/contracts/interfaces/IETSTargetTagger.sol';
import {ICollectModule} from '../../../interfaces/ICollectModule.sol';
import {ModuleBase} from '../ModuleBase.sol';
import {FollowValidationModuleBase} from '../FollowValidationModuleBase.sol';
import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';

import 'hardhat/console.sol';

/**
 * @title FreeCollectAndTagModule
 * @author Ethereum Tag Service <team@ets.xyz>
 *
 * @notice This Collect Module provides an integration between Lens Protocol and Ethereum Tag Service.
 *
 * At it's core Ethereum Tag Service is a decentralized web service that enables third-party services
 * (dApps, platforms, applications, smart contracts) and/or their users to tag any
 * addressable online artifact (nft, URL, transaction record) and record it to the blockchain.
 * Once recorded, ETS indexes the tagging data and exposes it via public APIs.
 *
 * ETS employs a novel design whereby the tags themselves are ERC-721 non-fungible tokens making
 * them available for use by any participant of the system. These composable tags, or “CTAGs”, thus
 * become data hubs connecting people, places and things across Web 3.
 *
 * This Module has provides two ways to tag a publication: When it's posted and when it's collected.
 * Details to follow...
 */
contract FreeCollectAndTagModule is FollowValidationModuleBase, ICollectModule {
    using Strings for uint256;

    constructor(address hub) ModuleBase(hub) {}

    mapping(uint256 => mapping(uint256 => bool)) internal _followerOnlyByPublicationByProfile;

    /**
     * @dev Use collect module initialization to tag a publication when it's first created.
     */
    function initializePublicationCollectModule(
        uint256 profileId,
        uint256 pubId,
        bytes calldata data
    ) external override onlyHub returns (bytes memory) {
        (bool followerOnly, address publisher, string memory recordType, string[] memory tags) = abi
            .decode(data, (bool, address, string, string[]));
        if (followerOnly) _followerOnlyByPublicationByProfile[profileId][pubId] = true;
        if (tags.length > 0) {
            _processTags(profileId, pubId, publisher, recordType, tags);
        }

        return data;
    }

    /**
     * @dev Todo: Build out with similar pattern to initializePublicationCollectModule
     */
    function processCollect(
        uint256 referrerProfileId,
        address collector,
        uint256 profileId,
        uint256 pubId,
        bytes calldata data
    ) external view override {
        if (_followerOnlyByPublicationByProfile[profileId][pubId])
            _checkFollowValidity(profileId, collector);

        console.log('processCollect');
        string[] memory tags = abi.decode(data, (string[]));
        for (uint256 i; i < tags.length; ++i) {
            console.log(tags[i]);
        }
    }

    function _processTags(
        uint256 _profileId,
        uint256 _pubId,
        address _targetTagger,
        string memory _recordType,
        string[] memory _tags
    ) internal {
        string memory targetURI = string(
            abi.encodePacked(
                'blink:polygon:mumbai:',
                Strings.toHexString(uint160(HUB), 20),
                ':',
                _profileId.toString(),
                ':',
                _pubId.toString()
            )
        );

        IETSTargetTagger tagger = IETSTargetTagger(_targetTagger);

        IETSTargetTagger.TaggingRecord[]
            memory taggingRecords = new IETSTargetTagger.TaggingRecord[](1);
        IETSTargetTagger.TaggingRecord memory taggingRecord = IETSTargetTagger.TaggingRecord({
            targetURI: targetURI,
            tagStrings: _tags,
            recordType: _recordType,
            enrich: false
        });
        taggingRecords[0] = taggingRecord;
        tagger.tagTarget(taggingRecords);
    }
}
