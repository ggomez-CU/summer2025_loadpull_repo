import subprocess

# Define the paths to your Python scripts
script1_path = ".\src\\system_validation_freqsweep.py"
script2_path = ".\src\\system_validation_freqsweep2.py"

# for i in range(5):
    # Run script1.py and wait for it to complete
print(f"Running {script1_path}...")
result1 = subprocess.run(["python", script1_path, "-f", "-i", "-p"], capture_output=True, text=True)
print(f"Output of {script1_path}:\n{result1.stdout}")
if result1.stderr:
    print(f"Errors from {script1_path}:\n{result1.stderr}")

print(f"Running {script2_path}...")
result2 = subprocess.run(["python", script2_path, "-f", "-i", "-p"], capture_output=True, text=True)
print(f"Output of {script2_path}:\n{result2.stdout}")
if result1.stderr:
    print(f"Errors from {script1_path}:\n{result1.stderr}")

print("\nAll scripts executed.")