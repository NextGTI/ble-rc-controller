# Protocolo do carrinho

[English](PROTOCOL.md) · [Español](PROTOCOL.es.md) · **Português**

Descreve a interface Bluetooth LE dos carrinhos compatíveis, como implementada em `lib/core/protocol.dart`. Foi obtida observando o comportamento dos carrinhos e analisando como o app deles monta os pacotes, apenas para criar um controle compatível. Este projeto não inclui código nem arquivos desse app.

## Encontrando o carrinho

O carrinho anuncia:

- um nome local que começa com **`SL-`** (por exemplo `SL-SF-25`),
- um serviço de 16 bits **`6936`**.

O app lista um dispositivo se qualquer um dos dois bater. Não precisa de pareamento nem PIN.

## GATT

| Serviço | Característica | Propriedades | Uso |
|---|---|---|---|
| `FFF0` | `FFF1` | write, write-without-response, notify | **Pacotes de controle** (o que o app escreve) |
| `FFF0` | `FFF2` | notify | não usada |
| `6936` | `FE01` | write, write-without-response, notify | não usada |
| Bateria `180F` | `2A19` | read, notify | Porcentagem de bateria |

O carrinho aceita **uma conexão por vez**.

## Pacote de controle

Escreva **8 bytes** em `FFF1`, **sem resposta**:

| Byte | Campo | Valores |
|---|---|---|
| 0 | modo | `1` ou `2` |
| 1 | frente | `0` / `1` |
| 2 | ré | `0` / `1` |
| 3 | esquerda | `0` / `1` |
| 4 | direita | `0` / `1` |
| 5 | luz | `0` / `1` |
| 6 | turbo | `0` / `1` |
| 7 | giro 360° | `0` / `1` |

Todos os campos, exceto `modo`, são simples liga/desliga; não há velocidade nem direção proporcionais. Um pacote com todos os campos em `0` para o carrinho.

Exemplo — frente com a luz ligada: `01 01 00 00 00 01 00 00`.

## Temporização

O app oficial do carrinho escreve um pacote só quando algo muda. Este app também repete o pacote atual pelo menos a cada 200 ms. Nos testes, uma conexão sem tráfego foi derrubada pelo carrinho após uns dez segundos.

Sempre envie um pacote neutro (tudo zero) antes de desconectar.

## Notas e dúvidas

- O significado de `modo` (1 ou 2) no próprio carrinho não está documentado aqui.
- Testado com um único modelo de carrinho. Os demais parecem usar a mesma interface; relatos são bem-vindos.
