TASK 1: Create Tables

CREATE TABLE medicines (
    medicine_id SERIAL PRIMARY KEY,
    medicine_name VARCHAR(100) NOT NULL,
    available_quantity INTEGER NOT NULL
);

CREATE TABLE dispensing_records (
    record_id SERIAL PRIMARY KEY,
    medicine_id INTEGER NOT NULL,
    student_number VARCHAR(50) NOT NULL,
    quantity INTEGER NOT NULL,
    status VARCHAR(30) NOT NULL
);

INSERT INTO medicines (medicine_name, available_quantity)
VALUES
('Paracetamol', 20),
('Amoxicillin', 10),
('Ibuprofen', 5);

TASK 2: Stock Check

DO $$
DECLARE
    v_quantity INTEGER;
BEGIN
    SELECT available_quantity
    INTO v_quantity
    FROM medicines
    WHERE medicine_id = 1;

    IF v_quantity = 0 THEN
        RAISE NOTICE 'Medicine is out of stock.';

    ELSIF v_quantity <= 5 THEN
        RAISE NOTICE 'Medicine is low on stock.';

    ELSE
        RAISE NOTICE 'Medicine is sufficiently stocked.';
    END IF;
END;
$$;

TASK 3: Stock Reviews

DO $$
DECLARE
    review_day INTEGER := 1;
BEGIN
    WHILE review_day <= 3 LOOP
        RAISE NOTICE 'Stock review day %', review_day;
        review_day := review_day + 1;
    END LOOP;
END;
$$;


DO $$
BEGIN
    FOR shelf_number IN 1..3 LOOP
        RAISE NOTICE 'Shelf inspection %', shelf_number;
    END LOOP;
END;
$$;

TASK 4: Dispensing Procedure

CREATE OR REPLACE PROCEDURE dispense_medicine(
    p_medicine_id INTEGER,
    p_student_number VARCHAR,
    p_quantity INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_stock INTEGER;
BEGIN
    SELECT available_quantity
    INTO v_stock
    FROM medicines
    WHERE medicine_id = p_medicine_id;

    IF v_stock >= p_quantity THEN

        UPDATE medicines
        SET available_quantity = available_quantity - p_quantity
        WHERE medicine_id = p_medicine_id;

        INSERT INTO dispensing_records
            (medicine_id, student_number, quantity, status)
        VALUES
            (p_medicine_id, p_student_number, p_quantity, 'Dispensed');

        RAISE NOTICE 'Medicine dispensed successfully.';

    ELSE
        RAISE NOTICE 'Insufficient stock.';
    END IF;
END;
$$;

TASK 5: Test Dispensing

CALL dispense_medicine(1, 'STU001', 3);

CALL dispense_medicine(2, 'STU002', 2);

CALL dispense_medicine(2, 'STU003', 20);

SELECT * FROM medicines;

SELECT * FROM dispensing_records;

TASK 6: Reverse Procedure

CREATE OR REPLACE PROCEDURE reverse_dispensing(
    p_record_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_medicine_id INTEGER;
    v_quantity INTEGER;
    v_status VARCHAR;
BEGIN
    SELECT medicine_id, quantity, status
    INTO v_medicine_id, v_quantity, v_status
    FROM dispensing_records
    WHERE record_id = p_record_id;

    IF v_status = 'Dispensed' THEN

        UPDATE medicines
        SET available_quantity = available_quantity + v_quantity
        WHERE medicine_id = v_medicine_id;

        UPDATE dispensing_records
        SET status = 'Reversed'
        WHERE record_id = p_record_id;

        RAISE NOTICE 'Dispensing reversed successfully.';

    ELSE
        RAISE NOTICE 'Record has already been reversed.';
    END IF;
END;
$$;

First check the record ID:

SELECT * FROM dispensing_records;

Then, if the record ID is 1:
CALL reverse_dispensing(1);

CALL reverse_dispensing(1);

SELECT * FROM medicines;

SELECT * FROM dispensing_records;


TASK 7: Low-Stock Cursor

DO $$
DECLARE
    medicine_cursor CURSOR FOR
        SELECT medicine_id, medicine_name, available_quantity
        FROM medicines
        WHERE available_quantity < 5;

    v_medicine_id INTEGER;
    v_medicine_name VARCHAR;
    v_quantity INTEGER;
BEGIN
    OPEN medicine_cursor;

    LOOP
        FETCH medicine_cursor
        INTO v_medicine_id, v_medicine_name, v_quantity;

        EXIT WHEN NOT FOUND;

        RAISE NOTICE
            'Medicine ID: %, Name: %, Available: %',
            v_medicine_id, v_medicine_name, v_quantity;
    END LOOP;

    CLOSE medicine_cursor;
END;
$$;

TASK 8: Handle Invalid Quantity

DO $$
DECLARE
    v_quantity INTEGER := -5;
BEGIN
    IF v_quantity < 0 THEN
        RAISE EXCEPTION
            'Invalid quantity: dispensing quantity cannot be negative.';
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error handled: %', SQLERRM;
END;
$$;

TASK 9: Final Results

SELECT * FROM medicines;

SELECT * FROM dispensing_records;
