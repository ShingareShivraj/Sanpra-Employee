import 'dart:convert';

import 'package:dio/dio.dart';

import '../model/customer_call_model.dart';
import 'api_endpoints.dart';
import 'api_service.dart';

class CustomerCallService {
  CustomerCallService({ApiService? api}) : _api = api ?? ApiService();

  final ApiService _api;

  Future<CustomerCallAccessModel> getAccess() async {
    final data = await _get(ApiEndpoints.customerCallAccess);
    return CustomerCallAccessModel.fromJson(data);
  }

  Future<CustomerSearchPageModel> searchCustomers({
    String? search,
    int start = 0,
    int pageLength = 20,
  }) async {
    final data = await _get(
      ApiEndpoints.customerCallCustomers,
      query: {
        if (search?.trim().isNotEmpty == true) 'search': search!.trim(),
        'start': start < 0 ? 0 : start,
        'page_length': pageLength.clamp(1, 100),
      },
    );
    return CustomerSearchPageModel.fromJson(data);
  }

  Future<CustomerDetailsModel> getCustomerDetails(String customer) async {
    _required(customer, 'Customer is required.');
    final data = await _get(
      ApiEndpoints.customerCallCustomerDetails,
      query: {'customer': customer.trim()},
    );
    return CustomerDetailsModel.fromJson(data);
  }

  /// Downloads only company-customer phone numbers for private local matching.
  /// Store this response in app-private storage; do not write it to shared files.
  Future<CustomerPhoneLookupModel> getPhoneLookup() async {
    final data = await _get(ApiEndpoints.customerCallPhoneLookup);
    return CustomerPhoneLookupModel.fromJson(data);
  }

  Future<CustomerCallMutationModel> createCall(
    CustomerCallCreateModel call,
  ) async {
    _validateCall(call);
    final data = await _post(
      ApiEndpoints.createCustomerCall,
      body: call.toApiJson(),
    );
    return CustomerCallMutationModel.fromJson(data);
  }

  /// Syncs up to 100 locally matched calls. Failed items remain available in
  /// [CustomerCallBatchResultModel.results] for retry instead of being hidden.
  Future<CustomerCallBatchResultModel> syncCalls(
    List<CustomerCallCreateModel> calls,
  ) async {
    if (calls.isEmpty) {
      return const CustomerCallBatchResultModel(
        success: true,
        synced: 0,
        failed: 0,
        results: [],
      );
    }
    if (calls.length > 100) {
      throw const CustomerCallServiceException(
        'A maximum of 100 calls can be synced at once.',
      );
    }
    for (final call in calls) {
      _validateCall(call);
    }
    final data = await _post(
      ApiEndpoints.syncCustomerCalls,
      body: {'records': calls.map((call) => call.toApiJson()).toList()},
      allowBusinessFailure: true,
    );
    return CustomerCallBatchResultModel.fromJson(data);
  }

  Future<CustomerCallPageModel> getCalls({
    String? customer,
    CustomerCallType? callType,
    DateTime? fromDate,
    DateTime? toDate,
    int start = 0,
    int pageLength = 20,
  }) async {
    if (fromDate != null && toDate != null && fromDate.isAfter(toDate)) {
      throw const CustomerCallServiceException(
        'From date cannot be after to date.',
      );
    }
    final data = await _get(
      ApiEndpoints.customerCalls,
      query: {
        if (customer?.trim().isNotEmpty == true) 'customer': customer!.trim(),
        if (callType != null) 'call_type': callType.apiValue,
        if (fromDate != null) 'from_date': _formatDate(fromDate),
        if (toDate != null) 'to_date': _formatDate(toDate),
        'start': start < 0 ? 0 : start,
        'page_length': pageLength.clamp(1, 100),
      },
    );
    return CustomerCallPageModel.fromJson(data);
  }

  Future<CustomerCallModel> getCall(String callRecord) async {
    _required(callRecord, 'Call record is required.');
    final data = await _get(
      ApiEndpoints.customerCall,
      query: {'name': callRecord.trim()},
    );
    return CustomerCallModel.fromJson(_map(data['call']));
  }

  /// Uploads an audio file privately, then binds it to an owned call record.
  Future<CustomerCallModel> uploadAndAttachRecording({
    required String callRecord,
    required String filePath,
    String? fileName,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    _required(callRecord, 'Call record is required.');
    _required(filePath, 'Recording file is required.');

    final resolvedName = fileName?.trim().isNotEmpty == true
        ? fileName!.trim()
        : filePath.split(RegExp(r'[/\\]')).last;

    try {
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          filename: resolvedName,
        ),
        'is_private': 1,
        'doctype': 'Customer Call Record',
        'docname': callRecord.trim(),
        'fieldname': 'recording_file',
      });

