const express = require('express');
const mongoose = require('mongoose');

const app = express();
const port = process.env.PORT || 3000;

const mongoUri = process.env.MONGO_URI || 'mongodb://localhost:27017/devops_test';
mongoose.set('strictQuery', false);

mongoose.connect(mongoUri, { useNewUrlParser: true, useUnifiedTopology: true })
  .then(() => console.log('Connected to MongoDB:', mongoUri))
  .catch(err => {
    console.error('MongoDB connection error:', err.message || err);
    process.exit(1);
  });

const itemSchema = new mongoose.Schema({
  name: String,
  createdAt: { type: Date, default: Date.now }
});
const Item = mongoose.model('Item', itemSchema);

app.use(express.json());

app.get('/', (req, res) => {
  res.send({ status: 'ok', message: 'Node.js + MongoDB on ECS (EC2)' });
});

app.get('/items', async (req, res) => {
  const items = await Item.find().limit(20).sort({ createdAt: -1 });
  res.json(items);
});

app.post('/items', async (req, res) => {
  const item = new Item({ name: req.body.name || 'unnamed' });
  await item.save();
  res.status(201).json(item);
});

app.listen(port, () => {
  console.log(`App listening on ${port}`);
});
