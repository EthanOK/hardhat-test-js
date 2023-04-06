// This script demonstrates access to the NFT API via the Alchemy SDK.
const { Network, Alchemy } = require("alchemy-sdk");

// Optional Config object, but defaults to demo api-key and eth-mainnet.
const settings = {
  apiKey: "83yL2qXH68vnTkzzida15zCVNGZCy1JO", // Replace with your Alchemy API Key.
  network: Network.ETH_GOERLI, // Replace with your network.
};

const alchemy = new Alchemy(settings);
async function main() {
  // Print owner's wallet address:
  const ownerAddr = "0x53188E798f2657576c9de8905478F46ac2f24b67";
  console.log("fetching NFTs for address:", ownerAddr);
  console.log("...");

  // Print total NFT count returned in the response:
  const nftsForOwner = await alchemy.nft.getNftsForOwner(ownerAddr);
  console.log("number of NFTs found:", nftsForOwner.totalCount);
  console.log("...");

  // Print contract address and tokenId for each NFT:
  for (const nft of nftsForOwner.ownedNfts) {
    console.log("===");
    console.log("contract address:", nft.contract.address);
    console.log("token ID:", nft.tokenId);
  }
  console.log("===");

  // Fetch metadata for a particular NFT:
  console.log("fetching metadata for a Crypto Coven NFT...");
  const response = await alchemy.nft.getNftMetadata(
    "0x0D3e02768aB63516Ab5D386fAD462214CA3E6A86",
    "1"
  );

  // Uncomment this line to see the full api response:
  console.log(response);

  // Print some commonly used fields:
  //   console.log("NFT name: ", response.title);
  //   console.log("token type: ", response.tokenType);
  //   console.log("tokenUri: ", response.tokenUri.gateway);
  //   console.log("image url: ", response.rawMetadata.image);
  //   console.log("time last updated: ", response.timeLastUpdated);
  console.log("===");
}

main();
