const { ethers } = require("ethers");

// 定义结构体类型
const personType = [
  "string", // name
  "uint256", // age
  "uint256[]", // favoriteNumbers
];

// 定义一个具有该结构体类型的对象
const person = {
  name: "Alice",
  age: 30,
  favoriteNumbers: [42, 7, 13],
};

// 编码该对象为字节数组
const encodedPerson = ethers.utils.defaultAbiCoder.encode(personType, [
  person.name,
  person.age,
  person.favoriteNumbers,
]);

console.log(encodedPerson); // 输出: 0x0000000000000000000000000000000000000000000000000000000000000005416c69636500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003
