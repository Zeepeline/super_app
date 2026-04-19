# Flutter Clean Architecture — AI Development Rules

> Dokumen ini adalah panduan wajib bagi AI dalam mengembangkan aplikasi Flutter menggunakan prinsip Clean Architecture. Semua kode yang dihasilkan harus mengikuti aturan berikut secara konsisten.

---

## 1. Struktur Direktori

Gunakan struktur berikut secara ketat:

```
lib/
├── core/
│   ├── error/
│   │   ├── exceptions.dart
│   │   └── failures.dart
│   ├── network/
│   │   └── network_info.dart
│   ├── usecases/
│   │   └── usecase.dart
│   └── utils/
│       └── constants.dart
│
├── features/
│   └── [feature_name]/
│       ├── data/
│       │   ├── datasources/
│       │   │   ├── [feature]_local_datasource.dart
│       │   │   └── [feature]_remote_datasource.dart
│       │   ├── models/
│       │   │   └── [feature]_model.dart
│       │   └── repositories/
│       │       └── [feature]_repository_impl.dart
│       │
│       ├── domain/
│       │   ├── entities/
│       │   │   └── [feature]_entity.dart
│       │   ├── repositories/
│       │   │   └── [feature]_repository.dart
│       │   └── usecases/
│       │       └── get_[feature].dart
│       │
│       └── presentation/
│           ├── bloc/
│           │   ├── [feature]_bloc.dart
│           │   ├── [feature]_event.dart
│           │   └── [feature]_state.dart
│           ├── pages/
│           │   └── [feature]_page.dart
│           └── widgets/
│               └── [feature]_widget.dart
│
├── injection_container.dart
└── main.dart
```

---

## 2. Aturan Layer

### 2.1 Domain Layer (Inti Bisnis)

- **Wajib bebas dari Flutter framework** — tidak ada import `package:flutter/*` kecuali `foundation.dart`.
- Berisi: `Entity`, `Repository (abstract)`, `UseCase`.
- Entity hanya memiliki properti murni, **tidak ada method konversi JSON**.
- UseCase mengimplementasikan interface `UseCase<Type, Params>` dari `core/usecases/usecase.dart`.
- Semua return type UseCase menggunakan `Either<Failure, T>` dari package `dartz`.

```dart
// Contoh UseCase
class GetUser implements UseCase<UserEntity, Params> {
  final UserRepository repository;
  GetUser(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(Params params) async {
    return await repository.getUser(params.id);
  }
}

class Params extends Equatable {
  final String id;
  const Params({required this.id});

  @override
  List<Object> get props => [id];
}
```

### 2.2 Data Layer

- Berisi: `Model`, `DataSource (abstract + impl)`, `Repository Impl`.
- `Model` adalah turunan dari `Entity` dengan tambahan method `fromJson` dan `toJson`.
- `RemoteDataSource` melempar `ServerException` saat error.
- `LocalDataSource` melempar `CacheException` saat error.
- `RepositoryImpl` menangkap exception dan mengkonversi ke `Failure` menggunakan `Either`.

```dart
// Contoh Model
class UserModel extends UserEntity {
  const UserModel({required super.id, required super.name});

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      UserModel(id: json['id'], name: json['name']);

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}
```

### 2.3 Presentation Layer

- Berisi: `Bloc/Cubit`, `Page`, `Widget`.
- Gunakan **flutter_bloc** sebagai state management.
- `Page` hanya boleh berisi logika navigasi dan memanggil Bloc.
- `Widget` harus stateless jika memungkinkan.
- Tidak ada logic bisnis di dalam widget — semua lewat Bloc/Event.

---

## 3. State Management (flutter_bloc)

- Gunakan **Bloc** untuk fitur dengan banyak event kompleks, **Cubit** untuk fitur sederhana.
- State harus bersifat immutable menggunakan `Equatable`.
- Setiap fitur memiliki minimal 3 state: `Initial`, `Loading`, `Loaded`, `Error`.

```dart
// Contoh State
abstract class UserState extends Equatable {
  const UserState();
  @override
  List<Object> get props => [];
}

class UserInitial extends UserState {}
class UserLoading extends UserState {}
class UserLoaded extends UserState {
  final UserEntity user;
  const UserLoaded(this.user);
  @override
  List<Object> get props => [user];
}
class UserError extends UserState {
  final String message;
  const UserError(this.message);
  @override
  List<Object> get props => [message];
}
```

---

## 4. Dependency Injection

- Gunakan package **get_it** + **injectable** untuk DI.
- Semua registrasi dipusatkan di `injection_container.dart`.
- Urutkan registrasi: External → DataSource → Repository → UseCase → Bloc.

