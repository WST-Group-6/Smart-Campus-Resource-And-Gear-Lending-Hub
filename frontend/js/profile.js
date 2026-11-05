// ==================================
// GET HTML ELEMENTS
// ==================================

const profileForm = document.getElementById("profile-form");

const editButton = document.getElementById("edit-profile-button");

const cancelButton = document.getElementById("cancel-edit-button");

const formActions = document.getElementById("form-actions");

const profileMessage = document.getElementById("profile-message");

const sidebarName = document.getElementById("sidebar-name");

const profileAvatar = document.getElementById("profile-avatar");


// ==================================
// PROFILE INPUT FIELDS
// ==================================

const editableFields = [
    "full-name",
    "email",
    "phone",
    "faculty",
    "department",
    "academic-year"
];


// ==================================
// SAVE ORIGINAL VALUES
// ==================================

let originalValues = {};

function saveOriginalValues() {

    originalValues = {};

    editableFields.forEach(function(fieldId) {

        const field = document.getElementById(fieldId);

        originalValues[fieldId] = field.value;

    });

}


// ==================================
// ENABLE EDIT MODE
// ==================================

function enableEditMode() {

    saveOriginalValues();

    editableFields.forEach(function(fieldId) {

        const field = document.getElementById(fieldId);

        field.disabled = false;

    });

    editButton.hidden = true;

    formActions.hidden = false;

    hideMessage();

}


// ==================================
// DISABLE EDIT MODE
// ==================================

function disableEditMode() {

    editableFields.forEach(function(fieldId) {

        const field = document.getElementById(fieldId);

        field.disabled = true;

    });

    editButton.hidden = false;

    formActions.hidden = true;

}


// ==================================
// UPDATE PROFILE DISPLAY
// ==================================

function updateProfileDisplay() {

    const fullName = document
        .getElementById("full-name")
        .value.trim();

    sidebarName.textContent = fullName || "Student Name";

    profileAvatar.textContent = fullName
        ? fullName.charAt(0).toUpperCase()
        : "S";

}


// ==================================
// SHOW MESSAGE
// ==================================

function showMessage(message, type) {

    profileMessage.textContent = message;

    profileMessage.className = "message " + type;

}


// ==================================
// HIDE MESSAGE
// ==================================

function hideMessage() {

    profileMessage.textContent = "";

    profileMessage.className = "message";

}


// ==================================
// EDIT PROFILE BUTTON
// ==================================

editButton.addEventListener("click", function() {

    enableEditMode();

});


// ==================================
// SAVE PROFILE CHANGES
// ==================================

profileForm.addEventListener("submit", function(event) {

    event.preventDefault();

    // Validate the form using browser validation.
    if (!profileForm.checkValidity()) {

        profileForm.reportValidity();

        return;

    }


    const fullName = document
        .getElementById("full-name")
        .value.trim();

    const email = document
        .getElementById("email")
        .value.trim();


    if (fullName.length < 2) {

        showMessage(
            "Please enter a valid full name.",
            "error"
        );

        return;

    }


    if (!email) {

        showMessage(
            "Please enter your university email address.",
            "error"
        );

        return;

    }


    // Update the profile display.
    updateProfileDisplay();


    // This is a frontend demonstration only.
    // Changes are not saved to the Java backend or database.

    disableEditMode();

    showMessage(
        "Profile updated in this page. Changes will not be saved after refreshing because the backend is not connected yet.",
        "success"
    );

});


// ==================================
// CANCEL EDITING
// ==================================

cancelButton.addEventListener("click", function() {

    // Restore the original values.
    editableFields.forEach(function(fieldId) {

        const field = document.getElementById(fieldId);

        field.value = originalValues[fieldId];

    });


    updateProfileDisplay();

    disableEditMode();

    hideMessage();

});


// ==================================
// INITIALIZE PROFILE PAGE
// ==================================

saveOriginalValues();

updateProfileDisplay();

disableEditMode();
