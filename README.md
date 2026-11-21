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
tipos     tipos de produto cadastrados
exc       marcas de exclusão (para a sincronização)
cfg       início, prazo, área construída e foto do perfil
```

Campos que valem citar: `cot[].conc` é o nome da concorrência (vazio = cotação avulsa) e `cot[].desconto` é o desconto negociado, rateado entre os itens na hora de virar compra.

Os arquivos das notas não entram nesse pacote: ficam no IndexedDB do aparelho e no repositório do Supabase, para não pesar na sincronização. O mesmo vale para fotos anexadas a gastos e cotações — eram embutidas em base64 dentro do próprio pacote, e um pacote grande demais faz o envio à nuvem falhar sem avisar. Em Configurações → Sincronização dá para ver o tamanho atual e mover fotos antigas que ainda estejam pesadas.

---

## O que o sistema faz

**Gastos** — lançamento com fornecedor, categoria, anexo e nota. O botão "Relatório em PDF" gera o dossiê completo da obra: resumo e custo por m², gasto por etapa, por tipo de produto e por fornecedor, tabela de materiais com quantidade e preço médio pago, mão de obra por trabalhador, todos os lançamentos etapa por etapa, pendências e notas fiscais — com a opção de sair só do recorte filtrado na tela. Divisão de uma compra entre várias etapas, pagamento parcelado, compra recorrente mensal, controle de entrega parcial de material e filtro por período.

**Telas de digitação** — Lançar gasto e Nova cotação abrem em duas colunas no computador e cabem na tela sem rolar; o botão Salvar fica fixo embaixo. No celular continuam em uma coluna, com Salvar sempre visível. O que é raro (receber material aos poucos, repetir todo mês, código e fornecedor de cada item) fica recolhido em "Mais opções" e abre sozinho quando já tem dado. Os campos e o formato dos dados são os mesmos de antes: nada do que já foi digitado muda.

**Cancelamento** — excluir um gasto ou colaborador não apaga: marca como cancelado e some dos totais. Os filtros Ativos / Cancelados / Todos mostram e permitem restaurar. Colaborador com gastos ativos não pode ser excluído.

**Filtro de gastos por data** — em Gastos dá para filtrar pela data da compra ou pela data em que foi digitado (atalhos Hoje, Ontem, Mês, Ano, Tudo).

**Listas e teclado nas telas de digitação** — categoria/etapa, tipo de produto, descrição e fornecedor usam a lista do próprio sistema (não a do navegador). Seta para baixo/cima percorre e marca a opção, Enter ou Tab confirma, Esc fecha; a lista abre para cima quando não cabe embaixo. A etapa do gasto começa **vazia** e é obrigatória para salvar (em compra com vários itens, cada item precisa da sua).

**Relatório personalizado** (aba Gastos) — monta um relatório de gastos do seu jeito. Você escolhe: a situação (só o que já foi pago, tudo ou só o que falta pagar), o período, quais categorias entram (Terreno e Projetos já vêm desmarcados) e se engenheiro/arquiteto/projetos ficam de fora pelo nome, descrição ou função do colaborador — uma caixa mostra na hora quanto ficou de fora. As colunas são marcadas e reordenadas com ↑ ↓ (Data, Descrição, Fornecedor, Tipo de produto, Etapa, Qtde, Valor unitário, Situação, Nota fiscal, Observações, Digitado em, e Valor, que é sempre a última). Dá para agrupar por etapa da obra, tipo de produto, fornecedor ou mês (ou não agrupar), ordenar por data, ordem alfabética ou valor, e ligar subtotais e um resumo por grupo com percentuais. Sai em PDF (A4, paisagem automática com muitas colunas) ou em planilha CSV com as mesmas colunas. Compra dividida entre etapas aparece uma linha por etapa. As escolhas ficam salvas.

**Cotações** — cada cotação vale por si e soma na previsão de pagamento. Quando duas ou mais disputam a **mesma** compra, você monta uma **concorrência** entre elas (botão "Montar concorrência", depois de criadas) e só a menor passa a contar na previsão. Dentro de uma concorrência, a comparação é feita **pelo preço unitário de cada item**, recalculando todas para a mesma quantidade — assim um orçamento com quantidade menor não ganha por engano. Mostra ainda quanto custaria comprando cada item no fornecedor mais barato.

A lista vem separada em concorrências, cotações com preço e a cotar. O botão "Imprimir" gera uma folha A4 por fornecedor, com itens, preços, desconto e espaço de conferência — feita para salvar em PDF e mandar ao fornecedor. Importa orçamento em PDF ou texto colado, tem campo de desconto negociado rateado entre os itens, validade preenchida com 5 dias por padrão, anexo de vários PDFs (que abrem dentro do sistema) e confirmação de compra **em lote**: marque várias cotações já acertadas e todas viram lançamentos de uma vez.

**Notas** — arquivo das notas fiscais para o habite-se. O XML da NF-e é lido por completo e sem erro — é sempre o melhor caminho. O PDF do DANFE é lido por texto, com conferência. Para cupom fiscal (NFC-e), que não tem PDF com texto, use "Ler QR code": o app extrai a chave de acesso da foto e abre a nota no site oficial, de onde dá para baixar o XML ou copiar o texto e colar. O leitor entende três formatos: orçamento em tabela, pedido com desconto e cupom de duas linhas. Os itens da nota podem virar gastos da obra em um toque. Relatório final por nota e por item, em planilha.

**Itens** — quanto de cada material já entrou na obra, com preço médio pago por unidade.

**Equipe** — pedreiro, servente e ajudantes com valor de diária. "Lançar pagamentos" abre uma grade: marca quem trabalhou, em quais dias (2ª a sábado, com meia diária quando for o caso), e lança tudo de uma vez. "Por comprovante Pix" é o caminho direto: sobe vários comprovantes de uma vez (PDF ou foto do Inter, Next e similares — em foto o texto é lido no próprio aparelho). O app lê valor, data e o nome de **quem recebeu** (nunca o de quem pagou), casa com o colaborador e mostra tudo numa tela de conferência de duas colunas. Ele **aprende**: o nome que aparece no Pix e o CPF parcial ficam guardados no colaborador, então na próxima semana o mesmo recebedor já vem reconhecido sozinho. Comprovante que já foi lançado (mesmo colaborador, data e valor) vem marcado para pular. A **lista da semana** é opcional: cole ou digite "Bruno - 800 reais pedreiro" (uma por linha) e o sistema confere cada comprovante pelo nome ou pelo valor, aprende apelidos (Zezin = o nome do Pix), preenche a função de quem for novo e avisa quem ainda está sem comprovante. O **período trabalhado é automático**: vai do último pagamento daquela pessoa até o pagamento atual (pagou dia 1, 15 e 30 → o do dia 15 cobre 1 a 15 e o do dia 30 cobre 15 a 30). Ele aparece na conferência, fica gravado no lançamento (`perIni`/`perFim`) e é mostrado também nos pagamentos antigos, calculado na hora, sem alterar o que já foi lançado. O primeiro pagamento de uma pessoa não tem período anterior. O comprovante fica anexado a cada lançamento.

A lista da Equipe mostra só quem recebeu algo no período filtrado; quem está zerado fica de fora (aparece só uma linha dizendo quantos cadastros foram ocultados), e some do filtro de período junto com o resto. Escolher o nome no filtro de colaborador sempre mostra a pessoa.

**Cadastro rápido e Pix de cada colaborador** — em Equipe, "Cadastro rápido" recebe uma linha por pessoa no formato `Apelido | Nome completo no Pix | função | chave Pix`, mostra quem será atualizado ou criado e aplica de uma vez. O mesmo dado (apelido, nome no Pix, chave) pode ser editado na ficha de cada colaborador, em "Pix e apelido". O reconhecimento dos comprovantes usa, nesta ordem: chave Pix, CPF parcial, nome no Pix aprendido e, por fim, semelhança de nome.

**Tipos de produto** — ao lançar ou importar, o sistema deduz o tipo de cada material (Ferro, Hidráulica, Ferramentas da Obra, Material elétrico...), reaproveitando a grafia que você já usa. Sempre dá para corrigir antes de salvar, e o cadastro completo (criar, renomear, excluir e mover) fica na aba Itens, em "Tipos de produto".

**Texto padronizado** — o que você digita em nomes, descrições e fornecedores ganha a primeira letra maiúscula por palavra ao sair do campo, respeitando preposições ("Maria do Socorro", "Pá de Areia"), siglas (CA, PVC, LTDA) e códigos com número (14x19x39, 1/2, 6,00mm). Vale também para o texto vindo de PDF, que costuma chegar todo em maiúsculas.

**Painel** — total investido, fase atual com as pendências em aberto, contas vencidas ou vencendo, material pago que ainda está com o fornecedor, e gasto por categoria (com detalhamento ao tocar).

**Indicadores** — prazo consumido, ritmo mensal, projeção pelo próprio ritmo, custo por m² e qualidade do registro.

**Configurações** — backup, planilha CSV, junção de bases, pontos de restauração dos últimos 7 dias, prazo e área construída, e os cadastros de categorias/etapas.

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

Antes de qualquer mudança grande, exporte o backup em **Configurações → Exportar backup**, em cada aparelho.

Se algo der errado depois de uma importação, **Configurações → Pontos de restauração** volta os dados para como estavam em qualquer um dos últimos 7 dias.

Se aparecerem lançamentos repetidos, **Configurações → Verificar duplicados** compara por conteúdo (data, descrição e valor) e remove as cópias, mantendo a versão mais completa.

## Sem quantidade / valor unitário

Lançamentos antigos podem estar sem quantidade ou valor unitário. Há um aviso 📏 no Painel, um card "Sem quantidade" em Indicadores e um botão em Itens; todos abrem a lista para ajuste.
- Na lista você digita a quantidade e o valor unitário: o total é calculado (qtd × unitário).
- Se o lançamento já tem total, digite só a quantidade: o unitário é calculado (total ÷ qtd).
- Filtros por motivo (sem quantidade, sem unitário, conta não bate) e o botão "Quantidade 1 nos vazios".
- Nenhum lançamento fica sem quantidade: ao salvar, o sistema completa o que faltar.
- O relatório personalizado agora mostra quantidade e unitário proporcionais nas compras divididas (rateio).

## Unificar nomes

Configurações → **Unificar nomes**. Junta nomes repetidos de **fornecedor** (gastos, cotações e itens, emitente das notas) e de **tipo** (gastos, itens de cotação e de nota). Produto/descrição não é alterado.
- Busque (ex.: "vitor"), marque os nomes que são a mesma coisa (ou "Marcar os que aparecem"), digite o nome final e confirme.
- O aviso mostra quantos registros mudam antes de aplicar; vale em tudo e sincroniza com a nuvem.
- Só some o que foi marcado; para desfazer, use Configurações → Restaurar.

Em Configurações, os totais de Lançamentos, Cotações abertas, Fotos e Notas fiscais são clicáveis: abrem uma lista (com busca nos lançamentos) e tocar em um item abre o registro.

Em Unificar nomes, tocar em "N reg. ›" abre a lista dos registros que usam aquele nome (data, tipo, descrição e valor); "Voltar" retorna mantendo as marcações.

**Sem nomes repetidos:** ao salvar gasto, cotação, nota ou tipo, fornecedor e tipo digitados que já existem (ignorando maiúscula, acento, espaços e pontuação) passam a usar a grafia já cadastrada. Ex.: "bazar da serra" vira "Bazar da Serra". Criar um tipo que já existe é bloqueado. Para juntar nomes diferentes (ex.: "Bazar" e "Bazar da Serra"), use Unificar nomes.

**Relatório personalizado — "Conferir com o Painel":** na prévia do relatório há um bloco que parte do total de Construção do Painel e mostra, linha a linha, o que ficou de fora (período De/Até, engenheiro/arquiteto/projetos pelo nome, categorias desmarcadas) até chegar ao valor do relatório. Lista também os lançamentos que saíram pelo nome e tem o atalho "Tirar a data final".

**Conferir entradas — "Conferido, está certo":** cada grupo de "mesma descrição e mesmo valor" tem o botão para marcar que a repetição é correta (mesmo produto comprado em dias diferentes). O grupo some da lista e do contador; se um novo lançamento igual aparecer, o grupo volta a ser avisado. "Rever" no fim da tela desfaz todas as marcações.

**Número (#) fixo em cada gasto:** cada lançamento tem um número que nasce uma vez e não muda (nem com gasto de data antiga, nem se outro for apagado). Os números que você já via foram mantidos. Dá para buscar em Gastos digitando `#123`; o número aparece em Conferir entradas, nas listas de Configurações, em Unificar nomes e no relatório (coluna "Nº", desligada por padrão). Em Conferir entradas, tocar num gasto abre a edição direto; gasto sem etapa aparece em vermelho.

