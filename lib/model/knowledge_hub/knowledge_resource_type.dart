/// Values must remain identical to the ERPNext Knowledge Hub Resource options.
enum KnowledgeResourceType {
  usefulLink('Useful Link'),
  courseLearning('Course / Learning'),
  document('Document'),
  research('Research'),
  importantNote('Important Note'),
  project('Project'),
  companyResource('Company Resource');

  final String apiValue;

  const KnowledgeResourceType(this.apiValue);

  static KnowledgeResourceType? tryFromApiValue(dynamic value) {
    final normalized = value?.toString().trim() ?? '';
    for (final type in values) {
      if (type.apiValue == normalized) return type;
    }
    return null;
  }

  static KnowledgeResourceType fromApiValue(dynamic value) {
    return tryFromApiValue(value) ?? KnowledgeResourceType.companyResource;
  }

  String get shortLabel {
    switch (this) {
      case KnowledgeResourceType.usefulLink:
        return 'Links';
      case KnowledgeResourceType.courseLearning:
        return 'Courses';
      case KnowledgeResourceType.document:
        return 'Documents';
      case KnowledgeResourceType.research:
        return 'Research';
      case KnowledgeResourceType.importantNote:
        return 'Notes';
      case KnowledgeResourceType.project:
        return 'Projects';
      case KnowledgeResourceType.companyResource:
        return 'Resources';
    }
  }

  bool get supportsUrl => const {
        KnowledgeResourceType.usefulLink,
        KnowledgeResourceType.courseLearning,
        KnowledgeResourceType.research,
        KnowledgeResourceType.companyResource,
      }.contains(this);

  bool get supportsAttachment => const {
        KnowledgeResourceType.document,
        KnowledgeResourceType.research,
        KnowledgeResourceType.companyResource,
      }.contains(this);

  bool get isProject => this == KnowledgeResourceType.project;
}

/// Values must remain identical to the ERPNext Status field options.
enum KnowledgeResourceStatus {
  draft('Draft'),
  pendingReview('Pending Review'),
  published('Published'),
  rejected('Rejected');

  final String apiValue;

  const KnowledgeResourceStatus(this.apiValue);

  static KnowledgeResourceStatus fromApiValue(dynamic value) {
    final normalized = value?.toString().trim() ?? '';
    for (final status in values) {
      if (status.apiValue == normalized) return status;
    }
    return KnowledgeResourceStatus.draft;
  }

  bool get isPublished => this == KnowledgeResourceStatus.published;
  bool get isPending => this == KnowledgeResourceStatus.pendingReview;
  bool get isEditableByOwner => !isPublished;
}

