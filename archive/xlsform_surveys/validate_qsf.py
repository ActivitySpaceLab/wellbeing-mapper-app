#!/usr/bin/env python3
"""
Validate QSF files and provide summary information
"""

import json
from pathlib import Path

def validate_qsf_file(file_path):
    """Validate a QSF file and return summary information"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        # Count questions
        questions = [e for e in data.get('SurveyElements', []) if e.get('Type') == 'Question']
        blocks = [e for e in data.get('SurveyElements', []) if e.get('Type') == 'Block']
        
        survey_name = data.get('SurveyEntry', {}).get('SurveyName', 'Unknown')
        
        return {
            'valid': True,
            'survey_name': survey_name,
            'questions': len(questions),
            'blocks': len(blocks),
            'file_size': file_path.stat().st_size
        }
    except Exception as e:
        return {
            'valid': False,
            'error': str(e),
            'file_size': file_path.stat().st_size if file_path.exists() else 0
        }

def main():
    current_dir = Path(__file__).parent
    
    qsf_files = [
        'Biweekly_Wellbeing_Survey.qsf',
        'Initial_Demographics_Survey.qsf'
    ]
    
    print("🔍 QSF File Validation Report")
    print("=" * 50)
    
    all_valid = True
    
    for qsf_file in qsf_files:
        file_path = current_dir / qsf_file
        if not file_path.exists():
            print(f"❌ {qsf_file}: File not found")
            all_valid = False
            continue
            
        result = validate_qsf_file(file_path)
        
        if result['valid']:
            print(f"✅ {qsf_file}")
            print(f"   Survey: {result['survey_name']}")
            print(f"   Questions: {result['questions']}")
            print(f"   Blocks: {result['blocks']}")
            print(f"   File Size: {result['file_size']:,} bytes")
        else:
            print(f"❌ {qsf_file}: {result['error']}")
            print(f"   File Size: {result['file_size']:,} bytes")
            all_valid = False
        
        print()
    
    if all_valid:
        print("🎉 All QSF files are valid and ready for Qualtrics import!")
    else:
        print("⚠️  Some QSF files have issues - please review before importing.")

if __name__ == '__main__':
    main()
