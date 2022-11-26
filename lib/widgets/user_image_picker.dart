import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class UserImagePicker extends StatefulWidget {
  final void Function(File pickedImage) imagePickFn;
  final imageUrl;

  UserImagePicker(this.imagePickFn, this.imageUrl);

  @override
  _UserImagePickerState createState() => _UserImagePickerState();
}

class _UserImagePickerState extends State<UserImagePicker> {
  File _pickedImage;

  void _pickImage() async {
    final picker = ImagePicker();
    var pickedImage;
    var pickedImageFile;

    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Container(
            child: new Wrap(
              children: <Widget>[
                new ListTile(
                    leading: new Icon(Icons.photo_library),
                    title: new Text('Galeria'),
                    onTap: () async {
                      pickedImage = await picker.getImage(
                        source: ImageSource.gallery,
                      );
                      pickedImageFile = File(pickedImage.path);
                      setState(() {
                        _pickedImage = pickedImageFile;
                      });
                      widget.imagePickFn(pickedImageFile);
                      Navigator.of(context).pop();
                    }),
                new ListTile(
                  leading: new Icon(Icons.photo_camera),
                  title: new Text('Câmera'),
                  onTap: () async {
                    pickedImage = await picker.getImage(
                      source: ImageSource.camera,
                    );
                    pickedImageFile = File(pickedImage.path);
                    setState(() {
                      _pickedImage = pickedImageFile;
                    });
                    widget.imagePickFn(pickedImageFile);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        CircleAvatar(
          radius: 40,
          backgroundColor: Colors.grey,
          backgroundImage: _pickedImage != null
              ? FileImage(_pickedImage)
              : widget.imageUrl != null
                  ? NetworkImage(widget.imageUrl)
                  : AssetImage('lib/assets/images/avatar.png'),
        ),
        FlatButton.icon(
          icon: Icon(Icons.image),
          onPressed: _pickImage,
          label: Text("Adicionar foto"),
          textColor: Theme.of(context).primaryColor,
        ),
      ],
    );
  }
}
