const quizService = require('../services/quizService');

class QuizController {
  async createQuiz(req, res, next) {
    try {
      const { title, timeLimit } = req.body;
      const quiz = await quizService.createQuiz(title, timeLimit);

      res.status(201).json({
        success: true,
        data: quiz
      });
    } catch (error) {
      next(error);
    }
  }

  async getAllQuizzes(req, res, next) {
    try {
      const quizzes = await quizService.getAllQuizzes();
      res.json({
        success: true,
        data: quizzes
      });
    } catch (error) {
      next(error);
    }
  }

  async getQuiz(req, res, next) {
    try {
      const { quizId } = req.params;
      const quiz = await quizService.getQuizById(quizId);

      res.json({
        success: true,
        data: quiz
      });
    } catch (error) {
      next(error);
    }
  }

  async deleteQuiz(req, res, next) {
    try {
      const { quizId } = req.params;
      await quizService.deleteQuiz(quizId);

      res.json({
        success: true,
        message: 'Quiz deleted successfully'
      });
    } catch (error) {
      next(error);
    }
  }

  async addQuestion(req, res, next) {
    try {
      const { quizId } = req.params;
      const { text, options, correctOptionNumber } = req.body;

      const question = await quizService.addQuestion(quizId, {
        text,
        options,
        correctOptionNumber
      });

      res.status(201).json({
        success: true,
        data: question
      });
    } catch (error) {
      next(error);
    }
  }

  async getQuizQuestions(req, res, next) {
    try {
      const { quizId } = req.params;
      const questions = await quizService.getQuizQuestions(quizId);

      res.json({
        success: true,
        data: questions
      });
    } catch (error) {
      next(error);
    }
  }

  async submitAnswers(req, res, next) {
    try {
      const { quizId, answers, timeTaken } = req.body;
      const result = await quizService.submitAnswers(quizId, answers, timeTaken);

      res.json({
        success: true,
        data: result
      });
    } catch (error) {
      next(error);
    }
  }

  async getQuizStatistics(req, res, next) {
    try {
      const { quizId } = req.params;
      const stats = await quizService.getQuizStatistics(quizId);

      res.json({
        success: true,
        data: stats
      });
    } catch (error) {
      next(error);
    }
  }

  async getQuizAttempts(req, res, next) {
    try {
      const { quizId } = req.params;
      const { limit = 10 } = req.query;
      const attempts = await quizService.getQuizAttempts(quizId, parseInt(limit));

      res.json({
        success: true,
        data: attempts
      });
    } catch (error) {
      next(error);
    }
  }

  async getAttemptDetails(req, res, next) {
    try {
      const { attemptId } = req.params;
      const details = await quizService.getAttemptDetails(attemptId);

      res.json({
        success: true,
        data: details
      });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new QuizController();