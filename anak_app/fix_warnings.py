import os
import re

base_dir = r"c:\Users\ThinkPad\Downloads\ANAK Mobile App UI\anak_app\lib"

# Fix cognitive, linguistic, motor unused variables
files_with_unused = [
    'screens/cognitive_test_screen.dart',
    'screens/linguistic_test_screen.dart',
    'screens/motor_test_game_screen.dart',
    'screens/word_puzzle_game_screen.dart',
    'screens/sticker_collection_screen.dart'
]

for f in files_with_unused:
    path = os.path.join(base_dir, f)
    if os.path.exists(path):
        with open(path, 'r', encoding='utf-8') as file:
            content = file.read()
        
        # Comment out specific known unused variables safely
        content = re.sub(r'(bool isThisSelected =.*?;)', r'// \1', content)
        content = re.sub(r'(bool isWrongSelected =.*?;)', r'// \1', content)
        content = re.sub(r'(bool isSelectedCorrect =.*?;)', r'// \1', content)
        content = re.sub(r'(int wordTime =.*?;)', r'// \1', content)
        content = re.sub(r'(int stars =.*?;)', r'// \1', content)
        content = re.sub(r'(final rarityOrder =.*?;)', r'// \1', content)
        
        with open(path, 'w', encoding='utf-8') as file:
            file.write(content)

# Fix childProfile?.name everywhere
for root, dirs, files in os.walk(base_dir):
    for f in files:
        if f.endswith('.dart'):
            path = os.path.join(root, f)
            with open(path, 'r', encoding='utf-8') as file:
                content = file.read()
            
            new_content = re.sub(r'childProfile\?\.name \?\? \'Sobat\'', r'childProfile.name', content)
            new_content = re.sub(r'childProfile\?\.name', r'childProfile.name', new_content)
            
            if new_content != content:
                with open(path, 'w', encoding='utf-8') as file:
                    file.write(new_content)

# Fix unused imports
sticker_notif = os.path.join(base_dir, 'widgets', 'sticker_notification.dart')
if os.path.exists(sticker_notif):
    with open(sticker_notif, 'r', encoding='utf-8') as file:
        content = file.read()
    content = content.replace("import '../models/sticker.dart';", "")
    with open(sticker_notif, 'w', encoding='utf-8') as file:
        file.write(content)

widget_test = os.path.join(base_dir, '..', 'test', 'widget_test.dart')
if os.path.exists(widget_test):
    with open(widget_test, 'r', encoding='utf-8') as file:
        content = file.read()
    content = content.replace("import 'package:flutter/material.dart';", "")
    with open(widget_test, 'w', encoding='utf-8') as file:
        file.write(content)

print("Warning fixes applied successfully!")
