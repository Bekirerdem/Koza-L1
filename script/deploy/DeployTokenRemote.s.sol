// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {KozaTokenRemote} from "../../src/templates/ictt-bridge/KozaTokenRemote.sol";
import {TokenRemoteSettings} from "@ictt/TokenRemote/interfaces/ITokenRemote.sol";

/**
 * @title DeployTokenRemote
 * @notice Foundry deployment script for KozaTokenRemote (Phase 1, Sprint 3, v0.3.0).
 *         Hedef zincirde (default: kozaTestL1) ERC-20 representation contract'ını yayar.
 *
 *         Kullanım (yerel kozaTestL1, .env doluyken):
 *
 *             forge script script/deploy/DeployTokenRemote.s.sol \
 *                 --rpc-url $KOZA_TEST_L1_RPC_URL \
 *                 --broadcast
 *
 *         Yerel L1'de Snowtrace verify yok; sadece broadcast.
 *
 *         Zorunlu env (.env):
 *           - PRIVATE_KEY                       — deployer (yerel L1 için EOA OK)
 *           - REMOTE_TELEPORTER_REGISTRY        — kozaTestL1'in Teleporter Registry adresi
 *                                                 (`avalanche blockchain describe kozaTestL1`'den alınır)
 *           - REMOTE_TOKEN_HOME_BLOCKCHAIN_ID   — Fuji C-Chain blockchain ID
 *                                                 (Avalanche P-Chain'den alınır, statik)
 *           - REMOTE_TOKEN_HOME_ADDRESS         — Fuji'ye deploy edilmiş KozaTokenHome adresi
 *
 *         Opsiyonel env:
 *           - REMOTE_TELEPORTER_MANAGER         (broadcaster)         — production: multisig
 *           - REMOTE_MIN_TELEPORTER_VERSION     (1)
 *           - REMOTE_TOKEN_HOME_DECIMALS        (18)                  — KGAS 18 decimals
 *           - REMOTE_TOKEN_NAME                 ("Wrapped Koza Gas")
 *           - REMOTE_TOKEN_SYMBOL               ("wKGAS")
 *           - REMOTE_TOKEN_DECIMALS             (18)
 *
 *         Production checklist:
 *           - REMOTE_TELEPORTER_MANAGER MUTLAKA multisig olmalı
 *           - REMOTE_TOKEN_HOME_ADDRESS deploy edilmiş ve Snowtrace verified olmalı
 *           - Deploy sonrası ilk işlem: registerWithHome(feeInfo) çağırarak
 *             Home tarafına kayıt mesajı gönder
 */
