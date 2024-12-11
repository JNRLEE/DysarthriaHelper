import os
import subprocess
import time
from datetime import datetime
import sys

# Path to training data directory
TRAINING_DATA_DIR = "/work/jerryfat/kaldi-trunk/egs/chiangyihan/s5/data/TrainingData"
SHELL_SCRIPT = "/work/jerryfat/kaldi-trunk/egs/chiangyihan/s5/run_combine_augment_JnrleV3.sh"

def get_model_directories():
    """Get all directories in the training data path."""
    return [d for d in os.listdir(TRAINING_DATA_DIR) 
            if os.path.isdir(os.path.join(TRAINING_DATA_DIR, d))]

def run_model(model_name):
    """Run the shell script for a specific model and wait for completion signal."""
    print(f"\n{'='*80}")
    print(f"Starting analysis for model: {model_name}")
    print(f"Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"{'='*80}\n")
    
    try:
        process = subprocess.Popen(
            ['bash', SHELL_SCRIPT, model_name],
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            universal_newlines=True,
            bufsize=1
        )

        inside_testing_found = False
        
        while True:
            line = process.stdout.readline()
            
            # Check if process ended unexpectedly
            if line == '' and process.poll() is not None:
                if not inside_testing_found:
                    print(f"Warning: Process ended without showing Inside testing results!")
                break
                
            if line:
                print(line.rstrip(), flush=True)
                
                # Check for completion marker
                if "#####Inside testing#####" in line:
                    inside_testing_found = True
                    # Continue reading a few more lines to get the WER results
                    for _ in range(3):
                        line = process.stdout.readline()
                        if line:
                            print(line.rstrip(), flush=True)
                    break
        
        # If process is still running after finding results, terminate it
        if inside_testing_found and process.poll() is None:
            process.terminate()
            try:
                process.wait(timeout=10)  # Give it 10 seconds to clean up
            except subprocess.TimeoutExpired:
                process.kill()  # Force kill if it doesn't terminate
        
        return_code = process.poll()
        
        print(f"\n{'='*80}")
        print(f"Completed analysis for model: {model_name}")
        print(f"Inside testing results found: {inside_testing_found}")
        print(f"Return code: {return_code}")
        print(f"Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"{'='*80}\n")
        
    except Exception as e:
        print(f"Error processing {model_name}: {str(e)}")

def main():
    # Get all model directories
    model_dirs = get_model_directories()
    
    print(f"Found {len(model_dirs)} models to process")
    
    # Process each model sequentially
    for idx, model_name in enumerate(model_dirs, 1):
        print(f"\nProcessing model {idx}/{len(model_dirs)}: {model_name}")
        run_model(model_name)
        time.sleep(2)  # Small delay between models

if __name__ == "__main__":
    main()