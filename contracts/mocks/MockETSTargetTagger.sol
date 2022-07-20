// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {IETS} from '@ets/monorepo/packages/contracts-core/contracts/interfaces/IETS.sol';
import {IETSTarget} from '@ets/monorepo/packages/contracts-core/contracts/interfaces/IETSTarget.sol';
import {IETSTargetTagger} from '@ets/monorepo/packages/contracts-core/contracts/interfaces/IETSTargetTagger.sol';

import 'hardhat/console.sol';

/**
 * @dev Mock mplementation of an IETSTargetTagger for Ethereum Tag Service (ETS).
 * Used to test integration between Lens Protocol and Ethereum Tag Service.
 *
 * For the purposes of mocking a tagging record being written from Lens Protocol to
 * ETS, we only want to compute the taggingRecordId and emit it.
 */
contract MockETSTargetTagger is IETSTargetTagger {
    /// @notice Address and interface for ETS Core.
    IETS public ets;

    /// @notice Address and interface for ETS Target.
    IETSTarget public etsTarget;

    /// @notice machine name for this target tagger.
    string public constant name = 'MockETSTargetTagger';

    /**
     * @dev this event lives within ETS Core (ETS.sol), being moved here for the purposes
     * of mocking ETS from within Lens.
     */
    event TargetTagged(uint256 taggingRecordId);

    constructor(IETS _ets, IETSTarget _etsTarget) {
        ets = _ets;
        etsTarget = _etsTarget;
    }

    /**
     * @dev Mock the recording an ETS Tagging Record.
     *
     * Typically, an IETSTargetTagger contract calls into ETS Core to write a Tagging Record
     * and ETS Core (ETS.sol) would emit the new taggingRecordId.
     *
     * To mock this, we'll bypass all of this and emit the taggingRecordId right from this mock.
     */
    function tagTarget(TaggingRecord[] calldata _taggingRecords) public payable {
        for (uint256 i; i < _taggingRecords.length; ++i) {
            _mockProcessTaggingRecord(_taggingRecords[i], payable(msg.sender));
        }
    }

    /**
     * @dev Ordinarily, this is a meaty transaction and involves all the ETS contracts, including
     * ETSAccessControls.sol, ETSToken.sol & ETSTarget.sol. This mock bypasses all of that.
     */
    function _mockProcessTaggingRecord(
        TaggingRecord calldata _taggingRecord,
        address payable _tagger
    ) internal {
        // When ETS core writes a taggingRecordId, it maps to a struct that includes
        // the tags. For the purposes of this mock, we are only interested in the taggingRecordId,
        // not the data it points to.
        uint256 targetId = etsTarget.computeTargetId(_taggingRecord.targetURI);
        uint256 taggingRecordId = ets.computeTaggingRecordId(
            targetId,
            _taggingRecord.recordType,
            address(this),
            payable(msg.sender)
        );

        emit TargetTagged(taggingRecordId);
    }

    /**
     * @dev return the name of this IETSTargetTagger implementation.
     */
    function getTaggerName() public pure returns (string memory) {
        return name;
    }

    function toggleTargetTaggerPaused() external override {}

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {}

    function getCreator() external view returns (address payable) {}

    function getOwner() external view returns (address payable) {}

    function isTargetTaggerPaused() external view returns (bool) {}
}

contract MockETSTarget is IETSTarget {
    function computeTargetId(string memory _targetURI) external view returns (uint256 targetId) {
        bytes32 targetId = keccak256(bytes(_targetURI));
        return uint256(targetId);
    }

    function setAccessControls(address _etsAccessControls) external {}

    function setEnrichTarget(address _etsEnrichTarget) external {}

    function getOrCreateTargetId(string memory _targetURI) external returns (uint256) {}

    function createTarget(string memory _targetURI) external returns (uint256 targetId) {}

    function updateTarget(
        uint256 _targetId,
        string calldata _targetURI,
        uint256 _enriched,
        uint256 _httpstatus,
        string calldata _ipfsHash
    ) external returns (bool success) {}

    function targetExists(string memory _targetURI) external view returns (bool) {}

    function targetExists(uint256 _targetId) external view returns (bool) {}

    function getTarget(string memory _targetURI) external view returns (Target memory) {}

    function getTarget(uint256 _targetId) external view returns (Target memory) {}
}

contract MockETS is IETS {
    function computeTaggingRecordId(
        uint256 _targetId,
        string memory _recordType,
        address _publisher,
        address _tagger
    ) public pure returns (uint256 taggingRecordId) {
        taggingRecordId = uint256(
            keccak256(abi.encodePacked(_targetId, _recordType, _publisher, _tagger))
        );
    }

    function tagTarget(
        uint256[] calldata _tagIds,
        uint256 _targetId,
        string memory _recordType,
        address payable _tagger
    ) external payable {}

    function updateTaggingRecord(uint256 _taggingRecordId, string[] calldata _tags)
        external
        payable
    {}

    function drawDown(address payable _account) external {}

    function getTaggingRecord(
        uint256 _targetId,
        string memory _recordType,
        address _tagger,
        address _publisher
    )
        external
        view
        returns (
            uint256[] memory etsTagIds,
            uint256 targetId,
            string memory recordType,
            address tagger,
            address publisher
        )
    {}

    function getTaggingRecordFromId(uint256 _id)
        external
        view
        returns (
            uint256[] memory etsTagIds,
            uint256 targetId,
            string memory recordType,
            address tagger,
            address publisher
        )
    {}

    function totalDue(address _account) external view returns (uint256 _due) {}

    function taggingFee() external view returns (uint256) {}
}