**Notas fiscais:** removido o vínculo com gastos (campo na nota, botões "Vincular", avisos "sem gasto vinculado", cards e a lista em Conferir entradas). As notas ficam só como arquivo/registro.

**Relatório personalizado — datas e conferência com o Painel:** as datas não ficam mais salvas; o relatório abre sempre com "De" = primeiro gasto e "Até" = hoje, e o botão **Toda a obra** volta a esse período. **Só construção** e **Todas** não tiram ninguém pelo nome, então o total de construção (situação "O que já paguei") é igual ao do Painel e de Indicadores ("Construção até agora"). **Sem terreno e projetos** continua tirando engenheiro/arquiteto/projetos pelo nome.

**Produtos iguais somados:** descrições do mesmo produto escritas de formas diferentes ("100 Sacos de Cimento 50kg", "Cimento 50kg", "1 Carrada de Areia (10m³)", "Areia") viram um item só. O sistema tira número e embalagem do começo ("100 Sacos de", "Carrada de") e, em areia/brita/pedra, o volume (10m³). Em **Itens** (resumo por material) cada produto mostra compras, período, quantidade total, valor unitário médio (total ÷ quantidade) e valor total. No **relatório personalizado**, "Agrupar por → Produto (itens iguais somados)" traz o resumo com Qtde total, Valor unit. médio e Valor (no PDF e no fim da planilha). Areia sem nome conta como **Areia Grossa**; Areia Média e Areia Fina continuam separadas. Se os preços de um mesmo produto forem muito diferentes (ex.: carrada e m³ misturados), aparece um aviso de unidades misturadas.

