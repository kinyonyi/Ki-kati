// lib/services/http_service.dart
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ki_kati/components/secureStorageServices.dart';
import 'package:http_parser/http_parser.dart';
import 'package:dio/dio.dart';
import 'package:mime/mime.dart';

class HttpService {
  Dio dio = Dio(); // Create an instance of Dio

  final String baseUrl;
  SecureStorageService storageService = SecureStorageService();

  HttpService(this.baseUrl);

  // Generic GET method
  Future<dynamic> get(String endpoint) async {
    // Retrieve user data using the key 'user_data'
    Map<String, dynamic>? retrievedUserData =
        await storageService.retrieveData('user_data');

    final url = Uri.parse('$baseUrl$endpoint');
    Map<String, String> headers = {};
    print(url);

    final token = retrievedUserData?['token'];

    if (token != null) {
      headers['Authorization'] =
          'Bearer $token'; // Add authorization header if token is available
    }

    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Generic POST method
  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl$endpoint');

    Map<String, dynamic>? retrievedUserData =
        await storageService.retrieveData('user_data');
    final token = retrievedUserData?['token'];

    // Set headers
    Map<String, String> headers = {
      'Content-Type': 'application/json',
    };

    // Add authorization header if token is available
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      // Check if the data contains media (files) for multipart upload
      if (data.containsKey('media') && data['media'] is List<File>) {
        // Create a MultipartRequest for file uploads
        var request = http.MultipartRequest('POST', url);

        // Add headers to the multipart request
        request.headers.addAll(headers);

        // Add the non-file fields as part of the request body
        data.forEach((key, value) {
          if (key != 'media') {
            request.fields[key] = value.toString();
          }
        });

        print(data);

        List<File> files = List<File>.from(data['media']);

        for (var file in files) {
          // Extract mime type using 'mime' package
          String mimeType = lookupMimeType(file.path) ??
              'application/octet-stream'; // Default mime type

          // Open the file and create a MultipartFile
          var fileStream = http.ByteStream(file.openRead());
          var fileLength = await file.length();
          var multipartFile = http.MultipartFile(
            'media', // Field name expected by backend
            fileStream,
            fileLength,
            filename: file.uri.pathSegments.last,
            contentType: MediaType.parse(mimeType),
          );

          // Add the file to the request
          request.files.add(multipartFile);
        }

        // Send the multipart request and get the response
        final response = await request.send();

        // Read the response and return it
        final responseBody = await response.stream.bytesToString();
        if (response.statusCode >= 200 && response.statusCode <= 299) {
          return {
            'statusCode': response.statusCode,
            'body': jsonDecode(responseBody),
          };
        } else {
          throw Exception(
              'Failed to post data: ${response.statusCode}, Body: $responseBody');
        }
      } else {
        // Normal POST request when no files are included (JSON body)
        final response = await http.post(
          url,
          headers: headers,
          body: json.encode(data),
        );

        if (response.statusCode >= 200 && response.statusCode <= 500) {
          return {
            'statusCode': response.statusCode,
            'body': jsonDecode(response.body),
          };
        } else {
          throw Exception('Failed to post data: ${response.statusCode}');
        }
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Generic PUT method
  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl$endpoint');

    Map<String, dynamic>? retrievedUserData =
        await storageService.retrieveData('user_data');
    final token = retrievedUserData?['token'];

    Map<String, String> headers = {
      'Content-Type': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final response = await http.put(
        url,
        headers: headers,
        body: json.encode(data),
      );

      if (response.statusCode >= 200 && response.statusCode <= 500) {
        return {
          'statusCode': response.statusCode,
          'body': jsonDecode(response.body),
        };
      } else {
        throw Exception('Failed to update data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Generic DELETE method
  Future<dynamic> delete(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    Map<String, String> headers = {};

    Map<String, dynamic>? retrievedUserData =
        await storageService.retrieveData('user_data');
    final token = retrievedUserData?['token'];

    if (token != null) {
      headers['Authorization'] =
          'Bearer $token'; // Add authorization header if token is available
    }

    try {
      final response = await http.delete(url, headers: headers);

      if (response.statusCode == 200 || response.statusCode == 204) {
        return {
          'statusCode': response.statusCode,
          'body': jsonDecode(response.body),
        };
      } else {
        throw Exception('Failed to delete data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<dynamic> postdio(String endpoint, Map<String, dynamic> data) async {
    final url = '$baseUrl$endpoint';

    // Retrieve user data for authorization
    Map<String, dynamic>? retrievedUserData =
        await storageService.retrieveData('user_data');
    final token = retrievedUserData?['token'];

    // Set headers
    Options options = Options(
      headers: {
        //'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    try {
      if (data.containsKey('media') && data['media'] is List<File>) {
        // Prepare multipart request
        FormData formData = FormData();

        // Add non-file data to the form
        data.forEach((key, value) {
          if (key != 'media') {
            formData.fields.add(MapEntry(key, value.toString()));
          }
        });

        // Add files to the form
        List<File> files = List<File>.from(data['media']);
        for (var file in files) {
          String? mimeType = lookupMimeType(file.path);

          // If mimeType is null (unable to detect), set a default mime type
          mimeType = mimeType ?? 'application/octet-stream';

          int fileSizeInBytes = await file.length();
          print(fileSizeInBytes);

          // For example, if you want to limit file size to 50MB:
          if (fileSizeInBytes > 50 * 1024 * 1024) {
            throw Exception('File is too large');
          }

          formData.files.add(MapEntry(
            'media', // The name of the field in your backend
            await MultipartFile.fromFile(file.path,
                contentType: MediaType.parse(mimeType)),
          ));
        }

        // Set 'Content-Type' as 'multipart/form-data' for the request
        options.headers!['Content-Type'] = 'multipart/form-data';

        // Make the POST request with multipart data

        print("FormData fields:");
        for (var field in formData.fields) {
          print("${field.key}: ${field.value}");
        }

        print("FormData files:");
        for (var file in formData.files) {
          print(
              "${file.key}: ${file.value.filename} (size: ${file.value.length} bytes)");
        }

        print("performing the post request now");
        Response response =
            await dio.post(url, data: formData, options: options);

        print("This is the response");
        print(response);

        // Check for successful response (2xx range)
        if (response.statusCode != null &&
            response.statusCode! >= 200 &&
            response.statusCode! < 300) {
          return {
            'statusCode': response.statusCode,
            'body': response.data,
          };
        } else {
          // Handle unexpected response codes (client/server errors)
          return {
            'statusCode': response.statusCode,
            'body': response.data ?? 'Unknown error',
            'error': 'Failed with status code: ${response.statusCode}'
          };
        }
      } else {
        // Set 'Content-Type' as 'application/json'
        options.headers!['Content-Type'] = 'application/json';
        // Regular POST request (without files)
        Response response =
            await dio.post(url, data: json.encode(data), options: options);

        return {
          'statusCode': response.statusCode,
          'body': response.data,
        };
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}




/*
  // Generic POST method
  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl$endpoint');

    print("Hello Dave, this is the message!");
    print(data);

    Map<String, dynamic>? retrievedUserData =
        await storageService.retrieveData('user_data');
    final token = retrievedUserData?['token'];

    Map<String, String> headers = {
      'Content-Type': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] =
          'Bearer $token'; // Add authorization header if token is available
    }
    try {
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode(data),
      );
      // Return a map with the status code and body regardless of the outcome

      /*return {
        'statusCode': response.statusCode,
        'body': jsonDecode(response.body),
      };
      */
      if (response.statusCode >= 200 && response.statusCode <= 500) {
        return {
          'statusCode': response.statusCode,
          'body': jsonDecode(response.body),
        };
      } else {
        throw Exception('Failed to post data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
*/