```dart
// injection_container.dart
final sl = GetIt.instance;

Future<void> init() async {
  // Bloc
  sl.registerFactory(() => UserBloc(getUser: sl()));

  // UseCases
  sl.registerLazySingleton(() => GetUser(sl()));

  // Repositories
  sl.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(remoteDataSource: sl(), localDataSource: sl()),
  );

  // DataSources
  sl.registerLazySingleton<UserRemoteDataSource>(
    () => UserRemoteDataSourceImpl(client: sl()),
  );

  // External
  sl.registerLazySingleton(() => http.Client());
}
```

---

## 5. Error Handling

- Selalu gunakan `Either<Failure, T>` dari `dartz` untuk semua return Repository dan UseCase.
- Definisikan semua custom `Failure` di `core/error/failures.dart`.
- Definisikan semua custom `Exception` di `core/error/exceptions.dart`.
- **Jangan gunakan `try-catch` di UseCase atau Presentation layer** — hanya di Repository dan DataSource.

```dart
// failures.dart
abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
  @override
  List<Object> get props => [message];
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
  @override
  List<Object> get props => [message];
}
```

---

## 6. Naming Convention

| Komponen        | Konvensi             | Contoh                 |
| --------------- | -------------------- | ---------------------- |
| File            | `snake_case`         | `user_repository.dart` |
| Class           | `PascalCase`         | `UserRepositoryImpl`   |
| Variable/Method | `camelCase`          | `getUserById`          |
| Constant        | `kCamelCase`         | `kBaseUrl`             |
| Folder/Feature  | `snake_case`         | `user_profile/`        |
| Event Bloc      | `PascalCase + Event` | `FetchUserEvent`       |
| State Bloc      | `PascalCase + State` | `UserLoadedState`      |

---

## 7. Package Wajib

```yaml
dependencies:
  flutter_bloc: ^8.x.x # State management
  get_it: ^7.x.x # Service locator
  injectable: ^2.x.x # DI code generation
  dartz: ^0.10.x # Functional programming (Either)
  equatable: ^2.x.x # Value equality
  dio: ^5.x.x # HTTP client
  shared_preferences: ^2.x.x # Local storage
  freezed_annotation: ^2.x.x # Immutable models (opsional)

dev_dependencies:
  injectable_generator: ^2.x.x
  build_runner: ^2.x.x
  freezed: ^2.x.x
  mocktail: ^1.x.x # Mocking untuk testing
```

---

## 8. Aturan Testing

- Setiap layer **wajib memiliki unit test**.
- Gunakan **mocktail** untuk mocking dependency.
- Test file mengikuti struktur `test/features/[feature]/[layer]/`.
- Minimal coverage: Domain 100%, Data 80%, Presentation 70%.

```
test/
└── features/
    └── user/
        ├── domain/
        │   └── usecases/
        │       └── get_user_test.dart
        ├── data/
        │   ├── datasources/
        │   └── repositories/
        └── presentation/
            └── bloc/
                └── user_bloc_test.dart
```

---

## 9. Aturan Tambahan (General)

1. **Tidak boleh ada logic bisnis di Widget atau Page** — semua harus melalui Bloc/UseCase.
2. **Tidak boleh memanggil API langsung dari Bloc** — wajib melalui UseCase → Repository → DataSource.
3. **Setiap class wajib memiliki satu tanggung jawab** (Single Responsibility Principle).
4. **Dependency hanya boleh mengarah ke dalam** — Presentation → Domain ← Data.
5. **Gunakan `const` constructor** sebanyak mungkin untuk performa.
6. **Hindari `dynamic` type** — selalu gunakan type yang eksplisit.
7. **Widget kompleks dipecah** menjadi widget kecil yang reusable di folder `widgets/`.
8. **Navigasi** dikelola di level Page, bukan di dalam widget anak.
9. **Hardcoded string dilarang** — gunakan constants atau localization.
10. **Setiap PR/commit wajib lolos semua unit test** sebelum merge.

---

## 10. Contoh Alur Lengkap

```
User tap tombol → Page dispatch Event →
Bloc handle Event → call UseCase →
UseCase call Repository (abstract) →
RepositoryImpl call RemoteDataSource →
RemoteDataSource fetch API →
Return Either<Failure, Model> →
RepositoryImpl map ke Entity →
UseCase return Either<Failure, Entity> →
Bloc emit State →
Page rebuild via BlocBuilder
```

---

_Rules ini bersifat wajib dan tidak boleh dilangkahi tanpa alasan yang kuat dan terdokumentasi._
