# Redesenho do BLE RC Controller: app e peças de divulgação

Data: 2026-10-10. Situação: aguardando revisão do Daniel.

## 1. Objetivo

Dar ao app e às peças de divulgação uma identidade própria, elegante e organizada, para quem gosta de automobilismo e de RC. O app continua fazendo exatamente o que faz hoje: muda a forma e a navegação, não as funções.

Critério de sucesso: o Daniel reconhece no app e nas peças o que aprovou nos esboços (companheiro visual, telas `direcao-a-v11`, `navegacao`, `telas-ajustes-v2`, `desktop` e `estados-v3`), em celular, tablet e computador, sem perder nada que já foi testado no tablet.

## 2. Decisões aprovadas

| Tema | Decisão |
|---|---|
| Público | Fãs de automobilismo e RC |
| Direção visual | "Cronometragem" amadurecida: painel de carro de alto padrão e software de telemetria |
| Carro | Decalque de traço fino visto de cima, sem pintura nem volume |
| Cor | Uma só cor de destaque, âmbar de instrumento, só no que está ativo ou pede ação |
| Fonte | Saira (a do esboço A), condensada e leve nos números e nomes |
| Efeitos | No fundo, sem disputar com o conteúdo: partículas que reagem ao carro, luz ambiente, reflexo de vidro, granulação |
| Superfícies | Vidro fosco com filete de luz na borda |
| Navegação | "Painel primeiro": sem barra de abas, tudo parte do painel |
| Escopo | Repensar tudo, inclusive a navegação, mantendo todas as funções |

Rejeitado nos esboços e fora deste desenho: régua de LEDs colorida, carro chapado ou com pintura metálica, verde/roxo/vermelho como cores de estado, traçado de circuito no fundo, rótulos numerados que não indicam sequência.

## 3. Identidade visual

### 3.1 Cores

Tema escuro único. O app deixa de ter tema claro, porque a identidade, os efeitos de luz e a legibilidade do âmbar dependem do fundo escuro.

| Nome | Valor | Uso |
|---|---|---|
| Fundo | `#0A0C0F` | Base de todas as telas |
| Texto | `#ECEEF1` | Texto principal |
| Texto 2 | `#99A0AB` | Texto secundário (contraste 7,5:1) |
| Texto 3 | `#7D8591` | Rótulos pequenos e dicas (5,2:1) |
| Traço | `#5E6570` | Marcas, escalas e contornos. Nunca em texto |
| Traço fraco | `#363C45` | Marcas menores das escalas |
| Âmbar | `#FFB547` | Estado ativo, ação principal, atenção |
| Âmbar quente | `#FF8A2A` | Só no degradê do halo do turbo |
| Vidro | branco a 4% | Fundo de células, listas e botões |
| Borda de vidro | branco a 8% | Contorno das superfícies de vidro |
| Farol | `#FFEBC8` | Facho dos faróis e poeira iluminada |

O texto metálico (nome do carro, bateria e títulos) é um degradê vertical de `#FFFFFF` a `#8E959F`.

### 3.2 Tipografia

- **Família:** Saira (licença SIL OFL 1.1), embutida no app como fonte variável com os eixos de peso e largura. O arquivo vem do repositório `google/fonts`. Baixá-lo é um passo do plano e precisa de aprovação.
- **Números e nomes** (nome do carro, bateria, graus, títulos de tela): largura 75%, peso 300. Algarismos de largura fixa.
- **Texto corrido e rótulos:** largura 100%, peso 400, só em caixa normal (sem caixa alta).

| Papel | Tamanho | Largura | Peso |
|---|---|---|---|
| Nome do carro no painel (celular / computador) | 42 / 56 | 75% | 300 |
| Bateria | 36 / 44 | 75% | 300 |
| Título de tela | 28 | 75% | 300 |
| Mensagem de estado | 22–26 | 75% | 300 |
| Texto de linha | 13,5–15 | 100% | 400 |
| Rótulo e dica | 10,5–12 | 100% | 400 |

