# Corrected R Code for Qualtrics Data Processing
# Based on actual app source code mappings from qualtrics_api_service.dart

# Load required libraries
library(dplyr)
library(readr)

# Create mapping data frames based on ACTUAL app source code
create_qualtrics_mappings <- function() {
  
  # Initial Survey Mapping (34 questions) - Based on _mapInitialSurveyToQualtrics()
  # NOTE: NEW SURVEYS now capture ALL 34 questions (Q1-Q34) - NO DATA LOSS!
  initial_survey_mapping <- data.frame(
    qid = paste0("Q", 1:34),
    app_field = c(
      "participant_uuid", "age", "suburb", "ethnicity", "gender",
      "sexuality", "birth_place", "building_type", "household_items", "education",
      "climate_activism", "employment_status", "income", "activities", "living_arrangement",
      "relationship_status", "general_health", "cheerful_spirits", "calm_relaxed", "active_vigorous",
      "woke_up_fresh", "daily_life_interesting", "cooperate_with_people", "improving_skills", "social_situations",
      "family_support", "family_knows_me", "access_to_food", "people_enjoy_time", "talk_to_family",
      "friends_support", "belong_in_community", "location_data", "submitted_at"
    ),
    question_text = c(
      "Participant UUID (hidden)",
      "Age",
      "Suburb or community in Gauteng",
      "Race/ethnicity (comma-separated)",
      "Gender identity",
      "Sexual orientation",
      "Place of birth",
      "Building type",
      "Household items (comma-separated)",
      "Education level",
      "Climate activism involvement",
      "Employment status",
      "Income",
      "Activities in last two weeks (comma-separated)",
      "Living arrangement",
      "Relationship status",
      "General health (1-5)",
      "WHO-5: Cheerful spirits (0-5)",
      "WHO-5: Calm and relaxed (0-5)",
      "WHO-5: Active and vigorous (0-5)",
      "WHO-5: Woke up fresh and rested (0-5)",
      "WHO-5: Daily life filled with interesting things (0-5)",
      "Personal: I cooperate with people (1-5)",
      "Personal: Improving qualifications/skills important (1-5)",
      "Personal: Know how to behave in social situations (1-5)",
      "Personal: Family have supported me (1-5)",
      "Personal: Family knows me (scale)",
      "Personal: Access to food (scale)",
      "Personal: People enjoy time with me (scale)",
      "Personal: Talk to family about problems (scale)",
      "Personal: Friends support me (scale)",
      "Personal: Belong in community (scale)",
      "Encrypted location data (hidden)",
      "Submission timestamp (hidden)"
    ),
    expected_values = c(
      "UUID string",
      "Number",
      "String",
      "Comma-separated list",
      "Male, Female, Transmale, Transfemale, Non-binary, Prefer not to say",
      "Heterosexual/straight, Lesbian, Gay, Bisexual, Queer, Other, Prefer not to say",
      "South Africa, Other African country, Other country, Prefer not to say",
      "A brick house, A townhouse in a complex, An RDP house, A flat or apartment, A backyard room, Informal dwelling, Other",
      "Comma-separated list of items",
      "Less than high school, High school, TVET college, Bachelor's degree, Professional degree, Post-graduate degree, Prefer not to say",
      "all the time, often, sometimes, occasionally, never",
      "Employment status",
      "Income level",
      "Comma-separated list of activities",
      "alone, others",
      "Single, In a committed relationship/married, Separated, Divorced, Widowed",
      "1=Excellent, 2=Very good, 3=Good, 4=Fair, 5=Poor",
      "0=At no time, 1=Some of the time, 2=Less than half, 3=More than half, 4=Most of the time, 5=All of the time",
      "0=At no time, 1=Some of the time, 2=Less than half, 3=More than half, 4=Most of the time, 5=All of the time",
      "0=At no time, 1=Some of the time, 2=Less than half, 3=More than half, 4=Most of the time, 5=All of the time",
      "0=At no time, 1=Some of the time, 2=Less than half, 3=More than half, 4=Most of the time, 5=All of the time",
      "0=At no time, 1=Some of the time, 2=Less than half, 3=More than half, 4=Most of the time, 5=All of the time",
      "1=Not at all, 2=A little, 3=Somewhat, 4=Quite a bit, 5=A lot",
      "1=Not at all, 2=A little, 3=Somewhat, 4=Quite a bit, 5=A lot",
      "1=Not at all, 2=A little, 3=Somewhat, 4=Quite a bit, 5=A lot",
      "1=Not at all, 2=A little, 3=Somewhat, 4=Quite a bit, 5=A lot",
      "Scale value",
      "Scale value",
      "Scale value", 
      "Scale value",
      "Scale value",
      "Scale value",
      "Encrypted JSON string",
      "ISO 8601 datetime string"
    ),
    survey_type = "initial",
    stringsAsFactors = FALSE
  )
  
  # Biweekly Survey Mapping (19 questions) - Based on _mapBiweeklySurveyToQualtrics()
  # App sends QID1_TEXT through QID19_TEXT, but Qualtrics exports as Q1-Q19
  biweekly_survey_mapping <- data.frame(
    qid = paste0("Q", 1:19),
    app_field = c(
      "participant_uuid", "activities", "living_arrangement", "relationship_status",
      "general_health", "cheerful_spirits", "calm_relaxed", "active_vigorous",
      "woke_up_fresh", "daily_life_interesting", "cooperate_with_people",
      "improving_skills", "social_situations", "family_support",
      "environmental_challenges", "challenges_stress_level", "coping_help",
      "location_data", "submitted_at"
    ),
    question_text = c(
      "Participant UUID (hidden)",
      "Activities in last two weeks (comma-separated)",
      "Living arrangement",
      "Relationship status",
      "General health (1-5)",
      "WHO-5: Have you been in good spirits? (0-5)",
      "WHO-5: Have you felt calm and relaxed? (0-5)",
      "WHO-5: Have you felt active and vigorous? (0-5)",
      "WHO-5: Did you wake up feeling fresh and rested? (0-5)",
      "WHO-5: Has your daily life been filled with things that interest you? (0-5)",
      "Personal: I cooperate with people (1-5)",
      "Personal: Improving qualifications/skills important (1-5)",
      "Personal: Know how to behave in social situations (1-5)",
      "Personal: Family have supported me (1-5)",
      "Environmental challenges experienced (text)",
      "Stress level from challenges",
      "What helped cope with challenges (text)",
      "Encrypted location data (hidden)",
      "Submission timestamp (hidden)"
    ),
    expected_values = c(
      "UUID string",
      "Comma-separated list of activities",
      "alone, others",
      "Single, In a committed relationship/married, Separated, Divorced, Widowed",
      "1=Excellent, 2=Very good, 3=Good, 4=Fair, 5=Poor",
      "0=At no time, 1=Some of the time, 2=Less than half, 3=More than half, 4=Most of the time, 5=All of the time",
      "0=At no time, 1=Some of the time, 2=Less than half, 3=More than half, 4=Most of the time, 5=All of the time",
      "0=At no time, 1=Some of the time, 2=Less than half, 3=More than half, 4=Most of the time, 5=All of the time",
      "0=At no time, 1=Some of the time, 2=Less than half, 3=More than half, 4=Most of the time, 5=All of the time",
      "0=At no time, 1=Some of the time, 2=Less than half, 3=More than half, 4=Most of the time, 5=All of the time",
      "1=Not at all, 2=A little, 3=Somewhat, 4=Quite a bit, 5=A lot",
      "1=Not at all, 2=A little, 3=Somewhat, 4=Quite a bit, 5=A lot",
      "1=Not at all, 2=A little, 3=Somewhat, 4=Quite a bit, 5=A lot",
      "1=Not at all, 2=A little, 3=Somewhat, 4=Quite a bit, 5=A lot",
      "Free text",
      "Stress level scale",
      "Free text",
      "Encrypted JSON string",
      "ISO 8601 datetime string"
    ),
    survey_type = "biweekly",
    stringsAsFactors = FALSE
  )
  
  # Consent Form Mapping (16 questions) - Based on _mapConsentToQualtrics()
  consent_survey_mapping <- data.frame(
    qid = paste0("QID", 1:16),
    app_field = c(
      "participant_code", "participant_uuid", "informed_consent", "data_processing_consent",
      "race_ethnicity_consent", "health_consent", "sexual_orientation_consent", "location_mobility_consent",
      "data_transfer_consent", "public_reporting_consent", "data_sharing_researchers_consent", "further_research_consent",
      "public_repository_consent", "followup_contact_consent", "participant_signature", "consented_at"
    ),
    question_text = c(
      "Participant Code",
      "Participant UUID (hidden)",
      "I GIVE MY CONSENT to participate in this pilot study",
      "I GIVE MY CONSENT for my personal data to be processed by Qualtrics",
      "I GIVE MY CONSENT to being asked about by race/ethnicity",
      "I GIVE MY CONSENT to being asked about my health",
      "I GIVE MY CONSENT to being asked about my sexual orientation",
      "I GIVE MY CONSENT to being asked about my location and mobility",
      "I GIVE MY CONSENT to transferring my personal data to countries outside South Africa",
      "I GIVE MY CONSENT to researchers reporting what I contribute publicly without my full name",
      "I GIVE MY CONSENT to what I contribute being shared with national and international researchers",
      "I GIVE MY CONSENT to what I contribute being used for further research or teaching purposes",
      "I GIVE MY CONSENT to what I contribute being placed in a public repository in deidentified form",
      "I GIVE MY CONSENT to being contacted about participation in possible follow-up studies",
      "Participant signature",
      "Consent timestamp"
    ),
    expected_values = c(
      "String",
      "UUID string",
      "1 or 0",
      "1 or 0",
      "1 or 0",
      "1 or 0",
      "1 or 0",
      "1 or 0",
      "1 or 0",
      "1 or 0",
      "1 or 0",
      "1 or 0",
      "1 or 0",
      "1 or 0",
      "String",
      "ISO 8601 datetime string"
    ),
    survey_type = "consent",
    stringsAsFactors = FALSE
  )
  
  # Combine all mappings
  all_mappings <- rbind(initial_survey_mapping, biweekly_survey_mapping, consent_survey_mapping)
  
  return(list(
    initial = initial_survey_mapping,
    biweekly = biweekly_survey_mapping,
    consent = consent_survey_mapping,
    all = all_mappings
  ))
}

