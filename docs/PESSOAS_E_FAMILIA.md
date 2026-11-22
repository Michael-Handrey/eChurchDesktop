# Pessoas e família: membros, visitantes, crianças e adolescentes

> **Situação:** em discussão (iniciada em 21/11/2026). Nada disto está implementado.
> Próximo passo: conversar com a secretaria sobre o cadastro físico (seção 8) e então fechar as decisões (seção 9).

---

## 1. O que existe hoje

- **Não há cadastro de criança.** Os tipos de pessoa são só *Membro*, *Aceitou Jesus* e *Reconciliado* (estes dois vêm dos apelos).
- **Pai, mãe e cônjuge são só texto.** Na ficha, o cônjuge "Carla Andressa Souza Leite" é um nome escrito, não aponta para o cadastro dela. O sistema não sabe quem é casado com quem nem quem são os filhos de quem.
- **Regra atual para menores de 18 anos:** só exige o *nome da mãe*, escrito como texto.
- **No banco local:** 452 pessoas; 23 com menos de 18 anos (2 com menos de 12), todas cadastradas como Membro; 306 casadas.

## 2. Ideia central: separar o que o tempo decide do que a secretaria decide

| Conceito | O que é | Quem decide | Gravado? |
|---|---|---|---|
| **Faixa etária** | Criança, Pré-adolescente/Adolescente, Adulto | a data de nascimento | **não**: calculada sempre |
| **Situação na igreja** | Membro ou Visitante | a secretaria | sim |
| **Responsáveis** | quem responde pelo menor de idade | a data de nascimento diz *até quando* | sim (vínculo) |

Assim ninguém precisa "mudar a criança de grupo" no aniversário, e ser membro não depende da idade.

## 3. Faixas etárias (calculadas)

| Faixa | Idade | Ministério | Precisa de responsável |
|---|---|---|---|
| **Criança** | 0 a 10 anos | Ministério Infantil | sim |
| **Pré-adolescente/Adolescente** | 11 a 17 anos | Avivah | sim |
| **Adulto** | 18 anos ou mais | — | não |

- Os limites (10 e 17) podem ficar **configuráveis** em Configurações > Geral, caso o ministério mude a idade um dia.
- Para separar só por idade dentro de uma tela (ex.: Infantil e Avivah), basta um filtro; o cadastro não muda.

## 4. Situação na igreja (gravada)

- **Membro:** a partir dos **12 anos**, por batismo ou profissão de fé. O sistema não aceitaria membro com menos de 12.
- **Visitante:** quem frequenta e ainda não é membro: crianças e adolescentes não batizados, e também adultos.
- *Aceitou Jesus* e *Reconciliado* continuam como hoje (apelos).

As duas coisas se combinam. Um adolescente de 14 anos batizado é **Membro** e está na faixa **Adolescente (Avivah)**, com os pais como responsáveis.

## 5. Responsáveis

- Toda pessoa com **menos de 18 anos**, Membro ou Visitante, precisa de **pelo menos um responsável** (pai, mãe ou outro: avó, tio...).
- O responsável aponta para um cadastro (membro ou visitante). Se não estiver na igreja, basta nome e telefone.
- Ao escolher um responsável **casado e vinculado ao cônjuge**, o sistema sugere incluir o cônjuge também. Um clique e os dois veem os mesmos filhos.
- **Aos 18 anos** o vínculo **não é apagado**: deixa de ser "responsável legal" e vira **família**. O filho continua aparecendo na ficha dos pais. Isso é calculado, ninguém precisa mexer.
- Funciona também com pais separados e com criança criada por avós.

### Exemplo: Michael e Carla

1. Filho nasce ou é cadastrado aos 5 anos → **Visitante**, faixa **Criança (Infantil)**, responsáveis: Michael e Carla.
2. Faz 11 → passa sozinho para **Pré-adolescente/Adolescente (Avivah)**.
3. É batizado aos 14 → a secretaria usa "Tornar membro" → **Membro**; Michael e Carla **continuam responsáveis**.
4. Faz 18 → continua Membro; o vínculo vira só família (aparece como filho na ficha dos dois).

## 6. Cônjuge como vínculo

Hoje: só texto (`spouse_name`). Proposta: **duas colunas**.

| Coluna | Uso |
|---|---|
| `spouse` (nova, referência a `natural_person`) | quando o cônjuge é membro ou visitante cadastrado |
| `spouse_name` (já existe) | quando o cônjuge **não** está cadastrado |

