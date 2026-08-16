import 'package:chanhung/core/helper/api_parser.dart';
import 'package:chanhung/data/model/project/project_model.dart';

class ProjectDashboardModel {
  bool success = false;
  ProjectDashboardData? data;

  ProjectDashboardModel();

  ProjectDashboardModel.fromJson(dynamic json) {
    success = ApiParser.asBool(json['success']);
    final map = ApiParser.asObject(json);
    data = map != null ? ProjectDashboardData.fromJson(map) : null;
  }
}

class ProjectDashboardData {
  int total = 0;
  int open = 0;
  int completed = 0;
  int hold = 0;
  int other = 0;
  double totalPrice = 0;
  double totalSettled = 0;
  double totalRemaining = 0;
  double paymentProgress = 0;
  int overdue = 0;
  ActionCenter? actionCenter;
  PartyFinance? partyFinance;
  List<Project> recentProjects = const [];

  ProjectDashboardData();

  ProjectDashboardData.fromJson(Map<String, dynamic> json) {
    total = ApiParser.asInt(json['total']);
    open = ApiParser.asInt(json['open']);
    completed = ApiParser.asInt(json['completed']);
    hold = ApiParser.asInt(json['hold']);
    other = ApiParser.asInt(json['other']);
    totalPrice = ApiParser.asDouble(json['total_price']);
    totalSettled = ApiParser.asDouble(json['total_settled']);
    totalRemaining = ApiParser.asDouble(json['total_remaining']);
    paymentProgress = ApiParser.asDouble(json['payment_progress']);
    overdue = ApiParser.asInt(json['overdue']);
    actionCenter = json['action_center'] is Map
        ? ActionCenter.fromJson(json['action_center'])
        : ActionCenter();
    partyFinance = json['party_finance'] is Map
        ? PartyFinance.fromJson(json['party_finance'])
        : PartyFinance();
    recentProjects = [];
    if (json['recent_projects'] is List) {
      for (final item in json['recent_projects']) {
        recentProjects.add(Project.fromJson(item));
      }
    }
  }
}

class ActionCenter {
  int todayTasks = 0;
  int overdueTasks = 0;
  int upcomingTasks = 0;
  int pendingSettlements = 0;
  int openHse = 0;
  int openRfi = 0;

  ActionCenter();

  ActionCenter.fromJson(dynamic json) {
    todayTasks = ApiParser.asInt(json['today_tasks']);
    overdueTasks = ApiParser.asInt(json['overdue_tasks']);
    upcomingTasks = ApiParser.asInt(json['upcoming_tasks']);
    pendingSettlements = ApiParser.asInt(json['pending_settlements']);
    openHse = ApiParser.asInt(json['open_hse']);
    openRfi = ApiParser.asInt(json['open_rfi']);
  }
}

class PartyAmounts {
  double contract = 0;
  double performed = 0;
  double accepted = 0;
  double requested = 0;
  double actual = 0;
  double debt = 0;

  PartyAmounts();

  PartyAmounts.fromJson(dynamic json) {
    contract = ApiParser.asDouble(json['contract']);
    performed = ApiParser.asDouble(json['performed']);
    accepted = ApiParser.asDouble(json['accepted']);
    requested = ApiParser.asDouble(json['requested']);
    actual = ApiParser.asDouble(json['actual']);
    debt = ApiParser.asDouble(json['debt']);
  }
}

class PartyFinance {
  PartyAmounts investor = PartyAmounts();
  PartyAmounts contractor = PartyAmounts();
  PartyAmounts supplier = PartyAmounts();

  PartyFinance();

  PartyFinance.fromJson(dynamic json) {
    investor = json['investor'] is Map
        ? PartyAmounts.fromJson(json['investor'])
        : PartyAmounts();
    contractor = json['contractor'] is Map
        ? PartyAmounts.fromJson(json['contractor'])
        : PartyAmounts();
    supplier = json['supplier'] is Map
        ? PartyAmounts.fromJson(json['supplier'])
        : PartyAmounts();
  }
}

class ProjectCounts {
  int files = 0;
  int comments = 0;
  int invoices = 0;
  int contracts = 0;
  int settlements = 0;
  int hse = 0;
  int rfi = 0;
  int diary = 0;

  ProjectCounts();

  ProjectCounts.fromJson(dynamic json) {
    files = ApiParser.asInt(json['files']);
    comments = ApiParser.asInt(json['comments']);
    invoices = ApiParser.asInt(json['invoices']);
    contracts = ApiParser.asInt(json['contracts']);
    settlements = ApiParser.asInt(json['settlements']);
    hse = ApiParser.asInt(json['hse']);
    rfi = ApiParser.asInt(json['rfi']);
    diary = ApiParser.asInt(json['diary']);
  }
}

class ProjectTaskStats {
  int total = 0;
  int todo = 0;
  int doing = 0;
  int done = 0;
  int overdue = 0;
  int urgent = 0;

  ProjectTaskStats();

  ProjectTaskStats.fromJson(dynamic json) {
    total = ApiParser.asInt(json['total']);
    todo = ApiParser.asInt(json['todo']);
    doing = ApiParser.asInt(json['doing']);
    done = ApiParser.asInt(json['done']);
    overdue = ApiParser.asInt(json['overdue']);
    urgent = ApiParser.asInt(json['urgent']);
  }
}
