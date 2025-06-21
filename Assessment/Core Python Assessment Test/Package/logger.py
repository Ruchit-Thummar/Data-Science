import datetime

def log_transaction(message):
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    with open("activity.log", "a") as f:
        f.write(f"[{timestamp}] {message}\n")

def view_log():
    with open("activity.log", "r") as f:
        data = f.read()
    print(data)
