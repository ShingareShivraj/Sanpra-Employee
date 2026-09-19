import 'dart:convert';

import 'package:dio/dio.dart';

import '../model/lead_model.dart';
import 'api_endpoints.dart';
import 'api_service.dart';

class LeadService {
  final ApiService _api;

  LeadService({ApiService? api}) : _api = api ?? ApiService();

  Future<LeadMasterDataModel> getMasterData() async {
    final response = await _get(ApiEndpoints.leadDetails);
    return LeadMasterDataModel.fromJson(response.data);
  }

  Future<LeadPageModel> getLeads({
    String? search,
    String? status,
    String? territory,
    int page = 1,
    int pageLength = 20,
  }) async {
    final response = await _get(
      ApiEndpoints.leads,
      query: {
        if (search?.trim().isNotEmpty == true) 'search': search!.trim(),
        if (status?.trim().isNotEmpty == true) 'status': status!.trim(),
        if (territory?.trim().isNotEmpty == true)
          'territory': territory!.trim(),
        'page': page < 1 ? 1 : page,
        'page_length': pageLength.clamp(1, 100),
      },
    );
    return LeadPageModel.fromJson(response.data);
  }

  Future<LeadModel> getLead(String leadName) async {
    _required(leadName, 'Lead is required.');
    final response = await _get(
      ApiEndpoints.leadDetail,
      query: {'lead': leadName.trim()},
    );
    return LeadModel.fromJson(response.data);
  }

  Future<LeadMutationResultModel> createLead(LeadModel lead) async {
    _validateLead(lead);
    final response = await _post(
      ApiEndpoints.createLead,
      data: lead.toWriteJson(),
    );
    return _leadMutation(response);
  }

  Future<LeadMutationResultModel> updateLead(LeadModel lead) async {
    _required(lead.name, 'Lead is required.');
    _validateLead(lead);

    final leadId = lead.name.trim();

    final payload = {
      ...lead.toWriteJson(includeEmptyValues: true),
      'name': leadId,
      'lead': leadId,
    };

    final response = await _post(
      ApiEndpoints.updateLead,
      data: payload,
    );

    return _leadMutation(response);
  }


  Future<LeadDeleteResultModel> deleteLead(String leadName) async {
    _required(leadName, 'Lead is required.');
    final response = await _post(
      ApiEndpoints.deleteLead,
      data: {'lead': leadName.trim()},
    );
    return LeadDeleteResultModel(
      message: response.message,
      id: _string(response.data['lead_id'], fallback: leadName.trim()),
    );
  }

  Future<LeadEventListModel> getLeadEvents(String leadName) async {
    _required(leadName, 'Lead is required.');
    final response = await _get(
      ApiEndpoints.leadEvents,
      query: {'lead': leadName.trim()},
    );
    return LeadEventListModel.fromJson(response.data);
  }

  Future<LeadEventModel> getLeadEvent(String eventName) async {
    _required(eventName, 'Event is required.');
    final response = await _get(
      ApiEndpoints.leadEvent,
      query: {'event': eventName.trim()},
    );
    return LeadEventModel.fromJson(response.data);
  }

  Future<LeadEventMutationResultModel> createLeadEvent({
    required String leadName,
    required LeadEventModel event,
  }) async {
    _required(leadName, 'Lead is required.');
    _validateEvent(event);
    final response = await _post(
      ApiEndpoints.createLeadEvent,
      data: {
        'lead': leadName.trim(),
        ...event.toWriteJson(includeNullDates: false),
      },
    );
    return _eventMutation(response, fallbackLeadId: leadName.trim());
  }

  Future<LeadEventMutationResultModel> updateLeadEvent(
    LeadEventModel event,
  ) async {
    _required(event.name, 'Event is required.');
    _validateEvent(event);
    final response = await _post(
      ApiEndpoints.updateLeadEvent,
      data: {
        'event': event.name.trim(),
        ...event.toWriteJson(
          includeEmptyValues: true,
          includeNullDates: false,
        ),
      },
    );
    return _eventMutation(response, fallbackLeadId: event.leadId);
  }

  Future<LeadDeleteResultModel> deleteLeadEvent(String eventName) async {
    _required(eventName, 'Event is required.');
    final response = await _post(
      ApiEndpoints.deleteLeadEvent,
      data: {'event': eventName.trim()},
    );
    return LeadDeleteResultModel(
      message: response.message,
      id: _string(response.data['event_id'], fallback: eventName.trim()),
    );
  }

  LeadMutationResultModel _leadMutation(_LeadEnvelope response) {
    final leadJson = _map(response.data['lead']);
    final lead = LeadModel.fromJson(leadJson);
    return LeadMutationResultModel(
      message: response.message,
      leadId: _string(
        response.data['lead_id'],
        fallback: lead.name,
      ),
      company: _string(response.data['company'], fallback: lead.company),
      lead: lead,
    );
  }

