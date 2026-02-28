# ========== 1. ビルド用ステージ ==========
# Node.js環境を使って、SlidevのスライドをHTMLに変換（ビルド）します
FROM node:20-alpine AS builder

WORKDIR /app

# パッケージの依存関係を先にコピーしてインストール（キャッシュを効かせるため）
COPY package*.json ./
RUN npm install

# スライドの原稿（.mdやcomponentsなど）をすべてコピー
COPY . .

# HTMLとして書き出し（デフォルトで /app/dist フォルダに出力されます）
RUN npm run build


# ========== 2. 本番配信ステージ ==========
# 超軽量なWebサーバー「Nginx」を使って、出来上がったHTMLだけを配信します
FROM nginx:alpine

# ビルド用ステージで作られた dist フォルダの中身を、Nginxの公開フォルダにコピー
COPY --from=builder /app/dist /usr/share/nginx/html

# ブラウザからアクセスするためのポート番号
EXPOSE 80

# Nginxを起動
CMD ["nginx", "-g", "daemon off;"]