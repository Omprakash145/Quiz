const db = require('../config/database');

class Question {
  static async create(quizId, { text, options, correctOptionNumber }) {
    const optionsJson = JSON.stringify(options ?? []);
    
    const [rows] = await db.execute(
      'CALL sp_add_question(?, ?, ?, ?)',
      [quizId, text, correctOptionNumber, optionsJson]
    );
    
    const result = rows[0][0];
    const parsedOptions = typeof result.options === 'string' ? JSON.parse(result.options) : result.options;
    return { ...result, options: parsedOptions };
  }

  static async findByQuizId(quizId) {
    const [rows] = await db.execute(
      'CALL sp_get_quiz_questions(?)',
      [quizId]
    );
    
    return rows[0].map(row => ({
      ...row,
      options: JSON.parse(row.options)
    }));
  }
}

module.exports = Question;