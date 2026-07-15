# 🐧 LinuxApps - Ricing & Utilities Suite

Bem-vindo ao **LinuxApps**, um repositório pessoal dedicado ao estudo e desenvolvimento de aplicativos úteis e extremamente customizados para o dia a dia no ecossistema Linux. 

Este projeto foi construído inteiramente utilizando o **Antigravity IDE** como assistente inteligente de programação (Pair Programming com IA).

## 🎯 Objetivo

A ideia principal deste repositório é criar pequenas ferramentas de *desktop* com alto apelo visual (focadas na estética de *Ricing* e *Cyberpunk/Retro*), mas sem perder a utilidade. O código e as práticas foram pensados e otimizados especialmente para funcionar de forma nativa e fluida nas distribuições:
- **Linux Mint**
- **Zorin OS**

## 📦 Aplicativos Atuais

Até o momento, a suíte conta com os seguintes utilitários construídos sobre **Electron + React + Vite**:

### 1. RetroPlayer 🎵
Um player de música frameless (sem bordas), arrastável, que permite buscar e fazer download de músicas do YouTube diretamente pela interface. Ele extrai automaticamente a arte de capa (thumbnail) original do vídeo, servindo como um widget estiloso para a área de trabalho.

### 2. CyberConvert (Format Converter) 💽
Um conversor universal de arquivos em lote (`Drag & Drop`). Rodando o poder bruto do **FFmpeg** nativo do sistema em segundo plano, ele permite a conversão assíncrona de Vídeos, Áudios e Imagens com apenas um clique e sem complicações.

## 🛠️ Tecnologias & Lições Aprendidas
- **Stack Base:** Electron, React, TypeScript, Vite.
- **Ricing Estético:** Uso intensivo de CSS para emular barras de título do Windows 95 e terminais UNIX (`-webkit-app-region: drag`), paletas de cores vaporwave/neon e fontes pixeladas nativas da comunidade (como `VT323`).
- **Engenharia:** O aprendizado contínuo (arquitetado na pasta `Skills`) foi essencial para superar os rígidos bloqueios do Chromium (`contextIsolation`, limitações do HTML5 File API para drag&drop) e criar streams de mídia limpos injetando protocolos customizados (`asset://`).

---

> *"Para quem gosta de ter controle absoluto sobre sua máquina e de exibir um desktop impecável."*
