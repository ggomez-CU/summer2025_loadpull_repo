import subprocess

# Define the paths to your Python scripts
script_path = '.\\src\\MMIC_driveupbias.py'
file1_path = r"C:\Users\grgo8200\Documents\GitHub\summer2025_loadpull_repo\data\PA_Spring2023\coupledlinephasefrommmic.json"
file2_path = r"C:\Users\grgo8200\Documents\GitHub\summer2025_loadpull_repo\data\PA_Spring2023\coupledlinebiasfrommmic.json"

# for i in range(5):
    # Run script1.py and wait for it to complete
# try:
#     print(f"Running {script_path}...")
#     result1 = subprocess.run(["python", script_path, "-o", "-i","-p", "-f", file1_path], capture_output=True, text=True)
#     print(f"Output of {script_path}:\n{result1.stdout}")
#     if result1.stderr:
#         print(f"Errors from {script_path}:\n{result1.stderr}")
# except:
#     quit()

print(f"Running {script_path}...")
result2 = subprocess.run(["python", script_path, "-o", "-i", "-p","-f", file2_path], capture_output=True, text=True)
print(f"Output of {script_path}:\n{result2.stdout}")
if result2.stderr:
    print(f"Errors from {script_path}:\n{result2.stderr}")

print(f"Running {script_path}...")
result1 = subprocess.run(["python", script_path, "-o", "-i", "-p","-f", file1_path], capture_output=True, text=True)
print(f"Output of {script_path}:\n{result1.stdout}")
if result1.stderr:
    print(f"Errors from {script_path}:\n{result1.stderr}")

print("\nAll scripts executed.")