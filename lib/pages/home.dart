import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
            decoration: const BoxDecoration(
              image: DecorationImage(
                fit: BoxFit.cover,
                image: AssetImage('assets/images/background/noise_image.webp'),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding:
                      EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                  child: Align(
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Text(
                          "Welcome!",
                          style: kHeadingTextStyle,
                        ),
                        Text(
                          "Enhance your senses with us!",
                          style: kSubHeadingTextStyle,
                        ),
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding:
                      EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
                  child: Text(
                    "Recent Models",
                    style: kSubTitleTextStyle,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: mostUsedModels.length,
                      itemBuilder: (context, index) {
                        return Container(
                          width: width / 2,
                          margin: const EdgeInsets.symmetric(
                              horizontal: 6.0, vertical: 8.0),
                          decoration: BoxDecoration(
                            color: cardColors[index % cardColors.length],
                            borderRadius: BorderRadius.circular(20.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(
                                    0.2), // Shadow color with transparency
                                spreadRadius: 1, // How far the shadow spreads
                                blurRadius: 2, // How soft the shadow is
                                offset: const Offset(
                                    0, 2), // Offset in x and y direction
                              ),
                            ],
                          ),
                          child: ListTile(
                            title: Text(
                              mostUsedModels[index]['name']!,
                              style: kHeadingTextStyle,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const Padding(
                  padding:
                      EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
                  child: Text(
                    "All Models",
                    style: kSubTitleTextStyle,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: ListView.builder(
                      itemCount: allModels.length,
                      itemBuilder: (context, index) {
                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AudioUploader(),
                              ),
                            );
                          },
                          splashColor: Colors.blue
                              .withOpacity(0.3), // Customize the splash color
                          borderRadius: BorderRadius.circular(
                              20.0), // Match ripple with widget shape
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6.0),
                            padding: const EdgeInsets.symmetric(
                                vertical: 16.0, horizontal: 4.0),
                            decoration: BoxDecoration(
                              color: cardColors[index % cardColors.length],
                              borderRadius: BorderRadius.circular(20.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(
                                      0.2), // Shadow color with transparency
                                  spreadRadius: 1, // How far the shadow spreads
                                  blurRadius: 2, // How soft the shadow is
                                  offset: const Offset(
                                      0, 2), // Offset in x and y direction
                                ),
                              ],
                            ),
                            child: ListTile(
                              title: Text(
                                allModels[index]['name']!,
                                style: kHeadingTextStyle,
                              ),
                              subtitle: Text(
                                allModels[index]['description']!,
                                style: kSubHeadingTextStyle.copyWith(fontSize: 14.0),
                                maxLines: 2,
                                overflow: TextOverflow.fade,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
