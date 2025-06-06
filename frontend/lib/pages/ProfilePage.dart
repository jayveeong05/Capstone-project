import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../main.dart';

class ProfilePage extends StatefulWidget{
  final String userId;

  ProfilePage({required this.userId});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>{
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullName = TextEditingController();
  final TextEditingController _age = TextEditingController();
  final TextEditingController _height = TextEditingController();
  final TextEditingController _weight = TextEditingController();
  final TextEditingController _location = TextEditingController();
  File? _image;

  Future<void> _pickImage() async{
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if(picked != null){
      setState(() {
        _image = File(picked.path);
      });
    }
  }
  Future<void> _saveProfile() async{
    if(!_formKey.currentState!.validate()) return;
    
    final request = http.MultipartRequest('POST', 
    Uri.parse('$baseUrl/profile'),
    );
    request.fields['userId'] = widget.userId;
    request.fields['fullName'] = _fullName.text;
    request.fields['age'] = _age.text;
    request.fields['height'] = _height.text;
    request.fields['weight'] = _weight.text;
    request.fields['location'] = _location.text;
    
    if(_image != null){
      request.files.add(await http.MultipartFile.fromPath('profile_picture', _image!.path));      
    }

    final responese = await request.send();

    if(responese.statusCode == 200){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile updated Successfully')));
    }else{
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update profile')));
    }
  }

@override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title:  Text('My Profile')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
        key: _formKey, 
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 60,
                backgroundImage: _image !=null ? FileImage(_image!): null,
                child: _image == null ? Icon(Icons.add_a_photo, size: 30): null,
              ),
            ),
            SizedBox(height: 20),
              TextFormField(
                controller: _fullName,
                decoration: InputDecoration(labelText: 'Full Name'),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _age,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Age'),
              ),
              TextFormField(
                controller: _height,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Height (cm)'),
              ),
              TextFormField(
                controller: _weight,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Weight (kg)'),
              ),
              TextFormField(
                controller: _location,
                decoration: InputDecoration(labelText: 'Location'),
              ),
              SizedBox(height: 20),
              ElevatedButton(onPressed: _saveProfile, child: Text('Save')),
          ],
        ),
      ),
      ),
    );
  }
}
