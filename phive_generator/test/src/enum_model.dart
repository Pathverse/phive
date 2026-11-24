import 'package:phive/phive.dart';

@PHiveAutoType()
enum AutoEnum { survey, quiz }

@PHiveType(81)
enum ExplicitEnum {
  @PHiveField(300)
  survey,
  @PHiveField(7)
  quiz,
}

@PHiveType(82)
enum MissingEnum {
  a,
  @PHiveField(0)
  b,
}

@PHiveType(83)
enum DuplicateEnum {
  @PHiveField(1)
  a,
  @PHiveField(1)
  b,
}

@PHiveAutoType(classHooks: [TolerantLayout()])
enum HookedEnum { a }
