const express = require('express');
const fs = require('fs');
const bodyParser = require('body-parser');
const app = express();

app.use(express.static('public'));
app.use(bodyParser.json());

const DATA_FILE = './content.json';
const ADMIN_PASSWORD = "Mike-MTC-2026!"; // Change this to whatever Mike wants

// Save updates with Password Check
app.post('/api/save', (req, res) => {
    const { password, data } = req.body;

    if (password !== ADMIN_PASSWORD) {
        return res.status(401).json({ error: "Unauthorized: Access Denied." });
    }

    fs.writeFileSync(DATA_FILE, JSON.stringify(data, null, 2));
    res.json({ success: true });
});

app.get('/api/content', (req, res) => {
    const content = JSON.parse(fs.readFileSync(DATA_FILE, 'utf8'));
    res.json(content);
});

app.listen(3000, () => console.log('MTC Secure Backend active on Port 3000'));