### 3.3 Superfícies, luz e forma

- **Vidro:** fundo branco a 4%, borda a 8%, filete de luz de 1 px no topo (branco a 6–7%) e desfoque do fundo de 14 px. Raio de 14–16 nas células e listas e de 22–24 nas folhas e painéis.
- **Ativo:** a borda passa a âmbar a 35%, o fundo ganha um degradê âmbar de 10% a 3% e o texto fica âmbar com halo suave.
- **Luz ambiente:** um degradê frio vindo do alto, um foco quente e fraco sob o carro e cantos escurecidos.
- **Reflexo de vidro:** uma faixa diagonal que atravessa a tela a cada 9 s, com no máximo 5,5% de intensidade.
- **Granulação:** ruído fino sobreposto a 8–10%.
- **Áreas de toque:** no mínimo 48×48.

### 3.4 Movimento

- Mudanças de estado (âmbar acendendo, texto trocando): 200–250 ms, com desaceleração.
- Ponteiro do transferidor: 350 ms, com um leve passar do ponto ao parar.
- Giro 360° do carro: 550 ms.
- Desenho do decalque ao conectar: o traço se completa em cerca de 1,6 s e repete enquanto conecta.
- **Reduzir movimento:** com a opção do sistema ligada, as partículas, o reflexo de vidro, o desenho do decalque e o giro ficam parados ou viram troca direta de estado. A informação continua toda na tela.

## 4. Componentes

### 4.1 Decalque do carro

Desenho próprio de um GT genérico visto de cima, sem imitar nenhum modelo real. É o mesmo contorno dos esboços: carroceria, quatro rodas, para-brisa, teto, vidro traseiro, linha central tracejada, faróis e lanternas.

| Variante | Aparência | Onde aparece |
|---|---|---|
| Sólido | Contorno em `#C9CFD8`, preenchimento a 5% | Carro conectado |
| Fantasma | Todos os traços tracejados em `#4A515B` | Sem carro e conexão perdida |
| Desenhando | O traço se completa progressivamente | Conectando |
| Ícone | Só a carroceria, em âmbar se conectado e cinza nos demais | Coluna de carros no computador |

Com o carro conectado, o decalque reage assim:
- **Direção:** as rodas da frente esterçam ±18° e o carro inclina ±4,5°.
- **Luz:** os faróis ficam cor de farol e projetam dois fachos curtos, que terminam antes do "0°" do transferidor.
- **Turbo:** um halo âmbar aparece atrás do carro.
- **Giro 360°:** o carro dá uma volta completa.

### 4.2 Transferidor de direção

Arco acima do carro, de −40° a +40°, com marcas a cada 5° e marcas maiores a cada 20°. O ponteiro âmbar fica em 0° ou em ±18°, e as marcas perto dele acendem. A leitura no alto diz "0°", "18° direita" ou "18° esquerda", e os rótulos "esquerda" e "direita" ficam nas pontas.

O carro só vira tudo ou nada, então o ponteiro tem só três posições. Ele marca o lado da curva, não um ângulo proporcional.

### 4.3 Escala do acelerador

Régua vertical à direita do carro, com "frente" no topo e "ré" embaixo. A barra âmbar parte do meio: sobe até 72% na frente, chega ao topo no turbo (que também acende a marca "turbo") e desce até 60% na ré. Como o acelerador também é tudo ou nada, as três alturas são fixas.

### 4.4 Células de estado

Grade de vidro com quatro células: Luz, Turbo, Giro 360° e Controle. Cada célula mostra um rótulo pequeno, o botão do controle que aciona a ação (✕, ○, △) e o valor:
- Luz: Acesa ou Apagada.
- Turbo: Ativo ou Desligado.
- Giro 360°: Girando ou Parado.
- Controle: o nome do controle, ou "Nenhum controle".

