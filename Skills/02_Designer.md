# Skill Designer - Linux Apps

Este documento define o padrão visual e a usabilidade (Designer) para os aplicativos deste projeto. O foco é uma identidade **Retro Pixel Art (8-bit / 16-bit / 32-bit)**, entregando uma experiência única e nostálgica que cause um impacto "Wow!" ao usuário.

## 1. Identidade Visual (Retro Aesthetic)

*   **Tipografia:** A alma do estilo retro. Use fontes pixeladas. 
    *   *Sugestão Primária:* **Press Start 2P** ou **VT323** (Google Fonts).
    *   Não use fontes padrão de sistema em títulos ou elementos principais da interface.
*   **Paleta de Cores:**
    *   Cores com alto contraste, baseadas em consoles clássicos (NES, SNES, Arcade).
    *   Modo escuro (Dark Mode) deve ser priorizado: fundos escuros (ex: `#1a1a1a` ou preto absoluto `#000000`), com elementos de destaque em cores neon/vibrantes (verde limão, rosa choque, ciano) ou cores clássicas de 8-bit (vermelho puro, azul escuro, amarelo).
*   **Formas e Bordas:**
    *   Sem cantos arredondados modernos (sem `border-radius` clássico).
    *   Bordas "blocky". Se for criar bordas, simule bordas em pixels.
    *   Use frameworks baseados em CSS-retro (como **NES.css**) ou simule esse efeito usando `box-shadow` duro.

## 2. Micro-Interações e Animações (Dinâmica)

*   **Efeitos de Hover (Ao Passar o Mouse):** Todo botão deve ter uma resposta imediata e dramática. Ex: inverter as cores, alterar a borda de bloco ou um efeito de clique de fliperama (botão abaixando).
*   **Animações 8-bit:** Utilize animações curtas e com poucos quadros (simulando baixo framerate) para modais aparecendo, menus abrindo ou barras de carregamento (ex: uma barra de load feita de bloquinhos).
*   **Cursores Personalizados:** Sempre que possível, o cursor padrão sobre o app deve ser um ponteiro pixelado (estilo espada, cursor do Windows 95 ou luva do Mario).

## 3. Usabilidade

*   **Feedback Visual:** Nunca deixe o usuário esperando sem saber. Sempre que uma ação for desencadeada (ex: baixar uma música), exiba uma barra de progresso no estilo fliperama (ex: "LOADING...").
*   **Limpeza (Clutter-free):** A interface deve ser "lean". O foco é na tarefa principal do app. Menus extras e configurações devem estar ocultos até serem chamados.
*   **Ícones e Assets:** Gere e utilize ícones desenhados como Pixel Art autêntico. Ícones genéricos modernos (Material Design, etc.) quebram a imersão e devem ser estritamente evitados.
