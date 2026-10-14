import 'package:watad/core/error/result.dart';
import 'package:watad/features/home/client/domain/entities/client_home_profile.dart';
import 'package:watad/features/home/client/domain/entities/client_suggested_contractor.dart';
import 'package:watad/features/home/client/domain/repositories/client_home_repository.dart';

class FakeClientHomeRepository implements ClientHomeRepository {
  FakeClientHomeRepository({this.profileResult, this.contractorsResult});

  Result<ClientHomeProfile>? profileResult;
  Result<List<ClientSuggestedContractor>>? contractorsResult;

  @override
  Future<Result<ClientHomeProfile>> getClientHomeProfile() {
    return Future.value(
      profileResult ??
          const Success(
            ClientHomeProfile(fullName: 'Test Client', isPhoneVerified: true),
          ),
    );
  }

  @override
  Future<Result<List<ClientSuggestedContractor>>> getSuggestedContractors() {
    return Future.value(
      contractorsResult ??
          const Success([
            ClientSuggestedContractor(
              id: 'contractor-1',
              companyName: 'Solid Construction',
              rating: 4.8,
              completedProjectsCount: 64,
              isVerified: true,
              specializedField: 'General Contracting',
            ),
          ]),
    );
  }
}
