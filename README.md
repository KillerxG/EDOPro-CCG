# Yu-Gi-Oh! CCG Epsilon - EDOPro Mod

Pasta preparada para subir no GitHub e colaborar no desenvolvimento do mod.

## Estrutura

- `EDOPro-Source/`: source filtrada do EDOPro usada para compilar o `EDOProMod.exe` e o `ocgmod.dll`.
- `mod-files/`: arquivos próprios do mod que ficam na instalação do jogo.
- `mod-files/script/Custom/`: scripts custom locais.
- `mod-files/script/ccg-brasil/`: scripts custom importantes que vieram do repositório CCG Brasil instalado.
- `mod-files/expansions/Mod.cdb`: banco custom do mod.
- `mod-files/config/`: configs custom do mod, incluindo `user_configs.json`.
- `installer/`: arquivos fonte do instalador, sem o instalador `.exe` pesado.

## O que nao foi incluido

- jogo instalado inteiro
- instalador `.exe` de 4GB
- `pics`, `cover`, `deck`, `replay`, `screenshots`
- builds e intermediarios: `bin`, `build`, `obj`, `.vs`, `vcpkg`
- repos oficiais completos dentro de `repositories`

## Repos externos usados pelo mod

O arquivo `mod-files/config/user_configs.json` aponta para estes repos:

- https://github.com/KillerxG/CCG-Brasil
- https://github.com/KillerxG/CCG-Field-Arts
- https://github.com/KillerxG/CCG-Brasil-Banlists
- https://github.com/KillerxG/CCG-Brasil-Genesys

## Observacao

Essa pasta e para desenvolvimento/colaboracao no GitHub. Para distribuir para jogadores, use o instalador separado.

## Workflow novo

A partir de agora, use este repo como base oficial de desenvolvimento. Veja docs/WORKFLOW.md para aplicar arquivos no jogo, puxar mudancas do jogo para o repo e compilar EDOProMod.exe / ocgmod.dll.

