const express = require('express')
const PORT = 8000
const HOST = '0.0.0.0'
const app = express()

app.get('/task2/', (req, res) => {
  res.send('Hello from task2!')
})

app.get('/task2/hi', (req, res) => {
  res.send('Hi from task2!')
})

app.listen(PORT, HOST)
console.log(`Running on ${HOST}:${PORT}`)
