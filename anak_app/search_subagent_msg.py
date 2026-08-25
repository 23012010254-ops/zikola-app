import os
import json
import sys

sys.stdout.reconfigure(encoding='utf-8')

app_data_dir = r"C:\Users\ThinkPad\.gemini\antigravity"
convo_id = "97cb6595-599e-4675-b015-b1de5d24e666"
transcript_path = os.path.join(app_data_dir, "brain", convo_id, ".system_generated", "logs", "transcript_full.jsonl")

if not os.path.exists(transcript_path):
    print("No transcript_full.jsonl")
    sys.exit(1)

with open(transcript_path, 'r', encoding='utf-8') as f:
    for idx, line in enumerate(f, 1):
        try:
            data = json.loads(line)
            content = data.get("content", "")
            # Check if this contains the subagent's report or response
            if content and ("spell_bee_game_screen" in content or "word_puzzle_game_screen" in content) and "Lomba Eja" in content:
                print(f"--- MATCH FOUND AT LINE {idx} ---")
                print(content[:3000])
                print("..." if len(content) > 3000 else "")
                print("="*80)
        except Exception as e:
            pass
