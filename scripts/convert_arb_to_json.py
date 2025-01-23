#!/usr/bin/env python3

import json
import os
import sys

def convert_arb_to_json(arb_path, json_path):
    with open(arb_path, 'r') as arb_file:
        arb_data = json.load(arb_file)
    
    # Filter out Flutter-specific keys
    filtered_data = {k: v for k, v in arb_data.items() 
                     if not k.startswith('@') and 
                     k in ['translation_mode', 'original_text_mode']}
    
    with open(json_path, 'w') as json_file:
        json.dump(filtered_data, json_file, ensure_ascii=False, indent=2)

def main():
    arb_dir = 'lib/l10n'
    json_dir = 'android/app/src/main/assets'
    
    # Ensure JSON directory exists
    os.makedirs(json_dir, exist_ok=True)
    
    # Convert each ARB file
    for filename in os.listdir(arb_dir):
        if filename.startswith('app_') and filename.endswith('.arb'):
            arb_path = os.path.join(arb_dir, filename)
            json_filename = filename.replace('.arb', '.json')
            json_path = os.path.join(json_dir, json_filename)
            
            convert_arb_to_json(arb_path, json_path)
            print(f'Converted {filename} to {json_filename}')

if __name__ == '__main__':
    main()
