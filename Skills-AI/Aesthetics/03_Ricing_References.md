# Referências Estéticas (Linux Ricing & Retro)

Este documento guarda as diretrizes visuais baseadas nas imagens de referência de *ricing* de Linux, essenciais para criar apps com a pegada "Retro-Modern".

## Estilo Visual (Cyberpunk / Win95 / Tiling WMs)

As imagens de referência apontam para um estilo muito popular na comunidade de customização do Linux (unixporn/ricing), que mistura elementos muito antigos com fluxos de trabalho modernos:

1. **Temas Clássicos (Retro GUI):**
   - Uso de temas que imitam sistemas operacionais antigos, como **Windows 95 (Chicago95)**, **CDE (Common Desktop Environment)** ou **Motif**.
   - Bordas de janelas espessas, cinzas ou em tons pastéis com efeitos de chanfro (bevel) 3D clássico.

2. **Paletas de Cores:**
   - **Pastel / Vaporwave:** Rosas claros, lilás, roxos escuros (como na imagem do terminal de fetch rosa).
   - **Alto Contraste / Cyberpunk:** Fundos pretos puros ou muito escuros com texto em neon (ciano, verde limão), como nas interfaces de terminal com arte ASCII.

3. **Elementos de Terminal (CLI):**
   - Muito uso de fontes *Monospace* pixeladas (como Terminus, VT323).
   - Artes ASCII (como o logo do Arch Linux, Debian ou personagens de anime desenhados em texto).
   - Barras de progresso e visualizadores de áudio em barras (ex: `cava`).

4. **Transparência e Blur:**
   - Janelas de terminal levemente transparentes sobre fundos de tela de pixel art ou paisagens digitais/anime retro.

## Como Aplicar isso nos Apps (React/Electron)?

Para atingir esse nível de *ricing* nos nossos apps:
- Continuar usando fontes monospace pixeladas.
- Usar cores de fundo inspiradas em paletas clássicas (ex: `#c0c0c0` para o cinza do Win95, ou roxos escuros para o cyberpunk).
- Fazer janelas sem as bordas modernas nativas do sistema (frameless windows no Electron) e desenhar nossas próprias barras de título estilo Windows 95 ou CDE usando CSS!
- Adicionar easter eggs no console (ASCII art).
