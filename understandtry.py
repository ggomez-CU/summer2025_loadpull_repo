from datetime import datetime
import os
import json
import shutil
import time

def main():

    data = {}
    output_file = os.getcwd() + "\\temp.json"

    with open(output_file, 'w') as f:
        json.dump(data, f, indent = 4)

    for i in range(100):
        try:
            thetime = {'Time' + str(i) : datetime.now().strftime("%H %M %S")}
            data.update(thetime)
            with open('temp.json', 'w') as f:
                json.dump(data,f,indent=4)

            os.remove(output_file)
            shutil.copyfile('temp.json', output_file)
        except:
            pass
        time.sleep(2)



if __name__ == "__main__":
    main()