Regras:
- **Mostrar:** com vínculo, o nome vem do cadastro do outro (se ele corrigir o nome, aparece corrigido).
- **Dois lados ao mesmo tempo:** ligar A a B liga B a A; desligar também.
- **Proteções:** só com estado civil Casado(a) (o formulário oferece atualizar o do outro); ninguém ligado a dois; ninguém ligado a si mesmo.
- **Falecimento:** o vínculo fica; o estado civil vira viúvo(a) à mão.
- **Endereço:** ao vincular um casal com endereços diferentes, oferecer "usar o mesmo endereço para os dois".

### Vincular os casais que já existem: rotina "Revisar cônjuges" (não script direto)

Motivos: o banco de produção é diferente do local; quem conhece as famílias é a secretaria; a rotina serve de novo depois (cadastros novos); cada vínculo fica registrado (quem e quando).

#### Como cada sugestão é encontrada

**Pelo nome** (sem acento, sem diferenciar maiúsculas, espaços simples):

| Tipo | Regra | Pares (local) |
|---|---|---|
| **A. Confirmado pelos dois lados** | o cônjuge escrito de cada um é o nome do outro | 86 |
| **B. Só um lado** | o cônjuge escrito de um é o nome do outro, mas o outro tem outro cônjuge escrito (ou nenhum) | 38 |
| **C. Nome parecido** | o cônjuge escrito não é o nome de ninguém, mas um nome começa com o outro (abreviado, sem sobrenome) | 4 |
| Sem sugestão | nenhum dos casos | 65 pessoas |

**Pelo endereço** (campos usados):

| Campo | Como |
|---|---|
| `natural_person.address` | mesmo registro = mesmo endereço |
| `address.street_name` | sem acento, sem o tipo no começo ("Rua", "R.", "Av."...), só letras e números |
| `address.street_number` | só letras e números ("s/n" → "sn") |
| `address.postal_code` | só os números; **CEP genérico de cidade (termina em 000, ex.: 86600-000, que aparece em 39 endereços) não conta** |
| `address.district` | mesmo bairro |
| `address.complement` | desempata: os dois preenchidos e diferentes ("Apto 12" × "Apto 31") = conflito; vazio de um lado não conta |
| `address.street_type` | não entra (o tipo escrito dentro do nome da rua já é tirado) |

**Mesmo endereço** = mesma rua + mesmo número + (CEP específico igual **ou** mesmo bairro), sem conflito de complemento.

#### Grau de certeza (números do banco **local**; a rotina calcula com os dados de produção)

| Confiança | Critério | Pares | Ação |
|---|---|---|---|
| **Alta** | A + mesmo endereço + os dois casados + mesma igreja + ninguém do par em outra sugestão | 65 | "Vincular todos" depois de conferir a lista |
| **Média** | o resto de A (endereço diferente, estado civil ou igreja diferentes, possível duplicado); B + mesmo endereço | 52 | confirmar um a um |
| **Baixa** | o resto de B; todos de C | 11 | confirmar com atenção |
| — | sem sugestão (cônjuge provavelmente não é membro) | 65 pessoas | fica como texto |

Com a regra nova (sem acento, sem o tipo da rua, CEP genérico fora, bairro e complemento), **74 dos 86 pares confirmados pelos dois lados moram no mesmo endereço** (antes eram 60 de 80).

#### Achados na contagem

- **Cadastros duplicados:** pelo menos dois casais estão cadastrados duas vezes (dois registros para cada pessoa), o que cria pares cruzados. 12 nomes aparecem em mais de uma sugestão. Eles **não entram no "vincular todos"**: antes é preciso decidir qual cadastro fica. A rotina deve avisar "possível cadastro duplicado".
- **Estado civil diferente:** 2 pares confirmados estão como casado × viúvo (pode ser falecimento não registrado no outro cadastro).
- **Igrejas diferentes:** 2 pares confirmados estão em igrejas diferentes.

A lista completa, par a par (com nomes e endereços), está em `eChurchWorkspace/REVISAO_CONJUGES_BANCO_LOCAL.md`, **fora dos repositórios** por ter dados pessoais.

- O endereço é **sinal de confiança, não regra**: pares confirmados pelos dois lados com endereços diferentes quase sempre são cadastro desatualizado.
- No formulário do membro, ao escrever o nome do cônjuge, sugerir na hora: "Fulana é membro. Vincular?" (quem tem o mesmo endereço aparece primeiro).

## 7. Telas e relatórios previstos

