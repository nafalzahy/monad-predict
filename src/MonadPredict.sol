// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title MonadPredict - prediction market Ya/Tidak dengan AMM (harga = probabilitas)
contract MonadPredict {
    uint256 constant FEE_BPS = 100; // fee 1% untuk pembuat pasar
    uint256 constant BPS = 10_000;
    uint256 public constant MIN_LIQUIDITY = 0.01 ether;
    uint256 public constant MIN_TRADE = 0.001 ether;
    address public immutable owner;

    struct Market {
        uint256 id;
        address creator;
        string question;
        string description;
        string category;
        string emoji;
        uint64 createdAt;
        uint64 closeTime;
        bool resolved;
        bool yesWon;
        uint256 yesReserve;
        uint256 noReserve;
        uint256 collateral;
        uint256 volume;
        uint256 fees;
        bool lpClaimed;
    }

    struct Trade {
        address trader;
        bool isYes;
        bool isBuy;
        uint256 amount; // MON masuk/keluar (wei)
        uint256 shares;
        uint16 yesPriceBps; // harga Ya setelah trade (10000 = 100%)
        uint64 time;
    }

    Market[] private markets;
    mapping(uint256 => mapping(address => uint256)) public yesShares;
    mapping(uint256 => mapping(address => uint256)) public noShares;
    mapping(uint256 => Trade[]) private trades;
    bool private locked;

    event MarketCreated(uint256 indexed id, address indexed creator, string question);
    event Traded(uint256 indexed id, address indexed trader, bool isYes, bool isBuy, uint256 amount, uint256 shares);
    event Resolved(uint256 indexed id, bool yesWon);

    modifier nonReentrant() {
        require(!locked, "Reentrancy");
        locked = true;
        _;
        locked = false;
    }

    constructor() {
        owner = msg.sender;
    }

    // ---------- Buat pasar ----------
    function createMarket(
        string calldata question,
        string calldata description,
        string calldata category,
        string calldata emoji,
        uint64 closeTime
    ) external payable returns (uint256 id) {
        require(msg.value >= MIN_LIQUIDITY, "Likuiditas awal terlalu kecil");
        require(closeTime > block.timestamp + 60, "Tutup minimal 1 menit lagi");
        require(bytes(question).length >= 5 && bytes(question).length <= 200, "Pertanyaan 5-200 karakter");
        require(bytes(description).length <= 1000, "Deskripsi terlalu panjang");
        id = markets.length;
        markets.push();
        Market storage m = markets[id];
        m.id = id;
        m.creator = msg.sender;
        m.question = question;
        m.description = description;
        m.category = category;
        m.emoji = emoji;
        m.createdAt = uint64(block.timestamp);
        m.closeTime = closeTime;
        m.yesReserve = msg.value;
        m.noReserve = msg.value;
        m.collateral = msg.value;
        emit MarketCreated(id, msg.sender, question);
    }

    // ---------- Beli / Jual ----------
    function buy(uint256 id, bool isYes, uint256 minShares) external payable nonReentrant {
        Market storage m = _open(id);
        require(msg.value >= MIN_TRADE, "Jumlah terlalu kecil");
        uint256 fee = (msg.value * FEE_BPS) / BPS;
        uint256 a = msg.value - fee;
        (uint256 out, uint256 ns, uint256 oth) =
            _buyOut(isYes ? m.yesReserve : m.noReserve, isYes ? m.noReserve : m.yesReserve, a);
        require(out > 0 && out >= minShares, "Slippage");
        if (isYes) {
            m.yesReserve = ns;
            m.noReserve = oth;
            yesShares[id][msg.sender] += out;
        } else {
            m.noReserve = ns;
            m.yesReserve = oth;
            noShares[id][msg.sender] += out;
        }
        m.collateral += a;
        m.fees += fee;
        _record(id, isYes, true, msg.value, out);
    }

    function sell(uint256 id, bool isYes, uint256 shares, uint256 minReturn) external nonReentrant {
        Market storage m = _open(id);
        require(
            shares > 0 && shares <= (isYes ? yesShares[id][msg.sender] : noShares[id][msg.sender]),
            "Saham tidak cukup"
        );
        uint256 same = isYes ? m.yesReserve : m.noReserve;
        uint256 oth = isYes ? m.noReserve : m.yesReserve;
        uint256 r = _sellQuote(same, oth, shares);
        uint256 fee = (r * FEE_BPS) / BPS;
        uint256 payout = r - fee;
        require(payout > 0 && payout >= minReturn, "Slippage");
        if (isYes) {
            yesShares[id][msg.sender] -= shares;
            m.yesReserve = same + shares - r;
            m.noReserve = oth - r;
        } else {
            noShares[id][msg.sender] -= shares;
            m.noReserve = same + shares - r;
            m.yesReserve = oth - r;
        }
        m.collateral -= r;
        m.fees += fee;
        _record(id, isYes, false, r, shares);
        _pay(msg.sender, payout);
    }

    // ---------- Resolusi & klaim ----------
    function resolve(uint256 id, bool yesWon) external {
        Market storage m = _get(id);
        require(msg.sender == m.creator || msg.sender == owner, "Bukan resolver");
        require(block.timestamp >= m.closeTime, "Pasar belum ditutup");
        require(!m.resolved, "Sudah diputuskan");
        m.resolved = true;
        m.yesWon = yesWon;
        emit Resolved(id, yesWon);
    }

    function redeem(uint256 id) external nonReentrant {
        Market storage m = _get(id);
        require(m.resolved, "Belum diputuskan");
        uint256 amount;
        if (m.yesWon) {
            amount = yesShares[id][msg.sender];
            yesShares[id][msg.sender] = 0;
        } else {
            amount = noShares[id][msg.sender];
            noShares[id][msg.sender] = 0;
        }
        require(amount > 0, "Tidak ada hadiah");
        m.collateral -= amount;
        _pay(msg.sender, amount);
    }

    /// Pembuat menarik fee kapan saja + sisa likuiditas setelah pasar diputuskan
    function claimCreator(uint256 id) external nonReentrant {
        Market storage m = _get(id);
        require(msg.sender == m.creator, "Bukan pembuat");
        uint256 amount = m.fees;
        m.fees = 0;
        if (m.resolved && !m.lpClaimed) {
            m.lpClaimed = true;
            uint256 lp = m.yesWon ? m.yesReserve : m.noReserve;
            m.collateral -= lp;
            amount += lp;
        }
        require(amount > 0, "Tidak ada yang bisa ditarik");
        _pay(msg.sender, amount);
    }

    // ---------- View (dibaca frontend, tanpa getLogs) ----------
    function marketCount() external view returns (uint256) {
        return markets.length;
    }

    function getMarkets(uint256 start, uint256 count) external view returns (Market[] memory out) {
        uint256 end = start + count > markets.length ? markets.length : start + count;
        out = new Market[](end > start ? end - start : 0);
        for (uint256 i = start; i < end; i++) out[i - start] = markets[i];
    }

    function tradeCount(uint256 id) external view returns (uint256) {
        return trades[id].length;
    }

    function getTrades(uint256 id, uint256 start, uint256 count) external view returns (Trade[] memory out) {
        Trade[] storage t = trades[id];
        uint256 end = start + count > t.length ? t.length : start + count;
        out = new Trade[](end > start ? end - start : 0);
        for (uint256 i = start; i < end; i++) out[i - start] = t[i];
    }

    function quoteBuy(uint256 id, bool isYes, uint256 amount) external view returns (uint256 out) {
        Market storage m = _get(id);
        (out,,) = _buyOut(
            isYes ? m.yesReserve : m.noReserve,
            isYes ? m.noReserve : m.yesReserve,
            amount - (amount * FEE_BPS) / BPS
        );
    }

    function quoteSell(uint256 id, bool isYes, uint256 shares) external view returns (uint256 payout) {
        Market storage m = _get(id);
        uint256 r = _sellQuote(isYes ? m.yesReserve : m.noReserve, isYes ? m.noReserve : m.yesReserve, shares);
        payout = r - (r * FEE_BPS) / BPS;
    }

    // ---------- Internal ----------
    function _get(uint256 id) internal view returns (Market storage) {
        require(id < markets.length, "Pasar tidak ada");
        return markets[id];
    }

    function _open(uint256 id) internal view returns (Market storage m) {
        m = _get(id);
        require(!m.resolved && block.timestamp < m.closeTime, "Pasar tidak terbuka");
    }

    function _record(uint256 id, bool isYes, bool isBuy, uint256 amount, uint256 shares) internal {
        Market storage m = markets[id];
        uint16 price = uint16((m.noReserve * BPS) / (m.yesReserve + m.noReserve));
        trades[id].push(Trade(msg.sender, isYes, isBuy, amount, shares, price, uint64(block.timestamp)));
        m.volume += amount;
        emit Traded(id, msg.sender, isYes, isBuy, amount, shares);
    }

    /// Rumus AMM (x*y=k): beli saham "same" dengan dana a
    function _buyOut(uint256 same, uint256 oth, uint256 a)
        internal
        pure
        returns (uint256 out, uint256 newSame, uint256 newOth)
    {
        newOth = oth + a;
        uint256 k = same * oth;
        newSame = k == 0 ? 0 : (k - 1) / newOth + 1; // pembulatan ke atas (menguntungkan pool)
        out = same + a - newSame;
    }

    /// Jual `shares` saham -> dana r yang dikembalikan (akar persamaan kuadrat)
    function _sellQuote(uint256 same, uint256 oth, uint256 shares) internal pure returns (uint256 r) {
        uint256 s = same + shares + oth;
        uint256 d = s * s - 4 * shares * oth;
        r = (s - _sqrtUp(d)) / 2;
        require((same + shares - r) * (oth - r) >= same * oth, "Invarian rusak");
    }

    function _sqrtUp(uint256 x) internal pure returns (uint256 y) {
        if (x == 0) return 0;
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        if (y * y < x) y += 1;
    }

    function _pay(address to, uint256 amount) internal {
        (bool ok,) = payable(to).call{value: amount}("");
        require(ok, "Transfer gagal");
    }
}