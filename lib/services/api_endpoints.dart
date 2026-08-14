class ApiEndpoints {

  static const String baseUrl = "http://110.225.251.71:9009";

// =========================
// Authentication
// =========================

  static const String login =
      "$baseUrl/api/method/geo_attendance.app.mobile_login";

  static const String logout =
      "$baseUrl/api/method/geo_attendance.api.mobile_logout";


// =========================
// Dashboard
// =========================

  static const String dashboard =
      "$baseUrl/api/method/geo_attendance.api.dashboard";

// =========================
// Attendance
// =========================


  static const String checkIn =
      "$baseUrl/api/method/geo_attendance.app.mobile_checkin";

  static const String checkOut =
      "$baseUrl/api/method/geo_attendance.app.mobile_checkin";


  static const String attendanceHistory =
      "$baseUrl/api/method/geo_attendance.app.attendance_history";

  static const String attendanceStatus =
      "$baseUrl/api/method/geo_attendance.app.get_today_attendance_status";

  static const String updateFCMToken =
      "$baseUrl/api/method/geo_attendance.app.update_fcm_token";

  static const String employeeTasks =
      "$baseUrl/api/method/geo_attendance.todo.get_employee_tasks";

  static const String dashboardTasks =
      "$baseUrl/api/method/geo_attendance.todo.get_dashboard_tasks";
  static const String completeEmployeeTask =
      "$baseUrl/api/method/"
      "geo_attendance.todo.complete_employee_task";

  // ============================================================
// EMPLOYEE TASKS
// ============================================================


  static const String taskDetails =
      "$baseUrl/api/method/geo_attendance.todo.get_task_details";

  static const String startEmployeeTask =
      "$baseUrl/api/method/geo_attendance.todo.start_employee_task";

  static const String submitTaskCompletion =
      "$baseUrl/api/method/geo_attendance.todo.submit_task_completion";


// ============================================================
// TASK MANAGER
// ============================================================

  static const String companyEmployees =
      "$baseUrl/api/method/geo_attendance.todo.get_company_employees";

  static const String companyTasks =
      "$baseUrl/api/method/geo_attendance.todo.get_company_tasks";

  static const String createTask =
      "$baseUrl/api/method/geo_attendance.todo.create_task";

  static const String assignTask =
      "$baseUrl/api/method/geo_attendance.todo.assign_task";

  static const String reassignTask =
      "$baseUrl/api/method/geo_attendance.todo.reassign_task";

  static const String pendingReviewTasks =
      "$baseUrl/api/method/geo_attendance.todo.get_pending_review_tasks";

  static const String reviewTask =
      "$baseUrl/api/method/geo_attendance.todo.review_task";
  static const String employeeTodos =
      '$baseUrl/api/method/geo_attendance.todo_api.get_employee_todos';

  static const String dashboardTodos =
      '$baseUrl/api/method/geo_attendance.todo_api.get_dashboard_todos';

  static const String completeEmployeeTodo =
      '$baseUrl/api/method/geo_attendance.todo_api.complete_employee_todo';
  static const String employeeProfile =
      '$baseUrl/api/method/geo_attendance.employee_profile_api.get_employee_profile';
  static const String issueApi =
      "$baseUrl/api/method/geo_attendance.issue_api";

  // ============================================================
  // EMPLOYEE
  // ============================================================

  static const String createIssue =
      "$issueApi.create_issue";

  static const String myIssues =
      "$issueApi.get_my_issues";

  static const String assignedIssues =
      "$issueApi.get_assigned_issues";

  static const String issueDetails =
      "$issueApi.get_issue_details";

  static const String submitIssueResolution =
      "$issueApi.submit_issue_resolution";

  // ============================================================
  // ISSUE MANAGER
  // ============================================================

  static const String companyIssues =
      "$issueApi.get_company_issues";

  static const String assignIssue =
      "$issueApi.assign_issue";

  static const String reassignIssue =
      "$issueApi.reassign_issue";

  static const String updateIssueStatus =
      "$issueApi.update_issue_status";

  // ============================================================
  // LOOKUPS
  // ============================================================


  static const String issueTypes =
      "$issueApi.get_issue_types";

  static const String issueDashboard =
      "$issueApi.get_issue_dashboard";

  static const String submitUnresolvedRemark =
      "$issueApi.submit_unresolved_remark";

  static const String addIssueRemark =
      "$issueApi.add_issue_remark";

  static const String resolveIssue =
      "$issueApi.resolve_issue";

  static const String closeIssue =
      "$issueApi.close_issue";
  static const String issueCompanyEmployees =
      "$issueApi.issue_get_company_employees";


  // =========================
// Attendance
// =========================


  static const String attendanceCalendar =
      "$baseUrl/api/method/geo_attendance.attendance.get_my_attendance_calendar";


//   leaves
  static const String leaveApi =
      "$baseUrl/api/method/geo_attendance.leaves";

  static const String leaveAccess =
      "$leaveApi.get_leave_access";

  static const String myLeaveTypes =
      "$leaveApi.get_my_leave_types";

  static const String myLeaveSummary =
      "$leaveApi.get_my_leave_summary";

  static const String applyLeave =
      "$leaveApi.apply_leave";

  static const String myLeaveApplications =
      "$leaveApi.get_my_leave_applications";

  static const String leaveApplication =
      "$leaveApi.get_leave_application";

  static const String cancelLeaveApplication =
      "$leaveApi.cancel_leave_application";

  static const String pendingLeaveApplications =
      "$leaveApi.get_pending_leave_applications";

  static const String leaveManagementSummary =
      "$leaveApi.get_leave_management_summary";

  static const String leaveApprovalDetails =
      "$leaveApi.get_leave_approval_details";

  static const String approveLeaveApplication =
      "$leaveApi.approve_leave_application";

  static const String rejectLeaveApplication =
      "$leaveApi.reject_leave_application";


//   salary

  static const String payrollApi =
      "$baseUrl/api/method/geo_attendance.payroll";

  static const String mySalarySummary =
      "$payrollApi.get_my_salary_summary";

  static const String mySalarySlips =
      "$payrollApi.get_my_salary_slips";

  static const String mySalarySlip =
      "$payrollApi.get_my_salary_slip";

  static const String downloadMySalarySlip =
      "$payrollApi.download_my_salary_slip";

}