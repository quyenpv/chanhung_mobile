import 'package:chanhung/data/controller/hr/hr_controller.dart';
import 'package:chanhung/data/model/hr/employee_model.dart';
import 'package:chanhung/data/model/hr/hr_dashboard_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses employee IDs returned with HR dashboard metrics', () {
    final model = HrDashboardModel.fromJson({
      'data': {
        'metrics': {
          'employee_ids': {
            'new_this_month': [2],
            'present_today': [1, 3],
            'on_leave_today': [3],
          },
        },
      },
    });

    expect(model.metrics!.newEmployeeIds, {'2'});
    expect(model.metrics!.presentTodayIds, {'1', '3'});
    expect(model.metrics!.onLeaveTodayIds, {'3'});
  });

  test('filters employees by the selected HR metric IDs', () {
    final employees = [
      Employee(id: '1', firstName: 'An'),
      Employee(id: '2', firstName: 'Binh'),
      Employee(id: '3', firstName: 'Chi'),
    ];
    final metrics = HrMetrics()
      ..newEmployeeIds = {'2'}
      ..presentTodayIds = {'1', '3'}
      ..onLeaveTodayIds = {'3'};

    expect(
      filterEmployeesByMetric(
        employees,
        HrEmployeeFilter.presentToday,
        metrics,
      ).map((employee) => employee.id),
      ['1', '3'],
    );
    expect(
      filterEmployeesByMetric(
        employees,
        HrEmployeeFilter.onLeaveToday,
        metrics,
      ).map((employee) => employee.id),
      ['3'],
    );
    expect(
      filterEmployeesByMetric(employees, HrEmployeeFilter.all, metrics),
      employees,
    );
  });
}