Uma célula ativa fica âmbar. O símbolo do botão vem dos atalhos atuais da ação. Com mais de uma entrada, mostra a primeira do controle e, se não houver nenhuma, a primeira tecla.

### 4.5 Botões de toque

Quatro botões embaixo do painel, nesta ordem: ←, →, ↓ e ↑. Ficam visíveis quando "Botões na tela" estiver ligado, que é o padrão no Android.

Em celular e tablet, Luz, Turbo e Giro 360° são acionados tocando nas células correspondentes, que viram botões. Isso mantém o comportamento atual:
- Luz liga e desliga a cada toque.
- Turbo e Giro 360° travam ligados até o segundo toque e se soltam ao desconectar.

Aparência: vidro com filete de luz. Apertado, o botão fica âmbar com halo e desce 1 px.

No computador, "Botões na tela" começa desligado. Se a pessoa ligar, os botões aparecem embaixo do painel, acima da legenda de teclas, e funcionam com clique.

### 4.6 Legenda de teclas (computador)

Uma linha embaixo do painel com as teclas de cada ação, tiradas dos atalhos atuais (padrão: W/↑ frente, S/↓ ré, A/D direção, Espaço turbo, L luz, Q giro). A tecla de uma ação ativa acende em âmbar. Com "Usar o teclado" desligado, a legenda some.

### 4.7 Partículas

Pontos e rastros finos desenhados atrás de todo o conteúdo do painel, que se comportam como ar e poeira passando pelo carro:

| Estado do carro | Comportamento |
|---|---|
| Parado | Flutuação lenta |
| Frente | Correm para baixo |
| Ré | Correm para cima |
| Curva | A corrente inclina para o lado oposto ao da curva |
| Turbo | Mais rápidas, alongadas em rastros, em tom quente |
| Giro 360° | Redemoinho em volta do carro |
| Faróis acesos | As partículas dentro do facho brilham em cor de farol |

- **Intensidade por zona:** máxima em volta do carro, 55% atrás do cabeçalho e caindo até 18% atrás das células e dos botões.
- **Profundidade:** cada partícula tem uma profundidade de 0,25 a 1, que define tamanho, velocidade e opacidade. A velocidade muda suavemente entre os estados.
- **Quantidade:** cerca de 95 no celular e 150 no computador, ajustada pela área.
- **Desempenho:** desenho próprio da tela, atualizado só com o app em primeiro plano. Para quando o app vai para segundo plano e quando o painel não está visível (ajustes abertos em tela cheia no celular).
- **Testes:** um parâmetro desliga as partículas, para os testes não dependerem de animação.

### 4.8 Outros componentes

- **Lista de carros:** linhas de vidro com nome, força do sinal (barras e "sinal forte", "médio" ou "fraco") e um botão. O botão diz "Conectar" sem carro conectado e "Trocar" quando há outro carro conectado. O carro conectado aparece em âmbar, com a bateria e o botão "Desconectar". Esta lista é usada pela folha de carros no celular e pela coluna lateral no computador.
- **Aviso:** um cartão âmbar no topo, com título, explicação e até duas ações em texto.
- **Etiqueta de entrada:** ícone de controle ou de teclado, o nome da entrada e um "×" para remover. Se a mesma entrada estiver em mais de uma ação, um ponto âmbar avisa.
- **Medidor de sinal:** nome do sinal, uma barra fina âmbar e o valor com duas casas.
- **Desenho do controle:** controle genérico em traço fino, com o botão, gatilho, analógico ou direcional do passo atual aceso em âmbar e pulsando.
- **Linha de ajuste:** título, descrição curta do que faz e, à direita, um valor, um interruptor ou "›".
- **Interruptor:** âmbar quando ligado, cinza quando desligado.

## 5. Navegação e telas

### 5.1 Estrutura

Não há barra de abas. O app abre no **painel**, e as outras telas partem dele:

