import 'dart:convert';

import 'package:dio/dio.dart';

import '../model/knowledge_hub/knowledge_resource_member_model.dart';
import '../model/knowledge_hub/knowledge_resource_model.dart';
import '../model/knowledge_hub/knowledge_resource_type.dart';
import 'api_endpoints.dart';
import 'api_service.dart';

class KnowledgeHubService {
  final ApiService _api;

  KnowledgeHubService({ApiService? api}) : _api = api ?? ApiService();

  Future<KnowledgeAccessModel> getAccess() async {
    final data = await _get(ApiEndpoints.knowledgeAccess);
    return KnowledgeAccessModel.fromJson(data);
  }

  Future<KnowledgeResourcesResponseModel> getResources({
    String? search,
    KnowledgeResourceType? resourceType,
    KnowledgeResourceStatus? status,
    bool mineOnly = false,
    int start = 0,
    int pageLength = 20,
  }) async {
    final data = await _get(
      ApiEndpoints.knowledgeResources,
      query: {
        if (search?.trim().isNotEmpty == true) 'search': search!.trim(),
        if (resourceType != null) 'resource_type': resourceType.apiValue,
        if (status != null) 'status': status.apiValue,
        'mine_only': mineOnly ? 1 : 0,
        'start': start < 0 ? 0 : start,
        'page_length': pageLength.clamp(1, 100),
      },
    );
    return KnowledgeResourcesResponseModel.fromJson(data);
  }

  Future<KnowledgeResourceModel> getResource(String resourceName) async {
    _required(resourceName, 'Knowledge resource is required.');
    final data = await _get(
      ApiEndpoints.knowledgeResource,
      query: {'resource_name': resourceName.trim()},
    );
    return KnowledgeResourceResponseModel.fromJson(data).resource;
  }

  Future<KnowledgeResourceModel> createResource({
    required String resourceTitle,
    required KnowledgeResourceType resourceType,
    required String description,
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
    List<KnowledgeResourceMemberModel> teamMembers = const [],
    bool submitForReview = true,
    bool publishNow = false,
  }) async {
    _validateCore(resourceTitle, description);
    final data = await _post(
      ApiEndpoints.createKnowledgeResource,
      data: _resourcePayload(
        resourceTitle: resourceTitle,
        resourceType: resourceType,
        description: description,
        url: url,
        githubUrl: githubUrl,
        documentationUrl: documentationUrl,
        attachment: attachment,
        thumbnail: thumbnail,
        tags: tags,
        technologies: technologies,
        projectDescription: projectDescription,
        projectBuild: projectBuild,
        projectScreenshots: projectScreenshots,
        teamMembers: teamMembers,
        submitForReview: submitForReview,
        publishNow: publishNow,
      ),
    );
    return KnowledgeResourceResponseModel.fromJson(data).resource;
  }

  Future<KnowledgeResourceModel> updateResource({
    required String resourceName,
    required String resourceTitle,
    required KnowledgeResourceType resourceType,
    required String description,
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
    List<KnowledgeResourceMemberModel> teamMembers = const [],
    bool submitForReview = false,
  }) async {
    _required(resourceName, 'Knowledge resource is required.');
    _validateCore(resourceTitle, description);
    final data = await _post(
      ApiEndpoints.updateKnowledgeResource,
      data: {
        'resource_name': resourceName.trim(),
        ..._resourcePayload(
          resourceTitle: resourceTitle,
          resourceType: resourceType,
          description: description,
          url: url,
          githubUrl: githubUrl,
          documentationUrl: documentationUrl,
          attachment: attachment,
          thumbnail: thumbnail,
          tags: tags,
          technologies: technologies,
          projectDescription: projectDescription,
          projectBuild: projectBuild,
          projectScreenshots: projectScreenshots,
          teamMembers: teamMembers,
          submitForReview: submitForReview,
        ),
      },
    );
    return KnowledgeResourceResponseModel.fromJson(data).resource;
  }

  Future<KnowledgeResourceModel> submitForReview(String resourceName) async {
    return _resourceAction(
      ApiEndpoints.submitKnowledgeForReview,
      resourceName,
    );
  }

  Future<KnowledgeResourceModel> publishResource(String resourceName) async {
    return _resourceAction(
      ApiEndpoints.publishKnowledgeResource,
      resourceName,
    );
  }

  Future<KnowledgeResourceModel> rejectResource(String resourceName) async {
    return _resourceAction(
      ApiEndpoints.rejectKnowledgeResource,
      resourceName,
    );
  }

  Future<KnowledgeResourceModel> reviewResource({
    required String resourceName,
    required KnowledgeReviewAction action,
  }) async {
    _required(resourceName, 'Knowledge resource is required.');
    final data = await _post(
      ApiEndpoints.reviewKnowledgeResource,
      data: {
        'resource_name': resourceName.trim(),
        'action': action == KnowledgeReviewAction.publish ? 'Publish' : 'Reject',
      },
    );
    return KnowledgeResourceResponseModel.fromJson(data).resource;
  }

  Future<void> deleteResource(String resourceName) async {
    _required(resourceName, 'Knowledge resource is required.');
    await _post(
      ApiEndpoints.deleteKnowledgeResource,
      data: {'resource_name': resourceName.trim()},
    );
  }

