<template>
  <div :class="['border-l-4 rounded-r-md p-4 my-4 shadow-sm', theme.bg, theme.border]">
    <div class="flex items-center mb-2">
      <span class="text-xl mr-2">{{ theme.icon }}</span>
      <span :class="['font-bold text-lg', theme.text]">{{ title }}</span>
    </div>
    <div class="text-gray-800 leading-relaxed text-base">
      <slot></slot>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  type: { type: String, default: 'info' }, // info, hint, warning, danger の4種類
  title: { type: String, required: true }
})

// 指定された type に応じて、色とアイコンを自動で切り替える
const theme = computed(() => {
  switch (props.type) {
    case 'hint':
      return { bg: 'bg-green-50', border: 'border-green-500', text: 'text-green-700', icon: '💡' }
    case 'warning':
      return { bg: 'bg-orange-50', border: 'border-orange-500', text: 'text-orange-700', icon: '⚠️' }
    case 'danger':
      return { bg: 'bg-red-50', border: 'border-red-500', text: 'text-red-700', icon: '🚨' }
    case 'info':
    default:
      return { bg: 'bg-blue-50', border: 'border-blue-500', text: 'text-blue-700', icon: 'ℹ️' }
  }
})
</script>