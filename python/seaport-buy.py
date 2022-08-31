import requests
import json

# https://docs.opensea.io/v2.0/reference/retrieve-listings
# Script for fetching the lowest listing to buy an NFT
collection_address = "0x5Af0D9827E0c53E4799BB226655A1de152A425a5"
url = f'https://api.opensea.io/v2/orders/ethereum/seaport/listings'

headers = {
    "X-API-KEY": "2972994f68bb4dfc9f68c944f473c329"
}

params = {
    "asset_contract_address": "0x5Af0D9827E0c53E4799BB226655A1de152A425a5",
    "token_ids": "5313"
}

response = requests.get(url, headers=headers, params=params)

response_data = response.json()
with open('seaport-buy.json', 'w') as json_file:
    json.dump(response_data, json_file)