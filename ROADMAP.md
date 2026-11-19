# eChurch Desktop — Roadmap

Funcionalidades planejadas e ainda não iniciadas. Para tarefas técnicas do backend, ver `TASKS.md` no projeto e-Church.

**Última atualização:** 2026-11-18

---

## Autenticação

### Recuperação de senha por e-mail

**Hoje:** o botão "Esqueceu a senha?" da tela de login orienta a falar com o administrador da igreja. Ele gera uma senha provisória, e o usuário cadastra uma nova senha no primeiro acesso.

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
