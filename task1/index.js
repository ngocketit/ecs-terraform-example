const express = require('express')
const PORT = 8000
const HOST = '0.0.0.0'
const app = express()

app.get('/task1/', (req, res) => {
  res.send('Hello from task1!')
})

app.get('/task1/hi', (req, res) => {
  res.send('Hi from task1!')
})

app.listen(PORT, HOST)
console.log(`Running on ${HOST}:${PORT}`)
