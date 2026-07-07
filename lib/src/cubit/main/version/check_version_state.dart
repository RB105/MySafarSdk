part of 'check_version_cubit.dart';

abstract class CheckVersionState {}

class CheckVersionInitState extends CheckVersionState {}

class VersionUpdateRequiredState extends CheckVersionState {}

class VersionUpdateOptionalState extends CheckVersionState {}