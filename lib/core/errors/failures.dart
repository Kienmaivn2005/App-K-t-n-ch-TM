/// Định nghĩa các loại lỗi (Failures) trong hệ thống Clean Architecture
abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;
}

class ScheduleFailure extends Failure {
  const ScheduleFailure(super.message);
}

class PrerequisiteFailure extends Failure {
  final List<String> missingPrerequisites;
  const PrerequisiteFailure(super.message, {this.missingPrerequisites = const []});
}

class StorageFailure extends Failure {
  const StorageFailure(super.message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

