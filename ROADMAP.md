# eChurch Desktop — Roadmap

Funcionalidades planejadas e ainda não iniciadas. Para tarefas técnicas do backend, ver `TASKS.md` no projeto e-Church.

**Última atualização:** 2026-11-21

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

### Regras de acesso (decidido em 2026-11-21)

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

**Ninguém exclui membros, nem o Administrador.** Desativa-se com um **motivo** (saiu da igreja, transferido para outra igreja, mudou de cidade, falecimento, cadastro duplicado, outro) e uma **descrição obrigatória**; o sistema grava quem desativou e quando. Reativar volta o membro para ativo (a justificativa anterior fica no log de auditoria). Já vale na API; a tela de membros terá os botões "Desativar" e "Reativar".

**Acesso por igreja: "sede supervisiona".** O alcance depende da igreja **e** da permissão:

| Quem | Alcança |
|---|---|
| Administrador | Todas as igrejas |
| **Secretaria da sede** | A sede e as filiais |
| Secretaria de filial | Só a própria filial |
| Usuário (só consulta), da sede ou de filial | Só a própria igreja |

O que pode fazer em cada igreja alcançada vem dos grupos (ex.: secretaria da sede edita membros de qualquer filial).

- **Feito na API (2026-11-21):** a regra vale para a lista de igrejas, o seletor da barra superior e os endpoints de **membros e apelos** (ler e alterar). As permissões por grupo também já valem na API: só Secretaria/Administrador alteram, só o Administrador exclui, e quem só consulta recebe o membro com os dados reduzidos da tabela acima (SEC-12b e SEC-13 no TASKS do backend).
- **A fazer na tela de membros:** o app esconder ou desabilitar o que cada um não pode fazer, e mostrar os membros da igreja escolhida no seletor.
- **Pedido de oração:** o Usuário poder registrar depende do cadastro de pedidos de oração, que ainda não existe na API (FEAT-9 no TASKS).

### Igreja em uso (seletor da barra superior)

Hoje a troca ainda não muda nenhum dado na tela, porque nenhuma tela lista dados por igreja.

- **Membros:** a tela vai mostrar os membros da igreja escolhida no seletor.
- **Painel inicial:** os números e atividades do dashboard (hoje fixos) vão carregar os dados da igreja escolhida.

### Grupos futuros

- **Tesouraria** (`ROLE_FINANCEIRO`): entra junto com o módulo **Financeiro**.
- **Pastoral** (`ROLE_PASTORAL`): entra junto com o módulo **Pastoral**.
- **Líder de ministério:** vê só os membros do próprio ministério. Definir junto com a **tela de Ministérios**.

---

## Relatórios & Documentos

### Pedidos de oração para o vaso de oração

A secretaria gerencia os pedidos de oração e os imprime para colocar no vaso de oração. Criar o relatório de impressão dos pedidos (por período e por igreja, respeitando a igreja em uso).

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
