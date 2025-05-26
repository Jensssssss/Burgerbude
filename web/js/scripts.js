document.addEventListener('DOMContentLoaded', (event) => {
    document.querySelectorAll('.order-button').forEach(button => {
        button.addEventListener('click', () => {
            showPopup(button.dataset.id, button.dataset.name, button.dataset.price);
        });
    });

    document.getElementById('popup-abort').addEventListener('click', hidePopup);
    document.getElementById('popup-add').addEventListener('click', addToCart);
    document.getElementById('confirmation-close').addEventListener('click', hideConfirmationPopup);

    document.querySelector('.popup .minus').addEventListener('click', () => {
        let quantity = document.getElementById('quantity');
        if (quantity.value > 1) quantity.value--;
    });

    document.querySelector('.popup .plus').addEventListener('click', () => {
        let quantity = document.getElementById('quantity');
        quantity.value++;
    });
});

function showPopup(id, name, price) {
    document.getElementById('popup').style.display = 'block';
    document.getElementById('popup-article-name').innerText = name;
    document.getElementById('popup-article-id').value = id;
    document.getElementById('popup-article-price').value = price; // Added hidden input for price
    document.getElementById('quantity').value = 1;
}

function hidePopup() {
    document.getElementById('popup').style.display = 'none';
}

function showConfirmationPopup(orderId) {
    document.getElementById('confirmation-popup').style.display = 'block';
    document.getElementById('order-id').innerText = orderId;
}

function hideConfirmationPopup() {
    document.getElementById('confirmation-popup').style.display = 'none';
    window.location = 'index.php';
}

function addToCart() {
    let id = document.getElementById('popup-article-id').value;
    let name = document.getElementById('popup-article-name').innerText;
    let quantity = parseInt(document.getElementById('quantity').value);
    let price = parseFloat(document.getElementById('popup-article-price').value); // Use the hidden input value

    let existingItem = cart.find(item => item.id === id);

    if (existingItem) {
        existingItem.quantity += quantity;
    } else {
        cart.push({ id, name, quantity, price });
    }

    updateCart();
    hidePopup();
}

function removeFromCart(id) {
    cart = cart.filter(item => item.id !== id);
    updateCart();
}

function updateCart() {
    let cartItems = document.getElementById('cart-items');
    if (!cartItems) return; // Ensure cartItems is not null
    cartItems.innerHTML = '';
    let total = 0;

    cart.forEach(item => {
        let itemTotal = item.price * item.quantity;
        total += itemTotal;

        let cartItem = document.createElement('div');
        cartItem.className = 'cart-item';
        cartItem.innerHTML = `<span class="quantity">${item.quantity} x </span><span class="name">${item.name}</span> <span class="price">${itemTotal.toFixed(2)} €</span> <span class="remove-item" onclick="removeFromCart('${item.id}')">X</span>`;
        cartItems.appendChild(cartItem);
    });

    document.getElementById('total-price').innerText = total.toFixed(2);
}

document.getElementById('checkout').addEventListener('click', () => {
    if (cart.length > 0) {
        let formData = new FormData();
        formData.append('cart', JSON.stringify(cart));

        fetch('checkout.php', {
            method: 'POST',
            body: formData
        }).then(response => response.json())
        .then(data => {
            if (data.status === 'success') {
                cart = [];
                updateCart();
                showConfirmationPopup(data.bestellung_id);
            } else {
                alert(data.message);
            }
        }).catch(error => {
            console.error('Error:', error);
            alert('Ein Fehler ist aufgetreten: ' + error.message);
        });
    }
});

let cart = [];
