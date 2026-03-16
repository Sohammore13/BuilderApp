import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';

import 'package:http_parser/http_parser.dart';

// 1. Go to cloudinary.com and create free account
// 2. Dashboard → Settings → Upload → Add upload preset
// 3. Set preset as "Unsigned"
// 4. Copy your Cloud Name and Upload Preset name
// 5. Replace YOUR_CLOUD_NAME and YOUR_UPLOAD_PRESET in this file

class CloudinaryService {
  final String cloudName = 'dzcqxvwnz';
  final String uploadPreset = 'Builder';

  Future<String?> uploadImage(Uint8List imageBytes, String fileName) async {
    try {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: fileName,
        ));

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonResult = json.decode(responseData);
        return jsonResult['secure_url'];
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<String?> uploadPDF(Uint8List pdfBytes, String fileName) async {
    try {
      // For raw files like PDFs, Cloudinary requires the /raw/upload endpoint.
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/raw/upload');
      
      // Ensure the filename has a .pdf extension
      final String finalFileName = fileName.toLowerCase().endsWith('.pdf') 
          ? fileName 
          : '$fileName.pdf';

      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          pdfBytes,
          filename: finalFileName,
          contentType: MediaType('application', 'pdf'),
        ));

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonResult = json.decode(responseData);
        
        // Return the secure URL exactly as Cloudinary provides it
        return jsonResult['secure_url'];
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}