```
Painel ── nome do carro ──► Folha de carros (celular e tablet)
   │                         (no computador: coluna lateral fixa)
   └──── engrenagem ──────► Ajustes ─┬─► Botões e teclas
                                     ├─► Controles ──► Ensinar controle
                                     ├─► Idioma
                                     └─► Sobre
```

No celular e no tablet, os Ajustes abrem como tela por cima do painel. No computador, abrem como painel lateral de 380 à direita, com o painel escurecido ao fundo, e as subtelas trocam dentro desse painel lateral.

### 5.2 Painel

**Cabeçalho:**
- À esquerda, o nome do carro em texto metálico e, abaixo, a situação ("Conectado", "Procurando", "Conectando", "Reconectando" ou "Bluetooth desligado") com um ponto ou um indicador girando.
- À direita, a bateria e a engrenagem.
- No celular e no tablet, tocar no nome abre a folha de carros.

O meio do painel muda conforme o estado:

| Estado | Centro do painel | Texto e ações |
|---|---|---|
| Procurando, sem carro por perto | Decalque fantasma com ondas âmbar de busca | "Ligue o carro" / "Ele aparece aqui sozinho, em poucos segundos." Dicas: "Não aparece? Feche outros apps ligados a ele. O carro aceita uma conexão por vez." e "Ainda nada? Desligue e ligue o carro de novo." |
| Procurando, com carros | Decalque fantasma | "Carros por perto", com a lista de carros |
| Bluetooth desligado | Decalque fantasma com o símbolo de Bluetooth cortado | "Bluetooth desligado" / "Ligue o Bluetooth para encontrar o carro." No Android, botão "Ligar o Bluetooth"; nos outros sistemas, só o texto |
| Bluetooth bloqueado | Igual | "Bluetooth bloqueado" / "Libere o Bluetooth para este app nos ajustes do sistema." Botão "Tentar de novo", que pede a permissão outra vez |
| Bluetooth indisponível | Igual | "Bluetooth LE indisponível" / "Este aparelho não consegue falar com o carro." Sem ação |
| Conectando | Decalque desenhando | "Conectando ao {carro}" / "Leva alguns segundos." Botão "Cancelar" |
| Conectado | Decalque sólido, transferidor, acelerador e partículas | Células de estado, mais botões de toque ou legenda de teclas |
| Conexão perdida | Decalque fantasma com a etiqueta "Conexão perdida" | "O carro parou. O app volta a conectar assim que ele aparecer." Células e botões apagados. Com a reconexão automática desligada, mostra a lista de carros com o aviso "O carro desconectou." |
| Falha ao conectar | Garagem | Aviso: "Não foi possível conectar ao {carro}" / "Desligue e ligue o carro e confira se nenhum outro app está conectado a ele." Ações "Tentar de novo" e "Fechar" |

### 5.3 Folha de carros (celular e tablet)

Folha de vidro que sobe sobre o painel escurecido. Mostra a lista de carros e, no rodapé, o interruptor "Reconectar ao último carro". Fecha ao arrastar para baixo, ao tocar fora ou ao conectar outro carro.

### 5.4 Ajustes

| Grupo | Linha | Descrição | Controle |
|---|---|---|---|
| Comandos | Botões e teclas | O que cada entrada faz | › |
| Comandos | Controles | Nome do controle conectado, ou "Nenhum controle" | › |
| Comandos | Botões na tela | Para tablet e celular | interruptor |
| Pilotagem | Zona morta do analógico | Ignora toques leves no analógico | valor e controle deslizante (10% a 60%) |
| Pilotagem | Reconectar ao último carro | — | interruptor |
| App | Idioma | Sistema, Português, English, Español | valor e › |
| App | Sobre | Versão {versão}, código aberto | › |

**Sobre:** nome e versão do app, link do repositório, licença MIT e o aviso de projeto independente, sem vínculo com a Shell nem com outras marcas.

### 5.5 Botões e teclas

