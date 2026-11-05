
/* ==================================
   SAMPLE BORROWING RECORDS
   ================================== */

const sampleBorrowings = [
    {
        id: "sample-1",
        name: "Data Structures Textbook",
        category: "Books",
        borrowDate: "2026-10-25",
        returnDate: "2026-10-30",
        status: "Pending"
    },
    {
        id: "sample-2",
        name: "Scientific Calculator",
        category: "Electronics",
        borrowDate: "2026-10-20",
        returnDate: "2026-10-27",
        status: "Borrowed"
    },
    {
        id: "sample-3",
        name: "Laptop",
        category: "Electronics",
        borrowDate: "2026-10-15",
        returnDate: "2026-10-22",
        status: "Returned"
    },
    {
        id: "sample-4",
        name: "Football",
        category: "Sports",
        borrowDate: "2026-10-28",
        returnDate: "2026-11-02",
        status: "Approved"
    },
    {
        id: "sample-5",
        name: "Software Engineering Book",
        category: "Books",
        borrowDate: "2026-10-12",
        returnDate: "2026-10-18",
        status: "Rejected"
    }
];


/* ==================================
   LOAD SAVED DATA
   ================================== */

function readStorage(key, fallback = []) {
    try {
        const data = JSON.parse(localStorage.getItem(key));
        return Array.isArray(data) ? data : fallback;
    } catch (error) {
        return fallback;
    }
}

function loadBorrowings() {
    const savedRequests = readStorage("campusBorrowings");
    const cancelledSampleIds = readStorage("campusCancelledSampleIds");

    // Keep sample records unless they were cancelled.
    const activeSamples = sampleBorrowings
        .filter(item => !cancelledSampleIds.includes(item.id));

    // Convert saved requests into the format used by this page.
    const formattedRequests = savedRequests.map(item => ({
        id: String(item.id),
        name: item.resourceName || item.name || "Unnamed Resource",
        category: item.category || "Other",
        borrowDate: item.startDate || item.borrowDate || "",
        returnDate: item.endDate || item.returnDate || "",
        status: item.status || "Pending",
        isSavedRequest: true
    }));

    return [...formattedRequests, ...activeSamples];
}

let borrowings = loadBorrowings();


/* ==================================
   GET HTML ELEMENTS
   ================================== */

const tableBody = document.getElementById("borrowings-table-body");
const searchInput = document.getElementById("search-input");
const statusFilter = document.getElementById("status-filter");
const emptyState = document.getElementById("empty-state");
const recordCount = document.getElementById("record-count");
const clearFiltersButton = document.getElementById("clear-filters");


/* ==================================
   FORMAT DATES
   ================================== */

function formatDate(dateString) {
    if (!dateString) {
        return "—";
    }

    const date = new Date(dateString + "T00:00:00");

    if (Number.isNaN(date.getTime())) {
        return "—";
    }

    return date.toLocaleDateString("en-GB", {
        day: "2-digit",
        month: "short",
        year: "numeric"
    });
}


/* ==================================
   UPDATE DASHBOARD STATISTICS
   ================================== */

function updateStatistics() {
    document.getElementById("total-requests").textContent =
        borrowings.length;

    document.getElementById("pending-requests").textContent =
        borrowings.filter(item => item.status === "Pending").length;

    document.getElementById("borrowed-requests").textContent =
        borrowings.filter(item => item.status === "Borrowed").length;

    document.getElementById("returned-requests").textContent =
        borrowings.filter(item => item.status === "Returned").length;
}


/* ==================================
   GET STATUS CSS CLASS
   ================================== */

function getStatusClass(status) {
    switch (status) {
        case "Pending":
            return "status-pending";

        case "Approved":
            return "status-approved";

        case "Borrowed":
            return "status-borrowed";

        case "Returned":
            return "status-returned";

        case "Rejected":
            return "status-rejected";

        default:
            return "";
    }
}


/* ==================================
   GET ACTION BUTTON
   ================================== */

