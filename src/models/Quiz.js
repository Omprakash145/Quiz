const db = require('../config/database');

class Quiz {
  static async create({ title, timeLimit = 300 }) {
    const [rows] = await db.execute(
      'CALL sp_create_quiz(?, ?)',
      [title, timeLimit]
    );
    return rows[0][0];
  }

  static async findById(id) {
    const [rows] = await db.execute(
      'CALL sp_get_quiz_by_id(?)',
      [id]
    );
    return rows[0][0];
  }

  static async findAll() {
    const [rows] = await db.execute('CALL sp_get_all_quizzes()');
    return rows[0];
  }

  static async delete(id) {
    const [rows] = await db.execute(
      'CALL sp_delete_quiz(?)',
      [id]
    );
    return rows[0][0];
  }
}

module.exports = Quiz;