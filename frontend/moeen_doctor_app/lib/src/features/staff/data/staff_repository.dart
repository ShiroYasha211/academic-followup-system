import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';

class StaffRepository {
  const StaffRepository(this._api);

  final ApiClient _api;

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) {
    return _api.get(path, queryParameters: query);
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> data) {
    return _api.post(path, data: data);
  }

  Future<Map<String, dynamic>> put(String path, Map<String, dynamic> data) {
    return _api.put(path, data: data);
  }

  Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> data) {
    return _api.patch(path, data: data);
  }

  Future<Map<String, dynamic>> delete(String path) {
    return _api.delete(path);
  }

  Future<Map<String, dynamic>> upload(
    String path,
    Map<String, dynamic> fields,
  ) {
    return _api.post(path, data: FormData.fromMap(fields));
  }

  Future<Map<String, dynamic>> uploadPut(
    String path,
    Map<String, dynamic> fields,
  ) {
    return _api.post(path, data: FormData.fromMap({...fields, '_method': 'PUT'}));
  }

  Future<List<int>> download(String path, {Map<String, dynamic>? query}) {
    return _api.getBytes(path, queryParameters: query);
  }
}
