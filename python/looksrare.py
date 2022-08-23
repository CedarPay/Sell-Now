import requests
import json

# https://looksrare.github.io/api-docs/#/Orders/OrderController.getOrders
collection_address = "0x5Af0D9827E0c53E4799BB226655A1de152A425a5"
url = f'https://api.looksrare.org/api/v1/orders?isOrderAsk=false&collection={collection_address}&status%5B%5D=VALID&sort=PRICE_DESC'

headers = {
    "Accept": "application/json",
    "X-API-KEY": "ajZV70CYg4ask6yHVtfIldXQ"
}


response = requests.get(url, headers=headers)

response_data = response.json()
with open('looksrare.json', 'w') as json_file:
    json.dump(response_data, json_file)