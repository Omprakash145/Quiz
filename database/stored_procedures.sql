USE quiz_db;

DELIMITER //

-- ==============================================
-- 1. CREATE QUIZ
-- ==============================================
DROP PROCEDURE IF EXISTS sp_create_quiz//
CREATE PROCEDURE sp_create_quiz(
  IN p_title VARCHAR(255),
  IN p_time_limit INT
)
BEGIN
  DECLARE v_quiz_id INT;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;
  
  -- Validation
  IF p_title IS NULL OR TRIM(p_title) = '' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Quiz title is required';
  END IF;
  
  IF p_time_limit < 60 OR p_time_limit > 7200 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Time limit must be between 60 and 7200 seconds';
  END IF;
  
  -- Insert quiz
  START TRANSACTION;
  INSERT INTO quizzes (title, time_limit) 
  VALUES (TRIM(p_title), p_time_limit);
  SET v_quiz_id = LAST_INSERT_ID();
  COMMIT;
  
  -- Return created quiz
  SELECT 
    id,
    title,
    time_limit as timeLimit,
    created_at as createdAt
  FROM quizzes
  WHERE id = v_quiz_id;
END//

-- ==============================================
-- 2. GET ALL QUIZZES
-- ==============================================
DROP PROCEDURE IF EXISTS sp_get_all_quizzes//
CREATE PROCEDURE sp_get_all_quizzes()
BEGIN
  SELECT 
    q.id,
    q.title,
    q.time_limit as timeLimit,
    q.created_at as createdAt,
    COUNT(DISTINCT qs.id) as questionCount,
    COUNT(DISTINCT qa.id) as attemptCount
  FROM quizzes q
  LEFT JOIN questions qs ON q.id = qs.quiz_id
  LEFT JOIN quiz_attempts qa ON q.id = qa.quiz_id
  GROUP BY q.id, q.title, q.time_limit, q.created_at
  ORDER BY q.created_at DESC;
END//

-- ==============================================
-- 3. GET QUIZ BY ID
-- ==============================================
DROP PROCEDURE IF EXISTS sp_get_quiz_by_id//
CREATE PROCEDURE sp_get_quiz_by_id(
  IN p_quiz_id INT
)
BEGIN
  DECLARE v_count INT;
  
  SELECT COUNT(*) INTO v_count FROM quizzes WHERE id = p_quiz_id;
  
  IF v_count = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Quiz not found';
  END IF;
  
  SELECT 
    q.id,
    q.title,
    q.time_limit as timeLimit,
    q.created_at as createdAt,
    COUNT(DISTINCT qs.id) as questionCount
  FROM quizzes q
  LEFT JOIN questions qs ON q.id = qs.quiz_id
  WHERE q.id = p_quiz_id
  GROUP BY q.id, q.title, q.time_limit, q.created_at;
END//

-- ==============================================
-- 4. DELETE QUIZ
-- ==============================================
DROP PROCEDURE IF EXISTS sp_delete_quiz//
CREATE PROCEDURE sp_delete_quiz(
  IN p_quiz_id INT
)
BEGIN
  DECLARE v_count INT;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;
  
  SELECT COUNT(*) INTO v_count FROM quizzes WHERE id = p_quiz_id;
  
  IF v_count = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Quiz not found';
  END IF;
  
  START TRANSACTION;
  DELETE FROM quizzes WHERE id = p_quiz_id;
  COMMIT;
  
  SELECT 'Quiz deleted successfully' as message;
END//

