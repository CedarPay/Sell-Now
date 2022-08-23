import requests
import json

# https://looksrare.github.io/api-docs/#/Orders/OrderController.getOrders
# Script for fetching the lowest listing to buy an NFT
collection_address = "0x5Af0D9827E0c53E4799BB226655A1de152A425a5"
url = f'https://api.looksrare.org/api/v1/orders?isOrderAsk=true&collection={collection_address}&status%5B%5D=VALID&sort=PRICE_ASC'

headers = {
    "Accept": "application/json",
    "X-API-KEY": "ajZV70CYg4ask6yHVtfIldXQ"
}


response = requests.get(url, headers=headers)

response_data = response.json()
with open('looksrare-buy.json', 'w') as json_file:
    json.dump(response_data, json_file)