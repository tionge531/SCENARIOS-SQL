TASK 1: Create Tables

CREATE TABLE lab_sessions (
    session_id SERIAL PRIMARY KEY,
    session_name VARCHAR(100) NOT NULL,
    available_workstations INTEGER NOT NULL
);

CREATE TABLE reservations (
    reservation_id SERIAL PRIMARY KEY,
    session_id INTEGER NOT NULL,
    lecturer VARCHAR(100) NOT NULL,
    number_of_workstations INTEGER NOT NULL,
    status VARCHAR(30) NOT NULL
);

INSERT INTO lab_sessions (session_name, available_workstations)
VALUES
('Database Practical', 20),
('Networking Practical', 10),
('Programming Practical', 5);

TASK 2: Capacity Check

DO $$
DECLARE
    v_workstations INTEGER;
BEGIN
    SELECT available_workstations
    INTO v_workstations
    FROM lab_sessions
    WHERE session_id = 1;

    IF v_workstations = 0 THEN
        RAISE NOTICE 'Session is full.';

    ELSIF v_workstations <= 5 THEN
        RAISE NOTICE 'Session is nearly full.';

    ELSE
        RAISE NOTICE 'Session has enough workstations.';
    END IF;
END;
$$;

TASK 3: Reminders and Checks

DO $$
DECLARE
    reminder_number INTEGER := 1;
BEGIN
    WHILE reminder_number <= 3 LOOP
        RAISE NOTICE 'Session preparation reminder %', reminder_number;
        reminder_number := reminder_number + 1;
    END LOOP;
END;
$$;


DO $$
BEGIN
    FOR workstation_check IN 1..3 LOOP
        RAISE NOTICE 'Workstation check %', workstation_check;
    END LOOP;
END;
$$;

TASK 4: Reservation Procedure

CREATE OR REPLACE PROCEDURE reserve_workstations(
    p_session_id INTEGER,
    p_lecturer VARCHAR,
    p_number_of_workstations INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_available INTEGER;
BEGIN
    SELECT available_workstations
    INTO v_available
    FROM lab_sessions
    WHERE session_id = p_session_id;

    IF v_available >= p_number_of_workstations THEN

        UPDATE lab_sessions
        SET available_workstations =
            available_workstations - p_number_of_workstations
        WHERE session_id = p_session_id;

        INSERT INTO reservations
            (session_id, lecturer, number_of_workstations, status)
        VALUES
            (p_session_id, p_lecturer,
             p_number_of_workstations, 'Reserved');

        RAISE NOTICE 'Workstations reserved successfully.';

    ELSE
        RAISE NOTICE 'Insufficient workstations available.';
    END IF;
END;
$$;

TASK 5: Test Reservations

CALL reserve_workstations(1, 'Mr Banda', 5);

CALL reserve_workstations(2, 'Ms Phiri', 3);

CALL reserve_workstations(3, 'Mr Zulu', 10);

SELECT * FROM lab_sessions;

SELECT * FROM reservations;

ASK 6: Cancel Procedure

CREATE OR REPLACE PROCEDURE cancel_reservation(
    p_reservation_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_session_id INTEGER;
    v_number_of_workstations INTEGER;
    v_status VARCHAR;
BEGIN
    SELECT session_id, number_of_workstations, status
    INTO v_session_id, v_number_of_workstations, v_status
    FROM reservations
    WHERE reservation_id = p_reservation_id;

    IF v_status = 'Reserved' THEN

        UPDATE lab_sessions
        SET available_workstations =
            available_workstations + v_number_of_workstations
        WHERE session_id = v_session_id;

        UPDATE reservations
        SET status = 'Cancelled'
        WHERE reservation_id = p_reservation_id;

        RAISE NOTICE 'Reservation cancelled successfully.';

    ELSE
        RAISE NOTICE 'Reservation has already been cancelled.';
    END IF;
END;
$$;

Check the reservation IDs:
SELECT * FROM reservations;

Then, if the reservation ID is 1:
CALL cancel_reservation(1);

CALL cancel_reservation(1);

SELECT * FROM lab_sessions;

SELECT * FROM reservations;

TASK 7: Low Availability Cursor

DO $$
DECLARE
    session_cursor CURSOR FOR
        SELECT session_id, session_name, available_workstations
        FROM lab_sessions
        WHERE available_workstations <= 5;

    v_session_id INTEGER;
    v_session_name VARCHAR;
    v_available INTEGER;
BEGIN
    OPEN session_cursor;

    LOOP
        FETCH session_cursor
        INTO v_session_id, v_session_name, v_available;

        EXIT WHEN NOT FOUND;

        RAISE NOTICE
            'Session ID: %, Session: %, Available: %',
            v_session_id, v_session_name, v_available;
    END LOOP;

    CLOSE session_cursor;
END;
$$;

TASK 8: Handle Invalid Quantity

DO $$
DECLARE
    v_quantity INTEGER := 0;
BEGIN
    IF v_quantity <= 0 THEN
        RAISE EXCEPTION
            'Invalid quantity: number of workstations must be greater than zero.';
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error handled: %', SQLERRM;
END;
$$;

TASK 9: Final Results

SELECT * FROM lab_sessions;

SELECT * FROM reservations;