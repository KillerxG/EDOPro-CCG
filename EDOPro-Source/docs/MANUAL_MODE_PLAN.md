# EDOPro Manual Duel Mode Plan

Objetivo: criar um modo manual estilo DuelingBook usando a estrutura do EDOPro, mantendo leitura de .cdb, .ydk e imagens por id.

## Decisao tecnica

Nao alterar o duelo normal no primeiro passo. O modo normal do EDOPro e dirigido pelo ocgcore e por mensagens como MSG_START, MSG_MOVE, MSG_SELECT_IDLECMD e MSG_UPDATE_DATA. Para um simulador manual, isso vira atrito porque o core espera regras automaticas.

O caminho recomendado e criar um modo novo, separado, que reaproveita:

- ClientField para desenhar zonas, maos, cemiterio, banido, deck e extra deck.
- ClientCard para estado visual da carta, codigo, posicao e textura.
- DeckManager para carregar .ydk com main/extra/side.
- DataManager e ImageManager para ler .cdb e pics por id.
- A interface/menu do EDOPro para cliques, hover e listas de pilhas.

## Pontos de entrada encontrados

- gframe/client_field.h
  - Guarda as pilhas: deck, hand, mzone, szone, grave, remove, extra.
  - Ja possui AddCard, RemoveCard, GetCard, GetList, MoveCard, RefreshAllCards e RefreshHandHitboxes.

- gframe/client_field.cpp
  - Initial cria cartas viradas para baixo em deck/extra.
  - AddCard/RemoveCard ja sabem reposicionar cartas nas zonas.
  - MoveCard anima a carta ate a coordenada correta.

- gframe/event_handler.cpp
  - ClientField::OnEvent processa clique no campo.
  - ClientField::GetHoverField detecta zona/slot pelo mouse.
  - ClientField::ShowMenu monta o menu contextual.
  - Aqui deve entrar o menu manual: comprar, invocar, setar, virar, mandar para GY, banir, voltar para mao, anexar overlay etc.

- gframe/deck_con.cpp
  - BUTTON_HAND_TEST usa DeckBuilder.GetCurrentDeck() e SingleMode::StartPlay.
  - Podemos criar um botao Manual Duel ao lado do Hand Test para iniciar a mesa manual com o deck selecionado.

- gframe/menu_handler.h / gframe/menu_handler.cpp
  - Define IDs de botoes e fluxo dos menus principais.
  - Aqui entra BUTTON_MANUAL_DUEL e a chamada para ManualMode::Start(...).

- gframe/game.cpp / gframe/game.h
  - Cria os botoes e janelas do UI, incluindo wCmdMenu.
  - Aqui entram os botoes visuais ou reaproveitamento dos botoes existentes com labels manuais.

## Primeira fase: mesa manual local

1. Criar ManualMode com estado simples:
   - ativo/inativo
   - jogador local 0/1
   - deck main/extra/side carregado do DeckBuilder
   - carta selecionada/origem/destino

2. Ao iniciar:
   - esconder menu principal/deck editor
   - mostrar campo, wCardImg, wInfos, wPhase e controles basicos
   - limpar dField
   - criar ClientCard para cada carta do main deck e extra deck
   - usar SetCode(id), owner, controler, location, position
   - adicionar ao dField com AddCard
   - chamar RefreshAllCards
   - setar event receiver para dField

3. Operacoes manuais minimas:
   - comprar do topo para a mao
   - mover carta para MZONE/SZONE escolhida
   - mudar posicao: face-up attack, face-up defense, face-down defense
   - enviar para cemiterio
   - banir face-up/face-down
   - voltar para mao
   - embaralhar deck
   - abrir pilhas: deck, grave, banished, extra

4. Sem regras automaticas:
   - nao validar summon normal/especial
   - nao validar chains
   - nao resolver efeitos
   - jogador controla tudo manualmente

## Segunda fase: sincronizacao LAN

Depois que o local funcionar, criar protocolo pequeno para sincronizar acoes manuais:

- ManualActionMoveCard
- ManualActionChangePosition
- ManualActionShuffleDeck
- ManualActionRevealCard
- ManualActionSetLP
- ManualActionChat/Log

A rede pode reaproveitar parte da tela LAN do EDOPro, mas nao deve depender das mensagens CTOS/STOC do duelo automatico no primeiro momento.

## Observacao importante

A pasta D:\GitHub\YGO-GAME e a distribuicao compilada do EDOPro. A pasta D:\GitHub\EDOPro-Source e o source de trabalho. O source baixado por zip veio sem submodulos; ocgcore e ocgcore/lua/src foram preenchidos manualmente a partir dos repositorios oficiais.

## Implementacao inicial adicionada

Arquivos criados/alterados:

- gframe/manual_mode.h
- gframe/manual_mode.cpp
- gframe/menu_handler.h
- gframe/game.h
- gframe/game.cpp
- gframe/deck_con.cpp

Fluxo atual:

1. Entrar no Deck Edit.
2. Selecionar ou montar um deck.
3. Clicar no botao Manual.
4. ManualMode::StartLocal fecha o editor, mostra o campo, cria cartas para os dois jogadores a partir do deck selecionado e preenche Deck/Extra visualmente.

Comandos manuais iniciais implementados em ManualMode e conectados em ClientField::OnEvent. Acoes atuais: Comprar, Monstro, Mao, Set M, Set S/T, Posicao, Cemiterio, Banir, Ver pilha e Embaralhar. Proximo passo: melhorar escolha de zona destino, LP/contadores e sincronizacao LAN.

