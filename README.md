# Gestão Obras C08

Sistema de acompanhamento de obra própria — gastos, cotações, notas fiscais, mão de obra, fotos e indicadores.
Feito para a construção da residência no Condomínio Monte das Cerejeiras, Quadra B, Lote 08, em Bananeiras-PB.

Roda no navegador do celular e do computador, funciona sem internet no canteiro e sincroniza sozinho entre os aparelhos.

---

## Como está montado

Um único arquivo HTML com tudo dentro (estrutura, estilo e código). Sem build, sem instalação, sem dependências para compilar.
A hospedagem é GitHub Pages; o Supabase guarda os dados na nuvem e os arquivos das notas fiscais.

| Arquivo | Para que serve |
|---|---|
| `index.html` | O sistema inteiro |
| `manifest.json` | Faz o Android abrir como aplicativo, e não como site |
| `sw.js` | Service worker — deixa o app abrir sem internet |
| `icon-192.png`, `icon-512.png`, `icon-maskable-512.png` | Ícones do app |

Todos ficam na raiz do repositório, no mesmo nível.

---

## Publicar uma atualização

1. Substitua `index.html` pela versão nova (e os demais arquivos, se mudaram).
2. Faça o commit. O GitHub Pages publica em cerca de um minuto.
3. No celular, se o app estiver salvo na tela inicial, feche-o pelo gerenciador de aplicativos e abra de novo — senão ele reabre a versão guardada em cache.

Ao mexer no `sw.js`, suba o número da versão do cache (`const CACHE='obra-c08-vN'`), senão os aparelhos continuam com a cópia antiga.

---

## Configuração do Supabase

Feita uma única vez. No painel do Supabase, em **SQL Editor → New query**, cole o `supabase-recriar.sql` e rode. Ele cria:

- a tabela `obra_dados` — um registro por usuário, com todos os dados da obra em JSON;
- o repositório de arquivos `notas` — onde ficam PDF, XML e fotos das notas fiscais.

Os dois usam Row Level Security: cada conta só enxerga o que é dela.

O usuário é criado em **Authentication → Users**. A URL do projeto e a chave publicável ficam no topo do `<script>` do `index.html`, em `SUPA_URL` e `SUPA_KEY`. A chave publicável pode ficar exposta — quem protege os dados são as políticas de acesso, não ela.

---

## Como os dados funcionam

O sistema é **offline-first**: tudo é gravado primeiro no aparelho (`localStorage`, chave `obraC08`) e depois enviado para a nuvem. Se a internet cair, nada para.

A sincronização acontece ao abrir o app, ao voltar para ele e a cada minuto. A junção é feita registro a registro:

- **mesmo registro nos dois lados** → fica a versão editada mais recentemente;
- **registro só na nuvem** → entra, a menos que tenha sido apagado aqui;
- **registro apagado** → deixa uma marca de exclusão que viaja junto, para o item não "ressuscitar" vindo do outro aparelho.

Estrutura guardada:

```
lanc      gastos lançados
cot       cotações e propostas de fornecedores
notas     notas fiscais, com os itens de cada uma
equipe    trabalhadores e valor da diária
passos    pendências por etapa da obra
fotos     álbum da obra
catExtra  categorias criadas por você
exc       marcas de exclusão (para a sincronização)
cfg       início, prazo, área construída e foto do perfil
```

Campos que valem citar: `cot[].conc` é o nome da concorrência (vazio = cotação avulsa) e `cot[].desconto` é o desconto negociado, rateado entre os itens na hora de virar compra.

Os arquivos das notas não entram nesse pacote: ficam no IndexedDB do aparelho e no repositório do Supabase, para não pesar na sincronização.

---

## O que o sistema faz

**Gastos** — lançamento com fornecedor, categoria, anexo e nota. Divisão de uma compra entre várias etapas, pagamento parcelado, compra recorrente mensal, controle de entrega parcial de material e filtro por período.

