# Skill DEV - Linux Apps

Este documento define as regras e boas práticas de desenvolvimento (DEV) para todos os pequenos aplicativos focados no ecossistema Linux (Ubuntu, Mint, Zorin). Ao programar um novo app ou dar manutenção, consulte este guia para manter a qualidade e o padrão.

## 1. Arquitetura e Stack

*   **Tecnologia Padrão (Apps com Interface Rica):** Sempre que o app precisar de uma interface gráfica complexa (especialmente com temática retro/pixel art), priorizar **Electron + React + Vite**. Isso permite estilização fácil com CSS.
*   **Modularidade:** Mantenha o código limpo. O código responsável pela interface (`frontend/`) deve ser separado da lógica de sistema operacional e de chamadas pesadas (que devem ocorrer no processo principal do Node.js, em `backend/` ou `main/`).
*   **Leveza:** Evite adicionar dependências desnecessárias. Apps para o dia-a-dia devem abrir rápido e consumir pouca memória.

## 2. Integração com o Linux

*   **Caminhos de Arquivos (FHS):** Ao salvar dados do usuário, não polua a raiz (home). Siga as diretrizes do FreeDesktop.org (XDG Base Directory):
    *   Arquivos de configuração: `~/.config/<NomeDoApp>/`
    *   Dados de usuário (músicas baixadas, bancos de dados locais): `~/.local/share/<NomeDoApp>/`
    *   Arquivos temporários ou de cache: `~/.cache/<NomeDoApp>/`
*   **Permissões e Execução:** Certifique-se de que os pacotes gerados (ex: `.AppImage`, `.deb`) terão os atalhos (`.desktop`) corretos criados em `~/.local/share/applications/` se instalados manualmente, e possuam ícones apropriados.

## 3. Segurança e Boas Práticas Node/Electron

*   **Node Integration:** Mantenha o `nodeIntegration: false` e use `contextIsolation: true` por padrão nas configurações do Electron `BrowserWindow`. Exponha apenas APIs seguras via `preload.js` usando `contextBridge`.
*   **Tratamento de Erros:** Comandos de terminal em background (ex: usando `child_process.exec` ou bibliotecas como `yt-dlp-exec`) devem tratar sempre a saída de erro (`stderr`) e nunca travar o processo principal sem feedback para a UI do usuário.

## 4. Estilo de Código

*   Use nomes de variáveis descritivas, em camelCase ou snake_case (dependendo da linguagem) mantendo consistência.
*   Escreva pequenos comentários explicativos em lógicas complexas, especialmente interações diretas com binários nativos do Linux (ex: bash, ffmpeg, yt-dlp).
*   Trate promessas de maneira limpa com `async/await`.
