<script>
export default {
  props: {
    heading: {
      type: String,
      required: false,
      default: '',
    },
    description: {
      type: String,
      required: false,
      default: null,
    },
  },
};
</script>

<template>
  <section class="settings-section js-search-settings-section">
    <div class="settings-sticky-header">
      <div class="settings-sticky-header-inner">
        <h2 class="gl-heading-2 !gl-mb-2" data-testid="settings-section-heading">
          <slot v-if="$scopedSlots.heading" name="heading"></slot>
          <template v-else>{{ heading }}</template>
        </h2>
        <p
          v-if="$scopedSlots.description || description"
          class="gl-mb-3 gl-text-subtle"
          data-testid="settings-section-description"
        >
          <slot v-if="$scopedSlots.description" name="description"></slot>
          <template v-else>{{ description }}</template>
        </p>
      </div>
    </div>
    <div>
      <slot></slot>
    </div>
  </section>
</template>
