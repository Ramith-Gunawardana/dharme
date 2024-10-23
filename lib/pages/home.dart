import 'package:flutter/material.dart';
import 'package:senses/classes/custom_snack_bar.dart';
import 'package:senses/components/primary_button.dart';
import 'package:senses/components/secondary_button.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:senses/classes/model.dart';
import 'package:senses/constants.dart';
import 'package:senses/pages/listening_screen.dart';

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

  @override
  void initState() {
    super.initState();
    loadModels();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return SafeArea(
      child: Scaffold(
        body: Center(
          child: Container(
            width: width,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            decoration: const BoxDecoration(
              image: DecorationImage(
                fit: BoxFit.cover,
                image: AssetImage('assets/images/background/noise_image.webp'),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    "Pick your preferred Model!",
                    style: kHeadingTextStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
                // SecondaryButton(title: "Fetch Models", process: fetchModels),
                models.isNotEmpty
                    ? DropdownButton<Model>(
                        value: selectedModel,
                        items: models.map((model) {
                          return DropdownMenuItem(
                            value: model,
                            child: Text(model.approveName),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedModel = value;
                          });
                        },
                      )
                    : const CircularProgressIndicator(),
                PrimaryButton(title: "Next", process: (){
                  if (selectedModel != null) {
                    // Navigate to next screen with selected model
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AudioUploader(
                          // jobId: "420297i39v92930",
                            // selectedModel: selectedModel!
                        ),
                      ),
                    );
                  }
                  else{
                    ScaffoldMessenger.of(context).showSnackBar(
                      CustomSnackBar(
                        backColor: kAmberColor,
                        time: 2,
                        title: 'A model must be selected',
                        icon: Icons.warning_amber,
                      ),
                    );
                  }
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
