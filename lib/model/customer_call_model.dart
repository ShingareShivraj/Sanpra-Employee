enum CustomerCallType {
  incoming('Incoming'),
  outgoing('Outgoing'),
  missed('Missed'),
  rejected('Rejected');

  const CustomerCallType(this.apiValue);
  final String apiValue;

  static CustomerCallType fromValue(dynamic value) {
    final text = _text(value).toLowerCase();
    return values.firstWhere(
      (item) => item.apiValue.toLowerCase() == text,
      orElse: () => CustomerCallType.outgoing,
    );
  }
}

enum CustomerCallSource {
  androidCallLog('Android Call Log'),
  sanpra('Sanpra');

  const CustomerCallSource(this.apiValue);
  final String apiValue;

  static CustomerCallSource fromValue(dynamic value) {
    final text = _text(value).toLowerCase();
    return values.firstWhere(
      (item) => item.apiValue.toLowerCase() == text,
      orElse: () => CustomerCallSource.androidCallLog,
    );
  }
}

enum CustomerCallSyncStatus {
  pending('Pending'),
  synced('Synced'),
  failed('Failed');

  const CustomerCallSyncStatus(this.apiValue);
  final String apiValue;

  static CustomerCallSyncStatus fromValue(dynamic value) {
    final text = _text(value).toLowerCase();
    return values.firstWhere(
      (item) => item.apiValue.toLowerCase() == text,
      orElse: () => CustomerCallSyncStatus.pending,
    );
  }
}

class CustomerCallEmployeeModel {
  final String name;
  final String employeeName;
  final String company;
  final String department;
  final String designation;

  const CustomerCallEmployeeModel({
    required this.name,
    required this.employeeName,
    required this.company,
    required this.department,
    required this.designation,
  });

  factory CustomerCallEmployeeModel.fromJson(Map<String, dynamic> json) {
    return CustomerCallEmployeeModel(
      name: _text(json['name']),
      employeeName: _text(json['employee_name']),
      company: _text(json['company']),
      department: _text(json['department']),
      designation: _text(json['designation']),
    );
  }
}

class CustomerCallAccessModel {
  final bool hasAccess;
  final String role;
  final CustomerCallEmployeeModel? employee;

  const CustomerCallAccessModel({
    required this.hasAccess,
    required this.role,
    this.employee,
  });

  factory CustomerCallAccessModel.fromJson(Map<String, dynamic> json) {
    final employee = _map(json['employee']);
    return CustomerCallAccessModel(
      hasAccess: _bool(json['has_access']),
      role: _text(json['role'], fallback: 'Mobile Caller'),
      employee: employee.isEmpty
          ? null
          : CustomerCallEmployeeModel.fromJson(employee),
    );
  }
}

class CustomerPhoneMatchModel {
  final String customer;
  final String customerName;
  final String? contact;
  final String? contactName;
  final String phoneNumber;
  final String normalizedNumber;
  final String label;

  const CustomerPhoneMatchModel({
    required this.customer,
    required this.customerName,
    this.contact,
    this.contactName,
    required this.phoneNumber,
    required this.normalizedNumber,
    required this.label,
  });

  factory CustomerPhoneMatchModel.fromJson(Map<String, dynamic> json) {
    return CustomerPhoneMatchModel(
      customer: _text(json['customer']),
      customerName: _text(json['customer_name']),
      contact: _nullableText(json['contact']),
      contactName: _nullableText(json['contact_name']),
      phoneNumber: _text(json['phone_number']),
      normalizedNumber: _text(json['normalized_number']),
      label: _text(json['label'], fallback: 'Phone'),
    );
  }
}

class CustomerCallCustomerModel {
  final String name;
  final String customerName;
  final String customerType;
  final String territory;
  final String customerGroup;
  final String? image;
  final bool disabled;
  final List<String> phoneNumbers;
  final int phoneCount;

