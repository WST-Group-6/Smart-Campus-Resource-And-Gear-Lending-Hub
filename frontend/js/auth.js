// CampusLend Login Page

const loginForm = document.getElementById("loginForm");
const passwordInput = document.getElementById("password");
const togglePasswordButton = document.getElementById("togglePassword");
const loginMessage = document.getElementById("loginMessage");
const forgotPasswordLink = document.getElementById("forgotPassword");

// Show or hide the password
togglePasswordButton.addEventListener("click", function () {
    const isPasswordHidden = passwordInput.type === "password";

    passwordInput.type = isPasswordHidden ? "text" : "password";

    togglePasswordButton.textContent = isPasswordHidden ? "Hide" : "Show";

    togglePasswordButton.setAttribute(
        "aria-label",
        isPasswordHidden ? "Hide password" : "Show password"
    );
});

// Display a message
function showLoginMessage(message, type) {
    loginMessage.textContent = message;
    loginMessage.className = "form-message visible " + type;
}

// Handle login form submission
loginForm.addEventListener("submit", function (event) {
    event.preventDefault();

    const email = document.getElementById("email").value.trim();
    const password = passwordInput.value;

    if (!email || !password) {
        showLoginMessage("Please enter your email and password.", "error");
        return;
    }

    showLoginMessage(
        "The login page is working! Account verification will be connected to the backend later.",
        "success"
    );

    console.log("Login form submitted.");
    console.log("Email entered:", email);

    // Do not send or store passwords in frontend code.
});

// Handle the forgot password link
forgotPasswordLink.addEventListener("click", function (event) {
    event.preventDefault();

    showLoginMessage(
        "Password recovery will be available after the backend is connected.",
        "error"
    );
});
