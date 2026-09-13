# Manga Reader (Flutter + MongoDB)

Versão em Flutter do app de leitura de mangás, agora com **login, favoritos,
histórico de leitura e comentários/avaliações**, tudo salvo em um MongoDB
externo.

## O que mudou em relação à versão Android/Kotlin

Esse é um projeto novo, em Flutter/Dart — não reaproveita o código Kotlin
anterior. A busca, lista de capítulos, leitor com anterior/próxima e download
de capítulo continuam existindo, com o mesmo comportamento de antes, mas
reescritos em Dart. Além disso:

- **Login e criação de conta** (usuário/senha, com senha em hash — nunca
  salva em texto puro).
- **Favoritos**: favoritar/desfavoritar um mangá (ícone de coração na tela de
  detalhes), com uma aba dedicada para ver todos.
- **Histórico de leitura**: toda vez que você troca de página, o app salva
  automaticamente em qual capítulo/página você parou. A aba "Histórico"
  lista tudo e te leva direto pra onde parou.
- **Comentários e avaliações**: cada mangá tem uma seção de comentários com
  nota de 1 a 5 estrelas, visível para qualquer usuário logado.

## Por que conectar direto ao MongoDB (e o que isso implica)

O app usa o pacote `mongo_dart` para falar diretamente com o MongoDB usando
usuário, senha e IP fixos no código (veja `lib/services/mongo_service.dart`).
Isso é comum em projetos de faculdade, mas vale entender duas coisas:

1. **Não é a arquitetura recomendada para produção.** O ideal, num app real,
   seria ter uma API/backend no meio (Node.js, Python, etc.) e o app mobile
   nunca teria a senha do banco. Aqui o app fala direto com o banco porque é
   isso que foi pedido — funciona bem para fins de estudo, numa rede
   controlada.
2. **O IP `10.112.4.57` é um endereço de rede privada.** Isso significa que
   o app só vai conseguir conectar quando o celular/emulador estiver na
   **mesma rede local** (ex: wifi do laboratório). Testando de casa, pelo
   dados móveis, ou em qualquer rede fora dessa, toda tela que depende do
   banco (login, favoritos, histórico, comentários) vai mostrar erro de
   conexão — isso é esperado, não é bug do código.

Se a autenticação falhar com algo como "auth failed" mesmo estando na rede
certa, o motivo mais comum é o usuário `aluno` ter sido criado no banco
`admin` em vez do banco `aluno`. Nesse caso, abra
`lib/services/mongo_service.dart` e adicione `?authSource=admin` no fim da
string de conexão:

```dart
final uri = 'mongodb://$_username:$_password@$_host:$_port/$_dbName?authSource=admin';
```

## Como rodar

Este projeto assume que você já tem o **Flutter SDK** instalado
(`flutter --version` funcionando no terminal). Se não tiver, instale pelo
site oficial: https://docs.flutter.dev/get-started/install

1. Crie um novo projeto Flutter vazio (isso gera as pastas nativas
   `android/` e `ios/` corretamente para a sua máquina, que não vêm neste
   zip):
   ```
   flutter create manga_reader
   ```
2. Dentro da pasta gerada, **substitua** o arquivo `pubspec.yaml` e a pasta
   `lib/` inteira pelos deste zip (pode sobrescrever o `lib/main.dart` de
   exemplo sem problema).
3. Baixe as dependências:
   ```
   flutter pub get
   ```
4. Confirme que a permissão de internet está no
   `android/app/src/main/AndroidManifest.xml`, dentro da tag `<manifest>`
   (antes de `<application>`):
   ```xml
   <uses-permission android:name="android.permission.INTERNET" />
   ```
   (o template do `flutter create` já costuma incluir isso, mas vale
   conferir — sem essa linha o app não acessa nem a internet nem o Mongo).
5. Conecte um emulador ou celular na **mesma rede** do MongoDB e rode:
   ```
   flutter run
   ```

## Estrutura do projeto

```
lib/
├── main.dart                    # Ponto de entrada + decide login vs. app
├── theme/app_theme.dart         # Paleta de cores e estilos (claro/escuro)
├── models/                      # Classes que representam os dados
│   ├── manga.dart / chapter.dart        (vêm da API MangaDex)
│   └── favorite.dart / history_entry.dart / comment.dart  (vêm do MongoDB)
├── services/
│   ├── mangadex_api.dart        # Busca, capítulos e páginas (MangaDex)
│   ├── mongo_service.dart       # Conexão única com o MongoDB
│   ├── auth_service.dart        # Registro/login (senha em hash)
│   ├── favorites_service.dart
│   ├── history_service.dart
│   ├── comments_service.dart
│   └── download_service.dart    # Salva páginas no armazenamento do app
├── state/app_state.dart         # Sessão do usuário logado (persistente)
├── widgets/manga_cover.dart     # Capa reutilizável com cache
└── screens/
    ├── login_screen.dart / register_screen.dart
    ├── home_shell.dart          # Navegação por abas
    ├── search_tab.dart / favorites_tab.dart / history_tab.dart / profile_tab.dart
    ├── manga_detail_screen.dart # Capítulos + favoritar + comentários
    └── reader_screen.dart       # Leitura das páginas + download
```

## Coleções criadas no MongoDB

Você não precisa criar nada manualmente — as coleções abaixo são criadas
sozinhas na primeira vez que cada funcionalidade é usada:

| Coleção            | O que guarda                                          |
|--------------------|--------------------------------------------------------|
| `users`            | usuário, salt e hash da senha                          |
| `favorites`        | mangás favoritados por usuário                          |
| `reading_progress` | último capítulo/página lido por usuário e mangá (1 por par) |
| `comments`         | comentários e notas (1 a 5) por mangá                   |

## Limitações conhecidas (de propósito, para manter simples)

- Não há recuperação de senha nem confirmação por e-mail.
- A conexão com o Mongo é reaberta apenas se o app for reiniciado — se a
  rede cair no meio do uso, pode ser necessário fechar e abrir o app de novo.
- Favoritos/histórico/comentários não têm paginação (ok para volume de uso
  de um projeto de estudo).
- O app funciona em Android e iOS, mas **não funciona em Flutter Web** — o
  pacote `mongo_dart` depende de sockets (`dart:io`), que não existem no
  navegador.

## Observação importante

Assim como no projeto Android/Kotlin anterior, este código foi escrito e
revisado com cuidado, mas não foi compilado neste ambiente (o sandbox usado
para gerar os arquivos não tem o Flutter SDK nem acesso ao MongoDB para
testar de verdade). As versões das bibliotecas no `pubspec.yaml` foram
conferidas no pub.dev no momento da escrita. Se `flutter pub get` ou
`flutter run` derem algum erro, me manda a mensagem completa que eu ajusto.
