import base64
import glob

def file_to_base64(file_path):
    try:
        with open(file_path, "rb") as file:
            # Read file content and encode it to base64
            encoded_string = base64.b64encode(file.read()).decode('utf-8')
            return encoded_string
    except FileNotFoundError:
        return "File not found. Please provide a valid file path."

if __name__ == "__main__":
    paths = sorted(glob.glob('./thai_fonts/*.png'))
    
    for file_path in paths:
        print(file_path)
        print(file_to_base64(file_path))

