const express = require('express');
const router = express.Router();
const quizController = require('../controllers/quizController');

router.post('/quizzes', quizController.createQuiz);
router.get('/quizzes', quizController.getAllQuizzes);
router.get('/quizzes/:quizId', quizController.getQuiz);
router.delete('/quizzes/:quizId', quizController.deleteQuiz);
router.post('/quizzes/:quizId/questions', quizController.addQuestion);
router.get('/quizzes/:quizId/questions', quizController.getQuizQuestions);
router.get('/quizzes/:quizId/statistics', quizController.getQuizStatistics);
router.get('/quizzes/:quizId/attempts', quizController.getQuizAttempts);
router.get('/attempts/:attemptId', quizController.getAttemptDetails);
router.post('/submit', quizController.submitAnswers);

module.exports = router;