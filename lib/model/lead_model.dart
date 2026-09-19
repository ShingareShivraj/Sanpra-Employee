enum LeadEventTiming { upcoming, ongoing, past }

class LeadModel {
  final String name;
  final String leadName;
  final String mobileNo;
  final String phone;
  final String emailId;
  final String companyName;
  final String source;
  final String status;
  final String city;
  final String state;
  final String territory;
  final String description;
  final String company;
  final DateTime? creation;
  final DateTime? modified;

  const LeadModel({
    this.name = '',
    required this.leadName,
    this.mobileNo = '',
    this.phone = '',
    this.emailId = '',
    this.companyName = '',
    this.source = '',
    this.status = '',
    this.city = '',
    this.state = '',
    this.territory = '',
    this.description = '',
    this.company = '',
    this.creation,
    this.modified,
  });

  factory LeadModel.fromJson(Map<String, dynamic> json) {
    return LeadModel(
      name: _string(
        json['name'],
        fallback: _string(json['lead_id'], fallback: _string(json['id'])),
      ),
      leadName: _string(
        json['lead_name'],
        fallback: _string(json['first_name'], fallback: _string(json['name'])),
      ),
      mobileNo: _string(json['mobile_no']),
      phone: _string(json['phone']),
      emailId: _string(json['email_id']),
      companyName: _string(json['company_name']),
      source: _string(json['source']),
      status: _string(json['status']),
      city: _string(json['city']),
      state: _string(json['state']),
      territory: _string(json['territory']),
      description: _string(json['custom_description']),
      company: _string(json['company']),
      creation: _dateTime(json['creation']),
      modified: _dateTime(json['modified']),
    );
  }

  Map<String, dynamic> toWriteJson({bool includeEmptyValues = false}) {
    return <String, dynamic>{
      'lead_name': leadName.trim(),
      if (includeEmptyValues || mobileNo.trim().isNotEmpty)
        'mobile_no': mobileNo.trim(),
      if (includeEmptyValues || phone.trim().isNotEmpty) 'phone': phone.trim(),
      if (includeEmptyValues || emailId.trim().isNotEmpty)
        'email_id': emailId.trim(),
      if (includeEmptyValues || companyName.trim().isNotEmpty)
        'company_name': companyName.trim(),
      if (includeEmptyValues || source.trim().isNotEmpty)
        'source': source.trim(),
      if (includeEmptyValues || status.trim().isNotEmpty)
        'status': status.trim(),
      if (includeEmptyValues || city.trim().isNotEmpty) 'city': city.trim(),
      if (includeEmptyValues || state.trim().isNotEmpty) 'state': state.trim(),
      if (includeEmptyValues || territory.trim().isNotEmpty)
        'territory': territory.trim(),
      if (includeEmptyValues || description.trim().isNotEmpty)
        'custom_description': description.trim(),
    };
  }

  LeadModel copyWith({
    String? name,
    String? leadName,
    String? mobileNo,
    String? phone,
    String? emailId,
    String? companyName,
    String? source,
    String? status,
    String? city,
    String? state,
    String? territory,
    String? description,
    String? company,
    DateTime? creation,
    DateTime? modified,
  }) {
    return LeadModel(
      name: name ?? this.name,
      leadName: leadName ?? this.leadName,
      mobileNo: mobileNo ?? this.mobileNo,
      phone: phone ?? this.phone,
      emailId: emailId ?? this.emailId,
      companyName: companyName ?? this.companyName,
      source: source ?? this.source,
      status: status ?? this.status,
      city: city ?? this.city,
      state: state ?? this.state,
      territory: territory ?? this.territory,
      description: description ?? this.description,
      company: company ?? this.company,
      creation: creation ?? this.creation,
      modified: modified ?? this.modified,
    );
  }

  String get primaryPhone => mobileNo.isNotEmpty ? mobileNo : phone;
  bool get hasEmail => emailId.isNotEmpty;
  String get location => [city, state].where((item) => item.isNotEmpty).join(', ');
}
class LeadEventModel {
  final String name;
  final String leadId;
  final String subject;
  final String description;
  final DateTime? startsOn;
  final DateTime? endsOn;
  final String category;
  final DateTime? creation;
  final DateTime? modified;

  const LeadEventModel({
    this.name = '',
    this.leadId = '',
    this.subject = '',
    this.description = '',
    this.startsOn,
    this.endsOn,
    this.category = '',
    this.creation,
    this.modified,
  });

