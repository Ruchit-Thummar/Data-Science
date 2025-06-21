from logger import view_log

def customer_menu():
    while True:
        print("\nCustomer Menu ")
        print("1. View Transactions")

        choice = input("Enter your choice ")

        if choice == '1':
            view_log()
        else:
            print("Invalid option")

        again = input("Do you want to perform more operations? ").lower()
        if again != 'yes':
            break
