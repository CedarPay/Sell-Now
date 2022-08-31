import requests
import json

# https://docs.opensea.io/v2.0/reference/retrieve-offers
# Script for fetching the lowest listing to buy an NFT
collection_address = "0x5Af0D9827E0c53E4799BB226655A1de152A425a5"
url = f'https://api.opensea.io/v2/orders/ethereum/seaport/offers'

headers = {
    "X-API-KEY": "2972994f68bb4dfc9f68c944f473c329"
}

params = {
    "asset_contract_address": "0x5Af0D9827E0c53E4799BB226655A1de152A425a5",
    "token_ids": "3852"
}

response = requests.get(url, headers=headers, params=params)

response_data = response.json()
with open('seaport-sell.json', 'w') as json_file:
    json.dump(response_data, json_file)


