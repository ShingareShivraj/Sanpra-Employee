class ApiEndpoints {

  static const String baseUrl = "https://erp.erpkey.in";

// =========================
// Authentication
// =========================

  static const String login =
      "$baseUrl/api/method/geo_attendance.app.mobile_login";

  static const String logout =
      "$baseUrl/api/method/geo_attendance.api.mobile_logout";

  static const String forgotPassword =
      "$baseUrl/api/method/frappe.core.doctype.user.user.reset_password";



  static const String updatePassword =
      "$baseUrl/api/method/frappe.auth.update_password";


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
  static const String updateEmployeePhoto =
      "$baseUrl/api/method/geo_attendance.employee_profile_api.update_employee_photo";
  static const String issueApi =
      "$baseUrl/api/method/geo_attendance.issue_api";


  static const String companyProjects =
      "$baseUrl/api/method/geo_attendance.todo.get_company_projects";

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


  static const String myShiftInfo =
      "$baseUrl/api/method/geo_attendance.attendance.get_my_shift_info";


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


  //chatting

  static const String chatApi =
      "$baseUrl/api/method/geo_attendance.chat";

  static const String chatAccess =
      "$chatApi.get_chat_access";

  static const String chatEmployees =
      "$chatApi.get_available_employees";

  static const String myChatGroups =
      "$chatApi.get_my_groups";

  static const String chatGroupDetails =
      "$chatApi.get_group_details";

  static const String chatMessages =
      "$chatApi.get_messages";

  static const String sendChatMessage =
      "$chatApi.send_message";

  static const String markChatGroupRead =
      "$chatApi.mark_group_read";

  static const String deleteChatMessage =
      "$chatApi.delete_message";

  static const String createChatGroup =
      "$chatApi.create_group";

  static const String updateChatGroup =
      "$chatApi.update_group";

  static const String addChatMembers =
      "$chatApi.add_members";

  static const String removeChatMember =
      "$chatApi.remove_member";

  static const String updateChatMemberPermission =
      "$chatApi.update_member_permission";

  static const String uploadFile =
      "$baseUrl/api/method/upload_file";

  static const String searchChatGroupMembers =
      "$chatApi.search_group_members";

  static const String chatForwardGroups =
      "$chatApi.get_forward_groups";

  static const String searchChatMessages =
      "$chatApi.search_messages";

  static const String editChatMessage =
      "$chatApi.edit_message";

  static const String forwardChatMessage =
      "$chatApi.forward_message";

  static const String setChatMessageReaction =
      "$chatApi.set_message_reaction";

  static const String removeChatMessageReaction =
      "$chatApi.remove_reaction";

  static const String chatMessageReadStatus =
      "$chatApi.get_message_read_status";

  static const String publishChatTyping =
      "$chatApi.publish_typing";

  static const String publishChatPresence =
      "$chatApi.publish_presence";

  static const String setChatGroupMute =
      "$chatApi.set_group_mute";

  static const String chatGroupNotificationSetting =
      "$chatApi.get_group_notification_setting";

  static const String toggleChatBookmark =
      "$chatApi.toggle_bookmark";

  static const String bookmarkedChatMessages =
      "$chatApi.get_bookmarked_messages";

  static const String pinChatMessage =
      "$chatApi.pin_message";

  static const String pinnedChatMessages =
      "$chatApi.get_pinned_messages";

  static const String chatMedia =
      "$chatApi.get_chat_media";

//   performance
  static const String performanceApi =
      "$baseUrl/api/method/geo_attendance.report";

  static const String performanceAccess =
      "$performanceApi.get_performance_access";

  static const String myMonthlyPerformance =
      "$performanceApi.get_my_monthly_performance";

  static const String monthlyPerformance =
      "$performanceApi.get_monthly_performance";

  static const String employeesMonthlyPerformance =
      "$performanceApi.get_employees_monthly_performance";

  static const String performanceDepartments =
      "$performanceApi.get_performance_departments";


  // Add these constants inside your existing ApiEndpoints class.

// ============================================================
// KNOWLEDGE HUB
// ============================================================

  static const String knowledgeApi =
      "$baseUrl/api/method/geo_attendance.knowledge";

  static const String knowledgeAccess =
      "$knowledgeApi.get_knowledge_access";

  static const String knowledgeResources =
      "$knowledgeApi.get_knowledge_resources";

  static const String knowledgeResource =
      "$knowledgeApi.get_knowledge_resource";

  static const String createKnowledgeResource =
      "$knowledgeApi.create_knowledge_resource";

  static const String updateKnowledgeResource =
      "$knowledgeApi.update_knowledge_resource";

  static const String submitKnowledgeForReview =
      "$knowledgeApi.submit_knowledge_for_review";

  static const String reviewKnowledgeResource =
      "$knowledgeApi.review_knowledge_resource";

  static const String publishKnowledgeResource =
      "$knowledgeApi.publish_knowledge_resource";

  static const String rejectKnowledgeResource =
      "$knowledgeApi.reject_knowledge_resource";

  static const String deleteKnowledgeResource =
      "$knowledgeApi.delete_knowledge_resource";

// work


  static const String myWork =
      '$baseUrl/api/method/geo_attendance.todo_api.get_my_work';

  static const String dashboardWork =
      '$baseUrl/api/method/geo_attendance.todo_api.get_dashboard_work';


  // Add these constants inside your existing ApiEndpoints class.

// ============================================================
// MEETINGS
// ============================================================

  static const String meetingApi =
      "$baseUrl/api/method/geo_attendance.meeting";

  static const String meetingAccess =
      "$meetingApi.get_meeting_access";

  static const String meetingEmployees =
      "$meetingApi.get_company_employees";

  static const String myMeetings =
      "$meetingApi.get_my_meetings";

  static const String meetingDetails =
      "$meetingApi.get_meeting_details";

  static const String createMeeting =
      "$meetingApi.create_meeting";

  static const String updateMeeting =
      "$meetingApi.update_meeting";

  static const String cancelMeeting =
      "$meetingApi.cancel_meeting";

  static const String updateMeetingAttendance =
      "$meetingApi.update_meeting_attendance";

  static const String updateMeetingOutcome =
      "$meetingApi.update_meeting_outcome";

  static const String addMeetingActionItem =
      "$meetingApi.add_meeting_action_item";

  static const String updateMeetingActionItem =
      "$meetingApi.update_meeting_action_item";

  static const String deleteMeetingActionItem =
      "$meetingApi.delete_meeting_action_item";

  static const String createMeetingTask =
      "$meetingApi.create_task_from_action_item";


  // ============================================================
// ACTIONS NEEDED
// ============================================================

  static const String actionsNeededApi =
      "$baseUrl/api/method/geo_attendance.actions_needed";

  static const String actionsNeeded =
      "$actionsNeededApi.get_actions_needed";




}