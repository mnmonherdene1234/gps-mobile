import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';
import 'package:localstorage/localstorage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'GPS Location'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late LocationSettings locationSettings;
  final _formKey = GlobalKey<FormState>();
  final Location _location = Location();
  String? name;
  late LocationData _locationData;
  final LocalStorage storage = LocalStorage('storage');

  void _sendLocation() async {
    Map<String, dynamic> jsonMap = {
      "name": storage.getItem("name"),
      "lat": _locationData.latitude,
      "lng": _locationData.longitude
    };
    String jsonString = json.encode(jsonMap);

    try {
      await http.post(
          Uri.parse(
              "https://web-production-a867.up.railway.app/v1/api/locations"),
          headers: {'Content-Type': 'application/json'},
          encoding: Encoding.getByName('utf-8'),
          body: jsonString);
    } catch (e) {}
  }

  void onTextFieldChange(String value) {
    setState(() {
      name = value;
    });
  }

  void checkPremission() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }
  }

  @override
  void initState() {
    super.initState();

    checkPremission();

    _location.enableBackgroundMode(enable: true);
    _location.onLocationChanged.listen((LocationData currentLocation) {
      _locationData = currentLocation;
      _sendLocation();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.only(left: 50, right: 50),
                child: Column(
                  children: [
                    Text(name ?? "*******"),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          name = storage.getItem("name");
                        });
                      },
                      child: const Text("Нэр харах"),
                    ),
                    TextFormField(
                      initialValue: name,
                      validator: ((value) {
                        if (value == null || value.isEmpty) {
                          return "Хоосон байна!";
                        }
                        return null;
                      }),
                      onChanged: onTextFieldChange,
                    ),
                    ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState?.validate() ?? false) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Амжилттай!")));
                            storage.setItem("name", name);
                            setState(() {
                              name = storage.getItem("name");
                            });
                          }
                        },
                        child: const Text("Хадгалах"))
                  ],
                ),
              )),
        ]),
      ),
    );
  }
}
