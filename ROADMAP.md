# eChurch Desktop — Roadmap

Funcionalidades planejadas e ainda não iniciadas. Para tarefas técnicas do backend, ver `TASKS.md` no projeto e-Church.

**Última atualização:** 2026-11-20

---

## Próximos passos (validação manual)

O código do login, da tela de usuários e do ajuste da janela está pronto e coberto por testes (`flutter analyze` limpo, 60 testes passando). A renovação de sessão durante o uso já foi conferida. Falta conferir no app aberto o que os testes não alcançam.

### 1. Validar a janela no app aberto

- splash, login e troca de senha abrem centralizados em 960×640 e não podem ser redimensionados, maximizados (nem por duplo clique na barra de título);
- o painel ocupa a área útil do monitor (sem cobrir a barra de tarefas) e não pode ser redimensionado, maximizado nem arrastado;
- no logout, a janela volta ao tamanho do login, centralizada;
- com o painel aberto, mudar a resolução, a escala ou a posição da barra de tarefas reajusta a janela à nova área útil.

### 2. Validar a redefinição de senha pelo administrador

Com a API local, entrar como administrador, abrir "Usuários" e:
- gerar uma senha provisória: o diálogo mostra a senha uma vez e permite copiar;
- definir uma senha escolhida: só libera quando atende às regras;
- entrar com o usuário redefinido: a troca de senha é exigida no primeiro acesso;
- uma sessão aberta antes do reset do usuário cai na próxima renovação.

### 3. Publicar (API 1.0.12 + app)

**Quando:** só na hora de subir para produção. O banco de produção continua com os nomes antigos até lá.

O jar em produção é de antes do Spring Boot 4, do Hibernate 7 e do banco em inglês. Antes de subir o jar novo, guardar cópia do jar, do `application.properties` do servidor e um dump do banco atual.

1. **Banco:** migrar o banco de produção para os nomes em inglês. Gerar um dump novo de produção (`dump.sql`), rodar `scripts/gen_dump_en.py dump.sql dump_en.sql` e restaurar. O `dump_en.sql` que está no projeto é antigo: restaurar ele perde o que foi cadastrado depois. A migração também cria as tabelas de sessão (`user_refresh_token`, `revoked_access_token`).
2. **`application.properties` do servidor** (menu de deploy do cPanel): tirar `PostgreSQL9Dialect`, `enable_lazy_load_no_trans` e as chaves que não existem mais; incluir `jwt.secret` (chave nova) e `echurch.credential.salt` (o mesmo valor de antes). Trocar `logging.file.max-size` por `logging.logback.rollingpolicy.max-file-size`.
3. **Jar:** subir o `eChurchIMDF.jar` 1.0.12; se não subir, o log lista o que falta.
4. **Administrador:** conferir que o usuário administrador está no grupo `ADMIN`, que dá a permissão `ROLE_ADMIN` (sem ela, o menu "Usuários" não aparece). No dump de produção, o login `ADMIN` só está em SECRETARIA e USUARIO, e o único administrador é o `rjmelo`: incluir o `ADMIN` no grupo `ADMIN`.
5. **App:** gerar o release com a URL da API em HTTPS, `flutter build windows --dart-define=BASE_URL=https://<servidor>/api` (o app recusa HTTP em release).

---

## Usuários e acesso

### Regras de acesso (decidido em 2026-11-20)

Os grupos funcionam como "cargos" e as permissões se **somam** (quem está em dois grupos tem o que os dois permitem). Cada permissão é conferida **na API** e no app (esconder ou desabilitar o que não pode), e entra junto com a tela que a usa. A primeira a aplicar tudo é a **tela de membros**.

| Grupo | Faz | Não pode |
|---|---|---|
| **Administrador** (`ROLE_ADMIN`) | Tudo, em todas as igrejas, mais usuários, grupos, permissões, senhas e configurações | — |
| **Secretaria** (`ROLE_SECRETARIA`) | Cadastrar, editar e desativar membros, crianças, ministérios e eventos; emitir credenciais e documentos; ver relatórios; **gerenciar e imprimir os pedidos de oração** | Usuários e configurações |
| **Usuário** (`ROLE_USER`, só consulta) | Ver membros (dados abaixo), eventos; registrar pedido de oração | Editar, excluir, emitir credenciais e documentos |

O que o **Usuário** vê de cada membro:

| Dado | Vê? |
|---|---|
| Nome, foto, ministério, situação | Sim |
| Telefone e e-mail | Sim (para contato) |
| Data de nascimento | Só dia e mês (aniversariantes) |
| Endereço | Não |
| CPF, RG | Não |
| Estado civil, filiação, histórico (batismo, entrada, saída) | Não |

**Ninguém exclui membros, nem o Administrador.** Desativa-se com um **motivo** (saiu da igreja, transferido para outra igreja, mudou de cidade, falecimento, cadastro duplicado, outro) e uma **descrição obrigatória**; o sistema grava quem desativou e quando. Reativar volta o membro para ativo (a justificativa anterior fica no log de auditoria). Já vale na API e na tela de membros (botões "Desativar" e "Reativar", só para Secretaria/Administrador).

