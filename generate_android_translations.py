import json
import os
import xml.etree.ElementTree as ET
import xml.dom.minidom as minidom

# Accessibility-related string keys to translate
ACCESSIBILITY_KEYS = [
    'accessibility_service_label',
    'accessibility_service_description',
    'accessibility_permission_title',
    'accessibility_permission_message',
    'accessibility_permission_benefits',
    'accessibility_permission_how_to',
    'btn_enable_accessibility',
    'btn_cancel'
]

def load_arb_file(file_path):
    with open(file_path, 'r') as f:
        return json.load(f)

def create_xml_translation(translations):
    # Create root element
    root = ET.Element('resources')
    
    # Add translations for specified keys
    for key in ACCESSIBILITY_KEYS:
        if key in translations:
            string_elem = ET.SubElement(root, 'string', name=key)
            string_elem.text = translations[key]
    
    # Pretty print XML
    rough_string = ET.tostring(root, 'utf-8')
    reparsed = minidom.parseString(rough_string)
    return reparsed.toprettyxml(indent="    ")

def main():
    l10n_dir = '/home/jeromy/Work/screen_translate/lib/l10n'
    android_res_dir = '/home/jeromy/Work/screen_translate/android/app/src/main/res'
    
    for filename in os.listdir(l10n_dir):
        if filename.startswith('app_') and filename.endswith('.arb'):
            language_code = filename[4:-4]  # Extract language code
            
            # Skip if not a valid language code
            if len(language_code) != 2:
                continue
            
            # Load translations
            translations = load_arb_file(os.path.join(l10n_dir, filename))
            
            # Create XML translation
            xml_content = create_xml_translation(translations)
            
            # Write to Android resources directory
            output_dir = os.path.join(android_res_dir, f'values-{language_code}')
            os.makedirs(output_dir, exist_ok=True)
            
            output_file = os.path.join(output_dir, 'strings.xml')
            with open(output_file, 'w') as f:
                f.write(xml_content)
            
            print(f"Created translation for {language_code}: {output_file}")

if __name__ == '__main__':
    main()
