import 'dart:convert';
import 'dart:io';
import 'package:document_scanner_flutter/document_scanner_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:floorplan2vr/home.dart';
import './email.dart';
import '../rendering/ViewerRendering.dart';
import 'package:document_scanner_flutter/document_scanner_flutter.dart';

class ImageInput extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _ImageInputState();
  }
}

class _ImageInputState extends State<ImageInput> {
  File? selectedImage;
  String? imagePath;
  String message = "";
  bool _isLoading = false;


  void _StartScan(BuildContext context) async {
    var image = await DocumentScannerFlutter.launch(context);
    if (image != null){
      setState(() {
        selectedImage = image;
        selectedImage = File(image.path);
        imagePath = image.path;
        setState(() {});
      });
    }
  }

  Future<http.Response> SendID(String title) {
    return http.post(
      Uri.parse("https://shoothouse.cylab.be/viewer"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'title': title,
      }),
    );
  }

  //-------------------------------------------------
  //   function to send the image to server
  //-------------------------------------------------
  send() async {
    setState(() {
      _isLoading = true;
    }); //show loader
    // Init the Type of request
    final request = http.MultipartRequest(
        "POST", Uri.parse("https://shoothouse.cylab.be/upload"));
    // Init the Header of the request
    final header = {"Content-type": "multipart/from-data"};
    // Add the image to the request
    request.files.add(http.MultipartFile('image',
        selectedImage!.readAsBytes().asStream(), selectedImage!.lengthSync(),
        filename: selectedImage!.path.split("/").last));
    // Fill the request with the header
    request.headers.addAll(header);
    // Send the request
    final response = await request.send();
    // Get the answer
    http.Response res = await http.Response.fromStream(response);
    // Decode the answer
    final resJson = jsonDecode(res.body);
    // Get the message in the json
    message = resJson['ID'];
    // Update the state
    setState(() {});
  }

  //-------------------------------------------------
  //   Open file picker from windows + Linux
  //-------------------------------------------------
  /*
  void _getFromGallery_windows() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      dialogTitle: 'Select an image',
      type: FileType.image,
    );

    if (result == null) return;

    PlatformFile file = result.files.single;

    if (file.path != null) {
      imagePath = file.path;
      selectedImage = File(file.path as String);
      setState(() {});
    }
  }
  */
  //-------------------------------------------------
  //   function to download model from server
  //-------------------------------------------------

  Future<File> downloadFile(String url, String fileName) async {
    var request = http.Request('GET', Uri.parse(url));
    var response = await http.Client().send(request);

    // Create a file to write the data to.
    var file = File(fileName);

    // Open the file for writing.
    var fileStream = file.openWrite();

    // Pipe the response stream to the file stream.
    await response.stream.pipe(fileStream);

    // Close the streams.
    await fileStream.flush();
    await fileStream.close();

    return file;
  }

  //-------------------------------------------------
  //   function to get image from phone storage - Android only
  //-------------------------------------------------
  /*
  Future _getFromGallery_android() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (image != null) {
      selectedImage = File(image.path);
      imagePath = image.path;
      setState(() {});
    } else {}
  }
  */
  //-------------------------------------------------
  //   function get image from camera - Android only
  //-------------------------------------------------

  /*
  Future _getFromCamera_android() async {
    final XFile? image =
        await ImagePicker().pickImage(source: ImageSource.camera);

    if (image != null) {
      selectedImage = File(image.path);
      imagePath = image.path;
      setState(() {});
    }
  }
  */
  //-------------------------------------------------
  //   Main function to get images from device
  //-------------------------------------------------
  /*
  void _OpenImagePicker(BuildContext context) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return (Platform.isAndroid == true)
              ? Container(
                  height: 200.0,
                  padding: EdgeInsets.all(10.0),
                  child: Column(children: [
                    Text('Pick an Image'),
                    SizedBox(
                      height: 10.0,
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        _getFromCamera_android();
                      },
                      icon: Icon(
                        // <-- Icon
                        Icons.camera_alt,
                        size: 24.0,
                      ),
                      label: Text('From Camera'), // <-- Text
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        _getFromGallery_android();
                      },
                      icon: Icon(
                        // <-- Icon
                        Icons.folder_open,
                        size: 24.0,
                      ),
                      label: Text('From Gallery'), // <-- Text
                    ),
                    SizedBox(height: 50.0),
                  ]),
                )
              : (Platform.isWindows == true || Platform.isLinux == true)
                  ? Container(
                      height: 200.0,
                      padding: EdgeInsets.all(10.0),
                      child: Column(children: [
                        Text('Pick an Image'),
                        SizedBox(
                          height: 10.0,
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            _getFromGallery_windows();
                          },
                          icon: Icon(
                            // <-- Icon
                            Icons.folder_open,
                            size: 24.0,
                          ),
                          label: Text('From Gallery'), // <-- Text
                        ),
                        SizedBox(height: 50.0),
                      ]),
                    )
                  : Text("Device not supported");
        });
  }
  */
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        image: DecorationImage(
            image: AssetImage("assets/back.png"), fit: BoxFit.contain),
      ),
      child: Center(
          child: (selectedImage != null)
              ? Column(children: [
                  SizedBox(
                    height: 20,
                  ),
                  Image.file(
                    File(imagePath!),
                    fit: BoxFit.cover,
                    height: 300,
                    width: 300,
                  ),
                  //-------------------------------------------------
                  //         If the image is not uploaded
                  //-------------------------------------------------
                  (message == "")
                      ? (_isLoading == false)
                          //-------------------------------------------------
                          //       If The image is selected but not send
                          //-------------------------------------------------
                          ? Column(
                              children: [
                                SizedBox(height: 50),
                                SizedBox(
                                  width: 120,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      send();
                                    },
                                    style: ButtonStyle(
                                        backgroundColor:
                                            MaterialStateProperty.all(
                                                Colors.red)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Row(
                                        children: const [
                                          Icon(Icons.upgrade),
                                          Text('Run')
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            )
                          //-------------------------------------------------
                          //         If the image selected and uploaded
                          //-------------------------------------------------
                          : Column(children: [
                              SizedBox(
                                height: 50,
                              ),
                              SizedBox(
                                  width: 100,
                                  child: CircularProgressIndicator())
                            ])

                      //-------------------------------------------------
                      //         If the image uploaded failed
                      //-------------------------------------------------
                      : (message == 'ERROR')
                          ? Column(
                              children: [
                                SizedBox(
                                  height: 20,
                                ),
                                SizedBox(
                                  child: Text('ERROR cannot transform in 3D'),
                                )
                              ],
                            )

                          //-------------------------------------------------
                          //   If the image uploaded Successfuly transformed
                          //-------------------------------------------------
                          : Column(children: [
                              SizedBox(
                                height: 10,
                              ),
                              SizedBox(
                                width: 230,
                                child: SizedBox(
                                  width: 230,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                RenderingVeiwer(message)),
                                      );
                                    },
                                    style: ButtonStyle(
                                        backgroundColor:
                                            MaterialStateProperty.all(
                                                Colors.red)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Row(
                                        children: const [
                                          Icon(Icons.remove_red_eye),
                                          Text('       Open 3D viewer')
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 230,
                                child: SizedBox(
                                  width: 230,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      var file = downloadFile(
                                          'https://example.com/file.pdf?str=$message',
                                          '$message');
                                    },
                                    style: ButtonStyle(
                                        backgroundColor:
                                            MaterialStateProperty.all(
                                                Colors.red)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Row(
                                        children: const [
                                          Icon(Icons.download),
                                          Text('    Download')
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 230,
                                child: SizedBox(
                                  width: 230,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                EmailForm(message)),
                                      );
                                    },
                                    style: ButtonStyle(
                                        backgroundColor:
                                            MaterialStateProperty.all(
                                                Colors.red)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Row(
                                        children: const [
                                          Icon(Icons.email_outlined),
                                          Text('    Send by Email')
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            ])
                ])
              :
              //-------------------------------------------------
              //   If the image is not selected yet
              //-------------------------------------------------

              Column(children: [
                  SizedBox(
                    height: 20,
                  ),
                  Container(
                    height: 300.0,
                    width: 300.0,
                    color: Colors.grey,
                    child: Center(child: Text("No image selected")),
                  ),
                  SizedBox(height: 50),
                  SizedBox(
                    width: 120,
                    child: ElevatedButton(
                      onPressed: () {
                        _StartScan(context);
                      },
                      style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all(Colors.red)),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          children: const [
                            Icon(Icons.upload_file),
                            Text(' Upload')
                          ],
                        ),
                      ),
                    ),
                  )
                ])),
    );
  }
}
