import 'package:chanhung/data/model/dept_daily_work/dept_daily_work_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DepartmentResponseModel', () {
    test('unwraps API envelope and parses backend title field', () {
      final response = DepartmentResponseModel.fromJson({
        'success': true,
        'data': {
          'success': true,
          'data': [
            {'id': 1, 'title': 'Kỹ thuật'},
          ],
        },
        'meta': {'version': '1.0'},
      });

      expect(response.data, hasLength(1));
      expect(response.data!.single.id, '1');
      expect(response.data!.single.name, 'Kỹ thuật');
    });

    test('parses object data without Map.forEach callback type errors', () {
      final response = DepartmentResponseModel.fromJson({
        'success': true,
        'data': {
          '4': {'id': 4, 'title': 'Kinh doanh'},
          '7': {'id': 7, 'title': 'Nhân sự'},
        },
      });

      expect(response.data, hasLength(2));
      expect(response.data!.map((item) => item.id), ['4', '7']);
    });
  });

  test('DeptDailyWorkResponseModel unwraps API envelope with task list', () {
    final response = DeptDailyWorkResponseModel.fromJson({
      'success': true,
      'data': {
        'success': true,
        'department_id': 4,
        'is_manager': true,
        'data': [
          {'id': 12, 'title': 'Kiểm tra hồ sơ'},
          {'id': 13, 'title': 'Duyệt tiến độ'},
        ],
      },
      'meta': {'version': '1.0'},
    });

    expect(response.departmentId, 4);
    expect(response.isManager, isTrue);
    expect(response.data, hasLength(2));
    expect(response.data!.first.id, '12');
    expect(response.data!.first.title, 'Kiểm tra hồ sơ');
  });
}
