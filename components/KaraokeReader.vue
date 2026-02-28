<template>
  <div class="relative mt-8 font-serif pr-12">
    <button
      @click="playKaraoke"
      class="absolute top-2 right-0 text-gray-500 hover:text-gray-800 transition-colors cursor-pointer"
      title="読み上げを再生"
    >
      <svg class="w-8 h-8" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
        <path fill="currentColor" d="M3 9v6h4l5 5V4L7 9H3zm13.5 3c0-1.77-1.02-3.29-2.5-4.03v8.05c1.48-.73 2.5-2.25 2.5-4.02zM14 3.23v2.06c2.89.86 5 3.54 5 6.71s-2.11 5.85-5 6.71v2.06c4.01-.91 7-4.49 7-8.77s-2.99-7.86-7-8.77z"/>
      </svg>
    </button>

    <div class="text-3xl leading-loose text-gray-800">
      <template v-if="tokens.length === 0">
        {{ text }}
      </template>
      <template v-else>
        <span
          v-for="(token, index) in tokens"
          :key="index"
          :class="[
            'transition-all duration-150 rounded px-1 mx-px inline-block',
            index === activeTokenIndex ? 'bg-yellow-300 text-black shadow-sm scale-105' : 'bg-transparent'
          ]"
        >{{ token.word }}</span>
      </template>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, watch } from 'vue'

const props = defineProps({
  text: { type: String, required: true },
  audioOnly: { type: Boolean, default: false },
  speed: { type: Number, default: 1.0 },
  gender: { type: String, default: 'female' }
})

const tokens = ref([])
const activeTokenIndex = ref(-1)

// 解析処理：外部スクリプトを読み込み、準備ができたら分割する
function initBudouX() {
  if (window.BudouX) {
    parseText()
    return
  }

  const script = document.createElement('script')
  script.src = 'https://unpkg.com/budoux/bundle/budoux-ja.min.js'
  script.onload = () => {
    parseText()
  }
  document.head.appendChild(script)
}

function parseText() {
  if (!window.BudouX) return
  
  const parser = window.BudouX.loadDefaultJapaneseParser()
  const segments = parser.parse(props.text)
  
  let currentIndex = 0
  tokens.value = segments.map(word => {
    const tokenInfo = {
      word: word,
      startIndex: currentIndex,
      endIndex: currentIndex + word.length
    }
    currentIndex += word.length
    return tokenInfo
  })
}

onMounted(() => {
  initBudouX()
})

// テキストが切り替わった時に再解析
watch(() => props.text, () => {
  parseText()
}, { immediate: true })

function playKaraoke() {
  speechSynthesis.cancel()
  activeTokenIndex.value = -1

  const msg = new SpeechSynthesisUtterance(props.text)
  msg.lang = 'ja-JP'
  msg.rate = props.speed

  const voices = speechSynthesis.getVoices()
  const jaVoices = voices.filter(v => v.lang === 'ja-JP')
  
  let voice = jaVoices.find(v => props.gender === 'male' ? /Keita|Ichiro|Male/i.test(v.name) : /Nanami|Google|Female/i.test(v.name))
  if (voice) msg.voice = voice

  // ハイライト制御（tokensがある場合のみ実行）
  if (tokens.value.length > 0) {
    msg.onboundary = (event) => {
      const charIndex = event.charIndex
      const targetIndex = tokens.value.findIndex(t => charIndex >= t.startIndex && charIndex < t.endIndex)
      if (targetIndex !== -1) {
        activeTokenIndex.value = targetIndex
      }
    }
    msg.onend = () => {
      activeTokenIndex.value = -1
    }
  }

  speechSynthesis.speak(msg)
}
</script>