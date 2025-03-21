import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import BlobControls from '~/repository/components/header_area/blob_controls.vue';
import blobControlsQuery from '~/repository/queries/blob_controls.query.graphql';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import createRouter from '~/repository/router';
import { updateElementsVisibility } from '~/repository/utils/dom';
import { resetShortcutsForTests } from '~/behaviors/shortcuts';
import ShortcutsBlob from '~/behaviors/shortcuts/shortcuts_blob';
import Shortcuts from '~/behaviors/shortcuts/shortcuts';
import BlobLinePermalinkUpdater from '~/blob/blob_line_permalink_updater';
import OverflowMenu from '~/repository/components/header_area/blob_overflow_menu.vue';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import OpenMrBadge from '~/repository/components/header_area/open_mr_badge.vue';
import { blobControlsDataMock, refMock } from '../../mock_data';

jest.mock('~/repository/utils/dom');
jest.mock('~/behaviors/shortcuts/shortcuts_blob');
jest.mock('~/blob/blob_line_permalink_updater');

let router;
let wrapper;
let mockResolver;

const createComponent = async ({
  props = {},
  blobInfoOverrides = {},
  glFeatures = { blobOverflowMenu: false },
  routerOverride = {},
} = {}) => {
  Vue.use(VueApollo);

  const projectPath = 'some/project';
  router = createRouter(projectPath, refMock);

  await router.push({
    name: 'blobPathDecoded',
    params: { path: '/some/file.js' },
    ...routerOverride,
  });

  mockResolver = jest.fn().mockResolvedValue({
    data: {
      project: {
        __typename: 'Project',
        id: '1234',
        repository: {
          __typename: 'Repository',
          empty: blobControlsDataMock.repository.empty,
          blobs: {
            __typename: 'RepositoryBlobConnection',
            nodes: [{ ...blobControlsDataMock.repository.blobs.nodes[0], ...blobInfoOverrides }],
          },
        },
      },
    },
  });

  await resetShortcutsForTests();

  wrapper = shallowMountExtended(BlobControls, {
    router,
    apolloProvider: createMockApollo([[blobControlsQuery, mockResolver]]),
    provide: {
      glFeatures,
      currentRef: refMock,
    },
    propsData: {
      projectPath,
      isBinary: false,
      refType: 'heads',
      ...props,
    },
    mixins: [{ data: () => ({ ref: refMock }) }, glFeatureFlagMixin()],
  });

  await waitForPromises();
};

