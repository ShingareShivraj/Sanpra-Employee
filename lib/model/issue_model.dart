class IssueModel {
  final String name;
  final String subject;
  final String description;
  final String status;
  final String priority;
  final String? issueType;
  final String? company;
  final String? createdByEmployee;
  final String? createdByName;
  final String? raisedBy;
  final DateTime? openingDate;
  final DateTime? creation;
  final DateTime? modified;
  final String? resolutionDetails;
  final DateTime? resolutionDateTime;
  final List<IssueAssigneeModel> assignees;

  const IssueModel({
    required this.name, required this.subject, required this.description,
    required this.status, required this.priority, this.issueType, this.company,
    this.createdByEmployee, this.createdByName, this.raisedBy, this.openingDate,
    this.creation, this.modified, this.resolutionDetails,
    this.resolutionDateTime, this.assignees = const [],
  });

  factory IssueModel.fromJson(Map<String, dynamic> json) => IssueModel(
    name: '${json['name'] ?? ''}', subject: '${json['subject'] ?? ''}',
    description: '${json['description'] ?? ''}', status: '${json['status'] ?? 'Open'}',
    priority: '${json['priority'] ?? 'Medium'}', issueType: json['issue_type']?.toString(),
    company: json['company']?.toString(),
    createdByEmployee: json['created_by_employee']?.toString(),
    createdByName: json['created_by_name']?.toString(), raisedBy: json['raised_by']?.toString(),
    openingDate: _date(json['opening_date']), creation: _date(json['creation']),
    modified: _date(json['modified']), resolutionDetails: json['resolution_details']?.toString(),
    resolutionDateTime: _date(json['resolution_datetime']),
    assignees: _maps(json['assignees']).map(IssueAssigneeModel.fromJson).toList(),
  );
}

class IssueDetailsModel {
  final IssueModel issue;
  final List<IssueAttachmentModel> attachments;
  final List<IssueRemarkModel> timeline;
  final bool isManager;
  final bool isCreator;
  final bool isAssignedToMe;
  final bool canSubmitResolution;
  final bool canManage;

  const IssueDetailsModel({required this.issue, this.attachments = const [],
    this.timeline = const [], this.isManager = false, this.isCreator = false,
    this.isAssignedToMe = false, this.canSubmitResolution = false,
    this.canManage = false});

  factory IssueDetailsModel.fromJson(Map<String, dynamic> json) {
    final data = Map<String, dynamic>.from(json['issue'] as Map? ?? json);
    return IssueDetailsModel(
      issue: IssueModel.fromJson(data),
      attachments: _maps(data['attachments']).map(IssueAttachmentModel.fromJson).toList(),
      timeline: _maps(data['timeline']).map(IssueRemarkModel.fromJson).toList(),
      isManager: data['is_manager'] == true, isCreator: data['is_creator'] == true,
      isAssignedToMe: data['is_assigned_to_me'] == true,
      canSubmitResolution: data['can_submit_resolution'] == true,
      canManage: data['can_manage'] == true,
    );
  }
}

class IssueAssigneeModel {
  final String employeeId;
  final String employeeName;
  final String userId;
  final String? designation;
  const IssueAssigneeModel({required this.employeeId, required this.employeeName,
    required this.userId, this.designation});
  factory IssueAssigneeModel.fromJson(Map<String, dynamic> j) => IssueAssigneeModel(
    employeeId: '${j['name'] ?? ''}', employeeName: '${j['employee_name'] ?? ''}',
    userId: '${j['user_id'] ?? ''}', designation: j['designation']?.toString());
}

class IssueAttachmentModel {
  final String name;
  final String fileName;
  final String fileUrl;
  final bool isPrivate;
  final DateTime? creation;
  const IssueAttachmentModel({required this.name, required this.fileName,
    required this.fileUrl, required this.isPrivate, this.creation});
  factory IssueAttachmentModel.fromJson(Map<String, dynamic> j) => IssueAttachmentModel(
    name: '${j['name'] ?? ''}', fileName: '${j['file_name'] ?? ''}',
    fileUrl: '${j['file_url'] ?? ''}', isPrivate: j['is_private'] == 1 || j['is_private'] == true,
    creation: _date(j['creation']));
}

class IssueRemarkModel {
  final String name;
  final String content;
  final String? authorEmail;
  final String? authorName;
  final DateTime? creation;
  const IssueRemarkModel({required this.name, required this.content,
    this.authorEmail, this.authorName, this.creation});
  factory IssueRemarkModel.fromJson(Map<String, dynamic> j) => IssueRemarkModel(
    name: '${j['name'] ?? ''}', content: '${j['content'] ?? ''}',
    authorEmail: j['comment_email']?.toString(), authorName: j['comment_by']?.toString(),
    creation: _date(j['creation']));
}

class CompanyEmployeeModel {
  final String name;
  final String employeeName;
  final String userId;
  final String? designation;
  final String? department;
  const CompanyEmployeeModel({required this.name, required this.employeeName,
    required this.userId, this.designation, this.department});
  factory CompanyEmployeeModel.fromJson(Map<String, dynamic> j) => CompanyEmployeeModel(
    name: '${j['name'] ?? ''}', employeeName: '${j['employee_name'] ?? ''}',
    userId: '${j['user_id'] ?? ''}', designation: j['designation']?.toString(),
    department: j['department']?.toString());
}

class IssueListResult {
  final List<IssueModel> items;
  final int total;
  final int start;
  final int pageLength;
  const IssueListResult({required this.items, required this.total,
    required this.start, required this.pageLength});
  factory IssueListResult.fromJson(Map<String, dynamic> j) => IssueListResult(
    items: _maps(j['items']).map(IssueModel.fromJson).toList(),
    total: _int(j['total']), start: _int(j['start']), pageLength: _int(j['page_length']));
  bool get hasMore => start + items.length < total;
}

class IssueDashboardCounts {
  final int myOpen;
  final int assignedOpen;
  final int companyOpen;
  final int awaitingReview;
  final bool isIssueManager;
  const IssueDashboardCounts({required this.myOpen, required this.assignedOpen,
    required this.companyOpen, required this.awaitingReview, required this.isIssueManager});
  factory IssueDashboardCounts.fromJson(Map<String, dynamic> j) => IssueDashboardCounts(
    myOpen: _int(j['my_open']), assignedOpen: _int(j['assigned_open']),
    companyOpen: _int(j['company_open']), awaitingReview: _int(j['awaiting_review']),
    isIssueManager: j['is_issue_manager'] == true);
}

DateTime? _date(dynamic value) => value == null || '$value'.isEmpty ? null : DateTime.tryParse('$value');
int _int(dynamic value) => value is int ? value : int.tryParse('$value') ?? 0;
List<Map<String, dynamic>> _maps(dynamic value) => value is List
    ? value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
    : const [];
