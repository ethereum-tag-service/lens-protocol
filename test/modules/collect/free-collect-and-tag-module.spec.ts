import '@nomiclabs/hardhat-ethers';
import { utils } from 'ethers';
import { expect } from 'chai';
import { ZERO_ADDRESS } from '../../helpers/constants';
import { ERRORS } from '../../helpers/errors';
import { getTimestamp, matchEvent, waitForTx } from '../../helpers/utils';
import {
  approvalFollowModule,
  FIRST_PROFILE_ID,
  governance,
  lensHub,
  makeSuiteCleanRoom,
  MOCK_FOLLOW_NFT_URI,
  MOCK_PROFILE_HANDLE,
  MOCK_PROFILE_URI,
  MOCK_URI,
  deployer,
  user,
  userAddress,
  userTwo,
  userTwoAddress,
  abiCoder,
} from '../../__setup.spec';

import {
  MockETS,
  MockETS__factory,
  MockETSTarget,
  MockETSTarget__factory,
  MockETSTargetTagger,
  MockETSTargetTagger__factory,
  FreeCollectAndTagModule,
  FreeCollectAndTagModule__factory,
} from '../../../typechain-types';

let mockETS: MockETS;
let mockETSTarget: MockETSTarget;
let mockETSTargetTagger: MockETSTargetTagger;
let freeCollectAndTagModule: FreeCollectAndTagModule;

makeSuiteCleanRoom('Free Collect & Tag via Ethereum Tag Service Module', function () {
  beforeEach(async function () {
    mockETS = await new MockETS__factory(deployer).deploy();
    mockETSTarget = await new MockETSTarget__factory(deployer).deploy();
    mockETSTargetTagger = await new MockETSTargetTagger__factory(deployer).deploy(
      mockETS.address,
      mockETSTarget.address
    );
    freeCollectAndTagModule = await new FreeCollectAndTagModule__factory(deployer).deploy(
      lensHub.address
    );

    await expect(
      lensHub.createProfile({
        to: userAddress,
        handle: MOCK_PROFILE_HANDLE,
        imageURI: MOCK_PROFILE_URI,
        followModule: ZERO_ADDRESS,
        followModuleInitData: [],
        followNFTURI: MOCK_FOLLOW_NFT_URI,
      })
    ).to.not.be.reverted;
    await expect(
      lensHub.connect(governance).whitelistCollectModule(freeCollectAndTagModule.address, true)
    ).to.not.be.reverted;
  });

  context('Scenarios', function () {
    it.only('User should post with the freeCollectAndTagModule as the collect module, successfully tag new publication and ETS emits new taggingRecordId', async function () {
      expect(await mockETSTargetTagger.connect(userTwo).getTaggerName()).to.equal(
        'MockETSTargetTagger'
      );

      let targetURI = 'blink:polygon:mumbai:' + lensHub.address.toString().toLowerCase() + ':1:1';
      const targetId = await mockETSTarget.computeTargetId(targetURI);
      const taggingRecordId = await mockETS.computeTaggingRecordId(
        targetId,
        'bookmark',
        mockETSTargetTagger.address,
        freeCollectAndTagModule.address
      );

      await expect(
        lensHub.connect(user).post({
          profileId: FIRST_PROFILE_ID,
          contentURI: MOCK_URI,
          collectModule: freeCollectAndTagModule.address,
          collectModuleInitData: abiCoder.encode(
            ['bool', 'address', 'string', 'string[]'],
            [false, mockETSTargetTagger.address, 'bookmark', ['#love', '#hate']]
          ),
          referenceModule: ZERO_ADDRESS,
          referenceModuleInitData: [],
        })
      )
        .to.emit(mockETSTargetTagger, 'TargetTagged')
        .withArgs(taggingRecordId);
    });

    it.only('User should post with the freeCollectAndTagModule as the collect module, but not tag the post', async function () {
      let targetURI = 'blink:polygon:mumbai:' + lensHub.address.toString().toLowerCase() + ':1:1';
      const targetId = await mockETSTarget.computeTargetId(targetURI);
      const taggingRecordId = await mockETS.computeTaggingRecordId(
        targetId,
        'bookmark',
        mockETSTargetTagger.address,
        freeCollectAndTagModule.address
      );

      await expect(
        lensHub.connect(user).post({
          profileId: FIRST_PROFILE_ID,
          contentURI: MOCK_URI,
          collectModule: freeCollectAndTagModule.address,
          collectModuleInitData: abiCoder.encode(
            ['bool', 'address', 'string', 'string[]'],
            [false, mockETSTargetTagger.address, '', []]
          ),
          referenceModule: ZERO_ADDRESS,
          referenceModuleInitData: [],
        })
      ).to.not.emit(mockETSTargetTagger, 'TargetTagged');
    });
  });
});
