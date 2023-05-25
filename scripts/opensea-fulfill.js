const options = { method: "GET", headers: { accept: "application/json" } };
const contract_address = "0xEAAfcC17f28Afe5CdA5b3F76770eFb7ef162D20b";
const token_ids = ["10"];
const chainName = "goerli";
const fulfiller = "0x6278A1E803A76796a3A1f7F6344fE874ebfe94B2";
async function main() {
  const [orderhashs, protocolAddress] = await getOrderHashs(
    contract_address,
    token_ids
  );
  await waitOneSecond();
  const transactions = [];
  for (let i = 0; i < orderhashs.length; i++) {
    const transaction = await getFulfillmentData_transaction(
      orderhashs[i],
      chainName,
      protocolAddress[i],
      fulfiller
    );
    transactions.push(transaction);
  }
  console.log(transactions);
}
function waitOneSecond() {
  return new Promise((resolve) => setTimeout(resolve, 1000));
}
async function getOrderHashs(contract_address, token_ids) {
  let str_token_ids = "";
  for (let i = 0; i < token_ids.length; i++) {
    if (i == 0) {
      str_token_ids = `${token_ids[i]}`;
    } else {
      str_token_ids = str_token_ids + `&token_ids=${token_ids[i]}`;
    }
  }

  const listings_url = `https://testnets-api.opensea.io/v2/orders/goerli/seaport/listings?asset_contract_address=${contract_address}&token_ids=${str_token_ids}`;
  const orders = await fetch(listings_url, options)
    .then((response) => response.json())
    .then((response) => {
      return response.orders;
    })
    .catch((err) => console.error(err));

  const orderhashs = [];
  const protocolAddress = [];
  for (let i = 0; i < orders.length; i++) {
    orderhashs.push(orders[i].order_hash);
    protocolAddress.push(orders[i].protocol_address);
  }
  return [orderhashs, protocolAddress];
}

async function getFulfillmentData_transaction(
  hash,
  chainName,
  protocol_address,
  fulfiller
) {
  const options = {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({
      listing: {
        hash: hash,
        chain: chainName,
        protocol_address: protocol_address,
      },
      fulfiller: { address: fulfiller },
    }),
  };

  const response_data = await fetch(
    "https://testnets-api.opensea.io/v2/listings/fulfillment_data",
    options
  )
    .then((response) => response.json())
    .then((response) => {
      return response;
    })
    .catch((err) => console.error(err));

  return response_data.fulfillment_data.transaction;
}

main();

const fulfillmentData_demo = {
  protocol: "seaport1.5",
  fulfillment_data: {
    transaction: {
      function:
        "fulfillBasicOrder_efficient_6GL6yc((address,uint256,uint256,address,address,address,uint256,uint256,uint8,uint256,uint256,bytes32,uint256,bytes32,bytes32,uint256,(uint256,address)[],bytes))",
      chain: 5,
      to: "0x00000000000000adc04c56bf30ac9d3c0aaf14dc",
      value: 100000000000000000,
      input_data: {
        parameters: {
          considerationToken: "0x0000000000000000000000000000000000000000",
          considerationIdentifier: "0",
          considerationAmount: "97500000000000000",
          offerer: "0x6278a1e803a76796a3a1f7f6344fe874ebfe94b2",
          zone: "0x004c00500000ad104d7dbd00e3ae0a5c00560c00",
          offerToken: "0xeaafcc17f28afe5cda5b3f76770efb7ef162d20b",
          offerIdentifier: "10",
          offerAmount: "1",
          basicOrderType: 0,
          startTime: "1684139190",
          endTime: "1686817590",
          zoneHash:
            "0x0000000000000000000000000000000000000000000000000000000000000000",
          salt: "24446860302761739304752683030156737591518664810215442929805305526143327727409",
          offererConduitKey:
            "0x0000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f0000",
          fulfillerConduitKey:
            "0x0000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f0000",
          totalOriginalAdditionalRecipients: "1",
          additionalRecipients: [
            {
              amount: "2500000000000000",
              recipient: "0x0000a26b00c1f0df003000390027140000faa719",
            },
          ],
          signature:
            "0x993c4bdc19dfc6a64f3ac0b7b79e1e453cd0897b45571de5e0ce9a3e94217bd33fedccfced28d49797168e9da5b682ed3d483880900d50f72c54bc9f92bbc87b",
        },
      },
    },
    orders: [
      {
        parameters: {
          offerer: "0x6278a1e803a76796a3a1f7f6344fe874ebfe94b2",
          offer: [
            {
              itemType: 2,
              token: "0xEAAfcC17f28Afe5CdA5b3F76770eFb7ef162D20b",
              identifierOrCriteria: "10",
              startAmount: "1",
              endAmount: "1",
            },
          ],
          consideration: [
            {
              itemType: 0,
              token: "0x0000000000000000000000000000000000000000",
              identifierOrCriteria: "0",
              startAmount: "97500000000000000",
              endAmount: "97500000000000000",
              recipient: "0x6278A1E803A76796a3A1f7F6344fE874ebfe94B2",
            },
            {
              itemType: 0,
              token: "0x0000000000000000000000000000000000000000",
              identifierOrCriteria: "0",
              startAmount: "2500000000000000",
              endAmount: "2500000000000000",
              recipient: "0x0000a26b00c1F0DF003000390027140000fAa719",
            },
          ],
          startTime: "1684139190",
          endTime: "1686817590",
          orderType: 0,
          zone: "0x004C00500000aD104D7DBd00e3ae0A5C00560C00",
          zoneHash:
            "0x0000000000000000000000000000000000000000000000000000000000000000",
          salt: "0x360c6ebe000000000000000000000000000000000000000044516ed02cb8ef31",
          conduitKey:
            "0x0000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f0000",
          totalOriginalConsiderationItems: 2,
          counter: 0,
        },
        signature:
          "0x993c4bdc19dfc6a64f3ac0b7b79e1e453cd0897b45571de5e0ce9a3e94217bd33fedccfced28d49797168e9da5b682ed3d483880900d50f72c54bc9f92bbc87b",
      },
    ],
  },
};