  const CustomerCallCustomerModel({
    required this.name,
    required this.customerName,
    required this.customerType,
    required this.territory,
    required this.customerGroup,
    this.image,
    required this.disabled,
    required this.phoneNumbers,
    required this.phoneCount,
  });

  factory CustomerCallCustomerModel.fromJson(Map<String, dynamic> json) {
    final phones = _list(json['phone_numbers'])
        .map((value) => _text(value))
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    return CustomerCallCustomerModel(
      name: _text(json['name']),
      customerName: _text(json['customer_name']),
      customerType: _text(json['customer_type']),
      territory: _text(json['territory']),
      customerGroup: _text(json['customer_group']),
      image: _nullableText(json['image']),
      disabled: _bool(json['disabled']),
      phoneNumbers: phones,
      phoneCount: _integer(json['phone_count'], fallback: phones.length),
    );
  }
}

class CustomerCallContactModel {
  final String name;
  final String fullName;
  final List<CustomerPhoneMatchModel> phones;

  const CustomerCallContactModel({
    required this.name,
    required this.fullName,
    required this.phones,
  });

  factory CustomerCallContactModel.fromJson(Map<String, dynamic> json) {
    return CustomerCallContactModel(
      name: _text(json['name']),
      fullName: _text(json['full_name']),
      phones: _list(json['phones'])
          .map((value) => CustomerPhoneMatchModel.fromJson(_map(value)))
          .toList(growable: false),
    );
  }
}

class CustomerDetailsModel {
  final CustomerCallCustomerModel customer;
  final List<CustomerCallContactModel> contacts;
  final List<CustomerPhoneMatchModel> phones;

  const CustomerDetailsModel({
    required this.customer,
    required this.contacts,
    required this.phones,
  });

  factory CustomerDetailsModel.fromJson(Map<String, dynamic> json) {
    return CustomerDetailsModel(
      customer: CustomerCallCustomerModel.fromJson(_map(json['customer'])),
      contacts: _list(json['contacts'])
          .map((value) => CustomerCallContactModel.fromJson(_map(value)))
          .toList(growable: false),
      phones: _list(json['phones'])
          .map((value) => CustomerPhoneMatchModel.fromJson(_map(value)))
          .toList(growable: false),
    );
  }
}

class CustomerSearchPageModel {
  final List<CustomerCallCustomerModel> customers;
  final int total;
  final int start;
  final int pageLength;
  final bool hasMore;

  const CustomerSearchPageModel({
    required this.customers,
    required this.total,
    required this.start,
    required this.pageLength,
    required this.hasMore,
  });

  factory CustomerSearchPageModel.fromJson(Map<String, dynamic> json) {
    return CustomerSearchPageModel(
      customers: _list(json['customers'])
          .map((value) => CustomerCallCustomerModel.fromJson(_map(value)))
          .toList(growable: false),
      total: _integer(json['total']),
      start: _integer(json['start']),
      pageLength: _integer(json['page_length'], fallback: 20),
      hasMore: _bool(json['has_more']),
    );
  }
}

class CustomerPhoneLookupModel {
  final String employee;
  final String company;
  final DateTime? generatedAt;
  final List<CustomerPhoneMatchModel> phones;

  const CustomerPhoneLookupModel({
    required this.employee,
    required this.company,
    this.generatedAt,
    required this.phones,
  });

  factory CustomerPhoneLookupModel.fromJson(Map<String, dynamic> json) {
    return CustomerPhoneLookupModel(
      employee: _text(json['employee']),
      company: _text(json['company']),
      generatedAt: _dateTime(json['generated_at']),
      phones: _list(json['phones'])
          .map((value) => CustomerPhoneMatchModel.fromJson(_map(value)))
          .toList(growable: false),
    );
  }