  /// Uploads through Frappe's standard upload_file endpoint.
  ///
  /// Pass [resourceName] and [fieldName] when updating an existing resource so
  /// private files are attached to that Knowledge Hub Resource document.
  Future<String> uploadFile({
    required String filePath,
    required String fileName,
    String? resourceName,
    String? fieldName,
    bool isPrivate = true,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    _required(filePath, 'File path is required.');
    _required(fileName, 'File name is required.');
    if ((resourceName == null) != (fieldName == null)) {
      throw const KnowledgeHubServiceException(
        'Resource name and field name must be provided together.',
      );
    }

    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
        'is_private': isPrivate ? 1 : 0,
        if (resourceName?.trim().isNotEmpty == true)
          'doctype': 'Knowledge Hub Resource',
        if (resourceName?.trim().isNotEmpty == true)
          'docname': resourceName!.trim(),
        if (fieldName?.trim().isNotEmpty == true) 'fieldname': fieldName!.trim(),
      });
      final response = await _api.dio.post(
        ApiEndpoints.uploadFile,
        data: formData,
        options: Options(contentType: Headers.multipartFormDataContentType),
        onSendProgress: onSendProgress,
      );
      final data = _unwrapMessage(response.data);
      final fileUrl = data['file_url']?.toString().trim() ?? '';
      if (fileUrl.isEmpty) {
        throw const KnowledgeHubServiceException(
          'File upload did not return a file URL.',
        );
      }
      return fileUrl;
    } on DioException catch (error) {
      throw KnowledgeHubServiceException(_dioMessage(error));
    } on KnowledgeHubServiceException {
      rethrow;
    } catch (error) {
      throw KnowledgeHubServiceException(_cleanError(error));
    }
  }

  Future<KnowledgeResourceModel> _resourceAction(
    String endpoint,
    String resourceName,
  ) async {
    _required(resourceName, 'Knowledge resource is required.');
    final data = await _post(
      endpoint,
      data: {'resource_name': resourceName.trim()},
    );
    return KnowledgeResourceResponseModel.fromJson(data).resource;
  }

  Map<String, dynamic> _resourcePayload({
    required String resourceTitle,
    required KnowledgeResourceType resourceType,
    required String description,
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
    required List<KnowledgeResourceMemberModel> teamMembers,
    required bool submitForReview,
    bool publishNow = false,
  }) {
    return {
      'resource_title': resourceTitle.trim(),
      'resource_type': resourceType.apiValue,
      'description': description.trim(),
      'url': url?.trim() ?? '',
      'github_url': githubUrl?.trim() ?? '',
      'documentation_url': documentationUrl?.trim() ?? '',
      'attachment': attachment?.trim() ?? '',
      'thumbnail': thumbnail?.trim() ?? '',
      'tags': tags?.trim() ?? '',
      'technologies': technologies?.trim() ?? '',
      'project_description': projectDescription?.trim() ?? '',
      'project_build': projectBuild?.trim() ?? '',
      'project_screenshots': projectScreenshots?.trim() ?? '',
      'team_members': teamMembers.map((member) => member.toJson()).toList(),
      'submit_for_review': submitForReview ? 1 : 0,
      if (publishNow) 'publish_now': 1,
    };
  }

  Future<Map<String, dynamic>> _get(
    String url, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final response = await _api.get(url: url, queryParameters: query);
      return _requireSuccess(_unwrapMessage(response.data));
    } on DioException catch (error) {
      throw KnowledgeHubServiceException(_dioMessage(error));
    } on KnowledgeHubServiceException {
      rethrow;
    } catch (error) {
      throw KnowledgeHubServiceException(_cleanError(error));
    }
  }

  Future<Map<String, dynamic>> _post(
    String url, {
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _api.post(url: url, data: data);
      return _requireSuccess(_unwrapMessage(response.data));
    } on DioException catch (error) {
      throw KnowledgeHubServiceException(_dioMessage(error));
    } on KnowledgeHubServiceException {
      rethrow;
    } catch (error) {
      throw KnowledgeHubServiceException(_cleanError(error));
    }
  }

  Map<String, dynamic> _unwrapMessage(dynamic value) {
    final root = _map(value);
    return root['message'] is Map ? _map(root['message']) : root;
  }

  Map<String, dynamic> _requireSuccess(Map<String, dynamic> data) {
    if (data['success'] == false) {
      throw KnowledgeHubServiceException(
        data['message']?.toString().trim().isNotEmpty == true
            ? data['message'].toString()
            : 'Unable to complete the Knowledge Hub request.',
      );
    }
    return data;
  }

  Map<String, dynamic> _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  void _validateCore(String title, String description) {
    _required(title, 'Resource title is required.');
    _required(description, 'Description is required.');
  }

  void _required(String value, String message) {
    if (value.trim().isEmpty) throw KnowledgeHubServiceException(message);
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

      final message = data['message'];
      if (message is Map && message['message'] != null) {
        return _stripHtml(message['message'].toString());
      }
      if (message is String && message.trim().isNotEmpty) {
        return _stripHtml(message);
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
        return 'The Knowledge Hub request timed out. Please try again.';
      case DioExceptionType.connectionError:
        return 'Unable to connect to the server.';
      default:
        return error.message ?? 'Unable to complete the Knowledge Hub request.';
    }
  }

  static String _stripHtml(String value) =>
      value.replaceAll(RegExp(r'<[^>]*>'), '').trim();

  static String _cleanError(Object error) =>
      error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
}

enum KnowledgeReviewAction { publish, reject }

class KnowledgeHubServiceException implements Exception {
  final String message;

  const KnowledgeHubServiceException(this.message);

  @override
  String toString() => message;
}

