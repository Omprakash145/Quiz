const Quiz = require('../models/Quiz');
const Question = require('../models/Question');
const db = require('../config/database');

class QuizService {
  async createQuiz(title, timeLimit) {
    return await Quiz.create({ title, timeLimit });
  }

  async getQuizById(quizId) {
    return await Quiz.findById(quizId);
  }

  async getAllQuizzes() {
    return await Quiz.findAll();
  }

  async deleteQuiz(quizId) {
    return await Quiz.delete(quizId);
  }

  async addQuestion(quizId, questionData) {
    return await Question.create(quizId, questionData);
  }

  async getQuizQuestions(quizId) {
    return await Question.findByQuizId(quizId);
  }

  async submitAnswers(quizId, answers, timeTaken) {
    const answersJson = JSON.stringify(answers ?? []);
    
    const [rows] = await db.execute(
      'CALL sp_submit_quiz_answers(?, ?, ?)',
      [quizId, answersJson, timeTaken]
    );
    
    const result = rows[0][0];
    const parsedResults = typeof result.results === 'string' ? JSON.parse(result.results) : result.results;
    return { ...result, results: parsedResults };
  }

  async getQuizStatistics(quizId) {
    const [rows] = await db.execute(
      'CALL sp_get_quiz_statistics(?)',
      [quizId]
    );
    return rows[0][0];
  }

  async getQuizAttempts(quizId, limit = 10) {
    const [rows] = await db.execute(
      'CALL sp_get_quiz_attempts(?, ?)',
      [quizId, limit]
    );
    return rows[0];
  }

  async getAttemptDetails(attemptId) {
    const [rows] = await db.execute(
      'CALL sp_get_attempt_details(?)',
      [attemptId]
    );
    
    return {
      attempt: rows[0][0],
      details: rows[1]
    };
  }
}

module.exports = new QuizService();