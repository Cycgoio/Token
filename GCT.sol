// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract GCT is ERC20, Ownable {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private _miners;

    uint256 public constant maxSupply = 1000000000 * 1e18;
    uint256 private _openTransferTimestamp = 1;
    mapping(address => bool) private _isExcludedFrom;

    constructor(uint256 initialSupply) ERC20("Green CycGo Token", "GCT") {
        _mint(msg.sender, initialSupply);

        _isExcludedFrom[msg.sender] = true;
        _isExcludedFrom[address(this)] = true;
    }

    // mint within max supply
    function mint(address _to, uint256 _amount)
        public
        onlyMiner
        returns (bool)
    {
        if (_amount.add(totalSupply()) > maxSupply) {
            return false;
        }
        _mint(_to, _amount);
        return true;
    }

    function burn(address account, uint256 amount) public onlyOwner {
        _burn(account, amount);
    }

    function setTimestamp(uint256 openTransferTimestamp) external onlyOwner {
        require(_openTransferTimestamp != 0, "opentime invalid");
        _openTransferTimestamp = openTransferTimestamp;
    }

    function setAccount(address[] memory accs, bool status) public onlyOwner {
        for (uint256 i = 0; i < accs.length; i++) {
            _isExcludedFrom[accs[i]] = status;
        }
    }

    function addMiner(address miner) public onlyOwner returns (bool) {
        require(miner != address(0), "ERC20: miner invalid");
        return EnumerableSet.add(_miners, miner);
    }

    function delMiner(address miner) public onlyOwner returns (bool) {
        require(miner != address(0), "ERC20: miner invalid");
        return EnumerableSet.remove(_miners, miner);
    }

    function isMiner(address account) public view returns (bool) {
        return EnumerableSet.contains(_miners, account);
    }

    function getMinerLen() public view returns (uint256) {
        return EnumerableSet.length(_miners);
    }

    function getMiner(uint256 _index) public view onlyOwner returns (address) {
        require(_index <= getMinerLen() - 1, "ERC20: index out of bounds");
        return EnumerableSet.at(_miners, _index);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        if (!_isExcludedFrom[sender] && !_isExcludedFrom[recipient]) {
            require(
                block.timestamp >= _openTransferTimestamp &&
                    _openTransferTimestamp > 0,
                "ERC20: invalid"
            );
        }
        super._transfer(sender, recipient, amount);
    }

    // modifier for mint function
    modifier onlyMiner() {
        require(isMiner(msg.sender), "ERC20: no permit");
        _;
    }
}
