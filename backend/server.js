const express = require("express");
const cors = require("cors");
const os = require("os");

const app = express();
const PORT = process.env.PORT || 3000;
const VERSION = process.env.APP_VERSION || "v1";

app.use(cors());
app.use(express.json());

app.get("/api/health", (req, res) => {
  res.json({ status: "ok", service: "backend", version: VERSION, hostname: os.hostname(), timestamp: new Date().toISOString() });
});

app.get("/api/message", (req, res) => {
  res.json({ message: "Hello from Backend Microservice", version: VERSION, servedBy: os.hostname() });
});

app.get("/api/error", (req, res) => {
  res.status(500).json({ status: "error", message: "Intentional 500 for incident/testing demos", servedBy: os.hostname() });
});

app.listen(PORT, "0.0.0.0", () => console.log(`Backend service is running on port ${PORT}`));