# Function to apply mappings to your Qualtrics data
apply_qualtrics_mappings <- function(qualtrics_data, survey_type = "auto") {
  
  # Get mappings
  mappings <- create_qualtrics_mappings()
  
  # Auto-detect survey type if not specified
  if (survey_type == "auto") {
    if ("Q34" %in% names(qualtrics_data)) {
      survey_type <- "initial"
    } else if ("Q19" %in% names(qualtrics_data)) {
      survey_type <- "biweekly"
    } else if ("QID16" %in% names(qualtrics_data)) {
      survey_type <- "consent"
    } else {
      # Let's check what columns are actually present for debugging
      cat("Available columns:", paste(names(qualtrics_data), collapse = ", "), "\n")
      stop("Cannot auto-detect survey type. Please specify: 'initial', 'biweekly', or 'consent'")
    }
  }
  
  # Get appropriate mapping
  mapping <- mappings[[survey_type]]
  
  # Create a lookup for renaming columns
  old_names <- names(qualtrics_data)
  new_names <- old_names
  
  # Apply mappings to column names
  for (i in 1:nrow(mapping)) {
    qid_pattern <- mapping$qid[i]
    if (qid_pattern %in% old_names) {
      new_names[old_names == qid_pattern] <- mapping$app_field[i]
    }
  }
  
  # Rename columns
  names(qualtrics_data) <- new_names
  
  # Add metadata as attributes
  for (i in 1:nrow(mapping)) {
    if (mapping$app_field[i] %in% names(qualtrics_data)) {
      attr(qualtrics_data[[mapping$app_field[i]]], "question_text") <- mapping$question_text[i]
      attr(qualtrics_data[[mapping$app_field[i]]], "expected_values") <- mapping$expected_values[i]
      attr(qualtrics_data[[mapping$app_field[i]]], "original_qid") <- mapping$qid[i]
    }
  }
  
  # Add survey type as attribute to the data frame
  attr(qualtrics_data, "survey_type") <- survey_type
  
  return(qualtrics_data)
}

