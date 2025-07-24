# **Wellbeing Mapper** 
## What is Wellbeing Mapper?

Wellbeing Mapper is a privacy-focused mobile application that lets you map your mental wellbeing in environmental & climate context. You can use the app to map the routes you take and the places where you spend time while tracking your mental wellbeing using a short survey and/or a digital diary. All of this information stays on your device for your own use and need not be shared with anyone else. If you have been recruited to participate in a study, you can also choose to share this information with researchers who are trying to better understand how environmental and climate factors impact mental wellbeing.

This application is part of a case study in the [Planet4Health project](https://planet4health.eu), a Horizon Europe research initiative focused on translating science into policy for planetary health. The case study specifically addresses "[Mental wellbeing in environmental & climate context](https://planet4health.eu/mental-wellbeing-in-environmental-climate-context/)" - an emerging field that recognizes how environmental and climate changes contribute to rising mental health and psychosocial issues.

### About the Planet4Health Case Study

Traditional studies on environmental and climate change impacts have predominantly focused on physical health. However, these changes also contribute to a range of mental health disorders from emotional distress to the exacerbation of existing mental health conditions, often referred to as climate-related psychological distress.

This case study aims to:
- Collect and analyze mental wellbeing data alongside environmental data
- Develop comprehensive understanding of mental health impacts from environmental factors
- Create integrated risk monitoring systems
- Map environmental hotspots affecting mental health
- Provide solutions for better preparedness and response capacity

[![CI tests](https://github.com/ActivitySpaceLab/wellbeing-mapper-app/actions/workflows/CI.yml/badge.svg)](https://github.com/ActivitySpaceLab/wellbeing-mapper-app/actions/workflows/CI.yml)
[![drive_test iOS](https://github.com/ActivitySpaceLab/wellbeing-mapper-app/actions/workflows/drive-ios.yml/badge.svg)](https://github.com/ActivitySpaceLab/wellbeing-mapper-app/actions/workflows/drive-ios.yml)
[![drive_test Android](https://github.com/ActivitySpaceLab/wellbeing-mapper-app/actions/workflows/drive-android.yml/badge.svg)](https://github.com/ActivitySpaceLab/wellbeing-mapper-app/actions/workflows/drive-android.yml)
[![codecov](https://codecov.io/gh/ActivitySpaceLab/wellbeing-mapper-app/branch/master/graph/badge.svg?token=HBJXBV7VR6)](https://codecov.io/gh/ActivitySpaceLab/wellbeing-mapper-app)

## Screenshots
<img src="Assets/images/3.0.2%2B18_screenshots.png"  width="95%"></img>

## Prerequisites

**Important**: This project requires **Flutter 3.27.1** with **Dart 3.6.0** specifically. The app will not compile with other versions due to dependency constraints.

### Using FVM (Recommended)
```bash
# Install FVM
dart pub global activate fvm

# Use the correct Flutter version
fvm use 3.27.1

# Verify version
fvm flutter --version
```

### Without FVM
Ensure you have Flutter 3.27.1 installed:
```bash
flutter --version
# Should show: Flutter 3.27.1 • Dart 3.6.0
```

## How to contribute
Do you want to contribute?

Feel free to fork our repository, create a new branch, make your changes and submit a pull request(*). We'll review it as soon as possible and merge it.

(*)Before opening the pull request, please run the commands `fvm flutter analyze` and `fvm flutter test` locally (or `flutter analyze` and `flutter test` if not using FVM) to ensure that your PR passes all the tests successfully in our continuous integration (CI) workflow.

It would be awesome if you assign yourself to an existing task or you open a new issue in [Github Issues](https://github.com/ActivitySpaceLab/wellbeing-mapper-app/issues), to keep other contributors informed on what you're working on.

If this project is useful for you, please consider starring this repository and giving us 5 stars on the app stores to give us more visibility.

## Contributors
- Otis Johnson
    - [github.com/StuffJoy](http://github.com/StuffJoy)
- Pablo Galve Millán
    - [github.com/pablogalve](https://github.com/pablogalve)
    - [linkedin.com/in/pablogalve/](https://www.linkedin.com/in/pablogalve/)
- John R.B. Palmer
    - [github.com/johnpalmer](https://github.com/johnpalmer)

## Features
* **Mental Health Mapping**: Track your mental wellbeing alongside your location data to understand environmental influences on your psychological health.
* **Environmental Context**: Correlate your wellbeing data with environmental factors like air quality, green spaces, and climate conditions.
* **Privacy-First Design**: Your data is only stored on your phone, so only you have access to it.
* **Multi-Site Research Support**: Participate in research studies in Barcelona, Spain or Gauteng, South Africa with site-specific surveys and consent forms.
* **End-to-End Encryption**: Research data is encrypted with military-grade RSA+AES encryption before transmission to protect participant privacy.
* **Secure Data Upload**: Bi-weekly encrypted uploads of survey responses and location data to authorized research servers.
* **Climate-Health Research**: Optionally contribute anonymized data to advance scientific understanding of climate-related psychological impacts.
* **Minimally Intrusive**: Designed to conserve battery power and run efficiently in the background.
* **Complete Control**: Turn tracking on and off whenever you want. Withdraw from research participation at any time.
* **Open Source**: Free, open source software. You'll never have to pay anything or watch any ads to use it.

## Research Participation

### Three Usage Modes
1. **Private Mode**: Use the app purely for personal mental health tracking with no data sharing
2. **Barcelona Research**: Participate in the Barcelona, Spain study with location consent and Spanish research protocols
3. **Gauteng Research**: Participate in the Gauteng, South Africa study with ethnicity demographics and health questions

### Data Security
- All research data is encrypted using RSA-4096 public key cryptography before upload
- Location tracking data is stored locally and only shared with explicit consent
- Participant identifiers are anonymized UUIDs with no personal information
- Research teams can only decrypt data with their corresponding private keys

### For Researchers
See the [Server Setup Guide](docs/SERVER_SETUP.md) and [Encryption Configuration Guide](docs/ENCRYPTION_SETUP.md) for detailed instructions on:
- Setting up data collection servers
- Configuring RSA public/private key pairs
- Managing participant data securely
- Database schema and API specifications

## Download the app
For more information about the Planet4Health project, please visit the [Planet4Health website](https://planet4health.eu) and learn about the [Mental wellbeing in environmental & climate context case study](https://planet4health.eu/mental-wellbeing-in-environmental-climate-context/).

- [Google Play (Android)](http://play.google.com/store/apps/details?id=edu.princeton.jrpalmer.asm).
- Apple Store (iOS) (Coming soon)
- [Github Releases (Android)](https://github.com/ActivitySpaceLab/wellbeing-mapper-app/releases).

## About Planet4Health

Planet4Health is a Horizon Europe research project focused on "Translating Science into Policy: A Multisectoral Approach to Adaptation and Mitigation of Adverse Effects of Vector-Borne Diseases, Environmental Pollution and Climate Change on Planetary Health." The project is part of the Planetary Health Cluster, which includes five Horizon Europe projects working together to address climate change and health challenges.

**Funding**: This project is funded by the European Union under the Horizon Europe programme. Views and opinions expressed are however those of the author(s) only and do not necessarily reflect those of the European Union or the European Health and Digital Executive Agency (HADEA).

## License
This repository contains the source code development version of Wellbeing Mapper, developed as part of the Planet4Health project case study on mental wellbeing in environmental & climate context.

This project is licensed under the [GNU GENERAL PUBLIC LICENSE](https://github.com/ActivitySpaceLab/wellbeing-mapper-app/blob/master/LICENSE)

Copyright 2011-2020 John R.B. Palmer 
Copyright 2021-2023 John R.B. Palmer and Pablo Galve Millán
Copyright 2021-2023 John R.B. Palmer, Pablo Galve Millán, and Otis Johnson

 
Wellbeing Mapper is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

Wellbeing Mapper is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program.  If not, see http://www.gnu.org/licenses.