-- ==============================================
-- 5. ADD QUESTION TO QUIZ
-- ==============================================
DROP PROCEDURE IF EXISTS sp_add_question//
CREATE PROCEDURE sp_add_question(
  IN p_quiz_id INT,
  IN p_text TEXT,
  IN p_correct_option_number INT,
  IN p_options JSON
)
BEGIN
  DECLARE v_question_id INT;
  DECLARE v_question_number INT;
  DECLARE v_option_count INT;
  DECLARE v_quiz_exists INT;
  DECLARE i INT DEFAULT 0;
  DECLARE v_option_text TEXT;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;
  
  -- Check if quiz exists
  SELECT COUNT(*) INTO v_quiz_exists FROM quizzes WHERE id = p_quiz_id;
  IF v_quiz_exists = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Quiz not found';
  END IF;
  
  -- Validate question text
  IF p_text IS NULL OR TRIM(p_text) = '' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Question text is required';
  END IF;
  
  IF LENGTH(p_text) > 500 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Question text must not exceed 500 characters';
  END IF;
  
  -- Validate options
  SET v_option_count = JSON_LENGTH(p_options);
  
  IF v_option_count < 2 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Question must have at least 2 options';
  END IF;
  
  IF v_option_count > 6 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Question cannot have more than 6 options';
  END IF;
  
  IF p_correct_option_number < 1 OR p_correct_option_number > v_option_count THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid correct option number';
  END IF;
  
  -- Get next question number
  SELECT COALESCE(MAX(question_number), 0) + 1 
  INTO v_question_number
  FROM questions 
  WHERE quiz_id = p_quiz_id;
  
  -- Insert question and options within a transaction
  START TRANSACTION;
  INSERT INTO questions (quiz_id, question_number, text, correct_option_number)
  VALUES (p_quiz_id, v_question_number, TRIM(p_text), p_correct_option_number);
  SET v_question_id = LAST_INSERT_ID();
  
  WHILE i < v_option_count DO
    SET v_option_text = JSON_UNQUOTE(JSON_EXTRACT(p_options, CONCAT('$[', i, ']')));
    
    IF v_option_text IS NULL OR TRIM(v_option_text) = '' THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Option text cannot be empty';
    END IF;
    
    INSERT INTO options (question_id, option_number, text)
    VALUES (v_question_id, i + 1, TRIM(v_option_text));
    
    SET i = i + 1;
  END WHILE;
  COMMIT;
  
  -- Return created question
  SELECT 
    q.id,
    q.question_number as questionNumber,
    q.text,
    (
      SELECT JSON_ARRAYAGG(
        JSON_OBJECT(
          'number', o.option_number,
          'text', o.text
        )
      )
      FROM options o
      WHERE o.question_id = q.id
      ORDER BY o.option_number
    ) as options
  FROM questions q
  WHERE q.id = v_question_id;
END//

-- ==============================================
-- 6. GET QUIZ QUESTIONS (WITHOUT ANSWERS)
-- ==============================================
DROP PROCEDURE IF EXISTS sp_get_quiz_questions//
CREATE PROCEDURE sp_get_quiz_questions(
  IN p_quiz_id INT
)
BEGIN
  DECLARE v_quiz_exists INT;
  
  SELECT COUNT(*) INTO v_quiz_exists FROM quizzes WHERE id = p_quiz_id;
  IF v_quiz_exists = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Quiz not found';
  END IF;
  
  SELECT 
    q.id,
    q.question_number as questionNumber,
    q.text,
    (
      SELECT JSON_ARRAYAGG(
        JSON_OBJECT(
          'number', o.option_number,
          'text', o.text
        )
      )
      FROM options o
      WHERE o.question_id = q.id
      ORDER BY o.option_number
    ) as options
  FROM questions q
  WHERE q.quiz_id = p_quiz_id
  ORDER BY q.question_number;
END//

