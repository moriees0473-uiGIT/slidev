<template>
  <div class="relative mt-8 font-serif pr-12">
    
    <button
      :disabled="!audioOnly && !isReady"
      @click="playKaraoke"
      class="absolute top-2 right-0 text-gray-500 hover:text-gray-800 transition-colors cursor-pointer disabled:opacity-30 disabled:cursor-not-allowed"
      title="読み上げを再生"
    >
      <svg class="w-8 h-8" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
        <path fill="currentColor" d="M3 9v6h4l5 5V4L7 9H3zm13.5 3c0-1.77-1.02-3.29-2.5-4.03v8.05c1.48-.73 2.5-2.25 2.5-4.02zM14 3.23v2.06c2.89.86 5 3.54 5 6.71s-2.11 5.85-5 6.71v2.06c4.01-.91 7-4.49 7-8.77s-2.99-7.86-7-8.77z"/>
      </svg>
    </button>

    <div v-if="audioOnly" class="text-3xl leading-loose text-gray-800">
      {{ text }}
    </div>

    <template v-else>
      <div v-if="!isReady" class="text-gray-400 text-sm animate-pulse">
        Kuromoji 辞書データを読み込み中...
      </div>
      
      <div v-else class="text-3xl leading-loose">
        <span
          v-for="(token, index) in tokens"
          :key="index"
          :class="getHighlightColor(token.pos, index, activeTokenIndex)"
          class="text-gray-800 transition-colors duration-150 rounded px-1 mx-px"
        >{{ token.word }}</span>
      </div>
    </template>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'

const props = defineProps({
  text: {
    type: String,
    required: true
  },
  audioOnly: {
    type: Boolean,
    default: false
  },
  speed: {
    type: Number,
    default: 1.0
  },
  gender: {
    type: String,
    default: 'female'
  },
  pitch: {
    type: Number,
    default: 1.2 
  },
  ignoreMinor: {
    type: Boolean,
    default: true 
  }
})

const tokens = ref([])
const activeTokenIndex = ref(-1)
const isReady = ref(false)

onMounted(() => {
  if (props.audioOnly) {
    isReady.value = true
    return
  }

  if (window.kuromoji) {
    initTokenizer()
  } else {
    const script = document.createElement('script')
    script.src = 'https://cdn.jsdelivr.net/npm/kuromoji@0.1.2/build/kuromoji.js'
    script.onload = () => initTokenizer()
    document.head.appendChild(script)
  }
})

function initTokenizer() {
  // 参照先を自サーバーのパス（/dict/）に変更
  // Static Siteの場合、ドメイン直下のpublic/dictを探しに行きます
  window.kuromoji.builder({ dicPath: "/dict/" }).build((err, tokenizer) => {
    if (err) {
      console.error("Kuromoji初期化エラー:", err);
      // エラー時でもボタンだけは使えるようにしておく
      isReady.value = true; 
      return;
    }
    const parsedTokens = tokenizer.tokenize(props.text);
    let currentIndex = 0

    tokens.value = parsedTokens.map(t => {
      const tokenInfo = {
        word: t.surface_form,
        pos: t.pos,
        startIndex: currentIndex,
        endIndex: currentIndex + t.surface_form.length
      }
      currentIndex += t.surface_form.length
      return tokenInfo
    })
    isReady.value = true
  })
}

function playKaraoke() {
  speechSynthesis.cancel()
  activeTokenIndex.value = -1

  const msg = new SpeechSynthesisUtterance(props.text)
  msg.lang = 'ja-JP'
  
  msg.rate = props.speed
  msg.pitch = props.pitch

  const voices = speechSynthesis.getVoices()
  const jaVoices = voices.filter(v => v.lang === 'ja-JP')
  let bestVoice = null;

  if (props.gender === 'male') {
    bestVoice = jaVoices.find(v => /Keita/i.test(v.name)) || jaVoices.find(v => /Ichiro|Ayumu|Otoya|Male|男性/i.test(v.name))
  } else {
    bestVoice = jaVoices.find(v => /Nanami/i.test(v.name)) || jaVoices.find(v => /Google/i.test(v.name)) || jaVoices.find(v => /Haruka|Kyoko|Mei|Female|女性/i.test(v.name))
  }
  
  if (bestVoice) {
    msg.voice = bestVoice
  } else if (jaVoices.length > 0) {
    msg.voice = jaVoices[0]
  }

  if (!props.audioOnly) {
    msg.onboundary = (event) => {
      const targetIndex = tokens.value.findIndex(t => event.charIndex >= t.startIndex && event.charIndex < t.endIndex)
      if (targetIndex !== -1) activeTokenIndex.value = targetIndex
    }
    msg.onend = () => {
      activeTokenIndex.value = tokens.value.length
    }
  }

  speechSynthesis.speak(msg)
}

function getHighlightColor(pos, index, activeIndex) {
  if (index > activeIndex) return 'bg-transparent'

  if (props.ignoreMinor && (pos === '助詞' || pos === '助動詞' || pos === '記号')) {
    return 'bg-transparent'
  }

  if (pos === '名詞') return 'bg-blue-300'
  if (pos === '動詞') return 'bg-green-300'
  if (pos === '形容詞') return 'bg-purple-300'
  
  if (pos === '助詞' || pos === '助動詞') return 'bg-yellow-300'
  if (pos === '記号') return 'bg-gray-300'
  
  return 'bg-pink-300'
}
</script>