- No topo, a explicação "Toque em Adicionar e aperte um botão do controle, mova o analógico ou aperte uma tecla." (no computador, "Clique").
- Um cartão com as sete ações. Cada uma mostra o nome, o modo de funcionamento ("enquanto pressionado" ou "cada toque liga e desliga"), as etiquetas das entradas e "+ Adicionar".
- **Capturando:** a ação ganha borda âmbar, um ponto pulsando e o texto "Aperte o que vai acionar {ação}", com "Cancelar" ao lado.
- **Rodapé fixo:** "Usar o teclado" com interruptor e "Restaurar padrão".

### 5.6 Controles

- "Conectados": cada controle com o nome e a situação, "Reconhecido" ou "Ensinado". Se não houver nenhum: "Pareie o controle por Bluetooth ou USB e aperte qualquer botão."
- "Sinais ao vivo": os sinais mais recentes como medidores.
- "Aperte botões para ver os sinais. Útil para conferir um controle que o app não conhece."
- Botão "Ensinar um controle novo", que abre o assistente para o controle conectado.
- Um controle ensinado ganha a ação "Esquecer o que foi ensinado".

### 5.7 Ensinar controle

- O desenho do controle, com a parte do passo atual acesa.
- A instrução do passo em texto grande, com a equivalência entre marcas, por exemplo "Aperte o botão de baixo" / "✕ no PlayStation, A no Xbox, B no Switch".
- O progresso: "Passo {n} de 18" e o grupo do passo (Botões de ação, Ombros e gatilhos, Botões do meio, Analógicos, Direcional).
- Etiquetas dos passos já feitos.
- "Pular" e "Cancelar". No fim, "Pronto", que salva.

Os 18 passos são os do código atual (`teachSteps`): quatro botões de ação, dois ombros, dois gatilhos, Voltar/Share, Start/Options, quatro eixos de analógico e quatro do direcional.

## 6. Layout por tamanho de tela

| Faixa | Layout |
|---|---|
| Largura < 600 (celular) | Uma coluna: cabeçalho, instrumento, células em 2×2 e botões de toque. Tudo cabe sem rolagem a partir de 320×568. Se faltar altura, as células e os botões ficam fixos e o instrumento encolhe |
| 600 a 899 (tablet em pé, como o Lenovo) | Igual ao celular, com o instrumento maior e as células em uma linha de quatro |
| Paisagem com altura < 500 | Duas colunas: o instrumento à esquerda e as células e os botões à direita |
| Largura ≥ 900 (computador) | Coluna lateral de 280 com os carros e os controles, painel no centro, legenda de teclas embaixo e Ajustes em painel lateral |

Os testes de layout atuais (320, 360, 390 e 430 de largura; 600×960; 800×360) continuam valendo, adaptados às telas novas. Entra um teste novo para janela de computador de 1180×760.

## 7. Comportamento e mudanças no Driver

A lógica fica no `Driver`, e as telas só leem dele. Mudanças necessárias:

1. **Estado "reconectando":** depois de uma queda com a reconexão automática ligada, o Driver indica que está reconectando ao carro perdido, até reconectar, até o usuário escolher outro carro ou até desligar a reconexão automática.
2. **Cancelar conexão:** desconectar durante "conectando" cancela a tentativa. O código atual já tem a ficha de conexão que permite isso. Falta um teste que prove.
3. **Ligar o Bluetooth:** `CarTransport.enableBluetooth()`, que chama `UniversalBle.enableBluetooth()`. O botão só aparece onde a função está disponível (Android).
4. **Tentar a permissão de novo:** usa o `requestPermissions()` que já existe.
5. **Nível de sinal em texto:** a partir do `FoundCar.signalLevel` que já existe (1 a 4). O nível 4 é "sinal forte", os níveis 3 e 2 são "sinal médio" e o nível 1 é "sinal fraco". As barras continuam com os quatro níveis.
6. **Símbolo de atalho por ação:** o primeiro botão do controle e a primeira tecla de cada ação, para as células e a legenda de teclas.

