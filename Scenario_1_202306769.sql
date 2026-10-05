TASK 1 Create tables

CREATE TABLE books (
    book_id SERIAL PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    available_copies INTEGER NOT NULL
);

CREATE TABLE book_loans (
    loan_id SERIAL PRIMARY KEY,
    book_id INTEGER NOT NULL,
    student_number VARCHAR(50) NOT NULL,
    quantity INTEGER NOT NULL,
    loan_status VARCHAR(30) NOT NULL
);

INSERT INTO books (title, available_copies)
VALUES
('Database Systems', 10),
('Computer Networks', 5),
('Software Engineering', 2);

TASK 2 Stock check

DO $$
DECLARE
    v_copies INTEGER;
BEGIN
    SELECT available_copies
    INTO v_copies
    FROM books
    WHERE book_id = 1;

    IF v_copies = 0 THEN
        RAISE NOTICE 'Book is unavailable.';

    ELSIF v_copies <= 2 THEN
        RAISE NOTICE 'Book is low on copies.';

    ELSE
        RAISE NOTICE 'Book is sufficiently stocked.';
    END IF;
END;
$$;

TASK 3 Reminders and shelves

DO $$
DECLARE
    reminder_number INTEGER := 1;
BEGIN
    WHILE reminder_number <= 3 LOOP
        RAISE NOTICE 'Overdue reminder %', reminder_number;
        reminder_number := reminder_number + 1;
    END LOOP;
END;
$$;


DO $$
BEGIN
    FOR shelf_number IN 1..3 LOOP
        RAISE NOTICE 'Library shelf number %', shelf_number;
    END LOOP;
END;
$$;

TASK 4 Borrow procedure

CREATE OR REPLACE PROCEDURE borrow_book(
    p_book_id INTEGER,
    p_student_number VARCHAR,
    p_quantity INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_available INTEGER;
BEGIN
    SELECT available_copies
    INTO v_available
    FROM books
    WHERE book_id = p_book_id;

    IF v_available >= p_quantity THEN

        UPDATE books
        SET available_copies = available_copies - p_quantity
        WHERE book_id = p_book_id;

        INSERT INTO book_loans
            (book_id, student_number, quantity, loan_status)
        VALUES
            (p_book_id, p_student_number, p_quantity, 'Borrowed');

        RAISE NOTICE 'Book borrowed successfully.';

    ELSE
        RAISE NOTICE 'Insufficient copies available.';
    END IF;
END;
$$;

TASK 5 Test borrowing

CALL borrow_book(1, 'STU001', 2);

CALL borrow_book(2, 'STU002', 1);

CALL borrow_book(3, 'STU003', 10);

SELECT * FROM books;

SELECT * FROM book_loans;

TASK 6  Return procedure

CREATE OR REPLACE PROCEDURE return_book(
    p_loan_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_book_id INTEGER;
    v_quantity INTEGER;
    v_status VARCHAR;
BEGIN
    SELECT book_id, quantity, loan_status
    INTO v_book_id, v_quantity, v_status
    FROM book_loans
    WHERE loan_id = p_loan_id;

    IF v_status = 'Borrowed' THEN

        UPDATE books
        SET available_copies = available_copies + v_quantity
        WHERE book_id = v_book_id;

        UPDATE book_loans
        SET loan_status = 'Returned'
        WHERE loan_id = p_loan_id;

        RAISE NOTICE 'Book returned successfully.';

    ELSE
        RAISE NOTICE 'Loan has already been returned.';
    END IF;
END;
$$;

First check your loan IDs:
SELECT * FROM book_loans;

Then, for example, if the loan ID is 1:
CALL return_book(1);

CALL return_book(1);

SELECT * FROM books;

SELECT * FROM book_loans;

TASK 7 Low- stock Cursor

DO $$
DECLARE
    book_cursor CURSOR FOR
        SELECT book_id, title, available_copies
        FROM books
        WHERE available_copies <= 2;

    v_book_id INTEGER;
    v_title VARCHAR;
    v_copies INTEGER;
BEGIN
    OPEN book_cursor;

    LOOP
        FETCH book_cursor
        INTO v_book_id, v_title, v_copies;

        EXIT WHEN NOT FOUND;

        RAISE NOTICE
            'Book ID: %, Title: %, Available copies: %',
            v_book_id, v_title, v_copies;
    END LOOP;

    CLOSE book_cursor;
END;
$$;

TASK 8 Handle invalid quantity

DO $$
DECLARE
    v_quantity INTEGER := 0;
BEGIN
    IF v_quantity <= 0 THEN
        RAISE EXCEPTION
            'Invalid quantity: borrowing quantity must be greater than zero.';
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error handled: %', SQLERRM;
END;
$$;

TASK 9 Final Results

SELECT * FROM books;

SELECT * FROM book_loans;


