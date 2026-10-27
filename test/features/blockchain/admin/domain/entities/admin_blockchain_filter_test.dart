import 'package:flutter_test/flutter_test.dart';
import 'package:watad/features/blockchain/admin/domain/entities/admin_blockchain_filter.dart';

import '../../../../../helpers/fake_admin_blockchain_repository.dart';

void main() {
  test('each chip shows its state, «الكل» every project', () {
    final [synced, failed] = fakeAdminBlockchainProjects;

    expect(AdminBlockchainFilter.all.matches(synced), isTrue);
    expect(AdminBlockchainFilter.all.matches(failed), isTrue);
    expect(AdminBlockchainFilter.failed.matches(failed), isTrue);
    expect(AdminBlockchainFilter.failed.matches(synced), isFalse);
    expect(AdminBlockchainFilter.synced.matches(synced), isTrue);
    expect(AdminBlockchainFilter.waiting.matches(synced), isFalse);
    expect(AdminBlockchainFilter.retrying.matches(failed), isFalse);
  });
}
