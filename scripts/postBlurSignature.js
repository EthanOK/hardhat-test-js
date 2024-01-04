// 请求pro.opensea 间接获取 calldata （需要两个Token，一个proopensea，一个blur）
const postProOpenseaBlurSignature = async (buyToken, buyAddress) => {
  const postURL = "https://api.pro.opensea.io/route";

  const data = {
    chainName: "ethereum",
    new: true,
    sender: "0xC675897Bb91797EaeA7584F025A5533DBB13A000",
    balanceToken: "0x0000000000000000000000000000000000000000",
    useFlashbots: false,
    sells: [],
    buys: [
      {
        priceInfo: {
          price: "28000000000000000",
          address: "0x0000000000000000000000000000000000000000",
          decimals: 18,
        },
        market: "blur_v2",
        standard: "ERC721",
        address: "0x11400ee484355c7bdf804702bf3367ebc7667e54",
        tokenId: "1147",
        amount: 1,
      },
    ],
    blurAuthToken:
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ3YWxsZXRBZGRyZXNzIjoiMHhjNjc1ODk3YmI5MTc5N2VhZWE3NTg0ZjAyNWE1NTMzZGJiMTNhMDAwIiwic2lnbmF0dXJlIjoiMHhhOTcyMmZjZWJiNDc5YmUyMTAxMzdkYTNjMWUxYjgxM2NjNDI5MzgyMjlmNzVkY2I1MWQ3NzZhYWMzYTBkMTM5MGQ2OGRkM2E3OGI5NmUwODhjNGMxMTE4OTNkY2FjODE1OGIxZWI0MDgyMmEwNzZkNTU1NzM5NTdmYTMwZTU5NjFjIiwiaWF0IjoxNzA0MjUzNDgwLCJleHAiOjE3MDY4NDU0ODB9.VaE08jd3bCLwwOuxa7cgxbifyooB7bgdlRGz00GMTDU",
  };
  try {
    // Make the POST request using the fetch API
    const response = await fetch(postURL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Sender: "0xC675897Bb91797EaeA7584F025A5533DBB13A000",
        Token:
          "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhZGRyZXNzIjoiMHhjNjc1ODk3YmI5MTc5N2VhZWE3NTg0ZjAyNWE1NTMzZGJiMTNhMDAwIiwiZGF0ZSI6IldlZCBKYW4gMDMgMjAyNCAwMTozMjowMiBHTVQrMDAwMCAoQ29vcmRpbmF0ZWQgVW5pdmVyc2FsIFRpbWUpIiwiaWF0IjoxNzA0MjQ1NTIyLCJleHAiOjE3MDQzMzE5MjJ9.KSDLDm-_K6RKMx1MkO-0A8uZWt26Y97apcjBBYynXUs",
      },
      body: JSON.stringify(data),
    });
    // console.log(response);
    if (response.ok) {
      const responseData = await response.json();
      console.log(responseData.data);
    } else {
      console.log(response.status);
      console.log(response.headers);

      console.log("Network Error");
    }
  } catch (error) {
    console.log(error);
  }
};

const postNFTGOBlurSignature = async (
  tokenAddress,
  tokenId,
  buyerAddress,
  buyerBlurAccessToken
) => {
  const postURL = "https://api.nftgo.io/api/v1/nft-aggregator/aggregate-v2";
  // 如何获得orderInfo
  const blurOrderInfos = await getNFTGoBlurOrderInfos(tokenAddress, tokenId);
  if (blurOrderInfos.length == 0) return null;
  const orderInfos = [blurOrderInfos[0]];
  const data = {
    orderInfos: orderInfos,
    buyer: buyerAddress,
    safeMode: false,
    // accessToken 是登陆 blur 获得的token
    accessToken: buyerBlurAccessToken,
  };
  try {
    // Make the POST request using the fetch API
    const response = await fetch(postURL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(data),
    });
    // console.log(response);
    if (response.ok) {
      const responseData = await response.json();
      if (responseData.errorCode != 0) {
        return null;
      }
      const txData = responseData.data.aggregateResult.actions[0].data.txData;
      console.log(txData);
      return txData;
    } else {
      console.log(response);

      console.log("Network Error");
    }
  } catch (error) {
    console.log(error);
  }
};

