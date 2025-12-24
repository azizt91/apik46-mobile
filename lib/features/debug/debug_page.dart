import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:apik_mobile/core/constants/api_constants.dart';

class DebugPage extends StatefulWidget {
  const DebugPage({super.key});

  @override
  State<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  String _tokenStatus = 'Checking...';
  String _apiResponse = 'Not tested yet';
  String _fullToken = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkToken();
  }

  Future<void> _checkToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    setState(() {
      if (token != null && token.isNotEmpty) {
        _tokenStatus = 'Token EXISTS (${token.length} chars)';
        _fullToken = token;
      } else {
        _tokenStatus = 'Token is NULL or EMPTY';
        _fullToken = '';
      }
    });
  }

  Future<void> _testDashboardApi() async {
    setState(() {
      _isLoading = true;
      _apiResponse = 'Loading...';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final dio = Dio();
      dio.options.baseUrl = ApiConstants.baseUrl;
      dio.options.headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

      final response = await dio.get(
        ApiConstants.dashboard,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      setState(() {
        _apiResponse = 'Status: ${response.statusCode}\n\n'
            'Response:\n${_prettyJson(response.data)}';
      });
    } on DioException catch (e) {
      setState(() {
        _apiResponse = 'DioException: ${e.type}\n'
            'Message: ${e.message}\n'
            'Status: ${e.response?.statusCode}\n'
            'Response: ${e.response?.data}';
      });
    } catch (e) {
      setState(() {
        _apiResponse = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _prettyJson(dynamic json) {
    try {
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(json);
    } catch (e) {
      return json.toString();
    }
  }

  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    _checkToken();
    setState(() {
      _apiResponse = 'Token cleared';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Info'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Token Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TOKEN STATUS',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(_tokenStatus,
                        style: TextStyle(
                          color: _tokenStatus.contains('EXISTS')
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                        )),
                    if (_fullToken.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Text('Token (tap to copy):',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: _fullToken));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Token copied!')),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _fullToken,
                            style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // API Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('API INFO',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text('Base URL: ${ApiConstants.baseUrl}'),
                    Text('Dashboard: ${ApiConstants.dashboard}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _testDashboardApi,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Test Dashboard API'),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _checkToken,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Refresh'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _clearToken,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Clear Token (Logout)'),
              ),
            ),
            const SizedBox(height: 16),

            // API Response Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('API RESPONSE',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: SelectableText(
                        _apiResponse,
                        style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class JsonEncoder {
  final String indent;
  const JsonEncoder.withIndent(this.indent);
  
  String convert(dynamic object) {
    return _encode(object, 0);
  }
  
  String _encode(dynamic object, int level) {
    final prefix = indent * level;
    final childPrefix = indent * (level + 1);
    
    if (object == null) return 'null';
    if (object is bool || object is num) return object.toString();
    if (object is String) return '"$object"';
    
    if (object is List) {
      if (object.isEmpty) return '[]';
      final items = object.map((e) => '$childPrefix${_encode(e, level + 1)}').join(',\n');
      return '[\n$items\n$prefix]';
    }
    
    if (object is Map) {
      if (object.isEmpty) return '{}';
      final items = object.entries
          .map((e) => '$childPrefix"${e.key}": ${_encode(e.value, level + 1)}')
          .join(',\n');
      return '{\n$items\n$prefix}';
    }
    
    return object.toString();
  }
}
