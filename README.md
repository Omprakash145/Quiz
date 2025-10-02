# Quiz API

This project is a backend API for a quiz application designed to handle quiz creation, question management, quiz participation, and scoring. It demonstrates clean backend architecture with separation of concerns and RESTful design.

## Getting Started

1. **Clone the repository**  
   ```bash
   git clone https://github.com/Omprakash145/Quiz.git
   cd Quiz
   ```

2. **Install dependencies**  
   ```bash
   npm install
   ```

3. **Configure environment variables**  
   Create a `.env` file in the root directory with the following variables (adjust values as needed):
   ```
   DB_HOST=localhost
   DB_USER=root
   DB_PASSWORD=your_password
   DB_NAME=quiz_db
   DB_PORT=3306
   PORT=3000
   ```

4. **Start the server**  
   ```bash
   npm start
   ```
   The API will run at `http://localhost:3000/`.

## API Endpoints

All endpoints are prefixed with `/api`.

### Quiz Management
- **POST /api/quizzes** — Create a new quiz
- **GET /api/quizzes** — Retrieve all quizzes
- **GET /api/quizzes/:quizId** — Retrieve details for a specific quiz
- **DELETE /api/quizzes/:quizId** — Delete a quiz by its ID

### Question Management
- **POST /api/quizzes/:quizId/questions** — Add a question to a specific quiz
- **GET /api/quizzes/:quizId/questions** — Get all questions for a specific quiz

### Participation and Results
- **POST /api/submit** — Submit answers for a quiz

### Statistics & Attempts
- **GET /api/quizzes/:quizId/statistics** — Get statistics for a specific quiz
- **GET /api/quizzes/:quizId/attempts** — Get attempts for a specific quiz
- **GET /api/attempts/:attemptId** — Get details for a specific attempt

---

Errors are returned in JSON format, indicating the error message and status.

For more details, visit the code or open an issue!