  CustomerPhoneMatchModel? match(String phoneNumber) {
    final requested = normalizePhoneNumber(phoneNumber);
    if (requested.isEmpty) return null;
    for (final phone in phones) {
      if (normalizePhoneNumber(phone.normalizedNumber) == requested ||
          normalizePhoneNumber(phone.phoneNumber) == requested) {
        return phone;
      }
    }
    return null;
  }
}

class CustomerCallModel {
  final String name;
  final String employee;
  final String customer;
  final String? contact;
  final String phoneNumber;
  final CustomerCallType callType;
  final DateTime? callDateTime;
  final int durationSeconds;
  final String deviceId;
  final String androidCallLogId;
  final CustomerCallSource source;
  final CustomerCallSyncStatus syncStatus;
  final DateTime? syncedAt;
  final String idempotencyKey;
  final String? recordingFile;
  final DateTime? creation;
  final DateTime? modified;

  const CustomerCallModel({
    required this.name,
    required this.employee,
    required this.customer,
    this.contact,
    required this.phoneNumber,
    required this.callType,
    this.callDateTime,
    required this.durationSeconds,
    required this.deviceId,
    required this.androidCallLogId,
    required this.source,
    required this.syncStatus,
    this.syncedAt,
    required this.idempotencyKey,
    this.recordingFile,
    this.creation,
    this.modified,
  });

  factory CustomerCallModel.fromJson(Map<String, dynamic> json) {
    return CustomerCallModel(
      name: _text(json['name']),
      employee: _text(json['employee']),
      customer: _text(json['customer']),
      contact: _nullableText(json['contact']),
      phoneNumber: _text(json['phone_number']),
      callType: CustomerCallType.fromValue(json['call_type']),
      callDateTime: _dateTime(json['call_datetime']),
      durationSeconds: _integer(json['duration_seconds']),
      deviceId: _text(json['device_id']),
      androidCallLogId: _text(json['android_call_log_id']),
      source: CustomerCallSource.fromValue(json['source']),
      syncStatus: CustomerCallSyncStatus.fromValue(json['sync_status']),
      syncedAt: _dateTime(json['synced_at']),
      idempotencyKey: _text(json['idempotency_key']),
      recordingFile: _nullableText(json['recording_file']),
      creation: _dateTime(json['creation']),
      modified: _dateTime(json['modified']),
    );
  }

  bool get hasRecording => recordingFile?.isNotEmpty == true;
  bool get isMissed => callType == CustomerCallType.missed;
  Duration get duration => Duration(seconds: durationSeconds);
}

class CustomerCallCreateModel {
  final String customer;
  final String? contact;
  final String phoneNumber;
  final CustomerCallType callType;
  final DateTime callDateTime;
  final int durationSeconds;
  final String idempotencyKey;
  final String deviceId;
  final String androidCallLogId;
  final CustomerCallSource source;

  const CustomerCallCreateModel({
    required this.customer,
    this.contact,
    required this.phoneNumber,
    required this.callType,
    required this.callDateTime,
    required this.durationSeconds,
    required this.idempotencyKey,
    this.deviceId = '',
    this.androidCallLogId = '',
    this.source = CustomerCallSource.androidCallLog,
  });

  Map<String, dynamic> toApiJson() {
    return {
      'customer': customer.trim(),
      if (contact?.trim().isNotEmpty == true) 'contact': contact!.trim(),
      'phone_number': phoneNumber.trim(),
      'call_type': callType.apiValue,
      'call_datetime': _formatApiDateTime(callDateTime),
      'duration_seconds': durationSeconds,
      'idempotency_key': idempotencyKey.trim(),
      'device_id': deviceId.trim(),
      'android_call_log_id': androidCallLogId.trim(),
      'source': source.apiValue,
    };
  }
}

class CustomerCallMutationModel {
  final bool created;
  final String message;
  final CustomerCallModel call;

  const CustomerCallMutationModel({
    required this.created,
    required this.message,
    required this.call,
  });

