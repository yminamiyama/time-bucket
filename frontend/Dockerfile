FROM node:20

WORKDIR /usr/src/app

RUN corepack enable && pnpm config set store-dir /usr/src/app/.pnpm-store

COPY package.json pnpm-lock.yaml* ./
RUN if [ -f package.json ]; then pnpm install; fi

COPY . .

EXPOSE 3000
CMD ["bash", "-lc", "pnpm dev"]