contract DeployTokenRemote is Script {
    /*//////////////////////////////////////////////////////////////
                                DEFAULTS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant DEFAULT_MIN_TELEPORTER_VERSION = 1;
    uint8 internal constant DEFAULT_HOME_TOKEN_DECIMALS = 18;
    string internal constant DEFAULT_TOKEN_NAME = "Wrapped Koza Gas";
    string internal constant DEFAULT_TOKEN_SYMBOL = "wKGAS";
    uint8 internal constant DEFAULT_TOKEN_DECIMALS = 18;

    /*//////////////////////////////////////////////////////////////
                                  RUN
    //////////////////////////////////////////////////////////////*/

    function run() external returns (KozaTokenRemote remote, address deployer) {
        // Required: registry, home blockchain ID, home address.
        address teleporterRegistry = vm.envAddress("REMOTE_TELEPORTER_REGISTRY");
        bytes32 tokenHomeBlockchainID = vm.envBytes32("REMOTE_TOKEN_HOME_BLOCKCHAIN_ID");
        address tokenHomeAddress = vm.envAddress("REMOTE_TOKEN_HOME_ADDRESS");

        // Optional: defaults below if unset.
        uint256 minTeleporterVersion = vm.envOr("REMOTE_MIN_TELEPORTER_VERSION", DEFAULT_MIN_TELEPORTER_VERSION);
        uint256 homeDecimalsRaw = vm.envOr("REMOTE_TOKEN_HOME_DECIMALS", uint256(DEFAULT_HOME_TOKEN_DECIMALS));
        uint8 homeTokenDecimals = uint8(homeDecimalsRaw);

        string memory tokenName = vm.envOr("REMOTE_TOKEN_NAME", DEFAULT_TOKEN_NAME);
        string memory tokenSymbol = vm.envOr("REMOTE_TOKEN_SYMBOL", DEFAULT_TOKEN_SYMBOL);
        uint256 tokenDecimalsRaw = vm.envOr("REMOTE_TOKEN_DECIMALS", uint256(DEFAULT_TOKEN_DECIMALS));
        uint8 tokenDecimals = uint8(tokenDecimalsRaw);

        address broadcaster = _resolveBroadcaster();
        address teleporterManager = vm.envOr("REMOTE_TELEPORTER_MANAGER", broadcaster);

        TokenRemoteSettings memory settings = TokenRemoteSettings({
            teleporterRegistryAddress: teleporterRegistry,
            teleporterManager: teleporterManager,
            minTeleporterVersion: minTeleporterVersion,
            tokenHomeBlockchainID: tokenHomeBlockchainID,
            tokenHomeAddress: tokenHomeAddress,
            tokenHomeDecimals: homeTokenDecimals
        });

        return deploy(settings, tokenName, tokenSymbol, tokenDecimals, broadcaster);
    }

    /// @notice Test-friendly entry point. Parametrik, env'e dokunmaz.
    function deploy(
        TokenRemoteSettings memory settings,
        string memory tokenName,
        string memory tokenSymbol,
        uint8 tokenDecimals,
        address broadcaster
    )
        public
        returns (KozaTokenRemote remote, address deployer)
    {
        _logPreDeploy(settings, tokenName, tokenSymbol, tokenDecimals, broadcaster);

        vm.startBroadcast();
        remote = new KozaTokenRemote(settings, tokenName, tokenSymbol, tokenDecimals);
        vm.stopBroadcast();

        deployer = broadcaster;

        _logPostDeploy(remote);
    }

    /*//////////////////////////////////////////////////////////////
                              INTERNALS
    //////////////////////////////////////////////////////////////*/

    function _resolveBroadcaster() internal view returns (address) {
        address explicitDeployer = vm.envOr("DEPLOYER_ADDRESS", address(0));
        if (explicitDeployer != address(0)) return explicitDeployer;

        uint256 pk = vm.envOr("PRIVATE_KEY", uint256(0));
        if (pk != 0) return vm.addr(pk);

        return tx.origin;
    }

    function _logPreDeploy(
        TokenRemoteSettings memory settings,
        string memory tokenName,
        string memory tokenSymbol,
        uint8 tokenDecimals,
        address broadcaster
    )
        internal
        pure
    {
        console2.log("=== Deploying KozaTokenRemote ===");
        console2.log("  Broadcaster:           ", broadcaster);
        console2.log("  Teleporter Registry:   ", settings.teleporterRegistryAddress);
        console2.log("  Teleporter Manager:    ", settings.teleporterManager);
        console2.log("  Min Teleporter Version:", settings.minTeleporterVersion);
        console2.log("  Home Address:          ", settings.tokenHomeAddress);
        console2.log("  Home Token Decimals:   ", settings.tokenHomeDecimals);
        console2.log("  Token Name:            ", tokenName);
        console2.log("  Token Symbol:          ", tokenSymbol);
        console2.log("  Token Decimals:        ", tokenDecimals);
        console2.log("  Home Blockchain ID:");
        console2.logBytes32(settings.tokenHomeBlockchainID);
    }

    function _logPostDeploy(KozaTokenRemote remote) internal view {
        console2.log("=== Deployed ===");
        console2.log("  KozaTokenRemote at: ", address(remote));
        console2.log("  Name:               ", remote.name());
        console2.log("  Symbol:             ", remote.symbol());
        console2.log("");
        console2.log("Next steps:");
        console2.log("  1) registerWithHome(feeInfo) cagrisini gonder (Home'a kayit mesaji).");
        console2.log("  2) End-to-end bridge demo icin Sprint 3G rehberini takip et.");
    }
}