  LeadEventMutationResultModel _eventMutation(
    _LeadEnvelope response, {
    required String fallbackLeadId,
  }) {
    final eventJson = _map(response.data['event']);
    final leadId = _string(
      response.data['lead_id'],
      fallback: fallbackLeadId,
    );
    final event = LeadEventModel.fromJson({...eventJson, 'lead_id': leadId});
    return LeadEventMutationResultModel(
      message: response.message,
      eventId: _string(
        response.data['event_id'],
        fallback: event.name,
      ),
      leadId: leadId,
      company: _string(response.data['company']),
      event: event,
    );
  }

  Future<_LeadEnvelope> _get(
    String url, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final response = await _api.get(url: url, queryParameters: query);
      return _parseEnvelope(response.data);
    } on DioException catch (error) {
      throw LeadServiceException(_dioMessage(error));
    } on LeadServiceException {
      rethrow;
    } catch (error) {
      throw LeadServiceException(_cleanError(error));
    }
  }

  Future<_LeadEnvelope> _post(
    String url, {
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _api.post(url: url, data: data);
      return _parseEnvelope(response.data);
    } on DioException catch (error) {
      throw LeadServiceException(_dioMessage(error));
    } on LeadServiceException {
      rethrow;
    } catch (error) {
      throw LeadServiceException(_cleanError(error));
    }
  }

  _LeadEnvelope _parseEnvelope(dynamic value) {
    var root = _map(value);
    if (root['message'] is Map) root = _map(root['message']);

    final statusCode = _integer(
      root['status_code'] ?? root['statusCode'] ?? root['status'] ?? root['code'],
      fallback: root['success'] == false ? 400 : 200,
    );
    final message = _string(
      root['message'],
      fallback: statusCode >= 200 && statusCode < 300
          ? 'Request completed successfully.'
          : 'Unable to complete the Lead request.',
    );
    final dataValue = root['data'];
    final data = dataValue is Map
        ? Map<String, dynamic>.from(dataValue)
        : <String, dynamic>{};

    if (statusCode < 200 || statusCode >= 300 || root['success'] == false) {
      throw LeadServiceException(_stripHtml(message), statusCode: statusCode);
    }
    return _LeadEnvelope(
      statusCode: statusCode,
      message: message,
      data: data,
    );
  }

  void _validateLead(LeadModel lead) {
    _required(lead.leadName, 'Lead name is required.');
    if (lead.emailId.isNotEmpty &&
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(lead.emailId.trim())) {
      throw const LeadServiceException('Enter a valid email address.');
    }
  }

  void _validateEvent(LeadEventModel event) {
    _required(event.subject, 'Event subject is required.');
    if (event.startsOn == null) {
      throw const LeadServiceException('Event start date and time are required.');
    }
    if (event.endsOn != null && event.endsOn!.isBefore(event.startsOn!)) {
      throw const LeadServiceException(
        'Event end date and time cannot be before its start.',
      );
    }
  }

  void _required(String value, String message) {
    if (value.trim().isEmpty) throw LeadServiceException(message);
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

  static int _integer(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static String _dioMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      final serverMessages = data['_server_messages'];
      if (serverMessages is String && serverMessages.isNotEmpty) {
        try {
          final decoded = jsonDecode(serverMessages);
          if (decoded is List && decoded.isNotEmpty) {
            final first = jsonDecode(decoded.first.toString());
            if (first is Map && first['message'] != null) {
              return _stripHtml(first['message'].toString());
            }
          }
        } catch (_) {}
      }
      final wrapped = data['message'];
      if (wrapped is Map) {
        final responseMessage = wrapped['message'];
        if (responseMessage is String && responseMessage.trim().isNotEmpty) {
          return _stripHtml(responseMessage);
        }
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
        return 'The Lead request timed out. Please try again.';
      case DioExceptionType.connectionError:
        return 'Unable to connect to the server.';
      default:
        return error.message ?? 'Unable to complete the Lead request.';
    }
  }

  static String _stripHtml(String value) {
    return value.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  static String _cleanError(Object error) {
    return error
        .toString()
        .replaceFirst(RegExp(r'^LeadServiceException:\s*'), '');
  }
}

class _LeadEnvelope {
  final int statusCode;
  final String message;
  final Map<String, dynamic> data;

  const _LeadEnvelope({
    required this.statusCode,
    required this.message,
    required this.data,
  });
}

class LeadServiceException implements Exception {
  final String message;
  final int? statusCode;

  const LeadServiceException(this.message, {this.statusCode});

  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;

  @override
  String toString() => message;
}