- **Membros:** quem tem a situação Membro, de qualquer idade (já existe).
- **Crianças e Adolescentes:** todos com menos de 18 anos; abas **Crianças (Infantil)** e **Pré-adolescentes/Adolescentes (Avivah)**; coluna "Membro" (sim/não); responsáveis.
- **Formulário único de pessoa:** para menores de 18, a seção **Responsáveis** é obrigatória e CPF, RG e endereço ficam opcionais (o endereço pode ser copiado de um responsável).
- **Ficha do membro:** seção **Família** (cônjuge e filhos), montada a partir dos vínculos.
- **Busca rápida:** grupo **Crianças e Adolescentes** junto com Membros.
- **Relatórios por data de referência:** a idade é calculada **na data do evento**. Ex.: "crianças até 10 anos em 12/10/2026" para o Dia das Crianças (quem ganha presente), com total por igreja e lista com nome, idade e responsáveis. O mesmo para o Avivah.
- **Avisos para a secretaria:**
  - menores de 18 sem responsável vinculado (os 23 de hoje entram aqui);
  - visitantes que completaram 18 anos (para decidir se seguem como visitantes).

### Alternativa considerada e descartada: cadastro de "Família"

Uma ficha "Família Santos Augusto" com a lista de pessoas e o papel de cada uma.
- **Contra:** criança de pais separados mora em duas casas, mas só caberia em uma família; mais uma ficha para manter (filho casa, muda de família); informação repetida com o cônjuge da ficha.
- Com os vínculos (cônjuge + responsáveis), a família **aparece sozinha** na ficha, sem cadastro a mais.

## 8. Perguntas para a secretaria (cadastro físico)

**Fichas que existem hoje**
- [ ] Existe ficha de criança separada da de membro? Quais campos ela tem?
- [ ] Existe ficha de visitante? O que é anotado?
- [ ] O Avivah (11 a 17) tem ficha própria?

**Dados da criança e do adolescente**
- [ ] Quais dados são obrigatórios? (nome, nascimento, responsáveis, telefone...)
- [ ] CPF e RG da criança são pedidos?
- [ ] Anotam **alergias, restrições alimentares, medicamentos, necessidades especiais**?
- [ ] Há **autorização de uso de imagem** ou de **saída/retirada** (quem pode buscar a criança)?
- [ ] Escola, série, tamanho de roupa (para eventos/presentes)?

**Responsáveis**
- [ ] Quantos responsáveis costumam ser anotados? Só pai e mãe, ou também avós/tios?
- [ ] O responsável que não é da igreja: o que se anota dele (nome, telefone, parentesco)?

**Casais**
- [ ] A ficha do membro registra o cônjuge pelo nome? Há ficha de casal ou de família?
- [ ] Ela consegue confirmar os casais pela lista "Revisar cônjuges" (65 de alta confiança, 63 a conferir)? A lista está em `REVISAO_CONJUGES_BANCO_LOCAL.md` (pasta do workspace).
- [ ] Ela conhece os casais cadastrados em duplicidade? Qual cadastro deve ficar?

**Rotina e uso**
- [ ] Quais relatórios ela faz hoje à mão? (ex.: contagem para o Dia das Crianças, lista do Avivah)
- [ ] Os limites 10 e 17 anos são fixos ou já mudaram alguma vez?
- [ ] Quem trata os visitantes adultos (que não são membros)? Eles devem entrar no sistema?

## 9. Decisões pendentes

| # | Decisão | Proposta | Situação |
|---|---|---|---|
| 1 | Criança no mesmo cadastro de pessoas (não em cadastro separado) | sim, com faixa etária calculada | a confirmar |
| 2 | Faixas: Criança 0–10, Pré-adolescente/Adolescente 11–17 | sim; limites configuráveis | a confirmar |
| 3 | Situações: Membro (a partir de 12) e **Visitante** | sim | nome "Visitante" definido; regra a confirmar |
| 4 | Responsáveis obrigatórios para menores de 18 (inclusive membros) | sim; aos 18 vira família | a confirmar |
| 5 | Vínculo por responsáveis, não cadastro de família | sim | a confirmar |
| 6 | Cônjuge como vínculo (`spouse` + `spouse_name`) | sim | **confirmado** (2026-11-22); coluna `spouse` |
| 7 | Vincular casais existentes por rotina da secretaria, com confiança pelo endereço (regra da seção 6) | sim | **confirmado** (2026-11-22) |
| 10 | Cadastros duplicados (mesma pessoa com dois registros): como juntar | rotina própria, antes de vincular os cônjuges; depois, CPF único no banco (DATA-1 no TASKS da API: 9 CPFs repetidos no banco local) | **feito** (2026-11-22): tela Membros > "Cadastros duplicados"; falta a secretaria juntar os casos |
| 8 | Campos extras da criança (saúde, autorizações, retirada) | depende da conversa com a secretaria | aberto |
| 9 | O que fazer com visitantes que completam 18 anos | aviso para a secretaria decidir | aberto |
