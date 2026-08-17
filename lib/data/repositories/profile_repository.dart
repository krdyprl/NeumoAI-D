import '../../models/profile.dart';

abstract class ProfileRepository {
  Future<Profile> getProfile();
  Future<void> updateProfile(Profile profile);
  Future<Profile?> getProfileById(String id);
  Future<Profile?> getProfileByEmail(String email);
  Future<bool> emailExists(String email);
  Future<void> createAccount(Profile profile, String passwordHash);
  Future<bool> verifyPassword(String email, String passwordHash);
}
