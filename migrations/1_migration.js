var Transit = artifacts.require("Transit");

module.exports = function(deployer) {
  // deployment steps
  deployer.deploy(Transit);
};
