<template>
  <div class="relative mt-8 font-serif pr-12">
    <div v-if="!isReady" class="text-gray-400 text-sm animate-pulse mb-2">
      辞書データ準備中...
    </div>

    <button
      :disabled="!isReady"
      @click="playKaraoke"
      class="absolute top-2 right-0 text-gray-500 hover:text-gray-800 transition-colors cursor-pointer disabled:opacity-30 disabled:cursor-not-allowed"
      title="読み上げを再生"
    >
      <svg class="w-8 h-8" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
        <path fill="currentColor" d="M3 9v6h4l5 5V4L7 9H3zm13.5 3c0-1.77-1.02-3.29-2.5-4.03v8.05c1.48-.73 2.5-2.25 2.5-4.02zM14 3.23v2.06c2.89.86 5 3.54 5 6.71s-2.11 5.85-5 6.71v2.06c4.01-.91 7-4.49 7-8.77s-2.99-7.86-7-8.77z"/>
      </svg>
    </button>

    <div class="text-3xl leading-loose">
      <span
        v-for="(token, index) in tokens"
        :key="index"
        :class="getHighlightColor(token.pos, index, activeTokenIndex)"
        class="text-gray-800 transition-all duration-150 rounded px-1 mx-px inline-block"
      >{{ token.word }}</span>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, watch } from 'vue'

const props = defineProps({
  text: { type: String, required: true },
  speed: { type: Number, default: 1.0 },
  gender: { type: String, default: 'female' },
  pitch: { type: Number, default: 1.2 }
})

const tokens = ref([])
const activeTokenIndex = ref(-1)
const isReady = ref(false)

onMounted(() => {
  if (window.kuromoji) {
    initTokenizer()
  } else {
    const script = document.createElement('script')
    script.src = 'https://unpkg.com/kuromoji@0.1.2/build/kuromoji.js'
    script.onload = () => initTokenizer()
    document.head.appendChild(script)
  }
})

function initTokenizer() {
  // Docker環境でも404になりにくい unpkg のパスを指定
  const DIC_PATH = 'https://unpkg.com/kuromoji@0.1.2/dict'

  window.kuromoji.builder({ dicPath: DIC_PATH }).build((err, tokenizer) => {
    if (err) {
      console.error("Kuromoji Init Error:", err)
      return
    }
    
    const parsed = tokenizer.tokenize(props.text)
    let currentIndex = 0
    
    tokens.value = parsed.map(t => {
      const res = {
        word: t.surface_form,
        pos: t.pos,
        startIndex: currentIndex,
        endIndex: currentIndex + t.surface_form.length
      }
      currentIndex += t.surface_form.length
      return res
    })
    isReady.value = true
  })
}

// テキストが変わったら再解析
watch(() => props.text, () => {
  if (isReady.value) initTokenizer()
})

function playKaraoke() {
  speechSynthesis.cancel()
  activeTokenIndex.value = -1

  const msg = new SpeechSynthesisUtterance(props.text)
  msg.lang = 'ja-JP'
  msg.rate = props.speed
  msg.pitch = props.pitch

  // 音声（Gender）の設定
  const voices = speechSynthesis.getVoices()
  const jaVoices = voices.filter(v => v.lang === 'ja-JP')
  let selectedVoice = null

  if (props.gender === 'male') {
    selectedVoice = jaVoices.find(v => /Keita|Ichiro|Male/i.test(v.name))
  } else {
    selectedVoice = jaVoices.find(v => /Nanami|Google|Female/i.test(v.name))
  }
  
  msg.voice = selectedVoice || jaVoices[0]

  // ハイライト制御
  msg.onboundary = (event) => {
    const targetIndex = tokens.value.findIndex(t => event.charIndex >= t.startIndex && event.charIndex < t.endIndex)
    if (targetIndex !== -1) activeTokenIndex.value = targetIndex
  }
  msg.onend = () => { activeTokenIndex.value = -1 }

  speechSynthesis.speak(msg)
}

function getHighlightColor(pos, index, activeIndex) {
  // 現在読んでいる単語の背景色（黄色）
  if (index === activeIndex) return 'bg-yellow-300 scale-110 shadow-sm z-10'

  // 品詞ごとの文字色分け
  if (pos === '名詞') return 'text-blue-600'
  if (pos === '動詞') return 'text-green-600'
  if (pos === '形容詞') return 'text-purple-600'
  if (pos === '助詞' || pos === '助動詞') return 'text-gray-400'
  return 'text-gray-800'
}
</script>
