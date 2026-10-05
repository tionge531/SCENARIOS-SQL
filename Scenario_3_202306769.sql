TASK 1: Create Tables

CREATE TABLE hostel_rooms (
    room_id SERIAL PRIMARY KEY,
    room_number VARCHAR(20) NOT NULL,
    available_bed_spaces INTEGER NOT NULL
);

CREATE TABLE allocations (
    allocation_id SERIAL PRIMARY KEY,
    student_number VARCHAR(50) NOT NULL,
    room_id INTEGER NOT NULL,
    status VARCHAR(30) NOT NULL
);

INSERT INTO hostel_rooms (room_number, available_bed_spaces)
VALUES
('A101', 4),
('A102', 2),
('A103', 1);


TASK 2: Room Availability

DO $$
DECLARE
    v_spaces INTEGER;
BEGIN
    SELECT available_bed_spaces
    INTO v_spaces
    FROM hostel_rooms
    WHERE room_id = 1;

    IF v_spaces = 0 THEN
        RAISE NOTICE 'Room is full.';

    ELSIF v_spaces = 1 THEN
        RAISE NOTICE 'Room has one space left.';

    ELSE
        RAISE NOTICE 'Room has several spaces.';
    END IF;
END;
$$;


TASK 3: Inspections and Checks

DO $$
DECLARE
    inspection_day INTEGER := 1;
BEGIN
    WHILE inspection_day <= 3 LOOP
        RAISE NOTICE 'Hostel inspection day %', inspection_day;
        inspection_day := inspection_day + 1;
    END LOOP;
END;
$$;


DO $$
BEGIN
    FOR room_check IN 1..3 LOOP
        RAISE NOTICE 'Room check %', room_check;
    END LOOP;
END;
$$;


TASK 4: Allocation Procedure

CREATE OR REPLACE PROCEDURE allocate_room(
    p_student_number VARCHAR,
    p_room_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_available INTEGER;
BEGIN
    SELECT available_bed_spaces
    INTO v_available
    FROM hostel_rooms
    WHERE room_id = p_room_id;

    IF v_available > 0 THEN

        UPDATE hostel_rooms
        SET available_bed_spaces = available_bed_spaces - 1
        WHERE room_id = p_room_id;

        INSERT INTO allocations
            (student_number, room_id, status)
        VALUES
            (p_student_number, p_room_id, 'Allocated');

        RAISE NOTICE 'Room allocated successfully.';

    ELSE
        RAISE NOTICE 'Room is full. Allocation not possible.';
    END IF;
END;
$$;


TASK 5: Test Allocations

CALL allocate_room('STU001', 1);

CALL allocate_room('STU002', 2);

UPDATE hostel_rooms
SET available_bed_spaces = 0
WHERE room_id = 3;

CALL allocate_room('STU003', 3);

SELECT * FROM hostel_rooms;

SELECT * FROM allocations;


TASK 6: Check-Out Procedure

CREATE OR REPLACE PROCEDURE check_out(
    p_allocation_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_room_id INTEGER;
    v_status VARCHAR;
BEGIN
    SELECT room_id, status
    INTO v_room_id, v_status
    FROM allocations
    WHERE allocation_id = p_allocation_id;

    IF v_status = 'Allocated' THEN

        UPDATE hostel_rooms
        SET available_bed_spaces = available_bed_spaces + 1
        WHERE room_id = v_room_id;

        UPDATE allocations
        SET status = 'Completed'
        WHERE allocation_id = p_allocation_id;

        RAISE NOTICE 'Student checked out successfully.';

    ELSE
        RAISE NOTICE 'Allocation has already been completed.';
    END IF;
END;
$$;

Check the allocation ID:
SELECT * FROM allocations;

Then, if the allocation ID is 1:
CALL check_out(1);

CALL check_out(1);

SELECT * FROM hostel_rooms;

SELECT * FROM allocations;


TASK 7: Full or Nearly Full Rooms

DO $$
DECLARE
    room_cursor CURSOR FOR
        SELECT room_id, room_number, available_bed_spaces
        FROM hostel_rooms
        WHERE available_bed_spaces <= 1;

    v_room_id INTEGER;
    v_room_number VARCHAR;
    v_available INTEGER;
BEGIN
    OPEN room_cursor;

    LOOP
        FETCH room_cursor
        INTO v_room_id, v_room_number, v_available;

        EXIT WHEN NOT FOUND;

        RAISE NOTICE
            'Room ID: %, Room: %, Available spaces: %',
            v_room_id, v_room_number, v_available;
    END LOOP;

    CLOSE room_cursor;
END;
$$;


TASK 8: Handle Invalid Input

DO $$
DECLARE
    v_room_id INTEGER := -1;
BEGIN
    IF v_room_id <= 0 THEN
        RAISE EXCEPTION
            'Invalid room ID: room ID must be greater than zero.';
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error handled: %', SQLERRM;
END;
$$;

TASK 9: Final Results

SELECT * FROM hostel_rooms;

SELECT * FROM allocations;