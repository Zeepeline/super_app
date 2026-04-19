import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/settings_entity.dart';
import '../repositories/settings_repository.dart';

class UpdateAudioQuality implements UseCase<SettingsEntity, AudioQuality> {
  final SettingsRepository repository;

  UpdateAudioQuality(this.repository);

  @override
  Future<Either<Failure, SettingsEntity>> call(AudioQuality quality) async {
    return await repository.updateAudioQuality(quality);
  }
}
