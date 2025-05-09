<script>
import { s__ } from '~/locale';
import { createAlert } from '~/alert';
import { reportToSentry } from '~/ci/utils';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import InputsTableSkeletonLoader from './pipeline_inputs_table/inputs_table_skeleton_loader.vue';
import PipelineInputsTable from './pipeline_inputs_table/pipeline_inputs_table.vue';
import getPipelineInputsQuery from './graphql/queries/pipeline_creation_inputs.query.graphql';

const ARRAY_TYPE = 'ARRAY';

export default {
  name: 'PipelineInputsForm',
  components: {
    CrudComponent,
    InputsTableSkeletonLoader,
    PipelineInputsTable,
  },
  inject: ['projectPath'],
  props: {
    queryRef: {
      type: String,
      required: true,
    },
    savedInputs: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  emits: ['update-inputs'],
  data() {
    return {
      inputs: [],
    };
  },
  apollo: {
    inputs: {
      query: getPipelineInputsQuery,
      variables() {
        return {
          fullPath: this.projectPath,
          ref: this.queryRef,
        };
      },
      skip() {
        return !this.projectPath;
      },
      update({ project }) {
        const queryInputs = project?.ciPipelineCreationInputs || [];
        const savedInputsMap = Object.fromEntries(
          this.savedInputs.map(({ name, value }) => [name, value]),
        );

        // if there are any saved inputs, overwrite the values
        return queryInputs.map((input) => ({
          ...input,
          default: savedInputsMap[input.name] ?? input.default,
        }));
      },
      error(error) {
        this.createErrorAlert(error);
        reportToSentry(this.$options.name, error);
      },
    },
  },
  computed: {
    hasInputs() {
      return Boolean(this.inputs.length);
    },
    isLoading() {
      return this.$apollo.queries.inputs.loading;
    },
  },
  methods: {
    handleInputsUpdated(updatedInput) {
      this.inputs = this.inputs.map((input) =>
        input.name === updatedInput.name ? updatedInput : input,
      );

      const nameValuePairs = this.inputs.map((input) => {
        let value = input.default;

        // Convert string to array for ARRAY type inputs
        if (input.type === ARRAY_TYPE && typeof value === 'string' && value) {
          try {
            value = JSON.parse(value);
            if (!Array.isArray(value)) value = [value];
          } catch (e) {
            value = value.split(',').map((item) => item.trim());
          }
        }

        return { name: input.name, value };
      });

      this.$emit('update-inputs', nameValuePairs);
    },
    createErrorAlert(error) {
      const graphQLErrors = error?.graphQLErrors?.map((err) => err.message) || [];
      const message = graphQLErrors.length
        ? graphQLErrors.join(', ')
        : s__('Pipelines|There was a problem fetching the pipeline inputs. Please try again.');

      createAlert({ message });
    },
  },
};
</script>

<template>
  <crud-component
    :count="inputs.length"
    :description="__('Specify the input values to use in this pipeline.')"
    :title="s__('Pipelines|Inputs')"
    icon="code"
  >
    <inputs-table-skeleton-loader v-if="isLoading" />
    <template v-else>
      <pipeline-inputs-table v-if="hasInputs" :inputs="inputs" @update="handleInputsUpdated" />
      <div v-else class="gl-flex gl-justify-center gl-text-subtle">
        {{ s__('Pipelines|There are no inputs for this configuration.') }}
      </div>
    </template>
  </crud-component>
</template>