-- ==============================================
-- 7. SUBMIT QUIZ ANSWERS
-- ==============================================
DROP PROCEDURE IF EXISTS sp_submit_quiz_answers//
CREATE PROCEDURE sp_submit_quiz_answers(
  IN p_quiz_id INT,
  IN p_answers JSON,
  IN p_time_taken INT
)
BEGIN
  DECLARE v_quiz_exists INT;
  DECLARE v_time_limit INT;
  DECLARE v_total_questions INT;
  DECLARE v_score INT DEFAULT 0;
  DECLARE v_percentage DECIMAL(5,2);
  DECLARE v_attempt_id INT;
  DECLARE v_answer_count INT;
  DECLARE i INT DEFAULT 0;
  DECLARE v_question_id INT;
  DECLARE v_selected_option INT;
  DECLARE v_correct_option INT;
  DECLARE v_is_correct BOOLEAN;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;
  
  -- Check quiz exists and get time limit
  SELECT COUNT(*), time_limit 
  INTO v_quiz_exists, v_time_limit
  FROM quizzes 
  WHERE id = p_quiz_id;
  
  IF v_quiz_exists = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Quiz not found';
  END IF;
  
  -- Validate time limit
  IF p_time_taken IS NOT NULL AND p_time_taken > v_time_limit THEN
    SIGNAL SQLSTATE '45000' 
    SET MESSAGE_TEXT = 'Time limit exceeded';
  END IF;
  
  -- Get total questions
  SELECT COUNT(*) INTO v_total_questions FROM questions WHERE quiz_id = p_quiz_id;
  
  IF v_total_questions = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Quiz has no questions';
  END IF;
  
  -- Validate answers
  SET v_answer_count = JSON_LENGTH(p_answers);
  
  -- Calculate score
  WHILE i < v_answer_count DO
    SET v_question_id = JSON_UNQUOTE(JSON_EXTRACT(p_answers, CONCAT('$[', i, '].questionId')));
    SET v_selected_option = JSON_UNQUOTE(JSON_EXTRACT(p_answers, CONCAT('$[', i, '].selectedOptionNumber')));
    
    -- Get correct option
    SELECT correct_option_number INTO v_correct_option
    FROM questions
    WHERE id = v_question_id AND quiz_id = p_quiz_id;
    
    IF v_correct_option IS NOT NULL THEN
      SET v_is_correct = (v_selected_option = v_correct_option);
      IF v_is_correct THEN
        SET v_score = v_score + 1;
      END IF;
    END IF;
    
    SET i = i + 1;
  END WHILE;
  
  -- Calculate percentage
  SET v_percentage = (v_score / v_total_questions) * 100;
  
  -- Save attempt and answers within a transaction
  START TRANSACTION;
  INSERT INTO quiz_attempts (quiz_id, score, total, time_taken, percentage)
  VALUES (p_quiz_id, v_score, v_total_questions, p_time_taken, v_percentage);
  SET v_attempt_id = LAST_INSERT_ID();
  
  SET i = 0;
  WHILE i < v_answer_count DO
    SET v_question_id = JSON_UNQUOTE(JSON_EXTRACT(p_answers, CONCAT('$[', i, '].questionId')));
    SET v_selected_option = JSON_UNQUOTE(JSON_EXTRACT(p_answers, CONCAT('$[', i, '].selectedOptionNumber')));
    
    SELECT correct_option_number INTO v_correct_option
    FROM questions
    WHERE id = v_question_id;
    
    IF v_correct_option IS NOT NULL THEN
      SET v_is_correct = (v_selected_option = v_correct_option);
      
      INSERT INTO answer_details (attempt_id, question_id, selected_option_number, is_correct)
      VALUES (v_attempt_id, v_question_id, v_selected_option, v_is_correct);
    END IF;
    
    SET i = i + 1;
  END WHILE;
  COMMIT;
  
  -- Return result with details
  SELECT 
    v_score as score,
    v_total_questions as total,
    v_percentage as percentage,
    p_time_taken as timeTaken,
    v_time_limit as timeLimit,
    v_attempt_id as attemptId,
    (
      SELECT JSON_ARRAYAGG(
        JSON_OBJECT(
          'questionId', ad.question_id,
          'questionNumber', q.question_number,
          'correct', ad.is_correct,
          'selectedOption', ad.selected_option_number,
          'correctOption', q.correct_option_number
        )
      )
      FROM answer_details ad
      JOIN questions q ON ad.question_id = q.id
      WHERE ad.attempt_id = v_attempt_id
    ) as results;
