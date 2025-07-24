import 'dart:convert';
import 'package:wellbeing_mapper/main.dart';
import 'package:wellbeing_mapper/models/app_localizations.dart';
import 'package:wellbeing_mapper/models/custom_locations.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share/share.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;

class WellbeingMapperSideDrawer extends StatelessWidget {
  _shareLocations() async {
    var now = new DateTime.now();
    List allLocations = await bg.BackgroundGeolocation.locations;
    List<ShareLocation> customLocation = [];

    // We get only timestamp and coordinates into our custom class
    for (var thisLocation in allLocations) {
      ShareLocation _loc = new ShareLocation(
          bg.Location(thisLocation).timestamp,
          bg.Location(thisLocation).coords.latitude,
          bg.Location(thisLocation).coords.longitude,
          bg.Location(thisLocation).coords.accuracy,
          GlobalData.userUUID);
      customLocation.add(_loc);
    }

    String prettyString = JsonEncoder.withIndent('  ').convert(customLocation);
    String subject =
        "wellbeing-mapper-app_trajectory_" + now.toIso8601String() + ".json";
    Share.share(prettyString, subject: subject);
  }

  _launchProjectURL() async {
    final Uri url = Uri.parse('http://activityspaceproject.com/');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Drawer(
      child: ListView(
        // Important: Remove any padding from the ListView.
        padding: EdgeInsets.zero,
        children: <Widget>[
          Container(
            height: 100,
            child: DrawerHeader(
              child: Text(
                  AppLocalizations.of(context)
                          ?.translate("side_drawer_title") ??
                      "",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              decoration: BoxDecoration(
                color: Colors.blueGrey[200],
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.list),
              title: Text(AppLocalizations.of(context)
                      ?.translate("locations_history") ??
                  ""),
              onTap: () {
                Navigator.of(context).pushNamed('/locations_history');
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.share),
              title: Text(
                  AppLocalizations.of(context)?.translate("share_locations") ??
                      ""),
              onTap: () {
                _shareLocations();
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.web),
              title: Text(AppLocalizations.of(context)
                      ?.translate("visit_project_website") ??
                  ""),
              onTap: () {
                _launchProjectURL();
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.report_problem_outlined),
              title: Text(
                  AppLocalizations.of(context)?.translate("report_an_issue") ??
                      ""),
              onTap: () {
                Navigator.of(context).pushNamed('/report_an_issue');
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.assignment),
              title: Text("Initial Survey"),
              subtitle: Text("Complete your initial demographics survey"),
              onTap: () {
                Navigator.of(context).pushNamed('/initial_survey');
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.assignment_turned_in),
              title: Text("Wellbeing Survey"),
              subtitle: Text("Bi-weekly wellbeing check-in"),
              onTap: () {
                Navigator.of(context).pushNamed('/recurring_survey');
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.history),
              title: Text("Survey History"),
              subtitle: Text("View completed surveys"),
              onTap: () {
                Navigator.of(context).pushNamed('/survey_list');
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: Text("Survey Notifications"),
              onTap: () {
                Navigator.of(context).pushNamed('/notification_settings');
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: Text("Research Participation"),
              subtitle: Text("Manage consent and participation settings"),
              onTap: () {
                Navigator.of(context).pushNamed('/participation_selection');
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.cloud_upload),
              title: Text("Research Data Upload"),
              subtitle: Text("Upload encrypted data to research servers"),
              onTap: () {
                Navigator.of(context).pushNamed('/data_upload');
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.cloud_upload),
              title: Text("Research Data Upload"),
              subtitle: Text("Upload encrypted data to research servers"),
              onTap: () {
                Navigator.of(context).pushNamed('/data_upload');
              },
            ),
          ),
/*           Card(
            child: ListTile(
              leading: const Icon(Icons.bar_chart),
              title: Text("Statistics"),
              onTap: () {
                Navigator.of(context).pushNamed('/my_statistics');
              },
            ),
          ),
 */
        ],
      ),
    );
  }
}
