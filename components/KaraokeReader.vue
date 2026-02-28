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

    <div v-if="audioOnly" class="text-3xl leading-loose text-gray-800">
      {{ text }}
    </div>

    <div v-else class="text-3xl leading-loose">
      <span
        v-for="(token, index) in tokens"
        :key="index"
        :class="index === activeTokenIndex ? 'bg-yellow-300 text-black shadow-sm' : 'bg-transparent'"
        class="text-gray-800 transition-all duration-150 rounded px-1 mx-px inline-block"
      >{{ token.word }}</span>
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

// BudouX を使ってテキストを分割する
async function initTokenizer() {
  // BudouX の軽量スクリプトを読み込む
  if (!window.BudouX) {
    await new Promise((resolve) => {
      const script = document.createElement('script')
      script.src = 'https://unpkg.com/budoux/bundle/budoux-ja.min.js'
      script.onload = resolve
      document.head.appendChild(script)
    })
  }

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
  initTokenizer()
})

watch(() => props.text, () => {
  initTokenizer()
})

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

  if (!props.audioOnly) {
    msg.onboundary = (event) => {
      const targetIndex = tokens.value.findIndex(t => event.charIndex >= t.startIndex && event.charIndex < t.endIndex)
      if (targetIndex !== -1) activeTokenIndex.value = targetIndex
    }
    msg.onend = () => { activeTokenIndex.value = -1 }
  }

  speechSynthesis.speak(msg)
}
</script>