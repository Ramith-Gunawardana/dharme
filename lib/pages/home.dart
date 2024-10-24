import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:senses/classes/custom_snack_bar.dart';
import 'package:senses/components/primary_button.dart';
import 'package:senses/components/secondary_button.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:senses/classes/model.dart';
import 'package:senses/constants.dart';
import 'package:senses/pages/listening_screen.dart';
import 'package:senses/classes/all_models.dart';
import 'package:senses/classes/card_colors.dart';
import 'package:senses/classes/most_used_models.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<Model> models = [];
  Model? selectedModel;

  // Allows fetching models in creating the context
  Future<void> loadModels() async {
    try {
      List<Model> fetchedModels = await fetchModels();
      setState(() {
        models = fetchedModels;
        selectedModel = models.isNotEmpty ? models.first : null;
      });
    } catch (e) {
      print('Error fetching models: $e');
    }
  }

  // Allows fetching models through button
  Future<List<Model>> fetchModels() async {
    final uri = Uri.parse(
        'https://4tnwcv11y4.execute-api.ap-south-1.amazonaws.com/get_approved_models');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        List<dynamic> jobs = data['jobs'];
        return jobs.map((job) => Model.fromJson(job)).toList();
      } else {
        throw Exception('Failed to fetch models');
      }
    } else {
      throw Exception('Failed to connect to API');
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case "warning":
        return Icons.warning;
      case "home":
        return Icons.home;
      case "location_city":
        return Icons.location_city;
      case "nightlight_round":
        return Icons.nightlight_round;
      case "factory":
        return Icons.factory;
      case "nature":
        return Icons.nature;
      case "work":
        return Icons.work;
      case "park":
        return Icons.park;
      case "directions_car":
        return Icons.directions_car;
      case "tune":
        return Icons.tune;
      default:
        return Icons.help; // Fallback icon
    }
  }

  @override
  void initState() {
    super.initState();
    loadModels();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
                image: AssetImage("assets/images/background/noise_image.webp"),
                fit: BoxFit.cover),
          ),
          child: Column(
            children: [
              Container(
                  margin: const EdgeInsets.symmetric(vertical: 16.0),
                  child: const Text(
                    "Welcome!",
                    style: kHeadingTextStyle,
                  )),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, // Number of columns
                      mainAxisSpacing: 10.0, // Vertical spacing
                      // crossAxisSpacing: 10.0, // Horizontal spacing
                      childAspectRatio: 0.8, // Make tiles square
                    ),
                    itemCount: allModels.length,
                    itemBuilder: (context, index) {
                      final item = allModels[index];
                      return _buildTile(item);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTile(Map<String, dynamic> item) {
    return Column(
      children: [
        Expanded(
          child: Material(
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AudioUploader()),
                );
              },
              splashColor: kOceanBlueColor.withOpacity(0.5), // Color of the splash effect
              borderRadius: BorderRadius.circular(10.0), // Match with the Container's border radius
              child: Container(
                padding: const EdgeInsets.all(30.0),
                decoration: BoxDecoration(
                  color: kOceanBlueColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Icon(
                  _getIconData(item['icon']),
                  size: 50,
                  color: kOceanBlueColor,
                ),
              ),
            ),
          )


        ),
        const SizedBox(height: 8.0),
        Text(
          item['name'],
          textAlign: TextAlign.center,
          style: kSubTitleTextStyle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
