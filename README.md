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

## 📂 Estrutura de Pastas (por camada → feature)

A organização segue o guia oficial de arquitetura do Flutter (MVVM em camadas `ui/`, `domain/`, `data/`),
conforme definido em `../eChurchWorkspace/FLUTTER_GUIDE.md`. **Leia o guia antes de criar arquivos.**

```
lib/
│
├── main.dart                       # Ponto de entrada: runApp(ApplicationBindings(child: MainApp()))
│
├── config/
│   ├── application_bindings.dart   # MultiProvider global (services, repositórios, notifiers, GoRouter)
│   └── environment.dart            # BASE_URL via --dart-define (a criar)
│
├── core/                           # Infra genérica sem regra de negócio (a criar, copiar do guia)
│   ├── command.dart / result.dart / view_model_initializable.dart
│   ├── auth/auth_session_notifier.dart
│   ├── exceptions/app_exception.dart
│   └── logging/
│
├── data/                           # (a criar) repositórios + services (api retrofit, local storage, mappers)
│
├── domain/
│   ├── models/<grupo>/             # Entidades puras (ex.: dashboard/quick_stat.dart)
│   └── use_cases/                  # Só quando orquestra 2+ repositórios
│
├── routing/
│   ├── routes.dart                 # Constantes de path (Routes.login, Routes.dashboard...)
│   └── router.dart                 # GoRouter com Bindings por rota
│
└── ui/
    ├── core/
    │   ├── theme/                  # app_colors, app_theme, theme.dart (barrel)
    │   └── share/                  # Widgets compartilhados entre features
    ├── main/                       # Shell desktop: MainScreen, sidebar, top_header, MainBindings
    ├── auth/login/                 # LoginBindings, LoginScreen, LoginViewModel, widgets/
    ├── dashboard/                  # DashboardScreen, DashboardViewModel, widgets/
    ├── members/                    # (futuro) list/, detail/, form/
    ├── children/                   # (futuro)
    └── prayer_requests/            # (futuro)
```
