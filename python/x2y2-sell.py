import requests
import json

# https://x2y2.readme.io/reference/get_v1-offers
# Script for fetching the hightest offer to instance sell the NFT
url = "https://api.x2y2.org/v1/offers"

headers = {
    "Accept": "application/json",
    "X-API-KEY": "a5926278-bd6c-449a-8b67-366d03a61eb4"
}

params = {
    "contract": "0x5Af0D9827E0c53E4799BB226655A1de152A425a5"
}


response = requests.get(url, headers=headers, params=params)

response_data = response.json()
with open('x2y2-sell.json', 'w') as json_file:
    json.dump(response_data, json_file)