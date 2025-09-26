#!/usr/bin/env python3
"""
Convert CSV files to XLSForm Excel workbooks
Creates proper Excel files with survey, choices, and settings worksheets
"""

import pandas as pd
from pathlib import Path
import sys

def create_xlsform_workbook(survey_csv, choices_csv, settings_csv, output_xlsx):
    """Create an XLSForm Excel workbook from CSV files"""
    try:
        # Read CSV files
        survey_df = pd.read_csv(survey_csv)
        choices_df = pd.read_csv(choices_csv)
        settings_df = pd.read_csv(settings_csv)
        
        # Create Excel writer
        with pd.ExcelWriter(output_xlsx, engine='openpyxl') as writer:
            # Write each worksheet
            survey_df.to_excel(writer, sheet_name='survey', index=False)
            choices_df.to_excel(writer, sheet_name='choices', index=False)
            settings_df.to_excel(writer, sheet_name='settings', index=False)
            
        print(f"Successfully created {output_xlsx}")
        return True
        
    except Exception as e:
        print(f"Error creating {output_xlsx}: {e}")
        return False

def main():
    # Get the current directory
    current_dir = Path(__file__).parent
    
    # Create biweekly survey workbook
    biweekly_success = create_xlsform_workbook(
        current_dir / 'biweekly_survey_data.csv',
        current_dir / 'biweekly_choices_data.csv', 
        current_dir / 'biweekly_settings_data.csv',
        current_dir / 'Biweekly_Wellbeing_Survey_XLSForm.xlsx'
    )
    
    # Create initial survey workbook  
    initial_success = create_xlsform_workbook(
        current_dir / 'initial_survey_data.csv',
        current_dir / 'initial_choices_data.csv',
        current_dir / 'initial_settings_data.csv', 
        current_dir / 'Initial_Survey_XLSForm.xlsx'
    )
    
    if biweekly_success and initial_success:
        print("\n✅ Both XLSForm workbooks created successfully!")
        print("Files created:")
        print("- Biweekly_Wellbeing_Survey_XLSForm.xlsx")
        print("- Initial_Survey_XLSForm.xlsx")
        print("\n💡 To also generate QSF files for Qualtrics import, run:")
        print("   python create_qsf_surveys.py")
    else:
        print("\n❌ Some workbooks failed to create")
        sys.exit(1)

if __name__ == '__main__':
    main()
