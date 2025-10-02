const express = require('express');
const cors = require('cors');
const quizRoutes = require('./routes/quizRoutes');
const errorHandler = require('./middleware/errorHandler');

const app = express();

app.use(cors());
app.use(express.json());

app.get('/', (req, res) => {
  res.json({
    message: 'Quiz API Server',
    version: '3.0.0',
    endpoints: {
      'POST /api/quizzes': 'Create a new quiz',
      'GET /api/quizzes': 'Get all quizzes',
      'GET /api/quizzes/:quizId': 'Get quiz details',
      'DELETE /api/quizzes/:quizId': 'Delete a quiz',
      'POST /api/quizzes/:quizId/questions': 'Add question to quiz',
      'GET /api/quizzes/:quizId/questions': 'Get quiz questions',
      'GET /api/quizzes/:quizId/statistics': 'Get quiz statistics',
      'GET /api/quizzes/:quizId/attempts': 'Get quiz attempts',
      'GET /api/attempts/:attemptId': 'Get attempt details',
      'POST /api/submit': 'Submit quiz answers'
    }
  });
});

app.use('/api', quizRoutes);
app.use(errorHandler);

module.exports = app;