Nada muda no protocolo, nos atalhos padrão, na trava do Turbo e do Giro 360° na tela nem na segurança: o carro para ao desconectar, ao trocar de app ou ao perder o controle.

## 8. Estrutura de código

Os arquivos atuais de `lib/ui/` são substituídos por:

```
lib/ui/
  theme/      tokens.dart (cores, tipos, durações), theme.dart
  shell.dart  escolhe o layout (celular, tablet, paisagem, computador) e onde abrem os Ajustes
  cockpit/    cockpit.dart, car_decal.dart, steering_gauge.dart, throttle_scale.dart,
              state_cells.dart, touch_pads.dart, key_legend.dart, particles.dart,
              cockpit_states.dart (procurando, Bluetooth, conectando, conexão perdida)
  garage/     car_list.dart, car_sheet.dart, garage_column.dart
  settings/   settings_page.dart, bindings_page.dart, controllers_page.dart,
              teach_page.dart, gamepad_drawing.dart, about_page.dart
  common/     glass.dart, notice.dart, input_chip.dart, signal_meter.dart, switch.dart
  strings.dart  (mantido: DriverScope e textos auxiliares)
```

Os desenhos (decalque, transferidor, acelerador, controle e partículas) são feitos com `CustomPainter`, sem imagens.

Os textos novos entram em `tool/gen_arb.py` nos três idiomas. Os textos que deixam de ser usados saem.

## 9. Peças de divulgação

As quatro peças são refeitas na nova identidade:
- feed do Instagram, 1080×1350;
- imagem do LinkedIn, 1200×627;
- prévia do GitHub, 1280×640;
- vídeo vertical de 18 s, 1080×1920, com faixa de áudio muda.

- **Composição:** fundo escuro com luz ambiente e granulação; o decalque do carro com os faróis acesos e a poeira brilhando no facho; o título em texto metálico, sem destacar uma palavra em outra cor; os recursos num cartão de vidro; o endereço do repositório acompanhado de um traço âmbar.
- **Telas do app** nas peças: renderizadas a partir do app de verdade, como hoje, pelo teste `marketing/render_ui_test.dart`.
- **Textos:** os mesmos de `marketing/texto-divulgacao.md`, já com a situação real de testes (Windows ainda não testado).
- **Vídeo:** mesmo roteiro do atual (carro, controle, app, recursos e encerramento), refeito com os elementos novos.

## 10. Testes

- **Automáticos:**
  - layout sem estouro em todas as faixas da seção 6, em português, inglês e espanhol;
  - um teste de tela para cada estado do painel da seção 5.2;
  - captura de botão e trava na tela;
  - testes do Driver para as mudanças da seção 7;
  - partículas desligadas nos testes.
- **Reduzir movimento:** um teste com a opção ligada confirma que nada quebra e que os estados continuam visíveis.
- **No aparelho:** APK de release no tablet com os dois carros e o DualShock, passando por todas as telas e estados possíveis; app do macOS no Mac. O Windows continua dependendo do teste do Daniel.

## 11. Fora do escopo

- Funções novas, mudanças no protocolo e iOS.
- Tema claro.
- Ícone do app: continua o atual.
- Publicar uma nova versão. Isso depende do plano de implementação e da aprovação do Daniel.

## 12. Riscos

| Risco | Como tratar |
|---|---|
| Desfoque e partículas pesados em Android simples | Limitar a quantidade de partículas, parar fora de primeiro plano e medir no tablet. Se pesar, trocar o desfoque por vidro opaco equivalente |
| Contraste dos textos pequenos | Texto nunca usa a cor de traço. Âmbar sobre o fundo dá cerca de 11:1 |
| Tamanho do app | A fonte variável acrescenta algumas centenas de KB |
| Reescrever todas as telas | Fazer por partes, com os testes atuais adaptados antes de remover as telas antigas |
