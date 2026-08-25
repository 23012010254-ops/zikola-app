import os
import re

files = [
    'story_builder_game.dart',
    'word_puzzle_game_screen.dart',
    'shape_sorting_game.dart',
    'sequence_memory_game.dart',
    'pattern_recognition_game_screen.dart',
    'number_sequence_game_screen.dart',
    'number_memory_game.dart',
    'mirror_pattern_game.dart',
    'memory_game_screen.dart',
    'desert_tank_shooter_game.dart',
    'desert_road_logic_game.dart',
    'alien_shooter_game.dart'
]

base_dir = r"c:\Users\ThinkPad\Downloads\ANAK Mobile App UI\anak_app\lib\screens"

for f in files:
    path = os.path.join(base_dir, f)
    with open(path, 'r', encoding='utf-8') as file:
        content = file.read()
    
    def replacer(match):
        game_key = match.group(1)
        inner = match.group(2)
        
        score_match = re.search(r"'score':\s*([^,}\n]+)", inner)
        time_match = re.search(r"'timeSpent':\s*([^,}\n]+)", inner)
        errors_match = re.search(r"'errors':\s*([^,}\n]+)", inner)
        
        score_val = score_match.group(1).strip() if score_match else '0'
        time_val = time_match.group(1).strip() if time_match else '0'
        errors_val = errors_match.group(1).strip() if errors_match else '0'
        
        return f"updateGameAssessment({game_key}, GameSession(score: {score_val}, timeSpent: {time_val}, errors: {errors_val}));"
        
    new_content = re.sub(r"updateGameAssessment\((['a-zA-Z]+),\s*\{([^}]*)\}\s*\);", replacer, content)
    
    with open(path, 'w', encoding='utf-8') as file:
        file.write(new_content)
print('Done!')
