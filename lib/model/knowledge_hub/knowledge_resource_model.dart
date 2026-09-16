import 'knowledge_resource_member_model.dart';
import 'knowledge_resource_type.dart';

class KnowledgeResourceModel {
  final String name;
  final String resourceTitle;
  final String company;
  final KnowledgeResourceType resourceType;
  final String description;
  final KnowledgeResourceStatus status;
  final String? url;
  final String? githubUrl;
  final String? documentationUrl;
  final String? attachment;
  final String? thumbnail;
  final String? tags;
  final String? technologies;
  final String? projectDescription;
  final String? projectBuild;
  final String? projectScreenshots;
  final List<KnowledgeResourceMemberModel> teamMembers;
  final String createdBy;
  final String? publishedBy;
  final DateTime? publishedOn;
  final DateTime? creation;
  final DateTime? modified;
  final bool isOwner;
  final bool canEdit;
  final bool canPublish;
  final bool canReject;
  final bool canDelete;

  const KnowledgeResourceModel({
    required this.name,
    required this.resourceTitle,
    required this.company,
    required this.resourceType,
    required this.description,
    required this.status,
    this.url,
    this.githubUrl,
    this.documentationUrl,
    this.attachment,
    this.thumbnail,
    this.tags,
    this.technologies,
    this.projectDescription,
    this.projectBuild,
    this.projectScreenshots,
    this.teamMembers = const [],
    required this.createdBy,
    this.publishedBy,
    this.publishedOn,
    this.creation,
    this.modified,
    this.isOwner = false,
    this.canEdit = false,
    this.canPublish = false,
    this.canReject = false,
    this.canDelete = false,
  });

  factory KnowledgeResourceModel.fromJson(Map<String, dynamic> json) {
    final memberRows = json['team_members'] is List
        ? json['team_members'] as List
        : const [];
    return KnowledgeResourceModel(
      name: _string(json['name']),
      resourceTitle: _string(json['resource_title']),
      company: _string(json['company']),
      resourceType: KnowledgeResourceType.fromApiValue(json['resource_type']),
      description: _string(json['description']),
      status: KnowledgeResourceStatus.fromApiValue(json['status']),
      url: _optionalString(json['url']),
      githubUrl: _optionalString(json['github_url']),
      documentationUrl: _optionalString(json['documentation_url']),
      attachment: _optionalString(json['attachment']),
      thumbnail: _optionalString(json['thumbnail']),
      tags: _optionalString(json['tags']),
      technologies: _optionalString(json['technologies']),
      projectDescription: _optionalString(json['project_description']),
      projectBuild: _optionalString(json['project_build']),
      projectScreenshots: _optionalString(json['project_screenshots']),
      teamMembers: memberRows
          .whereType<Map>()
          .map((row) => KnowledgeResourceMemberModel.fromJson(
                Map<String, dynamic>.from(row),
              ))
          .toList(growable: false),
      createdBy: _string(json['created_by']),
      publishedBy: _optionalString(json['published_by']),
      publishedOn: _date(json['published_on']),
      creation: _date(json['creation']),
      modified: _date(json['modified']),
      isOwner: _bool(json['is_owner']),
      canEdit: _bool(json['can_edit']),
      canPublish: _bool(json['can_publish']),
      canReject: _bool(json['can_reject']),
      canDelete: _bool(json['can_delete']),
    );
  }

  bool get isPublished => status.isPublished;
  bool get isPendingReview => status.isPending;
  bool get hasUrl => url?.isNotEmpty == true;
  bool get hasAttachment => attachment?.isNotEmpty == true;
  bool get hasThumbnail => thumbnail?.isNotEmpty == true;
  bool get hasProjectBuild => projectBuild?.isNotEmpty == true;
  bool get hasProjectScreenshots => projectScreenshots?.isNotEmpty == true;
  bool get isProject => resourceType.isProject;

  List<String> get tagList => _splitValues(tags);
  List<String> get technologyList => _splitValues(technologies);

