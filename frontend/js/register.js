// CampusLend Registration Page

const registerForm = document.getElementById("registerForm");

const passwordInput = document.getElementById("registerPassword");

const confirmPasswordInput = document.getElementById("confirmPassword");

const registerMessage = document.getElementById("registerMessage");


function showRegisterMessage(message, type) {
    registerMessage.textContent = message;

    registerMessage.className = "form-message visible " + type;
}


registerForm.addEventListener("submit", function (event) {
    event.preventDefault();

    const fullName = document.getElementById("fullName").value.trim();

    const studentId = document.getElementById("studentId").value.trim();

    const email = document.getElementById("registerEmail").value.trim();

    const password = passwordInput.value;

    const confirmPassword = confirmPasswordInput.value;

    const termsAccepted = document.getElementById("terms").checked;


    // Check that required text fields are not empty.
    if (!fullName || !studentId || !email || !password || !confirmPassword) {
        showRegisterMessage(
            "Please complete all required fields.",
            "error"
        );

        return;
    }


    // Check password length.
    if (password.length < 8) {
        showRegisterMessage(
            "Your password must contain at least 8 characters.",
            "error"
        );

        return;
    }


    // Check whether the passwords match.
    if (password !== confirmPassword) {
        showRegisterMessage(
            "The passwords do not match. Please try again.",
            "error"
        );

        return;
    }


    // Check whether the user accepted the terms.
    if (!termsAccepted) {
        showRegisterMessage(
            "Please accept the borrowing rules to continue.",
            "error"
        );

        return;
    }


    // Frontend demonstration only.
    showRegisterMessage(
        "Your form is valid! Account creation will be connected to the backend later.",
        "success"
    );

    console.log("Registration form validation successful.");

});