      // ApiService already adds the authenticated user's token.
      final response = await _api.dio.post(
        ApiEndpoints.uploadFile,
        data: form,
        options: Options(contentType: Headers.multipartFormDataContentType),
        onSendProgress: onSendProgress,
      );
      final uploaded = _unwrap(response.data);
      final fileUrl = _string(uploaded['file_url']);
      if (fileUrl.isEmpty) {
        throw const CustomerCallServiceException(
          'The server did not return the uploaded recording URL.',
        );
      }
      return attachRecording(callRecord: callRecord, fileUrl: fileUrl);
    } on DioException catch (error) {
      throw CustomerCallServiceException(_dioMessage(error));
    } on CustomerCallServiceException {
      rethrow;
    } catch (error) {
      throw CustomerCallServiceException(_cleanError(error));
    }
  }

  Future<CustomerCallModel> attachRecording({
    required String callRecord,
    required String fileUrl,
  }) async {
    _required(callRecord, 'Call record is required.');
    _required(fileUrl, 'Recording file URL is required.');
    final data = await _post(
      ApiEndpoints.attachCustomerCallRecording,
      body: {
        'call_record': callRecord.trim(),
        'file_url': fileUrl.trim(),
      },
    );
    return CustomerCallModel.fromJson(_map(data['call']));
  }

  Future<CustomerCallModel> removeRecording(String callRecord) async {
    _required(callRecord, 'Call record is required.');
    final data = await _post(
      ApiEndpoints.removeCustomerCallRecording,
      body: {'call_record': callRecord.trim()},
    );
    return CustomerCallModel.fromJson(_map(data['call']));
  }

  Future<Map<String, dynamic>> _get(
    String url, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final response = await _api.get(url: url, queryParameters: query);
      return _unwrap(response.data);
    } on DioException catch (error) {
      throw CustomerCallServiceException(_dioMessage(error));
    } on CustomerCallServiceException {
      rethrow;
    } catch (error) {
      throw CustomerCallServiceException(_cleanError(error));
    }
  }

  Future<Map<String, dynamic>> _post(
    String url, {
    required Map<String, dynamic> body,
    bool allowBusinessFailure = false,
  }) async {
    try {
      final response = await _api.post(url: url, data: body);
      return _unwrap(
        response.data,
        allowBusinessFailure: allowBusinessFailure,
      );
    } on DioException catch (error) {
      throw CustomerCallServiceException(_dioMessage(error));
    } on CustomerCallServiceException {
      rethrow;
    } catch (error) {
      throw CustomerCallServiceException(_cleanError(error));
    }
  }

  Map<String, dynamic> _unwrap(
    dynamic value, {
    bool allowBusinessFailure = false,
  }) {
    var root = _map(value);
    if (root['message'] is Map) root = _map(root['message']);

    if (!allowBusinessFailure && root['success'] == false) {
      throw CustomerCallServiceException(
        _string(root['message'], fallback: 'Unable to complete the request.'),
      );
    }
    return root;
  }

  void _validateCall(CustomerCallCreateModel call) {
    _required(call.customer, 'Customer is required.');
    _required(call.phoneNumber, 'Phone number is required.');
    _required(call.idempotencyKey, 'Idempotency key is required.');
    if (call.idempotencyKey.trim().length > 140) {
      throw const CustomerCallServiceException(
        'Idempotency key cannot exceed 140 characters.',
      );
    }
    if (call.durationSeconds < 0 || call.durationSeconds > 86400) {
      throw const CustomerCallServiceException('Call duration is invalid.');
    }
    if (call.callDateTime.isAfter(DateTime.now().add(const Duration(minutes: 10)))) {
      throw const CustomerCallServiceException(
        'Call date and time cannot be in the future.',
      );
    }
  }

  void _required(String value, String message) {
    if (value.trim().isEmpty) throw CustomerCallServiceException(message);
  }

  static Map<String, dynamic> _map(dynamic value) {
    return value is Map
        ? Map<String, dynamic>.from(value)
        : <String, dynamic>{};
  }

  static String _string(dynamic value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static String _formatDate(DateTime value) {
    String two(int number) => number.toString().padLeft(2, '0');
    return '${value.year.toString().padLeft(4, '0')}-'
        '${two(value.month)}-${two(value.day)}';
  }

  static String _dioMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      final serverMessages = data['_server_messages'];
      if (serverMessages is String && serverMessages.isNotEmpty) {
        try {
          final messages = jsonDecode(serverMessages);
          if (messages is List && messages.isNotEmpty) {
            final first = jsonDecode(messages.first.toString());
            if (first is Map && first['message'] != null) {
              return _stripHtml(first['message'].toString());
            }
          }
        } catch (_) {}
      }

      final wrapped = data['message'];
      if (wrapped is Map && wrapped['message'] != null) {
        return _stripHtml(wrapped['message'].toString());
      }
      if (wrapped is String && wrapped.trim().isNotEmpty) {
        return _stripHtml(wrapped);
      }
      if (data['exception'] != null) {
        return data['exception']
            .toString()
            .split('\n')
            .first
            .replaceFirst(RegExp(r'^[\w.]+:\s*'), '');
      }
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'The customer-call request timed out. Please try again.';
      case DioExceptionType.connectionError:
        return 'Unable to connect to the server.';
      default:
        return error.message ?? 'Unable to complete the customer-call request.';
    }
  }

  static String _stripHtml(String value) {
    return value.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  static String _cleanError(Object error) {
    return error
        .toString()
        .replaceFirst(RegExp(r'^CustomerCallServiceException:\s*'), '');
  }
}

class CustomerCallServiceException implements Exception {
  final String message;
  final int? statusCode;

  const CustomerCallServiceException(this.message, {this.statusCode});

  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;

  @override
  String toString() => message;
}