**Acesso por igreja: "sede supervisiona".** O alcance depende da igreja **e** da permissão:

| Quem | Alcança |
|---|---|
| Administrador | Todas as igrejas |
| **Secretaria da sede** | A sede e as filiais |
| Secretaria de filial | Só a própria filial |
| Usuário (só consulta), da sede ou de filial | Só a própria igreja |

O que pode fazer em cada igreja alcançada vem dos grupos (ex.: secretaria da sede edita membros de qualquer filial).

- **Feito na API (2026-11-20):** a regra vale para a lista de igrejas, o seletor da barra superior e os endpoints de **membros e apelos** (ler e alterar). As permissões por grupo também já valem na API: só Secretaria/Administrador alteram, só o Administrador exclui, e quem só consulta recebe o membro com os dados reduzidos da tabela acima (SEC-12b e SEC-13 no TASKS do backend).
- **Feito na tela de membros (etapa 1, 2026-11-20):** lista da igreja escolhida no seletor (Ativos / Inativos / Todos, busca por nome, filtro por cargo, páginas de 20, cabeçalho fixo ao rolar), detalhes (completos para Secretaria/Administrador, reduzidos para quem só consulta), desativar com motivo e descrição, e reativar. Quem só consulta não vê os botões.
- **Busca rápida na barra superior (2026-11-21):** acha um membro pelo nome, telefone ou (Secretaria/Administrador) CPF, comparando só os dígitos, em todas as igrejas do alcance e em qualquer situação. Os resultados (até 8) aparecem numa lista abaixo do campo; clicar ou Enter abre a ficha sem sair da tela. Ctrl+K vai para o campo, Esc fecha. Quando existir a tela de **Crianças**, entram como outro grupo na mesma lista. A busca da tela de membros usa a mesma regra.
- **Feito (etapa 2, 2026-11-21):** cadastro e edição do membro (Secretaria/Administrador): página com índice das seções (✓ completa, ! com erro, ○ faltando obrigatório) e Cancelar/Salvar sempre visíveis. Seções: dados pessoais, documentos (CPF validado), família, endereço (CEP preenche rua, cidade e bairro; bairro e profissão novos cadastrados ali mesmo), contato, igreja (cargo, ministérios, batismo) e observações. Erros da API aparecem no campo certo. Pai e mãe continuam como texto. **Cônjuge como vínculo (2026-11-22):** o campo Cônjuge busca entre os membros (vínculo nos dois lados; o outro passa a casado se não estiver) ou usa só o nome, quando o cônjuge não é membro; "Desvincular" tira o vínculo e deixa o nome. Os casais já cadastrados são ligados pela tela **"Revisar cônjuges"** (Membros, só Secretaria/Administrador): confiança alta em lote, média e baixa um a um (vincular escolhendo o endereço, "não é este", buscar outro membro), e quem não tem sugestão (buscar membro ou "não é membro"). Regras em [docs/PESSOAS_E_FAMILIA.md](docs/PESSOAS_E_FAMILIA.md).
- **Pedido de oração:** o Usuário poder registrar depende do cadastro de pedidos de oração, que ainda não existe na API (FEAT-9 no TASKS).

### Igreja em uso (seletor da barra superior)

As telas de **Membros** e **Pedidos de Oração** já seguem a igreja escolhida. O seletor indica a **igreja em uso** (onde entram os registros novos, qual igreja o "marcar todos no vaso" atinge), por isso não tem a opção "todas" (decidido em 2026-11-21). Nas listas, quem alcança mais de uma igreja tem o botão **"Todas as igrejas"**: mostra as igrejas do alcance juntas, com a coluna Igreja; trocar o seletor volta para a igreja escolhida. Nos pedidos, com ele ligado não há "marcar todos no vaso" (é por igreja).

- **Painel inicial (layout de 2026-11-20):** cards de Membros, Crianças e Pedido de Oração com o número de cada área (membros ativos, crianças cadastradas, pedidos novos); painel **Aniversariantes** (de hoje, com a idade, e dos próximos 7 dias; membros e crianças) ao lado dos **Últimos Registros**; faixa "Juntos na missão" no fim. **Dados reais desde 2026-11-22** (FEAT-6), da igreja escolhida no seletor, buscados cada vez que a tela abre: membros ativos; crianças = membros ativos de até 10 anos (provisório, até o cadastro de crianças); pedidos de oração novos (quem só consulta: só os seus); aniversariantes ativos de hoje e dos próximos 7 dias (idade só para Secretaria/Administrador; até 10 anos aparece como "criança"); últimos 5 registros (membros cadastrados e pedidos de oração).

### Grupos futuros

- **Tesouraria** (`ROLE_FINANCEIRO`): entra junto com o módulo **Financeiro**.
- **Pastoral** (`ROLE_PASTORAL`): entra junto com o módulo **Pastoral**.
- **Líder de ministério:** vê só os membros do próprio ministério. Definir junto com a **tela de Ministérios**.

---

## Ministérios