# Function to get question metadata
get_question_info <- function(data, field_name) {
  if (field_name %in% names(data)) {
    list(
      field_name = field_name,
      question_text = attr(data[[field_name]], "question_text"),
      expected_values = attr(data[[field_name]], "expected_values"),
      original_qid = attr(data[[field_name]], "original_qid")
    )
  } else {
    NULL
  }
}

# Function to create a data dictionary
create_data_dictionary <- function(mapped_data) {
  field_names <- names(mapped_data)
  
  dictionary <- data.frame(
    field_name = character(0),
    original_qid = character(0),
    question_text = character(0),
    expected_values = character(0),
    stringsAsFactors = FALSE
  )
  
  for (field in field_names) {
    info <- get_question_info(mapped_data, field)
    if (!is.null(info)) {
      dictionary <- rbind(dictionary, data.frame(
        field_name = info$field_name,
        original_qid = info$original_qid %||% "",
        question_text = info$question_text %||% "",
        expected_values = info$expected_values %||% "",
        stringsAsFactors = FALSE
      ))
    }
  }
  
  return(dictionary)
}

# Helper function for null coalescing
`%||%` <- function(x, y) if (is.null(x)) y else x

# Debug function to examine actual column structure
examine_qualtrics_structure <- function(data) {
  cat("Dataset has", ncol(data), "columns:\n")
  cat("Column names:\n")
  for (i in 1:length(names(data))) {
    cat(sprintf("%2d: %s\n", i, names(data)[i]))
  }
  
  # Look for QID patterns
  qid_cols <- grep("^QID\\d+", names(data), value = TRUE)
  
  if (length(qid_cols) > 0) {
    cat("\nQID columns found:", paste(qid_cols, collapse = ", "), "\n")
    max_qid <- max(as.numeric(gsub("QID", "", qid_cols)))
    cat("Highest QID:", max_qid, "\n")
    
    # Suggest survey type
    if (max_qid >= 34) {
      cat("Suggested survey type: initial (34 questions)\n")
    } else if (max_qid >= 19) {
      cat("Suggested survey type: biweekly (19 questions)\n") 
    } else if (max_qid >= 16) {
      cat("Suggested survey type: consent (16 questions)\n")
    }
  }
  
  return(list(
    total_cols = ncol(data),
    col_names = names(data),
    qid_cols = qid_cols
  ))
}

# Example usage:
# 
# # Load your Qualtrics data
# qualtrics_data <- read_csv("your_qualtrics_export.csv")
# 
# # Examine the structure first
# examine_qualtrics_structure(qualtrics_data)
# 
# # Apply mappings (auto-detects survey type based on max QID)
# mapped_data <- apply_qualtrics_mappings(qualtrics_data)
# 
# # Or specify survey type explicitly
# mapped_data <- apply_qualtrics_mappings(qualtrics_data, survey_type = "initial")
# 
# # Create a data dictionary for reference
# data_dict <- create_data_dictionary(mapped_data)
# write_csv(data_dict, "data_dictionary.csv")
# 
# # Get info about a specific field
# get_question_info(mapped_data, "general_health")