function getActionButton(item) {
    if (item.status === "Pending") {
        return `
            <button
                class="action-button cancel"
                data-action="cancel"
                data-id="${item.id}"
            >
                Cancel Request
            </button>
        `;
    }

    if (item.status === "Borrowed") {
        return `
            <button
                class="action-button disabled"
                disabled
                title="Return processing will be added later"
            >
                Return Item
            </button>
        `;
    }

    return `
        <button class="action-button disabled" disabled>
            No Action
        </button>
    `;
}


/* ==================================
   DISPLAY BORROWING RECORDS
   ================================== */

function displayBorrowings() {
    const searchText = searchInput.value.trim().toLowerCase();
    const selectedStatus = statusFilter.value;

    const filteredBorrowings = borrowings.filter(item => {
        const matchesSearch =
            item.name.toLowerCase().includes(searchText) ||
            item.category.toLowerCase().includes(searchText);

        const matchesStatus =
            selectedStatus === "All" ||
            item.status === selectedStatus;

        return matchesSearch && matchesStatus;
    });

    recordCount.textContent =
        `Showing ${filteredBorrowings.length} of ${borrowings.length} records`;

    if (filteredBorrowings.length === 0) {
        tableBody.innerHTML = "";
        emptyState.hidden = false;
        return;
    }

    emptyState.hidden = true;

    tableBody.innerHTML = filteredBorrowings.map(item => `
        <tr>
            <td>
                <span class="resource-name">
                    ${escapeHTML(item.name)}
                </span>

                <span class="resource-category">
                    ${escapeHTML(item.category)}
                </span>
            </td>

            <td>${formatDate(item.borrowDate)}</td>

            <td>${formatDate(item.returnDate)}</td>

            <td>
                <span class="status-badge ${getStatusClass(item.status)}">
                    ${escapeHTML(item.status)}
                </span>
            </td>

            <td>${getActionButton(item)}</td>
        </tr>
    `).join("");
}


/* ==================================
   SAFELY DISPLAY TEXT
   ================================== */

function escapeHTML(value) {
    return String(value).replace(/[&<>"']/g, character => ({
        "&": "&amp;",
        "<": "&lt;",
        ">": "&gt;",
        '"': "&quot;",
        "'": "&#39;"
    })[character]);
}


/* ==================================
   CANCEL A PENDING REQUEST
   ================================== */

tableBody.addEventListener("click", function(event) {
    const button = event.target.closest(
        'button[data-action="cancel"]'
    );

    if (!button) {
        return;
    }

    const itemId = button.dataset.id;

    const selectedItem = borrowings.find(
        item => String(item.id) === String(itemId)
    );

    if (!selectedItem || selectedItem.status !== "Pending") {
        return;
    }

    const confirmed = window.confirm(
        `Are you sure you want to cancel your request for "${selectedItem.name}"?`
    );

    if (!confirmed) {
        return;
    }

    if (selectedItem.isSavedRequest) {
        // Remove the saved request from localStorage.
        const savedRequests = readStorage("campusBorrowings");

        const updatedRequests = savedRequests.filter(
            item => String(item.id) !== String(itemId)
        );

        localStorage.setItem(
            "campusBorrowings",
            JSON.stringify(updatedRequests)
        );
    } else {
        // Remember cancelled sample records across page refreshes.
        const cancelledSampleIds = readStorage(
            "campusCancelledSampleIds"
        );

        if (!cancelledSampleIds.includes(itemId)) {
            cancelledSampleIds.push(itemId);
        }

        localStorage.setItem(
            "campusCancelledSampleIds",
            JSON.stringify(cancelledSampleIds)
        );
    }

    borrowings = loadBorrowings();

    updateStatistics();
    displayBorrowings();

    window.alert("Your pending borrowing request has been cancelled.");
});


/* ==================================
   SEARCH EVENT
   ================================== */

searchInput.addEventListener("input", function() {
    displayBorrowings();
});


/* ==================================
   STATUS FILTER EVENT
   ================================== */

statusFilter.addEventListener("change", function() {
    displayBorrowings();
});


/* ==================================
   CLEAR FILTERS
   ================================== */

clearFiltersButton.addEventListener("click", function() {
    searchInput.value = "";
    statusFilter.value = "All";

    displayBorrowings();
});


/* ==================================
   INITIALIZE PAGE
   ================================== */

updateStatistics();
displayBorrowings();

