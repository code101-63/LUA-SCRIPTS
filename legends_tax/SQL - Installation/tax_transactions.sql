CREATE TABLE tax_transactions (
    company_id VARCHAR(255) NOT NULL,
    tax_amount DECIMAL(10,2) NOT NULL,
    taxed_date DATE NOT NULL
);