END//

-- ==============================================
-- 8. GET QUIZ STATISTICS
-- ==============================================
DROP PROCEDURE IF EXISTS sp_get_quiz_statistics//
CREATE PROCEDURE sp_get_quiz_statistics(
  IN p_quiz_id INT
)
BEGIN
  DECLARE v_quiz_exists INT;
  
  SELECT COUNT(*) INTO v_quiz_exists FROM quizzes WHERE id = p_quiz_id;
  IF v_quiz_exists = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Quiz not found';
  END IF;
  
  SELECT 
    COUNT(*) as totalAttempts,
    COALESCE(AVG(score), 0) as averageScore,
    COALESCE(MAX(score), 0) as highestScore,
    COALESCE(MIN(score), 0) as lowestScore,
    COALESCE(AVG(percentage), 0) as averagePercentage,
    COALESCE(AVG(time_taken), 0) as averageTime,
    COALESCE(MIN(time_taken), 0) as fastestTime,
    COALESCE(MAX(time_taken), 0) as slowestTime
  FROM quiz_attempts
  WHERE quiz_id = p_quiz_id;
END//

-- ==============================================
-- 9. GET QUIZ ATTEMPTS
-- ==============================================
DROP PROCEDURE IF EXISTS sp_get_quiz_attempts//
CREATE PROCEDURE sp_get_quiz_attempts(
  IN p_quiz_id INT,
  IN p_limit INT
)
BEGIN
  DECLARE v_quiz_exists INT;
  
  SELECT COUNT(*) INTO v_quiz_exists FROM quizzes WHERE id = p_quiz_id;
  IF v_quiz_exists = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Quiz not found';
  END IF;
  
  SELECT 
    id,
    score,
    total,
    percentage,
    time_taken as timeTaken,
    attempted_at as attemptedAt
  FROM quiz_attempts
  WHERE quiz_id = p_quiz_id
  ORDER BY attempted_at DESC
  LIMIT p_limit;
END//

-- ==============================================
-- 10. GET ATTEMPT DETAILS
-- ==============================================
DROP PROCEDURE IF EXISTS sp_get_attempt_details//
CREATE PROCEDURE sp_get_attempt_details(
  IN p_attempt_id INT
)
BEGIN
  DECLARE v_attempt_exists INT;
  
  SELECT COUNT(*) INTO v_attempt_exists FROM quiz_attempts WHERE id = p_attempt_id;
  IF v_attempt_exists = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Attempt not found';
  END IF;
  
  -- Get attempt summary
  SELECT 
    qa.id,
    qa.quiz_id as quizId,
    q.title as quizTitle,
    qa.score,
    qa.total,
    qa.percentage,
    qa.time_taken as timeTaken,
    qa.attempted_at as attemptedAt
  FROM quiz_attempts qa
  JOIN quizzes q ON qa.quiz_id = q.id
  WHERE qa.id = p_attempt_id;
  
  -- Get answer details
  SELECT 
    ad.question_id as questionId,
    qs.question_number as questionNumber,
    qs.text as questionText,
    ad.selected_option_number as selectedOption,
    qs.correct_option_number as correctOption,
    ad.is_correct as isCorrect,
    (
      SELECT text 
      FROM options 
      WHERE question_id = ad.question_id 
      AND option_number = ad.selected_option_number
    ) as selectedOptionText,
    (
      SELECT text 
      FROM options 
      WHERE question_id = ad.question_id 
      AND option_number = qs.correct_option_number
    ) as correctOptionText
  FROM answer_details ad
  JOIN questions qs ON ad.question_id = qs.id
  WHERE ad.attempt_id = p_attempt_id
  ORDER BY qs.question_number;
END//

DELIMITER ;



