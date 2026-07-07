part of 'profile_cubit.dart';

class ProfileState extends Equatable {
  final ActionStatus profileInfoStatus;
  final String profileInfoError;
  final ProfileModel? profileModel;
  final ActionStatus updateProfileStatus;
  final String updateProfileError;
  final ActionStatus ticketStatus;
  final String ticketError;
  final List<ConfirmedTicketsModel> confirmedTicketsModel;

  const ProfileState(
      {this.profileInfoStatus = ActionStatus.isInitial,
      this.profileInfoError = '',
      this.updateProfileStatus = ActionStatus.isInitial,
      this.updateProfileError = '',
      this.profileModel,
      this.confirmedTicketsModel = const [],
      this.ticketError = '',
      this.ticketStatus = ActionStatus.isInitial});

  ProfileState copyWith(
      {ActionStatus? profileInfoStatus,
      String? profileInfoError,
      ProfileModel? profileModel,
      ActionStatus? updateProfileStatus,
      String? updateProfileError,
      List<ConfirmedTicketsModel>? confirmedTicketsModel,
      String? ticketError,
      ActionStatus? ticketStatus}) {
    return ProfileState(
        updateProfileError: updateProfileError ?? this.updateProfileError,
        updateProfileStatus: updateProfileStatus ?? this.updateProfileStatus,
        profileInfoError: profileInfoError ?? this.profileInfoError,
        profileInfoStatus: profileInfoStatus ?? this.profileInfoStatus,
        profileModel: profileModel ?? this.profileModel,
        confirmedTicketsModel:
            confirmedTicketsModel ?? this.confirmedTicketsModel,
        ticketError: ticketError ?? this.ticketError,
        ticketStatus: ticketStatus ?? this.ticketStatus);
  }

  @override
  List<Object?> get props => [
        profileModel,
        profileInfoStatus,
        profileInfoError,
        updateProfileStatus,
        updateProfileError,
        ticketStatus,
        ticketError,
        confirmedTicketsModel
      ];
}
