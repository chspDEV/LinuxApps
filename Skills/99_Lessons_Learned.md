# 🧠 Log de Aprimoramento Contínuo (Lessons Learned)

Este documento serve como a base de treinamento e feedback para a Inteligência Artificial. Sempre que iniciarmos um novo projeto ou sessão, a IA deve consultar este arquivo para evitar cometer os mesmos erros e reforçar os acertos passados.

## 🟢 O que deu MUITO certo (Padrões a manter)
- **Design de Ricing (Frameless):** A combinação de janelas sem borda (`frame: false` no Electron) com a custom title bar em CSS arrastável (`-webkit-app-region: drag`) cria a melhor experiência de interface para apps de desktop.
- **Divisão de Estética e Layout:** Usar estilos 8-bit/Cyberpunk (cores neon, VT323) mas manter um layout moderno e espaçado (estilo Spotify/Widget) funcionou perfeitamente.

## 🔴 O que deu errado (Erros a evitar)
- **Escape de Caracteres no React (Erro de Sintaxe):** Ao sobrescrever arquivos TSX que possuem *Template Strings* do JavaScript, a IA acabou inserindo barras invertidas literais (ex: `className={\`...\`}`), o que gerou erro de compilação. 
  - **Correção:** A IA deve sempre usar os crases limpos nas props do React ou evitar escapes desnecessários dependendo da ferramenta de escrita que estiver utilizando.
- **Segurança Chromium bloqueando `file://` em Dev Mode:** O motor do Electron (mesmo com `webSecurity: false`) barra silenciosamente carregamentos locais (`file://`) quando o app é servido via HTTP pelo Vite (`http://localhost`). Isso quebra áudios e imagens.
  - **Correção (Padrão Ouro):** A IA deve registrar um protocolo customizado no backend. No entanto, é **crucial** registrar privilégios de *streaming* (usando `protocol.registerSchemesAsPrivileged([{ scheme: 'asset', privileges: { stream: true, bypassCSP: true } }])`) ANTES do app estar pronto. Só assim o elemento `<audio>` vai conseguir tocar a mídia via `net.fetch(pathToFileURL(filePath).toString())`.
- **Content Security Policy (CSP):** O HTML base do Electron-Vite (`index.html`) vem com uma tag `<meta http-equiv="Content-Security-Policy">` super restritiva. Mesmo criando o protocolo customizado, o navegador vai bloquear a imagem e o som.
  - **Correção:** Sempre lembrar de adicionar permissão explícita para o protocolo (`asset:`) nas diretivas `img-src` e `media-src` do HTML base.

---

> **Como usar:** Caro(a) desenvolvedor(a), sempre que eu (a IA) fizer algo genial ou cometer um erro bobo em nossos projetos futuros, anote um resumo rápido aqui. Quando iniciarmos o próximo app, basta me dizer: *"Revise a pasta Skills antes de começar"*, e eu absorverei todo o seu feedback!