  factory LeadEventModel.fromJson(Map<String, dynamic> json) {
    return LeadEventModel(
      name: _string(json['name']),
      leadId: _string(
        json['lead_id'],
        fallback: json['reference_doctype']?.toString() == 'Lead'
            ? _string(json['reference_docname'])
            : '',
      ),
      subject: _string(json['subject'], fallback: _string(json['name'])),
      description: _string(json['description']),
      startsOn: _dateTime(json['starts_on']),
      endsOn: _dateTime(json['ends_on']),
      category: _string(
        json['event_category'],
        fallback: _string(json['category']),
      ),

      creation: _dateTime(json['creation']),
      modified: _dateTime(json['modified']),
    );
  }

  Map<String, dynamic> toWriteJson({
    bool includeEmptyValues = false,
    required bool includeNullDates,
  }) {
    return <String, dynamic>{
      'subject': subject.trim(),
      'category': category.trim(),
      if (startsOn != null)
        'starts_on': _frappeDateTime(startsOn!),
    };
  }

  LeadEventTiming timingAt(DateTime now) {
    final start = startsOn;
    if (start == null) return LeadEventTiming.past;
    final end = endsOn ?? start;
    if (now.isBefore(start)) return LeadEventTiming.upcoming;
    if (now.isAfter(end)) return LeadEventTiming.past;
    return LeadEventTiming.ongoing;
  }
}

class LeadMasterDataModel {
  final List<String> territories;
  final List<String> sources;
  final List<String> statuses;
  final List<String> eventCategories;

  const LeadMasterDataModel({
    this.territories = const [],
    this.sources = const [],
    this.statuses = const [],
    this.eventCategories = const [],
  });

  factory LeadMasterDataModel.fromJson(Map<String, dynamic> json) {
    return LeadMasterDataModel(
      territories: _stringList(json['territory']),
      sources: _stringList(json['source']),
      statuses: _stringList(json['status']),
      eventCategories: _stringList(json['event_categories']),

    );
  }
}

class LeadPageModel {
  final List<LeadModel> leads;
  final int page;
  final int pageLength;
  final int total;
  final bool hasMore;

  const LeadPageModel({
    this.leads = const [],
    required this.page,
    required this.pageLength,
    required this.total,
    required this.hasMore,
  });

  factory LeadPageModel.fromJson(Map<String, dynamic> json) {
    return LeadPageModel(
      leads: _mapList(json['data'])
          .map(LeadModel.fromJson)
          .toList(growable: false),
      page: _integer(json['page'], fallback: 1),
      pageLength: _integer(json['page_length'], fallback: 20),
      total: _integer(json['total']),
      hasMore: _boolean(json['has_more']),
    );
  }
}

class LeadEventListModel {
  final String leadId;
  final List<LeadEventModel> events;

  const LeadEventListModel({required this.leadId, this.events = const []});

  factory LeadEventListModel.fromJson(Map<String, dynamic> json) {
    final leadId = _string(json['lead_id']);
    return LeadEventListModel(
      leadId: leadId,
      events: _mapList(json['events'])
          .map((item) => LeadEventModel.fromJson({...item, 'lead_id': leadId}))
          .toList(growable: false),
    );
  }
}

class LeadMutationResultModel {
  final String message;
  final String leadId;
  final String company;
  final LeadModel lead;

  const LeadMutationResultModel({
    required this.message,
    required this.leadId,
    required this.company,
    required this.lead,
  });
}

class LeadEventMutationResultModel {
  final String message;
  final String eventId;
  final String leadId;
  final String company;
  final LeadEventModel event;

  const LeadEventMutationResultModel({
    required this.message,
    required this.eventId,
    required this.leadId,
    required this.company,
    required this.event,
  });
}

class LeadDeleteResultModel {
  final String message;
  final String id;

  const LeadDeleteResultModel({required this.message, required this.id});
}

String _string(dynamic value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

int _integer(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

bool _boolean(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  return {'1', 'true', 'yes'}.contains(value?.toString().trim().toLowerCase());
}

DateTime? _dateTime(dynamic value) {
  if (value is DateTime) return value;
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : DateTime.tryParse(text);
}

List<String> _stringList(dynamic value) {
  if (value is! List) return const [];
  return value
      .map((item) => item?.toString().trim() ?? '')
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

List<Map<String, dynamic>> _mapList(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList(growable: false);
}

String _frappeDateTime(DateTime value) {
  String two(int number) => number.toString().padLeft(2, '0');
  return '${value.year.toString().padLeft(4, '0')}-'
      '${two(value.month)}-${two(value.day)} '
      '${two(value.hour)}:${two(value.minute)}:${two(value.second)}';
}