describe('Blob controls component', () => {
  const findOpenMrBadge = () => wrapper.findComponent(OpenMrBadge);
  const findFindButton = () => wrapper.findByTestId('find');
  const findBlameButton = () => wrapper.findByTestId('blame');
  const findPermalinkButton = () => wrapper.findByTestId('permalink');
  const findOverflowMenu = () => wrapper.findComponent(OverflowMenu);
  const { bindInternalEventDocument } = useMockInternalEventsTracking();

  beforeEach(async () => {
    await createComponent();
  });

  describe('MR badge', () => {
    it('should render the baadge if `filter_blob_path` flag is on', async () => {
      await createComponent({ glFeatures: { filterBlobPath: true } });
      expect(findOpenMrBadge().exists()).toBe(true);
      expect(findOpenMrBadge().props('blobPath')).toBe('/some/file.js');
      expect(findOpenMrBadge().props('projectPath')).toBe('some/project');
    });

    it('should not render the baadge if `filter_blob_path` flag is off', async () => {
      await createComponent({ glFeatures: { filterBlobPath: false } });
      expect(findOpenMrBadge().exists()).toBe(false);
    });
  });

  describe('showBlobControls', () => {
    it('should not render blob controls when filePath does not exist', async () => {
      await createComponent({
        routerOverride: { name: 'blobPathDecoded', params: null },
      });
      expect(wrapper.element).not.toBeVisible();
    });

    it('should not render blob controls when route name is not blobPathDecoded', async () => {
      await createComponent({
        routerOverride: { name: 'blobPath', params: { path: '/some/file.js' } },
      });
      expect(wrapper.element).not.toBeVisible();
    });
  });

  describe('FindFile button', () => {
    it('renders FindFile button', () => {
      expect(findFindButton().exists()).toBe(true);
    });

    it('triggers a `focusSearchFile` shortcut when the findFile button is clicked', () => {
      const findFileButton = findFindButton();
      jest.spyOn(Shortcuts, 'focusSearchFile').mockResolvedValue();
      findFileButton.vm.$emit('click');

      expect(Shortcuts.focusSearchFile).toHaveBeenCalled();
    });

    it('emits a tracking event when the Find file button is clicked', () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);
      jest.spyOn(Shortcuts, 'focusSearchFile').mockResolvedValue();

      findFindButton().vm.$emit('click');

      expect(trackEventSpy).toHaveBeenCalledWith('click_find_file_button_on_repository_pages');
    });
  });

  describe('Blame button', () => {
    it('renders a blame button with the correct href', () => {
      expect(findBlameButton().attributes('href')).toBe('blame/file.js');
    });

    it('does not render blame button when blobInfo.storedExternally is true', async () => {
      await createComponent({ blobInfoOverrides: { storedExternally: true } });

      expect(findBlameButton().exists()).toBe(false);
    });

    it('does not render blame button when blobInfo.externalStorage is "lfs"', async () => {
      await createComponent({
        blobInfoOverrides: { storedExternally: true, externalStorage: 'lfs' },
      });

      expect(findBlameButton().exists()).toBe(false);
    });

    it('renders blame button when blobInfo.storedExternally is false and externalStorage is not "lfs"', async () => {
      await createComponent({}, { storedExternally: false, externalStorage: null });

      expect(findBlameButton().exists()).toBe(true);
    });
  });

  it('renders a permalink button with the correct href', () => {
    expect(findPermalinkButton().attributes('href')).toBe('permalink/file.js');
  });

  it.each`
    name                 | path
    ${'blobPathDecoded'} | ${null}
    ${'treePathDecoded'} | ${'myFile.js'}
  `(
    'does not render any buttons if router name is $name and router path is $path',
    async ({ name, path }) => {
      await router.replace({ name, params: { path } });

      await nextTick();

      expect(findFindButton().exists()).toBe(false);
      expect(findBlameButton().exists()).toBe(false);
      expect(findPermalinkButton().exists()).toBe(false);
      expect(updateElementsVisibility).toHaveBeenCalledWith('.tree-controls', true);
    },
  );

  it('loads the ShortcutsBlob', () => {
    expect(ShortcutsBlob).toHaveBeenCalled();
  });

  it('loads the BlobLinePermalinkUpdater', () => {
    expect(BlobLinePermalinkUpdater).toHaveBeenCalled();
  });

  describe('BlobOverflow dropdown', () => {
    beforeEach(async () => {
      await createComponent({ glFeatures: { blobOverflowMenu: true } });
    });

    it('renders BlobOverflow component with correct props', () => {
      expect(findOverflowMenu().exists()).toBe(true);
      expect(findOverflowMenu().props()).toEqual({
        projectPath: 'some/project',
        isBinary: true,
        overrideCopy: true,
        isEmptyRepository: false,
        isUsingLfs: false,
      });
    });

    it('passes the correct isBinary value to BlobOverflow when viewing a binary file', async () => {
      await createComponent({
        props: {
          isBinary: true,
        },
        blobInfoOverrides: {
          simpleViewer: {
            ...blobControlsDataMock.repository.blobs.nodes[0].simpleViewer,
            fileType: 'podfile',
          },
        },
        glFeatures: {
          blobOverflowMenu: true,
        },
      });

      expect(findOverflowMenu().props('isBinary')).toBe(true);
    });

    it('copies to clipboard raw blob text, when receives copy event', () => {
      jest.spyOn(navigator.clipboard, 'writeText');
      findOverflowMenu().vm.$emit('copy');

      expect(navigator.clipboard.writeText).toHaveBeenCalledWith('Example raw text content');
    });
  });
});
