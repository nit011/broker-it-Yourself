// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract AptosExchange {
    struct Order {
        address user;
        uint256 amount;
        uint256 price;
        bool isBuyOrder;
        bool isFilled;
    }

    mapping(address => uint256) public userBalances;
    mapping(address => mapping(uint256 => Order)) public userOrders;
    mapping(uint256 => Order[]) public buyOrderBook;
    mapping(uint256 => Order[]) public sellOrderBook;

    uint256 public orderId;

    event OrderPlaced(uint256 indexed orderId, address indexed user, uint256 amount, uint256 price, bool isBuyOrder);
    event OrderCancelled(uint256 indexed orderId, address indexed user);
    event TradeExecuted(uint256 indexed buyOrderId, uint256 indexed sellOrderId, address indexed buyer, address seller, uint256 amount, uint256 price);

    function placeBuyOrder(uint256 amount, uint256 price) external {
        require(amount > 0, "Amount must be greater than zero");
        require(price > 0, "Price must be greater than zero");

        userBalances[msg.sender] += amount;

        Order memory buyOrder = Order(msg.sender, amount, price, true, false);
        buyOrderBook[price].push(buyOrder);

        uint256 currentOrderId = orderId;
        userOrders[msg.sender][currentOrderId] = buyOrder;

        emit OrderPlaced(currentOrderId, msg.sender, amount, price, true);

        orderId++;
    }

    function placeSellOrder(uint256 amount, uint256 price) external {
        require(amount > 0, "Amount must be greater than zero");
        require(price > 0, "Price must be greater than zero");

        require(userBalances[msg.sender] >= amount, "Insufficient balance");

        userBalances[msg.sender] -= amount;

        Order memory sellOrder = Order(msg.sender, amount, price, false, false);
        sellOrderBook[price].push(sellOrder);

        uint256 currentOrderId = orderId;
        userOrders[msg.sender][currentOrderId] = sellOrder;

        emit OrderPlaced(currentOrderId, msg.sender, amount, price, false);

        orderId++;
    }

    function cancelOrder(uint256 orderId) external {
        Order storage order = userOrders[msg.sender][orderId];
        require(order.user == msg.sender, "Not the order owner");
        require(!order.isFilled, "Order already filled");

        if (order.isBuyOrder) {
            removeOrderFromBook(buyOrderBook[order.price], orderId);
        } else {
            removeOrderFromBook(sellOrderBook[order.price], orderId);
        }

        delete userOrders[msg.sender][orderId];
        emit OrderCancelled(orderId, msg.sender);
    }

    function executeTrade(uint256 buyOrderId, uint256 sellOrderId) external {
        Order storage buyOrder = userOrders[msg.sender][buyOrderId];
        Order storage sellOrder = userOrders[msg.sender][sellOrderId];

        require(buyOrder.user != address(0), "Invalid buy order");
        require(sellOrder.user != address(0), "Invalid sell order");
        require(buyOrder.isBuyOrder, "Invalid order type");
        require(!buyOrder.isFilled, "Buy order already filled");
        require(!sellOrder.isFilled, "Sell order already filled");
        require(sellOrder.price <= buyOrder.price, "Trade price mismatch");

        uint256 amount = (buyOrder.amount <= sellOrder.amount) ? buyOrder.amount : sellOrder.amount;
        uint256 totalPrice = amount * sellOrder.price;

        require(userBalances[sellOrder.user] >= amount, "Insufficient seller balance");

        userBalances[buyOrder.user] -= totalPrice;
        userBalances[sellOrder.user] += totalPrice;

        buyOrder.amount -= amount;
        sellOrder.amount -= amount;

        emit TradeExecuted(buyOrderId, sellOrderId, buyOrder.user, sellOrder.user, amount, sellOrder.price);

        if (buyOrder.amount == 0) {
            buyOrder.isFilled = true;
            removeOrderFromBook(buyOrderBook[buyOrder.price], buyOrderId);
        }

        if (sellOrder.amount == 0) {
            sellOrder.isFilled = true;
            removeOrderFromBook(sellOrderBook[sellOrder.price], sellOrderId);
        }
    }

    function getOrderBook(uint256 price, bool isBuyOrder) external view returns (Order[] memory) {
        if (isBuyOrder) {
            return buyOrderBook[price];
        } else {
            return sellOrderBook[price];
        }
    }

    function getUserOrder(address user, uint256 orderId) external view returns (Order memory) {
        return userOrders[user][orderId];
    }

    function removeOrderFromBook(Order[] storage orders, uint256 orderId) internal {
        for (uint256 i = 0; i < orders.length; i++) {
            if (orderId == i) {
                if (i != orders.length - 1) {
                    orders[i] = orders[orders.length - 1];
                }
                orders.pop();
                break;
            }
        }
    }
}
