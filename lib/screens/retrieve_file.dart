import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';

class FileRetrievalScreen extends StatefulWidget {
  final String transactionSignature;
  final String encryptionKey;
  const FileRetrievalScreen({
    super.key,
    required this.transactionSignature,
    required this.encryptionKey,
  });

  @override
  State<FileRetrievalScreen> createState() => _FileRetrievalScreenState();
}

class _FileRetrievalScreenState extends State<FileRetrievalScreen> {
  final TextEditingController _cidController = TextEditingController();
  final TextEditingController _keyController = TextEditingController();
  final TextEditingController _transactionController = TextEditingController();
  String _retrievalStatus = "Enter CID and Decryption Key to retrieve file.";
  String transactionSignature = "";
  String cid = "";
  String error = "";
  bool isLoading = false;

  static const String pinataApiKey = 'f7b770e84098104f4947';
  static const String pinataApiSecret =
      '6ee68dc0a40a9b9094c96f1b354e2ea2844c764e6cb3173dc0df6cb00e6453f1';

  Future<void> fetchCID(String signature) async {
    setState(() {
      isLoading = true;
      error = "";
      cid = "";
    });

    const String solanaDevnetUrl = "https://api.devnet.solana.com";

    try {
      final response = await http.post(
        Uri.parse(solanaDevnetUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "jsonrpc": "2.0",
          "id": 1,
          "method": "getTransaction",
          "params": [
            signature,
            {"encoding": "jsonParsed"}
          ]
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final transaction = responseData['result'];

        if (transaction == null) {
          setState(() {
            error = "Transaction not found or invalid signature.";
          });
          return;
        }

        final List<dynamic>? instructions =
            transaction['transaction']['message']['instructions'];

        if (instructions == null || instructions.isEmpty) {
          setState(() {
            error = "No instructions found in the transaction.";
          });
          return;
        }

        for (var instruction in instructions) {
          final programId = instruction['programId'];
          final parsed = instruction['parsed'];

          if (programId == "MemoSq4gqABAXKb96qnH8TysNcWxMyWCqXgDLGmfcHr" &&
              parsed != null &&
              parsed.isNotEmpty) {
            setState(() {
              cid = parsed;
              _cidController.text = cid;
              error = "";
            });
            return;
          }
        }

        setState(() {
          error = "CID not found in transaction instructions.";
        });
      } else {
        setState(() {
          error =
              "Failed to fetch transaction data. Status: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        error = "Network error: $e";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _retrieveFile() async {
    //await _requestPermissions();
    await _requestManageExternalStoragePermission();
    final cid = _cidController.text.trim();
    final keyString = _keyController.text.trim();

    if (cid.isEmpty || keyString.isEmpty) {
      setState(() {
        _retrievalStatus = "CID and Decryption Key cannot be empty.";
      });
      return;
    }

    try {
      setState(() {
        _retrievalStatus = "Fetching file metadata...";
      });

      final originalFileName = await _getFileNameFromMetadata(cid);

      setState(() {
        _retrievalStatus = "Fetching file from Pinata...";
      });

      final url = 'https://gateway.pinata.cloud/ipfs/$cid';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final encryptedBytes = response.bodyBytes;

        final decodedKey = base64Decode(keyString);
        final key = encrypt.Key(decodedKey.sublist(0, 32));
        final iv = encrypt.IV(decodedKey.sublist(32, 48));
        final encrypter =
            encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
        final decryptedBytes =
            encrypter.decryptBytes(encrypt.Encrypted(encryptedBytes), iv: iv);

        final downloadPath = await _getDownloadDirectory();
        final filePath = '$downloadPath/$originalFileName';

        final file = File(filePath);
        await file.create(recursive: true);
        await file.writeAsBytes(decryptedBytes);

        setState(() {
          _retrievalStatus =
              "File retrieved successfully! Saved as $originalFileName in Downloads.";
        });
      } else {
        setState(() {
          _retrievalStatus = "Failed to fetch file: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _retrievalStatus = "Error retrieving file: $e";
      });
    }
  }

  Future<String> _getDownloadDirectory() async {
    final directory = Directory('/storage/emulated/0/Download');
    if (await directory.exists()) {
      return directory.path;
    } else {
      throw Exception("Downloads directory not found!");
    }
  }

  Future<String> _getFileNameFromMetadata(String cid) async {
    const String pinataMetadataUrl =
        'https://api.pinata.cloud/data/pinList?hashContains=';

    try {
      final response = await http.get(
        Uri.parse('$pinataMetadataUrl$cid'),
        headers: {
          'pinata_api_key': pinataApiKey,
          'pinata_secret_api_key': pinataApiSecret,
        },
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        if (responseBody['rows'] != null && responseBody['rows'].isNotEmpty) {
          return responseBody['rows'][0]['metadata']['keyvalues']
              ['originalFileName'];
        }
      }
      throw Exception("Metadata not found or invalid response.");
    } catch (e) {
      throw Exception("Error fetching metadata: $e");
    }
  }

  // Requesting storage permissions
  Future<void> _requestPermissions() async {
    final storageStatus = await Permission.storage.request();
    if (!storageStatus.isGranted) {
      setState(() {
        _retrievalStatus = 'Permission to access storage is required.';
      });
    }
  }

// Function to request MANAGE_EXTERNAL_STORAGE permission
  Future<void> _requestManageExternalStoragePermission() async {
    final status = await Permission.manageExternalStorage.request();
    if (!status.isGranted) {
      setState(() {
        _retrievalStatus = 'Permission to access external storage is required.';
      });
    }
  }

  Widget _buildErrorMessage(String message) {
    return Text(
      message,
      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
    );
  }

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('File Retrieval'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Display the transactionSignature and encryptionKey at the top
            Column(
              children: [
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(
                        ClipboardData(text: widget.transactionSignature));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              "Transaction Signature copied to clipboard")),
                    );
                  },
                  child: Text(
                    'Transaction Signature: ${widget.transactionSignature}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 16,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(
                        ClipboardData(text: widget.encryptionKey));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Decryption Key copied to clipboard")),
                    );
                  },
                  child: Text(
                    'Decryption Key: ${widget.encryptionKey}',
                    style: const TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 16,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
            const SizedBox(height: 16),
            // Transaction Signature Section
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.deepPurple, width: 2.0),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Column(
                children: [
                  const Text(
                    "Retrieve CID from Solana",
                    style:
                        TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                  ),
                  TextField(
                    controller: _transactionController,
                    decoration: const InputDecoration(
                      labelText: "Enter Transaction Signature",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (_transactionController.text.isEmpty) {
                        setState(() {
                          error = "Transaction signature cannot be empty.";
                        });
                      } else {
                        fetchCID(_transactionController.text.trim());
                      }
                    },
                    child: const Text("Fetch CID"),
                  ),
                  if (isLoading) const CircularProgressIndicator(),
                  if (cid.isNotEmpty)
                    Text("CID: $cid",
                        style: const TextStyle(color: Colors.green)),
                  if (error.isNotEmpty)
                    Text("Error: $error",
                        style: const TextStyle(color: Colors.red)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // File Retrieval Section
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.deepPurple, width: 2.0),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Column(
                children: [
                  const Text(
                    "Retrieve File",
                    style:
                        TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: TextField(
                      controller: _cidController,
                      decoration: const InputDecoration(
                        labelText: "Enter CID",
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: TextField(
                      controller: _keyController,
                      decoration: const InputDecoration(
                        labelText: "Enter Decryption Key",
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _retrieveFile,
                    child: const Text("Retrieve File"),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(_retrievalStatus),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
