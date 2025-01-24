import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UploadMedicalReportPage extends StatefulWidget {
  const UploadMedicalReportPage({super.key});

  @override
  State<UploadMedicalReportPage> createState() =>
      _UploadMedicalReportPageState();
}

class _UploadMedicalReportPageState extends State<UploadMedicalReportPage> {
  String? _filePath;
  String _statusMessage = "Select a file to upload.";
  String? _encryptionKey;
  String? _cid;
  String? _originalFileName;

  final String dappUrl = 'https://solanablockchain.netlify.app';
  final String refUrl = 'https://example.com';

  Future<void> _requestStoragePermission() async {
    if (!await Permission.manageExternalStorage.isGranted) {
      await Permission.manageExternalStorage.request();
    }
  }

  Future<void> _selectFile() async {
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result != null && result.files.single.path != null) {
        setState(() {
          _filePath = result.files.single.path;
          _originalFileName = result.files.single.name;
          _statusMessage = "File selected: ${result.files.single.name}";
        });
      } else {
        setState(() {
          _statusMessage = "File selection canceled.";
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = "Error selecting file: $e";
      });
    }
  }

  Future<Map<String, dynamic>> _encryptFile(Uint8List fileData) async {
    final key = encrypt.Key.fromSecureRandom(32);
    final encrypter =
        encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
    final iv = encrypt.IV.fromSecureRandom(16);

    final encrypted = encrypter.encryptBytes(fileData, iv: iv);

    setState(() {
      _encryptionKey = base64Encode(key.bytes + iv.bytes);
      _encryptionKeyController.text = _encryptionKey!;
    });

    return {
      'encryptedData': Uint8List.fromList(encrypted.bytes),
      'encryptionKey': key.bytes,
      'iv': iv.bytes,
    };
  }

  Future<void> _uploadToPinata(Uint8List encryptedData, String fileName) async {
    const String apiKey = 'f7b770e84098104f4947';
    const String apiSecret =
        '6ee68dc0a40a9b9094c96f1b354e2ea2844c764e6cb3173dc0df6cb00e6453f1';
    const String url = 'https://api.pinata.cloud/pinning/pinFileToIPFS';

    try {
      final request = http.MultipartRequest('POST', Uri.parse(url))
        ..headers['pinata_api_key'] = apiKey
        ..headers['pinata_secret_api_key'] = apiSecret
        ..fields['pinataMetadata'] = jsonEncode({
          'name': fileName,
          'keyvalues': {
            'originalFileName': fileName,
          },
        })
        ..files.add(
          http.MultipartFile.fromBytes('file', encryptedData,
              filename: fileName),
        );

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final responseJson = jsonDecode(responseBody);
        setState(() {
          _cid = responseJson['IpfsHash'];
          _statusMessage = "File uploaded successfully!";
        });
      } else {
        setState(() {
          _statusMessage = "Failed to upload file: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = "Error uploading file: $e";
      });
    }
  }

  Future<void> _handleFileUpload() async {
    try {
      await _requestStoragePermission();

      if (_filePath == null) {
        setState(() {
          _statusMessage = "Please select a file first.";
        });
        return;
      }

      setState(() {
        _statusMessage = "Encrypting file...";
      });

      final fileBytes = await File(_filePath!).readAsBytes();
      final encryptionResult = await _encryptFile(fileBytes);

      setState(() {
        _statusMessage = "Uploading to Pinata...";
      });

      await _uploadToPinata(
        encryptionResult['encryptedData']!,
        _originalFileName!,
      );
    } catch (e) {
      setState(() {
        _statusMessage = "Error: $e";
      });
    }
  }

  Future<void> _openPhantomBrowser() async {
    final String encodedDappUrl = Uri.encodeComponent(dappUrl);
    final String encodedRefUrl = Uri.encodeComponent(refUrl);
    final String deepLink =
        'https://phantom.app/ul/browse/$encodedDappUrl?ref=$encodedRefUrl';

    if (!await launchUrl(Uri.parse(deepLink),
        mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $deepLink';
    }
  }

  void _copyToClipboard(String content) {
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Copied to clipboard!"),
        duration: Duration(seconds: 2),
      ),
    );
  }

  final _transactionSignatureController = TextEditingController();
  final _encryptionKeyController = TextEditingController();
  String? _selectedDoctorEmail;
  String? _userEmail;
  List<String> _doctorEmails = [];

  @override
  void initState() {
    super.initState();
    _fetchDoctorEmails();
    _setUserEmail();
  }

  Future<void> _fetchDoctorEmails() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('doctors').get();
    setState(() {
      _doctorEmails =
          snapshot.docs.map((doc) => doc['email'] as String).toList();
    });
  }

  Future<void> _setUserEmail() async {
    User? user = FirebaseAuth.instance.currentUser;
    setState(() {
      _userEmail = user?.email ?? '';
    });
  }

  Future<void> _saveTransactionDetails() async {
    if (_selectedDoctorEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a doctor."),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_transactionSignatureController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter the Transaction Signature."),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_encryptionKeyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter the Encryption Key."),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final transactionData = {
      'transactionSignature': _transactionSignatureController.text,
      'encryptionKey': _encryptionKey,
      'doctorEmail': _selectedDoctorEmail,
      'userEmail': _userEmail,
      'timestamp': DateTime.now(),
    };

    await FirebaseFirestore.instance
        .collection('transactions')
        .add(transactionData);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Details Sent"),
        content: const Text("Your details have been sent to the doctor."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );

    setState(() {
      _transactionSignatureController.clear();
      _encryptionKeyController.clear();
      _selectedDoctorEmail = null; // Clear the selected doctor.
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('File Upload'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.deepPurple, width: 2.0),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: _selectFile,
                      child: const Text("Select File"),
                    ),
                    if (_filePath != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text("Selected File: $_filePath"),
                      ),
                    ElevatedButton(
                      onPressed: _handleFileUpload,
                      child: const Text("Upload File"),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(_statusMessage),
                    ),
                    if (_cid != null)
                      GestureDetector(
                        onTap: () => _copyToClipboard(_cid!),
                        child: Text(
                          "CID: $_cid",
                          style: const TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    if (_encryptionKey != null)
                      GestureDetector(
                        onTap: () => _copyToClipboard(_encryptionKey!),
                        child: Text(
                          "Encryption Key: $_encryptionKey",
                          style: const TextStyle(
                            color: Colors.green,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _openPhantomBrowser,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
              child: const Text(
                "Save CID to Solana",
                style: TextStyle(fontSize: 18.0),
              ),
            ),
            DropdownButtonFormField<String>(
              value: _selectedDoctorEmail,
              decoration: const InputDecoration(labelText: 'Select Doctor'),
              items: _doctorEmails.map((email) {
                return DropdownMenuItem(
                  value: email,
                  child: Text(email),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDoctorEmail = value;
                });
              },
            ),
            TextField(
              controller: _transactionSignatureController,
              decoration:
                  const InputDecoration(labelText: 'Transaction Signature'),
            ),
            TextField(
              controller: _encryptionKeyController,
              decoration: const InputDecoration(labelText: 'Encryption Key'),
            ),
            ElevatedButton(
              onPressed: _saveTransactionDetails,
              child: const Text('Send Details'),
            ),
          ],
        ),
      ),
    );
  }
}
