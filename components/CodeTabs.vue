<template>
  <div class="border border-gray-300 rounded-md overflow-hidden mt-4 shadow-sm bg-white">
    <div class="flex bg-gray-100 border-b border-gray-300">
      <button 
        class="flex-1 py-2 font-bold transition-colors text-sm"
        :class="activeTab === 1 ? 'bg-white text-blue-600 border-b-2 border-blue-600' : 'text-gray-500 hover:bg-gray-200'"
        @click="activeTab = 1"
      >
        {{ tab1 }}
      </button>
      <button 
        class="flex-1 py-2 font-bold transition-colors text-sm"
        :class="activeTab === 2 ? 'bg-white text-blue-600 border-b-2 border-blue-600' : 'text-gray-500 hover:bg-gray-200'"
        @click="activeTab = 2"
      >
        {{ tab2 }}
      </button>
    </div>

    <div class="p-4">
      <div v-show="activeTab === 1">
        <slot name="content1"></slot>
      </div>
      <div v-show="activeTab === 2">
        <slot name="content2"></slot>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'

const props = defineProps({
  tab1: { type: String, default: 'コード' },
  tab2: { type: String, default: '実行結果' }
})

const activeTab = ref(1) // 最初はタブ1を開いておく
</script>