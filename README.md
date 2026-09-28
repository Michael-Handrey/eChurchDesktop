# ⛪ eChurch Desktop - Arquitetura e Stack

Este documento define as diretrizes tecnológicas, arquiteturais e a estrutura de pastas do projeto de gestão de igreja (Desktop).

## 🛠 Tech Stack

* **Framework:** Flutter 3.47.5

* **Linguagem:** Dart 3.13.1 (Restrição SDK: `>=3.13.1 <4.0.0`)

* **Arquitetura:** MVVM (Model-View-ViewModel) + Repository Pattern

* **Gerenciamento de Estado (UI):** `ChangeNotifier` e `ValueNotifier`

* **Injeção de Dependências (DI):** `provider` (Injeção via construtor, sem Service Locators globais)

* **Roteamento e Navegação:** `go_router` (com suporte a Route Guards reativos para proteção de rotas)

* **Requisições HTTP:** `dio`

* **Modelagem de Dados:** `json_serializable` (Serialização seguras)

* **Design System (UI):** `material_ui` (Pacote desacoplado do Flutter core para componentes visuais e temas Material).

## 📐 Princípios de Clean Code (UI)

1. **Proibido retornar Widgets em métodos:** Não utilizar métodos como `Widget _buildHeader()`.

2. **Componentização estrita:** Toda parte reutilizável ou com estado independente da interface deve ser extraída para uma classe própria (ex: estendendo `StatelessWidget` ou `StatefulWidget`).

3. **Uso de `const`:** Maximizar o uso de construtores constantes para otimizar a árvore de renderização do Flutter.

4. **Responsabilidades:** A `View` apenas exibe o estado e capta ações. A regra de negócio da tela e o controle de estado residem no `ViewModel`. O acesso a dados reside no `Repository`.

## 📂 Estrutura de Pastas (Feature-First)

A organização segue o padrão Feature-First acoplado ao MVVM, mantendo o código modular e escalável.

```
lib/
│
├── main.dart                       # Ponto de entrada da aplicação
│
├── app/                            # Configurações centrais do app
│   ├── app.dart                    # MaterialApp e configuração de Providers raiz
│   ├── router/
│   │   └── app_router.dart         # Configuração do go_router e guards de autenticação
│   └── dependencies/
│       └── app_dependencies.dart   # Central de injeção base (Providers globais)
│
├── core/                           # Recursos compartilhados entre todas as features
│   ├── theme/                      # Configurações do material_ui, cores e tipografia
│   ├── network/                    # Configurações do Dio, interceptors e tratamento de erro
│   ├── utils/                      # Helpers, formatadores (CPF, data, telefone) e extensões
│   └── widgets/                    # Componentes de UI globais (Inputs, botões, modais padronizados)
│
├── data/                           # Camada de Dados Global
│   ├── repositories/               # Implementação dos repositórios globais
│   └── services/                   # Clientes de API, WebSockets e persistência local
│
├── domain/                         # Camada de Domínio Global
│   └── models/                     # Entidades base geradas pelo freezed/json_serializable
│
└── features/                       # Módulos de negócio da aplicação
    │
    ├── auth/                       # Autenticação e controle de sessão
    │   ├── presentation/
    │   │   ├── viewmodels/         # AuthViewModel
    │   │   ├── views/              # LoginView
    │   │   └── widgets/
    │   └── data/                   # (Opcional) Repositórios específicos desta feature
    │
    ├── dashboard/                  # Tela principal (Menu lateral + Conteúdo)
    │   └── presentation/
    │       ├── viewmodels/         # DashboardViewModel
    │       ├── views/              # DashboardMainLayout, DashboardOverviewView
    │       └── widgets/            # AppSidebarWidget, TopHeaderWidget, StatisticCardWidget
    │
    ├── members/                    # Gestão de Membros
    │   └── presentation/
    │       ├── viewmodels/         # MembersListViewModel, MemberFormViewModel
    │       ├── views/              # MembersListView, MemberFormView
    │       └── widgets/            # MemberDataTableWidget, MemberFilterWidget
    │
    ├── children/                   # Gestão de Crianças
    │   └── presentation/
    │       ├── viewmodels/
    │       ├── views/
    │       └── widgets/
    │
    └── prayer_requests/            # Gestão de Pedidos de Oração
        └── presentation/
            ├── viewmodels/
            ├── views/
            └── widgets/

```