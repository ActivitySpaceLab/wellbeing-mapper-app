---
layout: default
title: Researcher Guide
description: Complete guide for researchers using the Wellbeing Mapper app for data collection and analysis
---

# Researcher Guide

This guide provides comprehensive information for researchers using the Wellbeing Mapper app for data collection and analysis in the Planet4Health study.

## Overview

The Wellbeing Mapper app is designed to collect anonymous, encrypted data about participants' mobility patterns and mental wellbeing in Gauteng, South Africa, and Barcelona, Spain.

## Data Collection & Analysis

### Location Data Decryption
- **[Location Data Decryption Guide](LOCATION_DATA_DECRYPTION.md)** - Complete guide to decrypt location data from Qualtrics exports
- **Python Decryption Tool** - Automated tool for processing encrypted location data
- **CSV Output** - Ready for analysis in R, SPSS, or other statistical software

### Encryption Setup
- **[Encryption Setup](ENCRYPTION_SETUP.md)** - Security and key management for data collection
- **RSA+AES Hybrid Encryption** - Industry-standard data protection
- **Key Management** - Secure handling of encryption keys

### Server Configuration
- **[Server Setup](SERVER_SETUP.md)** - Research server configuration
- **Data Storage** - Secure data hosting requirements
- **Access Controls** - Research team access management

## Research Setup

### Participant Management
- **[Participant Validation System](PARTICIPANT_VALIDATION_SYSTEM.md)** - Secure participant access control
- **Participant Codes** - Generation and distribution system
- **Validation Process** - Ensuring secure study access

### Research Features
- **[Research Features Summary](RESEARCH_FEATURES_SUMMARY.md)** - Available research tools
- **Survey System** - Initial and biweekly wellbeing assessments
- **Location Tracking** - Background GPS data collection
- **Notification System** - Automated survey reminders

### Privacy & Ethics
- **[Privacy Documentation](PRIVACY.md)** - Data protection measures
- **Consent System** - Informed consent collection
- **Anonymization** - Participant privacy protection
- **GDPR Compliance** - European data protection standards

## Data Types Collected

### Location Data
- **GPS Coordinates** - Encrypted longitude/latitude points
- **Timestamp Information** - Time-stamped location visits
- **Movement Patterns** - Mobility and activity spaces
- **Environmental Context** - Location-based environmental exposures

### Survey Data
- **Initial Survey** - Baseline demographic and wellbeing data
- **Biweekly Surveys** - Regular wellbeing assessments
- **Consent Records** - Participant consent status
- **Response Metadata** - Survey completion information

### Technical Data
- **App Usage Metrics** - Feature usage patterns (anonymized)
- **Performance Data** - Technical performance indicators
- **Error Logs** - System error reporting (anonymized)

## Analysis Workflow

### 1. Data Export from Qualtrics
- Access Qualtrics survey responses
- Download response data in CSV format
- Identify encrypted location data fields

### 2. Data Decryption
- Use Python decryption tool
- Process encrypted location data
- Generate analysis-ready CSV files

### 3. Data Analysis
- Import data into statistical software
- Merge location and survey data
- Apply analysis protocols

### 4. Results Reporting
- Follow ethical reporting guidelines
- Maintain participant anonymity
- Share findings with research community

## Quality Assurance

### Data Validation
- **Encryption Verification** - Ensure all data is properly encrypted
- **Completeness Checks** - Verify data collection integrity
- **Participant Validation** - Confirm authorized participation

### Technical Monitoring
- **System Performance** - Monitor app functionality
- **Data Transfer** - Verify successful data transmission
- **Error Tracking** - Identify and resolve technical issues

## Ethical Considerations

### Participant Rights
- **Voluntary Participation** - All participation is voluntary
- **Informed Consent** - Full disclosure of data collection
- **Right to Withdraw** - Participants can leave study anytime
- **Data Deletion** - Option to request data removal

### Data Protection
- **Anonymization** - No personal identifiers collected
- **Encryption** - All data encrypted before transmission
- **Secure Storage** - Protected data hosting
- **Access Controls** - Restricted researcher access

### Research Ethics
- **University Approval** - Ethics committee oversight
- **Study Protocols** - Standardized research procedures
- **Participant Safety** - Mental health safeguarding
- **Community Benefit** - Research for public good

## Support & Contact

### Technical Support
- **Developer Team** - [GitHub Issues](https://github.com/ActivitySpaceLab/gauteng-wellbeing-mapper-app/issues)
- **Documentation** - Complete technical guides
- **Integration Support** - Analysis tool integration

### Research Team
- **Principal Investigators**:
  - Linda Theron: linda.theron@up.ac.za (University of Pretoria)
  - Caradee Wright: Caradee.Wright@mrc.ac.za (South African Medical Research Council)
  - John Palmer: john.palmer@upf.edu (Universitat Pompeu Fabra, Barcelona)

### Study Coordination
- **Participant Recruitment** - Contact research coordinators
- **Data Queries** - Statistical analysis support
- **Protocol Questions** - Research methodology guidance

## Additional Resources

### Training Materials
- **Researcher Training** - Onboarding for new team members
- **Data Analysis Protocols** - Standardized analysis procedures
- **Best Practices** - Research quality guidelines

### Publications
- **Study Protocol** - Published research methodology
- **Preliminary Results** - Early findings and insights
- **Conference Presentations** - Research dissemination

---

*For questions about this guide, contact the research team or open an issue on [GitHub](https://github.com/ActivitySpaceLab/gauteng-wellbeing-mapper-app/issues).*