const getNFTGoBlurOrderInfos = async (contractAddress, tokenId) => {
  const postURL = `https://api.nftgo.io/api/v2/asset/orders?contract=${contractAddress}&tokenId=${tokenId}&limit=20`;
  const orderInfos = [];
  try {
    // Make the POST request using the fetch API
    const response = await fetch(postURL, {
      method: "GET",
      headers: {
        accept: "application/json",
      },
    });

    if (response.ok) {
      const responseData = await response.json();

      const orders = responseData.data.orders;

      if (orders.length > 0) {
        for (let i = 0; i < orders.length; i++) {
          const order = orders[i];
          // console.log(order);
          if (order.orderKind.includes("blur")) {
            const orderInfo = {
              contractAddress: order.address,
              maker: order.maker,
              orderId: order.id,
              tokenId: order.tokenId,
            };
            orderInfos.push(orderInfo);
          }
          return orderInfos;
        }
      } else {
        return orderInfos;
      }
    } else {
      console.log("Network Error");
    }
  } catch (error) {
    console.log(error);
  }
};

const getBlurLoginMessage = async (userAddress) => {
  const postURL =
    "https://api.nftgo.io/api/v1/nft-aggregator/blur/auth/challenge";
  const data = { address: userAddress };
  try {
    // Make the POST request using the fetch API
    const response = await fetch(postURL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(data),
    });
    // console.log(response);
    if (response.ok) {
      const responseData = await response.json();
      if (responseData.errorCode != 0) {
        return null;
      }
      const data = responseData.data;
      console.log(data);
      return data;
    } else {
      console.log(response.status);
      return null;
    }
  } catch (error) {
    console.log(error);
  }
};

const getBlurAccessToken = async () => {
  const postURL = "https://api.nftgo.io/api/v1/nft-aggregator/blur/auth/login";
  const data = {
    message:
      "Sign in to Blur\n\nChallenge: a7e206ef138b094938feeb90d396beacc172e30b84d405bc4e6e933a702e5683",
    walletAddress: "0xc675897bb91797eaea7584f025a5533dbb13a000",
    expiresOn: "2024-01-03T09:15:34.716Z",
    hmac: "a7e206ef138b094938feeb90d396beacc172e30b84d405bc4e6e933a702e5683",
    signature:
      "0x4cf5175d809ac9195daf74d9ddd1904d37dfa2508cb92fb87b125eaec6de559d69e5eadc354d9bf5cb571f7f7626f47198f97072128d6486d2c4dc656894692d1b",
  };
  try {
    // Make the POST request using the fetch API
    const response = await fetch(postURL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(data),
    });
    // console.log(response);
    if (response.ok) {
      const responseData = await response.json();
      console.log(responseData);
      if (responseData.errorCode != 0) {
        return null;
      }
      const data = responseData.data;
      console.log(data);
      return data;
    } else {
      console.log(response.status);
      return null;
    }
  } catch (error) {
    console.log(error);
    return null;
  }
};

// const getNFTGoCollectionId = async (contractAddress) => {
//   // get collection_id
//   const getURL =
//     "https://data-api.nftgo.io/eth/v2/collection/" + contractAddress + "/info";
//   const options = {
//     method: "GET",
//     headers: {
//       accept: "application/json",
//       "X-API-KEY": "014d3ec9-a79d-45db-9075-181c0c11a29a",
//     },
//   };
//   try {
//     const response = await fetch(getURL, options);
//     if (response.ok) {
//       const responseData = await response.json();
//       const collection_id = responseData.collection_id;
//       return collection_id;
//     } else {
//       console.log("status:", response.status);
//     }
//   } catch (error) {
//     console.log(error);
//   }
// };
// 行不通
// const postBlurSignature = async (buyToken, buyAddress) => {
//   const postURL =
//     "https://core-api.prod.blur.io/v1/buy/0x11400ee484355c7bdf804702bf3367ebc7667e54";

//   const data = {
//     tokenPrices: [
//       {
//         price: {
//           unit: "ETH",
//           amount: "0.02",
//           listedAt: "2023-11-05T13:48:53.014Z",
//         },
//         tokenId: "1053",
//         isSuspicious: false,
//       },
//     ],
//     userAddress: "0x22d43c43a340ebcc08e4c098079e2f0f068111cd",
//   };

