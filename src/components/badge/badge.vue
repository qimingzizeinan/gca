<template>
  <div class="container">
    <sup class="sup">{{ value }}</sup>
    <slot></slot>
  </div>
</template>
<script setup lang="ts">
interface IBadge {
  value: number;
}
withDefaults(defineProps<IBadge>(), {
  value: 0,
});
</script>
<style lang="scss" scoped>
.container {
  position: relative;
  display: inline-block;
  .sup {
    font-size: 12px;
    height: 16px;
    padding: 0 6px;
    border-radius: 16px;
    display: flex;
    justify-content: center;
    align-items: center;
    background-color: blue;
    color: #fff;
    position: absolute;
    top: 0;
    right: 0;
    transform: translate(50%, -50%);
  }
}
</style>