**Cotações** — cada cotação vale por si e soma na previsão de pagamento. Quando duas ou mais disputam a **mesma** compra, você monta uma **concorrência** entre elas (botão "Montar concorrência", depois de criadas) e só a menor passa a contar na previsão. Dentro de uma concorrência, a comparação é feita **pelo preço unitário de cada item**, recalculando todas para a mesma quantidade — assim um orçamento com quantidade menor não ganha por engano. Mostra ainda quanto custaria comprando cada item no fornecedor mais barato.

A lista vem separada em concorrências, cotações com preço e a cotar. Importa orçamento em PDF ou texto colado, tem campo de desconto negociado rateado entre os itens, validade preenchida com 5 dias por padrão, anexo de vários PDFs (que abrem dentro do sistema) e confirmação de compra **em lote**: marque várias cotações já acertadas e todas viram lançamentos de uma vez.

**Notas** — arquivo das notas fiscais para o habite-se. O XML da NF-e é lido por completo e sem erro; o PDF do DANFE é lido por texto, com conferência. Os itens da nota podem virar gastos da obra em um toque. Relatório final por nota e por item, em planilha.

**Itens** — quanto de cada material já entrou na obra, com preço médio pago por unidade.

**Equipe** — pedreiro, servente e ajudantes com valor de diária. O lançamento da semana marca os dias trabalhados e vira gasto na etapa de mão de obra.

**Tipos de produto** — ao lançar ou importar, o sistema deduz o tipo de cada material (Ferro, Hidráulica, Ferramentas da Obra, Material elétrico...), reaproveitando a grafia que você já usa. Sempre dá para corrigir antes de salvar.

**Texto padronizado** — o que você digita em nomes, descrições e fornecedores ganha a primeira letra maiúscula por palavra ao sair do campo, respeitando preposições ("Maria do Socorro", "Pá de Areia"), siglas (CA, PVC, LTDA) e códigos com número (14x19x39, 1/2, 6,00mm). Vale também para o texto vindo de PDF, que costuma chegar todo em maiúsculas.

**Painel** — total investido, fase atual com as pendências em aberto, contas vencidas ou vencendo, material pago que ainda está com o fornecedor, e gasto por categoria (com detalhamento ao tocar).

**Indicadores** — prazo consumido, ritmo mensal, projeção pelo próprio ritmo, custo por m² e qualidade do registro.

**Importações** — backup, planilha CSV, junção de bases e pontos de restauração dos últimos 7 dias.

---

## Detalhes que costumam confundir

**A aba Gastos abre filtrada no mês atual.** O Painel mostra a obra inteira. Para conferir um contra o outro, marque "Todos os períodos" ou use o botão "Desde o início". O total geral aparece embaixo sempre que houver filtro ativo.

**O Painel conta só o que está pago.** A aba Gastos, no padrão, inclui também as contas em aberto.

**Os valores abrem escondidos.** O ícone de olho no topo revela.

**A leitura de PDF depende de o arquivo ter texto.** Orçamento digitalizado ou fotografado não tem — nesse caso, use "Colar o texto do orçamento" ou digite. Quando o layout foge do padrão, "Escolher as linhas na mão" resolve.

**Sem nuvem o app continua funcionando.** Se o login falhar por problema de conexão, aparece a opção de entrar em modo local; um aviso vermelho no Painel deixa claro que nada está sendo sincronizado.

**Concorrência não é automática.** Cotações com nomes parecidos não são agrupadas sozinhas — se elas não estiverem numa concorrência, todas somam na previsão, que é o comportamento certo para compras diferentes.

---

## Manutenção

Antes de qualquer mudança grande, exporte o backup em **Importações → Exportar backup**, em cada aparelho.

Se algo der errado depois de uma importação, **Importações → Pontos de restauração** volta os dados para como estavam em qualquer um dos últimos 7 dias.

Se aparecerem lançamentos repetidos, **Importações → Verificar duplicados** compara por conteúdo (data, descrição e valor) e remove as cópias, mantendo a versão mais completa.