//   try {
//     // Make the POST request using the fetch API
//     const response = await fetch(postURL, {
//       method: "POST",
//       headers: {
//         "Content-Type": "application/json",
//         Cookie:
//           "rl_page_init_referrer=RudderEncrypt%3AU2FsdGVkX19eT4iEdistPYEv9sQ%2BVPmUuEcY6nGrgTmFxEXRyljZ%2BawEn8sV2m3YYHfYe51yolzYblaCww2bSQ%3D%3D; rl_page_init_referring_domain=RudderEncrypt%3AU2FsdGVkX19nmVPczUwZQ7Gb%2BbeAxs0qkkZstbgScNw%3D; walletAddress=0x22d43c43a340ebcc08e4c098079e2f0f068111cd; rl_trait=RudderEncrypt%3AU2FsdGVkX19KACz09aHybENmGZ3U%2FMIpjZH%2B0DvdZgA%3D; rl_group_id=RudderEncrypt%3AU2FsdGVkX1%2BdCD73DEVVINcKRLMh0m6KcbmdaGjnoNQ%3D; rl_group_trait=RudderEncrypt%3AU2FsdGVkX1%2BpM8qULoggxz1UONRIYSNJXpvSXEWxUok%3D; rl_anonymous_id=RudderEncrypt%3AU2FsdGVkX18jj%2BKBnqBX1rz%2FdFVNr%2B9YZjcx4QUdwV9iQvHzLnwpWdM4yfeXaqzw0Ea%2FFCmXLBfp91JQpfXQyw%3D%3D; rl_user_id=RudderEncrypt%3AU2FsdGVkX18%2FLaix6Krk97C8rFuOZ1uoQSkjlXzNdkjJK1XlpSr9f7%2F7pjj%2Fze4D1OqhKUXqDBrV4FsbX2JbUA%3D%3D; fs_uid=#o-19FFTT-na1#560edff2-f9e1-4542-b182-6470afe7c5af:45de180b-8b2f-4b1d-b7d1-82775c15a3a2:1704257992003::1#1f9724d5#/1735793991; authToken=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ3YWxsZXRBZGRyZXNzIjoiMHgyMmQ0M2M0M2EzNDBlYmNjMDhlNGMwOTgwNzllMmYwZjA2ODExMWNkIiwic2lnbmF0dXJlIjoiMHhiZDEwYjEwNjQ3MWMwZDcxNmM2ZjY3ZjMzODk0ZThlMmY4NDlmMjY1MDBhNzEwNzE5MDhmMDY2NWQ0MTgzZjZjMTI1MzJhNGI5Yjk4NTdjYzJiMTQ2OGI5Zjg2ZjU0YmY5MGNiNzI5NDg2ZTRhMTJkYzZiNmU2ODVjZTJjODM1ZTFiIiwiaWF0IjoxNzA0MjU3OTk1LCJleHAiOjE3MDY4NDk5OTV9.Os8lzyj_8hokc1HkpMSAIkbvnquehWC2WiT0KEbF0dQ; __cf_bm=4yZl1Bya9dJvnnBU7KJsA8kbY_v3Oyq6K6G8no1MErU-1704258498-1-AeiQOVcYMXL4pkQz0bDfD3grxgzgg/jnOZgcis2zGx5Ug4EbhzS7Jl26EdQKaabHMldvI6KhMRaSpdgxyU0zV8g=; fs_lua=1.1704258817225; rl_session=RudderEncrypt%3AU2FsdGVkX19T%2FF9WRUe0DVdCOuhShKWI9eX17Ti0jUWyYpzlsfAvbSJVbw7aEnFOEqs5bzU%2F11sueSH%2BDOs4lz72vpckE7U7KumHYk76wfAkSYqQ2ofTZNzwm8DGoRp8qSQoBemphdEqMTtB2htssA%3D%3D",
//       },
//       body: JSON.stringify(data),
//     });
//     // console.log(response);
//     if (response.ok) {
//       const responseData = await response.json();
//       console.log(responseData.data);
//     } else {
//       console.log(response.status);
//       console.log(response.headers);

//       console.log("Network Error");
//     }
//   } catch (error) {
//     console.log(error);
//   }
// };

async function main() {
  // await postProOpenseaBlurSignature(
  //   "0x11400ee484355c7bdf804702bf3367ebc7667e54",
  //   "0xc675897bb91797eaea7584f025a5533dbb13a000"
  // );
  await postNFTGOBlurSignature(
    "0x11400ee484355c7bdf804702bf3367ebc7667e54",
    "1053",
    "0xc675897bb91797eaea7584f025a5533dbb13a000",
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ3YWxsZXRBZGRyZXNzIjoiMHhjNjc1ODk3YmI5MTc5N2VhZWE3NTg0ZjAyNWE1NTMzZGJiMTNhMDAwIiwic2lnbmF0dXJlIjoiMHg0MGU4MmQ2MDc4ZmU5MzNlMDMyODNlZmJlODQ3NzM1M2EyYTc2YjU5NzdkNmJmODliN2QwMWJkMTI2OWNhYjE2NmJlMDZmZmU3M2UzNWVhNzFlNTQyMTU3M2VjY2RhNGEwMmJkNmFiZTM2OWFhZDc2MmUzODQyZDc0YTY3YzQwNzFiIiwiaWF0IjoxNzA0Mjc0NDA4LCJleHAiOjE3MDY4NjY0MDh9.yrr0hWP5xJqewMRQ_FvgevIOrn54xcoMcb-uJew0lkU"
  );
  // await getBlurLoginMessage("0xc675897bb91797eaea7584f025a5533dbb13a000" );
  // await getBlurAccessToken();
}

main();
