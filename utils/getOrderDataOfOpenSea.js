async function getOrder(openseaSDK, accountAddress, tokenAddress, tokenId) {
  const order = await openseaSDK.api.getOrder({
    side: "ask",
    assetContractAddress: tokenAddress,
    tokenId: tokenId,
  });

  if (order.orderHash == null) {
    return;
  }

  const fulfillment = await openseaSDK.api.generateFulfillmentData(
    accountAddress,
    order.orderHash,
    order.protocolAddress,
    order.side
  );
  return fulfillment.fulfillment_data.transaction;
}

module.exports = getOrder;