  factory CustomerCallMutationModel.fromJson(Map<String, dynamic> json) {
    return CustomerCallMutationModel(
      created: _bool(json['created']),
      message: _text(json['message']),
      call: CustomerCallModel.fromJson(_map(json['call'])),
    );
  }
}

class CustomerCallPageModel {
  final List<CustomerCallModel> calls;
  final int total;
  final int start;
  final int pageLength;
  final bool hasMore;

  const CustomerCallPageModel({
    required this.calls,
    required this.total,
    required this.start,
    required this.pageLength,
    required this.hasMore,
  });

  factory CustomerCallPageModel.fromJson(Map<String, dynamic> json) {
    return CustomerCallPageModel(
      calls: _list(json['calls'])
          .map((value) => CustomerCallModel.fromJson(_map(value)))
          .toList(growable: false),
      total: _integer(json['total']),
      start: _integer(json['start']),
      pageLength: _integer(json['page_length'], fallback: 20),
      hasMore: _bool(json['has_more']),
    );
  }
}

class CustomerCallSyncItemModel {
  final int index;
  final bool success;
  final bool created;
  final String idempotencyKey;
  final String? error;
  final CustomerCallModel? call;

  const CustomerCallSyncItemModel({
    required this.index,
    required this.success,
    required this.created,
    required this.idempotencyKey,
    this.error,
    this.call,
  });

  factory CustomerCallSyncItemModel.fromJson(Map<String, dynamic> json) {
    final call = _map(json['call']);
    return CustomerCallSyncItemModel(
      index: _integer(json['index']),
      success: _bool(json['success']),
      created: _bool(json['created']),
      idempotencyKey: _text(json['idempotency_key']),
      error: _nullableText(json['error']),
      call: call.isEmpty ? null : CustomerCallModel.fromJson(call),
    );
  }
}

class CustomerCallBatchResultModel {
  final bool success;
  final int synced;
  final int failed;
  final List<CustomerCallSyncItemModel> results;

  const CustomerCallBatchResultModel({
    required this.success,
    required this.synced,
    required this.failed,
    required this.results,
  });

  factory CustomerCallBatchResultModel.fromJson(Map<String, dynamic> json) {
    return CustomerCallBatchResultModel(
      success: _bool(json['success']),
      synced: _integer(json['synced']),
      failed: _integer(json['failed']),
      results: _list(json['results'])
          .map((value) => CustomerCallSyncItemModel.fromJson(_map(value)))
          .toList(growable: false),
    );
  }
}

String normalizePhoneNumber(String value) {
  var digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('00')) digits = digits.substring(2);
  if (digits.length == 12 && digits.startsWith('91')) {
    return digits.substring(2);
  }
  if (digits.length == 11 && digits.startsWith('0')) {
    return digits.substring(1);
  }
  return digits;
}

Map<String, dynamic> _map(dynamic value) {
  return value is Map
      ? Map<String, dynamic>.from(value)
      : <String, dynamic>{};
}

List<dynamic> _list(dynamic value) => value is List ? value : const [];

String _text(dynamic value, {String fallback = ''}) {
  final result = value?.toString().trim() ?? '';
  return result.isEmpty ? fallback : result;
}

String? _nullableText(dynamic value) {
  final result = _text(value);
  return result.isEmpty ? null : result;
}

int _integer(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

bool _bool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  return {'1', 'true', 'yes'}.contains(value?.toString().toLowerCase());
}

DateTime? _dateTime(dynamic value) {
  final text = _text(value);
  if (text.isEmpty) return null;
  return DateTime.tryParse(text.replaceFirst(' ', 'T'));
}

String _formatApiDateTime(DateTime value) {
  String two(int number) => number.toString().padLeft(2, '0');
  return '${value.year.toString().padLeft(4, '0')}-'
      '${two(value.month)}-${two(value.day)} '
      '${two(value.hour)}:${two(value.minute)}:${two(value.second)}';
}