Hoje (banco local): 10 ministérios, todos da Sede, cada um com o **tipo** ("Ministério de Jovens") e o **nome próprio** ("Filhos da Promessa"), líder e vice-líder; 169 participações de membros.

- **Etapa 1 (feita, 2026-11-22):** tela Secretaria > Ministérios: lista da igreja escolhida (tipo, nome, líder, vice-líder, número de membros); cadastrar e editar (tipo, nome, igreja, líder e vice-líder buscados entre os membros; líder e vice entram como membros do ministério); **desativar em vez de excluir** (some do formulário do membro; reativar volta); ver os membros do ministério, incluir e tirar. Secretaria/Administrador alteram; quem só consulta vê.
- **Etapa 2:** perfil **Líder de ministério** (vê só os membros do próprio ministério; FEAT-8).
- **A decidir:** Ministério Infantil (0–10) e Avivah (11–17): os membros entram **automaticamente pela idade** ou são marcados à mão? (ver [docs/PESSOAS_E_FAMILIA.md](docs/PESSOAS_E_FAMILIA.md)).
- **Depois:** funções ministeriais (27 cadastradas, só 5 em uso).

## Relatórios & Documentos

### Pedidos de oração para o vaso de oração

**Feito (2026-11-20):** tela "Pedido de Oração" (Secretaria → Pedido de Oração) e API (`/api/v1/prayer-requests`).

Regras decididas:
- **Origem:** a equipe registra pelo desktop; a **comunidade** vai enviar pelo **app mobile futuro**, sem login (qualquer pessoa pode pedir; a igreja é opcional). Pedido **sem igreja** fica com a **Sede**.
- **Situações:** Novo → **No vaso** (fim do ciclo). Pedido que não condiz com a proposta (ofensas, propaganda) → **Rejeitado** (motivo opcional) → pode ser **excluído** da lista: nada é apagado, só o administrador vê os excluídos e pode restaurar.
- **Secretaria:** no Novo, marca no vaso (um, vários, a página toda ou **todos os novos**), rejeita e edita (só os que a própria igreja registrou); no Rejeitado, exclui. **Depois do vaso, nada.**
- **Administrador:** o mesmo, e ainda: no vaso, rejeitar ou **voltar para novo**; rejeitado, voltar para novo; excluído, restaurar; edita qualquer pedido registrado pela equipe.
- **Pedidos da comunidade não são editados** (as palavras são de quem pediu); só vão para o vaso ou são rejeitados.
- **Usuário de consulta:** registra e vê só os que ele registrou.
- As ações de cada pedido vêm da API (`actions`): as regras ficam num lugar só e o app só mostra os botões permitidos.

**A fazer:**
- **"Marcar no vaso" deve imprimir:** ao marcar (selecionados ou todos), gerar a impressão dos pedidos para o vaso de oração (por igreja, respeitando a igreja em uso). Depende dos relatórios (FEAT-5 no TASKS); hoje a marcação é só de situação e a impressão é feita por fora.
- **App mobile da comunidade:** usar o envio público (`POST /api/v1/public/prayer-requests` e `GET /api/v1/public/churches`). Já existe, mas **desligado** (`echurch.public-prayer-requests.enabled=false`; ligado só no perfil dev). Antes de ligar em produção, avaliar proteção extra contra spam (captcha ou verificação no app), além do limite de 5 envios por IP a cada 15 minutos.
- Painel inicial: o card "Pedidos de Oração" e os "Últimos Registros" com os dados reais (FEAT-6).
- Limpar os 1.817 registros antigos do site (spam) quando não precisar mais deles para testar o layout.

---

## Autenticação

### Recuperação de senha por e-mail

**Status:** na geladeira (decidido em 2026-11-19). Por enquanto, o administrador redefine a senha pela tela de usuários.

**Hoje:** o botão "Esqueceu a senha?" da tela de login orienta a falar com o administrador da igreja. Ele gera uma senha provisória na tela de usuários, e o usuário cadastra uma nova senha no primeiro acesso.

**Objetivo:** o próprio usuário redefinir a senha, sem depender do administrador.

**Fluxo proposto:**
1. Na tela de login, o usuário informa o login ou o e-mail.
2. O backend envia um link ou código de uso único para o e-mail cadastrado.
3. O usuário informa o código e cadastra a nova senha, com a mesma regra de força da troca de senha.

**Backend (e-Church):**
- Configurar envio de e-mail (SMTP), com credenciais por variável de ambiente.
- Criar tabela de tokens de redefinição: hash do token, usuário, expiração curta (ex.: 30 min) e uso único.
- `POST /api/v1/auth/password-reset/request`: sempre responde 200, exista ou não o usuário (sem enumeração de usuários). Com limite de tentativas por IP e por login.
- `POST /api/v1/auth/password-reset/confirm`: valida o token, aplica a `PasswordPolicy` e revoga todas as sessões do usuário.

**App (eChurchDesktop):**
- Tela "Esqueceu a senha?" com o pedido do código.
- Tela de nova senha, reaproveitando a checagem de regras da tela de primeiro acesso.

**Pré-requisito:** usuários com e-mail cadastrado e verificado.
