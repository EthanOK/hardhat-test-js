const ethers = require("ethers");
const BigNumber = ethers.BigNumber;
const gr = require("graphql-request");
const { request, gql } = gr;
const tokenId =
  "110363799599573736734551540813868541250290672745665884892129987155663208250196";
// Should return 0xaf2caa1c2ca1d027f1ac823b529d0a67cd144264b2789fa2ea4d63a67c7103cc
const labelHash = BigNumber.from(tokenId).toHexString();

const url = "https://api.thegraph.com/subgraphs/name/ensdomains/ens";
const GET_LABEL_NAME = gql`
query{
  domains(first:1, where:{labelhash:"${labelHash}"}){
    labelName
  }
}`;

request(url, GET_LABEL_NAME).then((data) => {
  const labelName = data.domains[0].labelName;
  console.log(labelName + ".eth");
});

// { domains: [ { labelName: 'vitalik' } ] }
