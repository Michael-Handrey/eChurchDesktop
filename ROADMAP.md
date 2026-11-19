# eChurch Desktop — Roadmap

Funcionalidades planejadas e ainda não iniciadas. Para tarefas técnicas do backend, ver `TASKS.md` no projeto e-Church.

**Última atualização:** 2026-11-19

---

## Próximos passos (login)

Pendências que restaram ao fechar o login, em ordem sugerida.

### 1. Validar a janela no app aberto

Os testes automáticos não cobrem o comportamento da janela do Windows. Conferir manualmente:
- splash, login e troca de senha abrem centralizados em 960×640 e não podem ser redimensionados, maximizados (nem por duplo clique na barra de título);
- o painel ocupa a área útil do monitor (sem cobrir a barra de tarefas) e não pode ser redimensionado, maximizado nem arrastado;
- no logout, a janela volta ao tamanho do login, centralizada.

### 2. Redefinição de senha pelo administrador

**Por quê:** o "Esqueceu a senha?" orienta a falar com o administrador, mas hoje não existe como gerar a senha provisória pelo sistema. Nenhum código liga o `first_access` de um usuário: só dá para fazer direto no banco.

**Backend (e-Church):**
- Endpoint restrito a administrador, ex.: `POST /api/v1/users/{id}/reset-password`.
- Gera uma senha provisória aleatória e forte, que já atende à `PasswordPolicy`.
- Devolve a senha uma única vez (não fica guardada em texto em lugar nenhum).
- Liga o `first_access` do usuário e revoga as sessões dele.
- Registra quem redefiniu e quando.

**App (eChurchDesktop):**
- Ação "Redefinir senha" na futura tela de usuários, com diálogo que mostra a senha provisória uma vez e permite copiar.

### 3. Testar a renovação de sessão durante o uso

Coberta pelos testes do interceptor, mas só dá para conferir na prática quando existir a primeira tela que chama a API (ex.: membros). Com `JWT_ACCESS_EXPIRATION_MS=60000` na configuração do VS Code, usar a tela por mais de 1 minuto: a ação seguinte deve funcionar sem deslogar e o log mostrar "Sessão renovada". Remover a variável depois.

### 4. Limpeza da tela de login

A tela de login ainda mostra um carregamento enquanto a sessão é restaurada. Com a splash, esse caso não acontece mais: remover o código e o parâmetro `session` da `LoginScreen`.

### 5. Reajustar a janela quando a tela muda

Limitação conhecida: se a resolução ou a barra de tarefas mudar com o app aberto, a janela do painel não se reajusta sozinha (só no próximo login). Ouvir a mudança de monitor e reaplicar a área útil.

---

## Autenticação

### Recuperação de senha por e-mail

**Hoje:** o botão "Esqueceu a senha?" da tela de login orienta a falar com o administrador da igreja. Ele gera uma senha provisória (por enquanto só pelo banco; ver o item 2 acima), e o usuário cadastra uma nova senha no primeiro acesso.

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
