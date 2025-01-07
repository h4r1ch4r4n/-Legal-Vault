// Contract ABI
const abi = [
    {
        "inputs": [
            {
                "internalType": "string",
                "name": "hash",
                "type": "string"
            }
        ],
        "name": "addRecord",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "uint256",
                "name": "id",
                "type": "uint256"
            }
        ],
        "name": "getRecord",
        "outputs": [
            {
                "components": [
                    { "internalType": "uint256", "name": "id", "type": "uint256" },
                    { "internalType": "string", "name": "hash", "type": "string" },
                    { "internalType": "address", "name": "owner", "type": "address" },
                    { "internalType": "uint256", "name": "timestamp", "type": "uint256" }
                ],
                "internalType": "struct LegalRecordVault.LegalRecord",
                "name": "",
                "type": "tuple"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    }
];

// Replace with your deployed contract address
const contractAddress = "0xYourContractAddressHere";

// Initialize web3
let web3;
let contract;

window.onload = async () => {
    if (typeof window.ethereum !== 'undefined') {
        web3 = new Web3(window.ethereum);
        await window.ethereum.request({ method: "eth_requestAccounts" });
        contract = new web3.eth.Contract(abi, contractAddress);
        loadRecords();
    } else {
        alert("Please install MetaMask to use this application.");
    }
};

// Add a new record
async function addRecord() {
    const recordHash = document.getElementById("recordHash").value;
    if (!recordHash) {
        alert("Please enter a record hash.");
        return;
    }

    const accounts = await web3.eth.getAccounts();
    await contract.methods.addRecord(recordHash).send({ from: accounts[0] });
    alert("Record added successfully!");
    document.getElementById("recordHash").value = "";
    loadRecords();
}

// Load all records
async function loadRecords() {
    const recordTable = document.getElementById("recordTable");
    recordTable.innerHTML = "";

    const recordCount = await contract.methods.recordCount().call();

    for (let i = 1; i <= recordCount; i++) {
        const record = await contract.methods.getRecord(i).call();
        const row = `<tr>
            <td>${record.id}</td>
            <td>${record.hash}</td>
            <td>${record.owner}</td>
            <td>${new Date(record.timestamp * 1000).toLocaleString()}</td>
        </tr>`;
        recordTable.innerHTML += row;
    }
}