  /// Complete create/update payload. The service may remove [resource_name]
  /// for create requests.
  Map<String, dynamic> toApiMap({
    bool submitForReview = false,
    bool publishNow = false,
  }) {
    return {
      if (name.isNotEmpty) 'resource_name': name,
      'resource_title': resourceTitle,
      'resource_type': resourceType.apiValue,
      'description': description,
      'url': url ?? '',
      'github_url': githubUrl ?? '',
      'documentation_url': documentationUrl ?? '',
      'attachment': attachment ?? '',
      'thumbnail': thumbnail ?? '',
      'tags': tags ?? '',
      'technologies': technologies ?? '',
      'project_description': projectDescription ?? '',
      'project_build': projectBuild ?? '',
      'project_screenshots': projectScreenshots ?? '',
      'team_members': teamMembers.map((member) => member.toJson()).toList(),
      'submit_for_review': submitForReview ? 1 : 0,
      if (publishNow) 'publish_now': 1,
    };
  }

  KnowledgeResourceModel copyWith({
    String? name,
    String? resourceTitle,
    String? company,
    KnowledgeResourceType? resourceType,
    String? description,
    KnowledgeResourceStatus? status,
    String? url,
    String? githubUrl,
    String? documentationUrl,
    String? attachment,
    String? thumbnail,
    String? tags,
    String? technologies,
    String? projectDescription,
    String? projectBuild,
    String? projectScreenshots,
    List<KnowledgeResourceMemberModel>? teamMembers,
    String? createdBy,
    String? publishedBy,
    DateTime? publishedOn,
    DateTime? creation,
    DateTime? modified,
    bool? isOwner,
    bool? canEdit,
    bool? canPublish,
    bool? canReject,
    bool? canDelete,
  }) {
    return KnowledgeResourceModel(
      name: name ?? this.name,
      resourceTitle: resourceTitle ?? this.resourceTitle,
      company: company ?? this.company,
      resourceType: resourceType ?? this.resourceType,
      description: description ?? this.description,
      status: status ?? this.status,
      url: url ?? this.url,
      githubUrl: githubUrl ?? this.githubUrl,
      documentationUrl: documentationUrl ?? this.documentationUrl,
      attachment: attachment ?? this.attachment,
      thumbnail: thumbnail ?? this.thumbnail,
      tags: tags ?? this.tags,
      technologies: technologies ?? this.technologies,
      projectDescription: projectDescription ?? this.projectDescription,
      projectBuild: projectBuild ?? this.projectBuild,
      projectScreenshots: projectScreenshots ?? this.projectScreenshots,
      teamMembers: teamMembers ?? this.teamMembers,
      createdBy: createdBy ?? this.createdBy,
      publishedBy: publishedBy ?? this.publishedBy,
      publishedOn: publishedOn ?? this.publishedOn,
      creation: creation ?? this.creation,
      modified: modified ?? this.modified,
      isOwner: isOwner ?? this.isOwner,
      canEdit: canEdit ?? this.canEdit,
      canPublish: canPublish ?? this.canPublish,
      canReject: canReject ?? this.canReject,
      canDelete: canDelete ?? this.canDelete,
    );
  }
}

class KnowledgeEmployeeModel {
  final String name;
  final String employeeName;
  final String? department;
  final String? designation;

  const KnowledgeEmployeeModel({
    required this.name,
    required this.employeeName,
    this.department,
    this.designation,
  });

  factory KnowledgeEmployeeModel.fromJson(Map<String, dynamic> json) {
    final name = _string(json['name']);
    return KnowledgeEmployeeModel(
      name: name,
      employeeName: _string(json['employee_name'], fallback: name),
      department: _optionalString(json['department']),
      designation: _optionalString(json['designation']),
    );
  }
}

class KnowledgeAccessModel {
  final bool success;
  final bool isKnowledgeManager;
  final String company;
  final KnowledgeEmployeeModel employee;
  final List<KnowledgeResourceType> resourceTypes;
  final List<KnowledgeResourceStatus> statuses;

  const KnowledgeAccessModel({
    required this.success,
    required this.isKnowledgeManager,
    required this.company,
    required this.employee,
    required this.resourceTypes,
    required this.statuses,
  });