**Relatório personalizado — tipo de relatório:** no começo do formulário há "Tipo de relatório". **Compra por compra (detalhado)** é o de sempre; a descrição agora fica em uma linha só (o aviso "parte de compra dividida" virou um "(parte)" ao lado) e fornecedor/tipo/etapa quebram linha para dar espaço a ela. **Produtos somados (sem fornecedor e sem etapa)** gera uma tabela só com Produto, Tipo, Compras, Qtde total, Valor unit. médio, Valor total e %, em PDF ou planilha, respeitando período, situação e categorias escolhidos (ordem alfabética ou por valor).

**Quantidades sempre inteiras:** todas as telas, relatórios e planilhas mostram quantidade sem casas decimais; no gasto e no ajuste "Sem quantidade" a quantidade é arredondada para número inteiro (mínimo 1) ao salvar. O valor unitário médio continua calculado com o total exato.

**Produtos (itens iguais somados):** é um tipo de relatório (campo "Tipo de relatório"), só com o resumo por produto — sem lançamentos, fornecedor nem etapa. Foi retirada a opção "Produto" de "Agrupar por" do relatório detalhado, para não listar lançamentos por baixo.

**Versão:** o sistema mostra a versão em Configurações (e no rodapé dos relatórios). Hoje: **versão 29 (21/11/2026)**. A cada entrega sobe junto: `APP_VERSAO` no HTML e o número do cache no `sw.js` (`obra-c08-v29`).

**Mão de obra nos produtos somados:** tudo que tem o tipo "Mão de obra" vira uma linha só, "Mão de obra - Todos" (também na tela Itens).

**Resumo por fase no final:** os relatórios (detalhado e produtos somados) terminam com o "Resumo por fase da obra" (compras, valor e %); na planilha de produtos somados ele vem no fim.

**Cabeçalho dos relatórios personalizados:** ficam só o título e a data de emissão (sem endereço da obra, período, situação nem lista do que não entra).
