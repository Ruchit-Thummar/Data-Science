from data import fruit_stock
from logger import log_transaction

def add_fruits():
    name = input('Fruit name ').lower()
    qty = int(input('Quantity '))
    price = int(input('Price '))

    fruit_stock[name] = {'price': price, 'quantity': qty}
    print('Fruit added')
    log_transaction(f"Added {qty} {name} at {price}")
    print("Task completed successfully")

def view_fruits():
    if fruit_stock:
        print(fruit_stock)
    else:
        print('No fruits in stock')
    print("Task completed successfully")

def update_fruits():
    name = input('Enter fruit name to update ').lower()

    if name not in fruit_stock:
        print(f'{name} fruit is not found')
        return

    print('What do you want to update?')
    print("1. Name")
    print("2. Quantity")
    print("3. Price")

    c = input('Enter your choice: ')

    if c == '1':
        newname = input('Enter new name ').lower()
        fruit_stock[newname] = fruit_stock.pop(name)
        name = newname
        print(f"Name changed to {name}")
        log_transaction(f"Renamed fruit to {name}")

    elif c == '2':
        qty = int(input('Enter new quantity '))
        fruit_stock[name]['quantity'] = qty
        print(f"Quantity of {name} updated")
        log_transaction(f"Updated {name} quantity to {qty}")

    elif c == '3':
        price = int(input('Enter new price: '))
        fruit_stock[name]['price'] = price
        print(f"Price of {name} updated")
        log_transaction(f"Updated {name} price to {price}")

    else:
        print("Invalid option selected")
        return

    print("Task completed successfully")
