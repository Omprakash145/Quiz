require('dotenv').config();
const app = require('./src/app');

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`🚀 Quiz API Server running on port ${PORT}`);
  console.log(`📝 Documentation: http://localhost:${PORT}/`);
});