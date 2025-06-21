from manager import manager_menu
from customer import customer_menu

def run_store():
    print("Welcome to the Fruit Market ")

    while True:
        print("\nPlease choose your role ")
        print("1. Manager")
        print("2. Customer")

        role = input("Enter your choice ")

        if role == '1':
            manager_menu()
        elif role == '2':
            customer_menu()
        else:
            print("Invalid input")

run_store()