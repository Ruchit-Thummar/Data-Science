from stock import add_fruits, view_fruits, update_fruits

def manager_menu():
    while True:
        print("\nManager Menu")
        print("1. Add Fruit Stock")
        print("2. View Fruits Stock")
        print("3. Update Fruit Stock")

        choice = input("Enter your choice ")

        if choice == '1':
            add_fruits()
        elif choice == '2':
            view_fruits()
        elif choice == '3':
            update_fruits()
        else:
            print("Invalid option")

        again = input("Do you want to perform more operations? ").lower()
        if again != 'yes':
            break
