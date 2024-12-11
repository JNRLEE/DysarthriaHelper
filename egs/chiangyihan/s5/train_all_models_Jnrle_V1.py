#!/usr/bin/env python3
import os
import subprocess
from pathlib import Path

def train_models():
    base_path = os.getcwd()
    training_data_path = os.path.join(base_path, "data/LDV_asr_Jnrle_v1/TrainingData")
    script_path = "./run_combine_augment_JnrleV2.sh"

    print(f"Current working directory: {base_path}")
    print(f"Looking for models in: {training_data_path}")

    try:
        model_names = [d for d in os.listdir(training_data_path) 
                      if os.path.isdir(os.path.join(training_data_path, d))]
        print(f"Found {len(model_names)} models to process")
    except Exception as e:
        print(f"Error accessing directory {training_data_path}: {str(e)}")
        return

    for model_name in model_names:
        print(f"\n=== Starting training for model: {model_name} ===")

        try:
            # Run the shell script, capturing stdout and stderr
            process = subprocess.Popen(
                ["bash", script_path, model_name],
                stdout=subprocess.PIPE,  # Capture stdout
                stderr=subprocess.PIPE,  # Capture stderr
                text=True              # Decode output as text (Python 3.7+)
            )

            # Print stdout and stderr as they become available
            while True:
                output = process.stdout.readline()
                error = process.stderr.readline()

                if output:
                    print(output.strip()) # Print without newline characters
                if error:
                    print(f"ERROR: {error.strip()}") # Highlight errors

                if process.poll() is not None: #Check if process finished
                    break


            returncode = process.wait() #Wait for the process to complete
            if returncode != 0:
                print(f"Training for {model_name} failed with return code: {returncode}")
                # Decide whether to continue or stop based on the error
                # You might want to raise an exception here to stop the loop
            else:    
                print(f"=== Completed processing for {model_name} ===")

        except Exception as e:
            print(f"Unexpected error with {model_name}: {str(e)}")
            # Always break on actual Python exceptions
            break

if __name__ == "__main__":
    train_models()