  factory KnowledgeAccessModel.fromJson(Map<String, dynamic> json) {
    final rawTypes = json['resource_types'] is List
        ? json['resource_types'] as List
        : const [];
    final rawStatuses = json['statuses'] is List
        ? json['statuses'] as List
        : const [];
    return KnowledgeAccessModel(
      success: _bool(json['success'], fallback: true),
      isKnowledgeManager: _bool(json['is_knowledge_manager']),
      company: _string(json['company']),
      employee: KnowledgeEmployeeModel.fromJson(_map(json['employee'])),
      resourceTypes: rawTypes
          .map(KnowledgeResourceType.tryFromApiValue)
          .whereType<KnowledgeResourceType>()
          .toList(growable: false),
      statuses: rawStatuses
          .map(KnowledgeResourceStatus.fromApiValue)
          .toSet()
          .toList(growable: false),
    );
  }
}

class KnowledgePaginationModel {
  final int total;
  final int start;
  final int pageLength;
  final bool hasMore;

  const KnowledgePaginationModel({
    required this.total,
    required this.start,
    required this.pageLength,
    required this.hasMore,
  });

  factory KnowledgePaginationModel.fromJson(Map<String, dynamic> json) {
    return KnowledgePaginationModel(
      total: _int(json['total']),
      start: _int(json['start']),
      pageLength: _int(json['page_length'], fallback: 20),
      hasMore: _bool(json['has_more']),
    );
  }
}

class KnowledgeResourcesResponseModel {
  final bool success;
  final List<KnowledgeResourceModel> resources;
  final KnowledgePaginationModel pagination;

  const KnowledgeResourcesResponseModel({
    required this.success,
    required this.resources,
    required this.pagination,
  });

  factory KnowledgeResourcesResponseModel.fromJson(Map<String, dynamic> json) {
    final rows = json['resources'] is List ? json['resources'] as List : const [];
    return KnowledgeResourcesResponseModel(
      success: _bool(json['success'], fallback: true),
      resources: rows
          .whereType<Map>()
          .map((row) => KnowledgeResourceModel.fromJson(
                Map<String, dynamic>.from(row),
              ))
          .toList(growable: false),
      pagination: KnowledgePaginationModel.fromJson(_map(json['pagination'])),
    );
  }
}

class KnowledgeResourceResponseModel {
  final bool success;
  final String? message;
  final KnowledgeResourceModel resource;

  const KnowledgeResourceResponseModel({
    required this.success,
    this.message,
    required this.resource,
  });

  factory KnowledgeResourceResponseModel.fromJson(Map<String, dynamic> json) {
    return KnowledgeResourceResponseModel(
      success: _bool(json['success'], fallback: true),
      message: _optionalString(json['message']),
      resource: KnowledgeResourceModel.fromJson(_map(json['resource'])),
    );
  }
}

class KnowledgeDeleteResponseModel {
  final bool success;
  final String? message;
  final String resourceName;

  const KnowledgeDeleteResponseModel({
    required this.success,
    this.message,
    required this.resourceName,
  });

  factory KnowledgeDeleteResponseModel.fromJson(Map<String, dynamic> json) {
    return KnowledgeDeleteResponseModel(
      success: _bool(json['success'], fallback: true),
      message: _optionalString(json['message']),
      resourceName: _string(json['resource_name']),
    );
  }
}

Map<String, dynamic> _map(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

String _string(dynamic value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String? _optionalString(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

int _int(dynamic value, {int fallback = 0}) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

bool _bool(dynamic value, {bool fallback = false}) {
  if (value == null) return fallback;
  if (value is bool) return value;
  if (value is num) return value != 0;
  return {'1', 'true', 'yes', 'on'}
      .contains(value.toString().trim().toLowerCase());
}

DateTime? _date(dynamic value) {
  final text = value?.toString().trim() ?? '';
  if (text.isEmpty) return null;
  return DateTime.tryParse(text.replaceFirst(' ', 'T'));
}

List<String> _splitValues(String? value) {
  if (value == null || value.trim().isEmpty) return const [];
  return value
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}
