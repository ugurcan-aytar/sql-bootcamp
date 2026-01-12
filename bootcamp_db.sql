-- ============================================================================
-- SQL BOOTCAMP - UNIFIED DATABASE
-- A comprehensive PostgreSQL database for all Day 1-5 exercises
-- ============================================================================
-- Version: 1.0
-- PostgreSQL: 14+
-- Compatible with: Neon, Supabase, standard PostgreSQL
-- ============================================================================

-- Drop existing objects if they exist (order matters for foreign keys)
DROP SCHEMA IF EXISTS sales CASCADE;
DROP SCHEMA IF EXISTS inventory CASCADE;
DROP SCHEMA IF EXISTS hr CASCADE;
DROP SCHEMA IF EXISTS analytics CASCADE;
DROP SCHEMA IF EXISTS audit CASCADE;
DROP SCHEMA IF EXISTS library CASCADE;

-- Drop tables in reverse dependency order
DROP TABLE IF EXISTS account_transactions CASCADE;
DROP TABLE IF EXISTS accounts CASCADE;
DROP TABLE IF EXISTS audit_log CASCADE;
DROP TABLE IF EXISTS stock_movements CASCADE;
DROP TABLE IF EXISTS order_lines CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS suppliers CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS countries CASCADE;

-- ============================================================================
-- PART 1: CORE TABLES (Public Schema)
-- ============================================================================

-- Countries (reference data)
CREATE TABLE countries (
    id SERIAL PRIMARY KEY,
    code CHAR(2) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    region VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Customers
CREATE TABLE customers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(50),
    city VARCHAR(100),
    address TEXT,
    country_id INTEGER REFERENCES countries(id),
    customer_type VARCHAR(20) DEFAULT 'individual' CHECK (customer_type IN ('individual', 'business', 'vip')),
    credit_limit DECIMAL(12,2) DEFAULT 1000.00,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'suspended')),
    notes TEXT,
    deleted_at TIMESTAMP,  -- For soft delete exercises
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Categories (hierarchical)
CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    parent_id INTEGER REFERENCES categories(id),
    description TEXT,
    slug VARCHAR(100),
    display_order INTEGER DEFAULT 0,
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Suppliers
CREATE TABLE suppliers (
    id SERIAL PRIMARY KEY,
    company_name VARCHAR(255) NOT NULL,
    contact_name VARCHAR(100),
    email VARCHAR(255),
    phone VARCHAR(50),
    address TEXT,
    city VARCHAR(100),
    country_id INTEGER REFERENCES countries(id),
    payment_terms INTEGER DEFAULT 30,
    rating DECIMAL(3,2) CHECK (rating >= 0 AND rating <= 5),
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Products
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    sku VARCHAR(50) UNIQUE,
    category_id INTEGER REFERENCES categories(id),
    supplier_id INTEGER REFERENCES suppliers(id),
    description TEXT,
    price DECIMAL(10,2) NOT NULL DEFAULT 0,
    cost DECIMAL(10,2),
    stock_quantity INTEGER DEFAULT 0,
    reorder_level INTEGER DEFAULT 10,
    max_stock INTEGER DEFAULT 1000,
    weight DECIMAL(8,3),
    dimensions VARCHAR(50),
    active BOOLEAN DEFAULT true,
    type VARCHAR(20) DEFAULT 'product' CHECK (type IN ('product', 'service', 'consumable', 'digital')),
    attributes JSONB,  -- For JSON exercises
    tags TEXT[],       -- For array exercises
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Orders (header)
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    order_number VARCHAR(20) NOT NULL UNIQUE,
    customer_id INTEGER NOT NULL REFERENCES customers(id),
    order_date DATE NOT NULL DEFAULT CURRENT_DATE,
    required_date DATE,
    shipped_date DATE,
    shipping_address TEXT,
    shipping_city VARCHAR(100),
    shipping_country_id INTEGER REFERENCES countries(id),
    status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled', 'returned')),
    payment_method VARCHAR(30),
    payment_status VARCHAR(20) DEFAULT 'pending' CHECK (payment_status IN ('pending', 'paid', 'refunded', 'failed')),
    subtotal DECIMAL(12,2) DEFAULT 0,
    tax_rate DECIMAL(5,2) DEFAULT 18.00,
    tax_amount DECIMAL(12,2) DEFAULT 0,
    shipping_cost DECIMAL(10,2) DEFAULT 0,
    discount_amount DECIMAL(10,2) DEFAULT 0,
    total_amount DECIMAL(12,2) DEFAULT 0,
    notes TEXT,
    metadata JSONB,  -- For JSON exercises
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Order Lines (detail)
CREATE TABLE order_lines (
    id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id INTEGER NOT NULL REFERENCES products(id),
    quantity INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),
    unit_price DECIMAL(10,2) NOT NULL,
    discount_percent DECIMAL(5,2) DEFAULT 0 CHECK (discount_percent >= 0 AND discount_percent <= 100),
    line_total DECIMAL(12,2) GENERATED ALWAYS AS (quantity * unit_price * (1 - discount_percent/100)) STORED,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Stock Movements
CREATE TABLE stock_movements (
    id SERIAL PRIMARY KEY,
    product_id INTEGER NOT NULL REFERENCES products(id),
    movement_type VARCHAR(20) NOT NULL CHECK (movement_type IN ('purchase', 'sale', 'return', 'adjustment', 'transfer', 'damage')),
    quantity INTEGER NOT NULL,
    unit_cost DECIMAL(10,2),
    reference_type VARCHAR(50),
    reference_id INTEGER,
    warehouse_from VARCHAR(50),
    warehouse_to VARCHAR(50),
    movement_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    performed_by VARCHAR(100),
    notes TEXT
);

-- Employees (for hierarchy/recursive CTE)
CREATE TABLE employees (
    id SERIAL PRIMARY KEY,
    employee_code VARCHAR(20) UNIQUE,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE,
    phone VARCHAR(50),
    department VARCHAR(100),
    job_title VARCHAR(100),
    manager_id INTEGER REFERENCES employees(id),
    hire_date DATE NOT NULL,
    birth_date DATE,
    salary DECIMAL(12,2),
    commission_rate DECIMAL(5,2),
    address TEXT,
    city VARCHAR(100),
    country_id INTEGER REFERENCES countries(id),
    active BOOLEAN DEFAULT true,
    termination_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Accounts (for transaction exercises)
CREATE TABLE accounts (
    id VARCHAR(20) PRIMARY KEY,
    customer_id INTEGER REFERENCES customers(id),
    holder_name VARCHAR(255) NOT NULL,
    account_type VARCHAR(30) DEFAULT 'checking' CHECK (account_type IN ('checking', 'savings', 'credit', 'investment')),
    balance DECIMAL(15,2) NOT NULL DEFAULT 0,
    currency CHAR(3) DEFAULT 'USD',
    credit_limit DECIMAL(15,2),
    interest_rate DECIMAL(5,4),
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'frozen', 'closed')),
    opened_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_transaction_at TIMESTAMP
);

-- Account Transactions
CREATE TABLE account_transactions (
    id SERIAL PRIMARY KEY,
    transaction_code VARCHAR(30) UNIQUE,
    from_account_id VARCHAR(20) REFERENCES accounts(id),
    to_account_id VARCHAR(20) REFERENCES accounts(id),
    transaction_type VARCHAR(30) NOT NULL CHECK (transaction_type IN ('deposit', 'withdrawal', 'transfer', 'payment', 'fee', 'interest', 'refund')),
    amount DECIMAL(15,2) NOT NULL CHECK (amount > 0),
    fee DECIMAL(10,2) DEFAULT 0,
    description TEXT,
    status VARCHAR(20) DEFAULT 'completed' CHECK (status IN ('pending', 'completed', 'failed', 'reversed')),
    transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processed_by VARCHAR(100)
);

-- Audit Log (for trigger exercises)
CREATE TABLE audit_log (
    id SERIAL PRIMARY KEY,
    table_name VARCHAR(100) NOT NULL,
    record_id INTEGER,
    action VARCHAR(10) NOT NULL CHECK (action IN ('INSERT', 'UPDATE', 'DELETE')),
    old_values JSONB,
    new_values JSONB,
    changed_fields TEXT[],
    changed_by VARCHAR(100) DEFAULT CURRENT_USER,
    ip_address INET,
    user_agent TEXT,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- PART 2: LIBRARY SYSTEM (For Day 3 Normalization Examples)
-- ============================================================================

CREATE SCHEMA IF NOT EXISTS library;

-- Authors
CREATE TABLE library.authors (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    birth_year INTEGER,
    death_year INTEGER,
    nationality VARCHAR(100),
    biography TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Books
CREATE TABLE library.books (
    id SERIAL PRIMARY KEY,
    isbn VARCHAR(20) UNIQUE,
    title VARCHAR(500) NOT NULL,
    publication_year INTEGER,
    publisher VARCHAR(255),
    edition INTEGER DEFAULT 1,
    pages INTEGER,
    language VARCHAR(50) DEFAULT 'English',
    genre VARCHAR(100),
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Book Authors (many-to-many)
CREATE TABLE library.book_authors (
    book_id INTEGER REFERENCES library.books(id) ON DELETE CASCADE,
    author_id INTEGER REFERENCES library.authors(id) ON DELETE CASCADE,
    author_role VARCHAR(50) DEFAULT 'author',
    PRIMARY KEY (book_id, author_id)
);

-- Book Copies
CREATE TABLE library.book_copies (
    id SERIAL PRIMARY KEY,
    book_id INTEGER NOT NULL REFERENCES library.books(id),
    copy_number INTEGER NOT NULL,
    location VARCHAR(100),
    condition VARCHAR(20) DEFAULT 'good' CHECK (condition IN ('new', 'good', 'fair', 'poor', 'damaged')),
    acquisition_date DATE,
    status VARCHAR(20) DEFAULT 'available' CHECK (status IN ('available', 'borrowed', 'reserved', 'maintenance', 'lost')),
    UNIQUE(book_id, copy_number)
);

-- Members
CREATE TABLE library.members (
    id SERIAL PRIMARY KEY,
    member_code VARCHAR(20) UNIQUE NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(50),
    address TEXT,
    membership_type VARCHAR(30) DEFAULT 'standard' CHECK (membership_type IN ('student', 'standard', 'premium', 'senior')),
    membership_start DATE NOT NULL DEFAULT CURRENT_DATE,
    membership_end DATE,
    max_books INTEGER DEFAULT 5,
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Loans
CREATE TABLE library.loans (
    id SERIAL PRIMARY KEY,
    copy_id INTEGER NOT NULL REFERENCES library.book_copies(id),
    member_id INTEGER NOT NULL REFERENCES library.members(id),
    loan_date DATE NOT NULL DEFAULT CURRENT_DATE,
    due_date DATE NOT NULL,
    return_date DATE,
    renewals INTEGER DEFAULT 0,
    fine_amount DECIMAL(8,2) DEFAULT 0,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'returned', 'overdue', 'lost')),
    notes TEXT
);

-- Reservations
CREATE TABLE library.reservations (
    id SERIAL PRIMARY KEY,
    book_id INTEGER NOT NULL REFERENCES library.books(id),
    member_id INTEGER NOT NULL REFERENCES library.members(id),
    reservation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expiry_date DATE,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'ready', 'fulfilled', 'cancelled', 'expired')),
    notification_sent BOOLEAN DEFAULT false
);

-- ============================================================================
-- PART 3: HR SCHEMA (For Advanced Exercises)
-- ============================================================================

CREATE SCHEMA IF NOT EXISTS hr;

-- Departments
CREATE TABLE hr.departments (
    id SERIAL PRIMARY KEY,
    code VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    parent_id INTEGER REFERENCES hr.departments(id),
    manager_id INTEGER,
    budget DECIMAL(15,2),
    location VARCHAR(100),
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Job Positions
CREATE TABLE hr.positions (
    id SERIAL PRIMARY KEY,
    code VARCHAR(20) UNIQUE NOT NULL,
    title VARCHAR(100) NOT NULL,
    department_id INTEGER REFERENCES hr.departments(id),
    min_salary DECIMAL(12,2),
    max_salary DECIMAL(12,2),
    description TEXT,
    requirements TEXT[],
    active BOOLEAN DEFAULT true
);

-- Employee Records (more detailed than public.employees)
CREATE TABLE hr.employee_records (
    id SERIAL PRIMARY KEY,
    employee_id INTEGER REFERENCES employees(id),
    position_id INTEGER REFERENCES hr.positions(id),
    department_id INTEGER REFERENCES hr.departments(id),
    employment_type VARCHAR(30) CHECK (employment_type IN ('full-time', 'part-time', 'contract', 'intern')),
    start_date DATE NOT NULL,
    end_date DATE,
    salary DECIMAL(12,2),
    bonus_target DECIMAL(10,2),
    vacation_days INTEGER DEFAULT 20,
    sick_days INTEGER DEFAULT 10,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Salary History
CREATE TABLE hr.salary_history (
    id SERIAL PRIMARY KEY,
    employee_id INTEGER NOT NULL REFERENCES employees(id),
    effective_date DATE NOT NULL,
    salary DECIMAL(12,2) NOT NULL,
    change_reason VARCHAR(100),
    approved_by INTEGER REFERENCES employees(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Performance Reviews
CREATE TABLE hr.performance_reviews (
    id SERIAL PRIMARY KEY,
    employee_id INTEGER NOT NULL REFERENCES employees(id),
    reviewer_id INTEGER NOT NULL REFERENCES employees(id),
    review_period_start DATE NOT NULL,
    review_period_end DATE NOT NULL,
    rating DECIMAL(3,2) CHECK (rating >= 1 AND rating <= 5),
    goals_met INTEGER,
    goals_total INTEGER,
    strengths TEXT,
    improvements TEXT,
    comments TEXT,
    status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft', 'submitted', 'acknowledged', 'disputed')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- PART 4: SALES SCHEMA (For Multi-Schema Exercises)
-- ============================================================================

CREATE SCHEMA IF NOT EXISTS sales;

-- Sales Regions
CREATE TABLE sales.regions (
    id SERIAL PRIMARY KEY,
    code VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    target_revenue DECIMAL(15,2),
    manager_id INTEGER REFERENCES employees(id)
);

-- Sales Representatives
CREATE TABLE sales.representatives (
    id SERIAL PRIMARY KEY,
    employee_id INTEGER NOT NULL REFERENCES employees(id),
    region_id INTEGER REFERENCES sales.regions(id),
    territory VARCHAR(255),
    quota DECIMAL(15,2),
    commission_rate DECIMAL(5,2) DEFAULT 5.00,
    active BOOLEAN DEFAULT true
);

-- Sales Targets
CREATE TABLE sales.targets (
    id SERIAL PRIMARY KEY,
    rep_id INTEGER REFERENCES sales.representatives(id),
    region_id INTEGER REFERENCES sales.regions(id),
    year INTEGER NOT NULL,
    month INTEGER CHECK (month >= 1 AND month <= 12),
    target_amount DECIMAL(15,2) NOT NULL,
    achieved_amount DECIMAL(15,2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Quotes
CREATE TABLE sales.quotes (
    id SERIAL PRIMARY KEY,
    quote_number VARCHAR(30) UNIQUE NOT NULL,
    customer_id INTEGER NOT NULL REFERENCES customers(id),
    rep_id INTEGER REFERENCES sales.representatives(id),
    quote_date DATE NOT NULL DEFAULT CURRENT_DATE,
    valid_until DATE,
    status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft', 'sent', 'accepted', 'rejected', 'expired', 'converted')),
    total_amount DECIMAL(15,2),
    discount_percent DECIMAL(5,2) DEFAULT 0,
    notes TEXT,
    converted_order_id INTEGER REFERENCES orders(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- PART 5: INVENTORY SCHEMA
-- ============================================================================

CREATE SCHEMA IF NOT EXISTS inventory;

-- Warehouses
CREATE TABLE inventory.warehouses (
    id SERIAL PRIMARY KEY,
    code VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    address TEXT,
    city VARCHAR(100),
    country_id INTEGER REFERENCES countries(id),
    capacity INTEGER,
    manager_id INTEGER REFERENCES employees(id),
    active BOOLEAN DEFAULT true
);

-- Warehouse Stock
CREATE TABLE inventory.warehouse_stock (
    id SERIAL PRIMARY KEY,
    warehouse_id INTEGER NOT NULL REFERENCES inventory.warehouses(id),
    product_id INTEGER NOT NULL REFERENCES products(id),
    quantity INTEGER NOT NULL DEFAULT 0,
    reserved_quantity INTEGER DEFAULT 0,
    reorder_point INTEGER,
    last_counted DATE,
    last_restocked DATE,
    UNIQUE(warehouse_id, product_id)
);

-- Purchase Orders
CREATE TABLE inventory.purchase_orders (
    id SERIAL PRIMARY KEY,
    po_number VARCHAR(30) UNIQUE NOT NULL,
    supplier_id INTEGER NOT NULL REFERENCES suppliers(id),
    warehouse_id INTEGER REFERENCES inventory.warehouses(id),
    order_date DATE NOT NULL DEFAULT CURRENT_DATE,
    expected_date DATE,
    received_date DATE,
    status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft', 'sent', 'confirmed', 'partial', 'received', 'cancelled')),
    total_amount DECIMAL(15,2),
    notes TEXT,
    created_by INTEGER REFERENCES employees(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Purchase Order Lines
CREATE TABLE inventory.purchase_order_lines (
    id SERIAL PRIMARY KEY,
    po_id INTEGER NOT NULL REFERENCES inventory.purchase_orders(id) ON DELETE CASCADE,
    product_id INTEGER NOT NULL REFERENCES products(id),
    quantity_ordered INTEGER NOT NULL,
    quantity_received INTEGER DEFAULT 0,
    unit_cost DECIMAL(10,2) NOT NULL,
    line_total DECIMAL(12,2) GENERATED ALWAYS AS (quantity_ordered * unit_cost) STORED
);

-- ============================================================================
-- PART 6: ANALYTICS SCHEMA (For Window Function and CTE Exercises)
-- ============================================================================

CREATE SCHEMA IF NOT EXISTS analytics;

-- Daily Sales Summary (for time-series analysis)
CREATE TABLE analytics.daily_sales (
    id SERIAL PRIMARY KEY,
    sale_date DATE NOT NULL UNIQUE,
    order_count INTEGER DEFAULT 0,
    item_count INTEGER DEFAULT 0,
    unique_customers INTEGER DEFAULT 0,
    gross_revenue DECIMAL(15,2) DEFAULT 0,
    discounts DECIMAL(12,2) DEFAULT 0,
    tax_collected DECIMAL(12,2) DEFAULT 0,
    net_revenue DECIMAL(15,2) DEFAULT 0,
    avg_order_value DECIMAL(10,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Customer Segments
CREATE TABLE analytics.customer_segments (
    id SERIAL PRIMARY KEY,
    segment_name VARCHAR(100) NOT NULL,
    description TEXT,
    min_orders INTEGER,
    max_orders INTEGER,
    min_spend DECIMAL(12,2),
    max_spend DECIMAL(12,2),
    color_code VARCHAR(7)
);

-- Product Performance
CREATE TABLE analytics.product_metrics (
    id SERIAL PRIMARY KEY,
    product_id INTEGER NOT NULL REFERENCES products(id),
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    units_sold INTEGER DEFAULT 0,
    revenue DECIMAL(15,2) DEFAULT 0,
    return_count INTEGER DEFAULT 0,
    avg_rating DECIMAL(3,2),
    review_count INTEGER DEFAULT 0,
    UNIQUE(product_id, period_start, period_end)
);

-- ============================================================================
-- PART 7: AUDIT SCHEMA
-- ============================================================================

CREATE SCHEMA IF NOT EXISTS audit;

-- Detailed Change Log
CREATE TABLE audit.change_log (
    id BIGSERIAL PRIMARY KEY,
    schema_name VARCHAR(100) NOT NULL,
    table_name VARCHAR(100) NOT NULL,
    operation VARCHAR(10) NOT NULL,
    row_id TEXT,
    old_data JSONB,
    new_data JSONB,
    query TEXT,
    user_name VARCHAR(100) DEFAULT CURRENT_USER,
    application_name VARCHAR(100),
    client_addr INET,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Login History
CREATE TABLE audit.login_history (
    id SERIAL PRIMARY KEY,
    user_name VARCHAR(100) NOT NULL,
    login_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    logout_time TIMESTAMP,
    ip_address INET,
    user_agent TEXT,
    success BOOLEAN DEFAULT true,
    failure_reason TEXT
);

-- Data Access Log
CREATE TABLE audit.data_access_log (
    id BIGSERIAL PRIMARY KEY,
    user_name VARCHAR(100) NOT NULL,
    table_accessed VARCHAR(100) NOT NULL,
    access_type VARCHAR(20) NOT NULL,
    record_count INTEGER,
    query_text TEXT,
    execution_time_ms INTEGER,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- PART 8: REFERENCE DATA
-- ============================================================================

-- Countries (30 records)
INSERT INTO countries (code, name, region) VALUES
('TR', 'Turkey', 'Europe'),
('DE', 'Germany', 'Europe'),
('US', 'United States', 'North America'),
('GB', 'United Kingdom', 'Europe'),
('FR', 'France', 'Europe'),
('ES', 'Spain', 'Europe'),
('JP', 'Japan', 'Asia'),
('CA', 'Canada', 'North America'),
('IT', 'Italy', 'Europe'),
('NL', 'Netherlands', 'Europe'),
('BE', 'Belgium', 'Europe'),
('AT', 'Austria', 'Europe'),
('CH', 'Switzerland', 'Europe'),
('SE', 'Sweden', 'Europe'),
('NO', 'Norway', 'Europe'),
('DK', 'Denmark', 'Europe'),
('FI', 'Finland', 'Europe'),
('PL', 'Poland', 'Europe'),
('CZ', 'Czech Republic', 'Europe'),
('PT', 'Portugal', 'Europe'),
('AU', 'Australia', 'Oceania'),
('NZ', 'New Zealand', 'Oceania'),
('SG', 'Singapore', 'Asia'),
('KR', 'South Korea', 'Asia'),
('CN', 'China', 'Asia'),
('IN', 'India', 'Asia'),
('BR', 'Brazil', 'South America'),
('MX', 'Mexico', 'North America'),
('AE', 'United Arab Emirates', 'Middle East'),
('SA', 'Saudi Arabia', 'Middle East');

-- Categories (with hierarchy)
INSERT INTO categories (id, name, parent_id, description, slug, display_order) VALUES
(1, 'Electronics', NULL, 'Electronic devices and gadgets', 'electronics', 1),
(2, 'Computers', 1, 'Desktop and laptop computers', 'computers', 1),
(3, 'Smartphones', 1, 'Mobile phones and accessories', 'smartphones', 2),
(4, 'Audio', 1, 'Headphones, speakers, and audio equipment', 'audio', 3),
(5, 'Clothing', NULL, 'Apparel and fashion', 'clothing', 2),
(6, 'Men''s Clothing', 5, 'Clothing for men', 'mens-clothing', 1),
(7, 'Women''s Clothing', 5, 'Clothing for women', 'womens-clothing', 2),
(8, 'Kids'' Clothing', 5, 'Clothing for children', 'kids-clothing', 3),
(9, 'Books', NULL, 'Books and publications', 'books', 3),
(10, 'Fiction', 9, 'Fiction books', 'fiction', 1),
(11, 'Non-Fiction', 9, 'Non-fiction books', 'non-fiction', 2),
(12, 'Technical', 9, 'Technical and programming books', 'technical', 3),
(13, 'Home & Garden', NULL, 'Home improvement and garden supplies', 'home-garden', 4),
(14, 'Furniture', 13, 'Home and office furniture', 'furniture', 1),
(15, 'Kitchen', 13, 'Kitchen appliances and tools', 'kitchen', 2),
(16, 'Garden Tools', 13, 'Outdoor and garden equipment', 'garden-tools', 3),
(17, 'Sports', NULL, 'Sports equipment and apparel', 'sports', 5),
(18, 'Fitness', 17, 'Gym and fitness equipment', 'fitness', 1),
(19, 'Outdoor Sports', 17, 'Outdoor and adventure sports', 'outdoor-sports', 2),
(20, 'Office Supplies', NULL, 'Office equipment and supplies', 'office-supplies', 6),
(21, 'Stationery', 20, 'Writing and paper supplies', 'stationery', 1),
(22, 'Office Electronics', 20, 'Printers, scanners, and accessories', 'office-electronics', 2);

SELECT setval('categories_id_seq', 22);

-- Suppliers (15 records)
INSERT INTO suppliers (company_name, contact_name, email, phone, city, country_id, payment_terms, rating) VALUES
('TechWorld Supplies', 'John Smith', 'john@techworld.com', '+1-555-0101', 'San Francisco', 3, 30, 4.5),
('European Electronics GmbH', 'Hans Mueller', 'hans@euroelec.de', '+49-30-12345', 'Berlin', 2, 45, 4.2),
('Asia Tech Trading', 'Wei Chen', 'wei@asiatech.cn', '+86-21-88888', 'Shanghai', 25, 60, 4.0),
('Global Fashion Ltd', 'Marie Dubois', 'marie@globalfashion.fr', '+33-1-44444', 'Paris', 5, 30, 4.8),
('BookSource International', 'David Wilson', 'david@booksource.com', '+1-555-0202', 'New York', 3, 30, 4.3),
('Home Essentials Co', 'Sarah Johnson', 'sarah@homeessentials.com', '+1-555-0303', 'Chicago', 3, 45, 4.1),
('SportGear Pro', 'Michael Brown', 'michael@sportgear.com', '+1-555-0404', 'Los Angeles', 3, 30, 4.6),
('Office Solutions Ltd', 'Emma Taylor', 'emma@officesolutions.co.uk', '+44-20-7777', 'London', 4, 30, 4.4),
('Nordic Supplies AB', 'Erik Johansson', 'erik@nordicsupplies.se', '+46-8-12345', 'Stockholm', 14, 45, 4.7),
('Mediterranean Trade SpA', 'Marco Rossi', 'marco@medtrade.it', '+39-02-33333', 'Milan', 9, 60, 4.0),
('Aussie Goods Pty', 'James Cook', 'james@aussiegoods.com.au', '+61-2-9999', 'Sydney', 21, 45, 4.2),
('Turkish Textiles A.S.', 'Ahmet Yilmaz', 'ahmet@turkishtextiles.com.tr', '+90-212-5555', 'Istanbul', 1, 30, 4.5),
('Japan Quality Inc', 'Yuki Tanaka', 'yuki@japanquality.jp', '+81-3-6666', 'Tokyo', 7, 45, 4.9),
('Canadian Warehouse Ltd', 'Robert Martin', 'robert@canwarehouse.ca', '+1-416-7777', 'Toronto', 8, 30, 4.3),
('Dutch Distributors BV', 'Jan de Vries', 'jan@dutchdist.nl', '+31-20-8888', 'Amsterdam', 10, 30, 4.4);

-- Customers (50 records with variety)
INSERT INTO customers (name, email, phone, city, address, country_id, customer_type, credit_limit, status, created_at) VALUES
('Acme Corporation', 'orders@acme.com', '+1-555-1001', 'New York', '123 Broadway Ave', 3, 'business', 50000.00, 'active', '2021-03-15'),
('John Doe', 'john.doe@email.com', '+1-555-1002', 'Los Angeles', '456 Sunset Blvd', 3, 'individual', 2000.00, 'active', '2021-05-20'),
('Jane Smith', 'jane.smith@email.com', NULL, 'Chicago', '789 Michigan Ave', 3, 'individual', 1500.00, 'active', '2021-06-10'),
('TechStart GmbH', 'info@techstart.de', '+49-30-2001', 'Berlin', 'Alexanderplatz 10', 2, 'business', 30000.00, 'active', '2021-07-01'),
('Marie Curie', NULL, '+33-1-3001', 'Paris', '15 Rue de Science', 5, 'individual', 3000.00, 'active', '2021-08-15'),
('Global Trade Ltd', 'sales@globaltrade.co.uk', '+44-20-4001', 'London', '1 Canary Wharf', 4, 'vip', 100000.00, 'active', '2021-02-28'),
('Carlos Garcia', 'carlos.garcia@email.es', '+34-91-5001', 'Madrid', 'Gran Via 42', 6, 'individual', 2500.00, 'active', '2021-09-20'),
('Amsterdam Digital BV', 'contact@amsterdigital.nl', '+31-20-6001', 'Amsterdam', 'Keizersgracht 100', 10, 'business', 25000.00, 'active', '2021-10-05'),
('Sofia Andersson', 'sofia.andersson@email.se', NULL, 'Stockholm', 'Kungsgatan 55', 14, 'individual', 2000.00, 'active', '2021-11-12'),
('Tokyo Electronics Co', 'orders@tokyoelec.jp', '+81-3-7001', 'Tokyo', 'Shibuya 3-5-1', 7, 'vip', 75000.00, 'active', '2021-04-18'),
('Robert Brown', 'robert.brown@email.com', '+1-416-8001', 'Toronto', '100 King St West', 8, 'individual', 1800.00, 'active', '2022-01-15'),
('Anna Kowalski', 'anna.kowalski@email.pl', '+48-22-9001', 'Warsaw', 'Marszalkowska 20', 18, 'individual', 1200.00, 'active', '2022-02-20'),
('Swiss Precision AG', 'info@swissprecision.ch', '+41-44-1001', 'Zurich', 'Bahnhofstrasse 50', 13, 'business', 40000.00, 'active', '2022-03-10'),
('Liam O''Connor', 'liam.oconnor@email.ie', '+353-1-2001', 'Dublin', NULL, 4, 'individual', 1500.00, 'inactive', '2022-04-05'),
('Isabella Romano', 'isabella.romano@email.it', '+39-06-3001', 'Rome', 'Via del Corso 50', 9, 'individual', 2200.00, 'active', '2022-05-15'),
('Nordic Solutions Oy', 'sales@nordicsol.fi', '+358-9-4001', 'Helsinki', 'Mannerheimintie 10', 17, 'business', 20000.00, 'active', '2022-06-01'),
('Chen Wei', 'chen.wei@email.cn', '+86-21-5001', 'Shanghai', 'Nanjing Road 888', 25, 'individual', 3500.00, 'active', '2022-07-20'),
('Australian Imports Pty', 'orders@ausimports.com.au', '+61-2-6001', 'Sydney', '1 George Street', 21, 'business', 35000.00, 'active', '2022-08-10'),
('Mohammed Al-Hassan', 'mohammed@email.ae', '+971-4-7001', 'Dubai', 'Sheikh Zayed Road', 29, 'vip', 80000.00, 'active', '2022-09-05'),
('Maria Santos', 'maria.santos@email.br', '+55-11-8001', 'Sao Paulo', 'Av. Paulista 1000', 27, 'individual', 2000.00, 'active', '2022-10-15'),
('Peter Muller', 'peter.muller@email.at', '+43-1-9001', 'Vienna', 'Stephansplatz 5', 12, 'individual', 1800.00, 'active', '2022-11-20'),
('Copenhagen Tech ApS', 'info@cphtech.dk', '+45-33-1001', 'Copenhagen', 'Stroget 15', 16, 'business', 22000.00, 'active', '2022-12-01'),
('Emma Wilson', 'emma.wilson@email.com', '+1-555-1101', 'Boston', '50 Beacon Street', 3, 'individual', 2500.00, 'active', '2023-01-10'),
('Berlin Startups UG', 'hello@berlinstartups.de', '+49-30-2101', 'Berlin', 'Torstrasse 100', 2, 'business', 15000.00, 'active', '2023-02-15'),
('Yuki Yamamoto', 'yuki.yamamoto@email.jp', '+81-3-7101', 'Osaka', 'Dotonbori 2-1', 7, 'individual', 3000.00, 'active', '2023-03-20'),
('Brussels Enterprises', 'contact@brusselsent.be', '+32-2-1001', 'Brussels', 'Grand Place 1', 11, 'business', 28000.00, 'active', '2023-04-05'),
('Lucas Martin', 'lucas.martin@email.fr', '+33-4-2001', 'Lyon', 'Place Bellecour 20', 5, 'individual', 1700.00, 'active', '2023-05-12'),
('Singapore Trading Pte', 'orders@sgtrading.sg', '+65-6-3001', 'Singapore', 'Orchard Road 100', 23, 'business', 45000.00, 'active', '2023-06-18'),
('Helena Novak', 'helena.novak@email.cz', '+420-2-4001', 'Prague', 'Wenceslas Square 30', 19, 'individual', 1400.00, 'active', '2023-07-25'),
('Seoul Digital Co', 'sales@seouldigital.kr', '+82-2-5001', 'Seoul', 'Gangnam District', 24, 'business', 55000.00, 'active', '2023-08-01'),
('David Thompson', 'david.thompson@email.nz', '+64-9-6001', 'Auckland', 'Queen Street 200', 22, 'individual', 1600.00, 'active', '2023-09-10'),
('Lisboa Comercio Lda', 'geral@lisboacom.pt', '+351-21-7001', 'Lisbon', 'Av. da Liberdade 50', 20, 'business', 18000.00, 'active', '2023-10-15'),
('Ahmed Khan', 'ahmed.khan@email.in', '+91-22-8001', 'Mumbai', 'Marine Drive 100', 26, 'individual', 2800.00, 'active', '2023-11-20'),
('Mexico City Imports SA', 'compras@mxcimports.mx', '+52-55-9001', 'Mexico City', 'Reforma 500', 28, 'business', 32000.00, 'active', '2023-12-01'),
('Oslo Commerce AS', 'post@oslocommerce.no', '+47-22-1001', 'Oslo', 'Karl Johans gate 10', 15, 'business', 24000.00, 'active', '2024-01-05'),
('Emily Chen', 'emily.chen@email.com', '+1-650-1201', 'San Francisco', '500 Market Street', 3, 'individual', 3200.00, 'active', '2024-01-15'),
('Munich Industries GmbH', 'einkauf@munichindustries.de', '+49-89-2201', 'Munich', 'Marienplatz 8', 2, 'vip', 90000.00, 'active', '2024-02-01'),
('Sarah O''Brien', 'sarah.obrien@email.com', '+353-1-2101', 'Dublin', 'Grafton Street 40', 4, 'individual', 1900.00, 'active', '2024-02-10'),
('Vancouver Tech Inc', 'info@vantech.ca', '+1-604-1301', 'Vancouver', '1000 Burrard St', 8, 'business', 38000.00, 'active', '2024-02-20'),
('Inactive Customer LLC', 'old@inactive.com', '+1-555-0000', 'Detroit', '1 Old Street', 3, 'business', 5000.00, 'inactive', '2020-01-01'),
('Suspended User', NULL, NULL, 'Unknown', NULL, NULL, 'individual', 0.00, 'suspended', '2019-06-15'),
('No Orders Customer', 'noorders@email.com', '+1-555-9999', 'Miami', '100 Beach Ave', 3, 'individual', 1000.00, 'active', '2024-03-01'),
('Another No Orders', 'another@noorders.com', '+44-20-9999', 'Manchester', '50 Canal St', 4, 'individual', 1500.00, 'active', '2024-03-05'),
('Orphan Record Inc', 'orphan@example.com', '+1-555-8888', 'Seattle', '200 Pine St', 3, 'business', 10000.00, 'active', '2024-03-10'),
('Riyadh Trading Est', 'orders@riyadhtrading.sa', '+966-11-1001', 'Riyadh', 'King Fahd Road', 30, 'business', 60000.00, 'active', '2024-03-15'),
('Test NULL Fields', NULL, NULL, NULL, NULL, NULL, 'individual', 500.00, 'active', '2024-03-20'),
('Julia Fernandez', 'julia.fernandez@email.es', '+34-93-6001', 'Barcelona', 'La Rambla 100', 6, 'individual', 2100.00, 'active', '2024-03-25'),
('Hamburg Handel GmbH', 'vertrieb@hamburghandel.de', '+49-40-2301', 'Hamburg', 'Jungfernstieg 20', 2, 'business', 27000.00, 'active', '2024-04-01'),
('Marco Bianchi', 'marco.bianchi@email.it', '+39-02-4001', 'Milan', 'Via Montenapoleone 10', 9, 'vip', 45000.00, 'active', '2024-04-05'),
('Final Test Corp', 'test@finaltest.com', '+1-555-7777', 'Austin', '1 Congress Ave', 3, 'business', 20000.00, 'active', '2024-04-10');

-- ============================================================================
-- PART 9: PRODUCTS WITH JSON ATTRIBUTES
-- ============================================================================

INSERT INTO products (name, sku, category_id, supplier_id, description, price, cost, stock_quantity, reorder_level, weight, type, attributes, tags) VALUES
-- Electronics - Computers
('ProBook Laptop 15"', 'COMP-001', 2, 1, 'Professional laptop with 15.6" display, Intel i7, 16GB RAM', 1299.99, 850.00, 45, 10, 2.100, 'product',
 '{"brand": "TechPro", "processor": "Intel i7-12700H", "ram": "16GB DDR5", "storage": "512GB NVMe SSD", "display": "15.6 inch FHD", "battery": "72Wh", "warranty_months": 24}',
 ARRAY['laptop', 'business', 'portable']),
('UltraBook Air 13"', 'COMP-002', 2, 1, 'Ultra-thin laptop, perfect for travel', 999.99, 650.00, 30, 8, 1.200, 'product',
 '{"brand": "TechPro", "processor": "Intel i5-1240P", "ram": "8GB DDR5", "storage": "256GB NVMe SSD", "display": "13.3 inch FHD", "battery": "54Wh", "color": "Silver"}',
 ARRAY['laptop', 'ultrabook', 'travel']),
('Gaming Desktop Beast', 'COMP-003', 2, 1, 'High-performance gaming desktop', 1899.99, 1200.00, 15, 5, 12.500, 'product',
 '{"brand": "GameMax", "processor": "AMD Ryzen 9 5900X", "ram": "32GB DDR4", "storage": "1TB NVMe + 2TB HDD", "gpu": "RTX 4070 Ti", "psu": "750W Gold"}',
 ARRAY['desktop', 'gaming', 'high-performance']),
('Office Desktop Standard', 'COMP-004', 2, 2, 'Reliable office desktop computer', 599.99, 380.00, 60, 15, 8.000, 'product',
 '{"brand": "EuroTech", "processor": "Intel i3-12100", "ram": "8GB DDR4", "storage": "256GB SSD", "os": "Windows 11 Pro"}',
 ARRAY['desktop', 'office', 'budget']),

-- Electronics - Smartphones
('SmartPhone Pro Max', 'PHONE-001', 3, 3, 'Flagship smartphone with advanced camera', 1199.99, 750.00, 80, 20, 0.228, 'product',
 '{"brand": "TechMobile", "screen": "6.7 inch OLED", "storage": "256GB", "ram": "12GB", "camera": "108MP + 12MP + 10MP", "battery": "5000mAh", "5g": true, "colors": ["Black", "Silver", "Blue"]}',
 ARRAY['smartphone', 'flagship', '5g']),
('SmartPhone Lite', 'PHONE-002', 3, 3, 'Affordable smartphone for everyday use', 299.99, 180.00, 150, 30, 0.185, 'product',
 '{"brand": "TechMobile", "screen": "6.1 inch LCD", "storage": "64GB", "ram": "4GB", "camera": "48MP + 2MP", "battery": "4000mAh", "5g": false}',
 ARRAY['smartphone', 'budget', 'everyday']),
('SmartPhone Plus', 'PHONE-003', 3, 13, 'Mid-range smartphone with great value', 549.99, 320.00, 100, 25, 0.195, 'product',
 '{"brand": "JapanTech", "screen": "6.4 inch AMOLED", "storage": "128GB", "ram": "8GB", "camera": "64MP + 8MP + 2MP", "battery": "4500mAh", "5g": true}',
 ARRAY['smartphone', 'midrange', '5g']),

-- Electronics - Audio
('Wireless Headphones Pro', 'AUDIO-001', 4, 13, 'Premium noise-canceling wireless headphones', 349.99, 180.00, 70, 15, 0.250, 'product',
 '{"brand": "SoundMaster", "type": "Over-ear", "noise_canceling": true, "battery_hours": 30, "bluetooth": "5.2", "drivers": "40mm", "frequency": "20Hz-20kHz"}',
 ARRAY['headphones', 'wireless', 'noise-canceling']),
('Wireless Earbuds Sport', 'AUDIO-002', 4, 3, 'Waterproof earbuds for sports', 129.99, 65.00, 200, 40, 0.055, 'product',
 '{"brand": "FitSound", "type": "In-ear", "waterproof": "IPX7", "battery_hours": 8, "case_battery_hours": 32, "bluetooth": "5.0"}',
 ARRAY['earbuds', 'wireless', 'sports', 'waterproof']),
('Bluetooth Speaker Portable', 'AUDIO-003', 4, 1, 'Compact portable Bluetooth speaker', 79.99, 40.00, 120, 25, 0.540, 'product',
 '{"brand": "SoundMax", "power": "20W", "battery_hours": 12, "waterproof": "IPX5", "bluetooth": "5.0", "aux_input": true}',
 ARRAY['speaker', 'bluetooth', 'portable']),
('Studio Monitor Speakers', 'AUDIO-004', 4, 2, 'Professional studio monitor pair', 599.99, 350.00, 25, 5, 8.200, 'product',
 '{"brand": "ProAudio", "type": "Active", "power": "100W per speaker", "frequency": "45Hz-22kHz", "inputs": ["XLR", "TRS", "RCA"]}',
 ARRAY['speakers', 'studio', 'professional']),

-- Clothing - Men
('Classic Cotton T-Shirt', 'MEN-001', 6, 4, 'Premium cotton t-shirt for everyday wear', 29.99, 12.00, 500, 100, 0.200, 'product',
 '{"brand": "FashionBasics", "material": "100% Cotton", "sizes": ["S", "M", "L", "XL", "XXL"], "colors": ["White", "Black", "Navy", "Gray"], "care": "Machine wash cold"}',
 ARRAY['tshirt', 'cotton', 'casual']),
('Business Dress Shirt', 'MEN-002', 6, 4, 'Formal dress shirt for business occasions', 69.99, 28.00, 200, 40, 0.280, 'product',
 '{"brand": "ExecutiveWear", "material": "Cotton blend", "sizes": ["S", "M", "L", "XL"], "collar": "Spread", "fit": "Slim", "colors": ["White", "Light Blue", "Pink"]}',
 ARRAY['shirt', 'formal', 'business']),
('Denim Jeans Regular Fit', 'MEN-003', 6, 12, 'Classic denim jeans with regular fit', 89.99, 35.00, 300, 60, 0.650, 'product',
 '{"brand": "DenimCraft", "material": "98% Cotton, 2% Elastane", "waist_sizes": [28, 30, 32, 34, 36, 38], "length_sizes": [30, 32, 34], "wash": "Medium blue"}',
 ARRAY['jeans', 'denim', 'casual']),
('Wool Blend Suit Jacket', 'MEN-004', 6, 4, 'Premium wool blend suit jacket', 299.99, 120.00, 50, 10, 1.100, 'product',
 '{"brand": "SuitMaster", "material": "70% Wool, 30% Polyester", "sizes": ["46", "48", "50", "52", "54"], "fit": "Modern", "lining": "Full", "colors": ["Navy", "Charcoal", "Black"]}',
 ARRAY['suit', 'jacket', 'formal', 'wool']),

-- Clothing - Women
('Silk Blend Blouse', 'WOM-001', 7, 4, 'Elegant silk blend blouse', 79.99, 32.00, 150, 30, 0.180, 'product',
 '{"brand": "EleganceWear", "material": "70% Silk, 30% Polyester", "sizes": ["XS", "S", "M", "L", "XL"], "colors": ["Ivory", "Black", "Blush"], "care": "Dry clean only"}',
 ARRAY['blouse', 'silk', 'elegant']),
('Stretch Yoga Pants', 'WOM-002', 7, 7, 'High-waist yoga pants with pockets', 49.99, 18.00, 400, 80, 0.220, 'product',
 '{"brand": "ActiveFit", "material": "88% Nylon, 12% Spandex", "sizes": ["XS", "S", "M", "L", "XL"], "features": ["High waist", "Side pockets", "Moisture wicking"]}',
 ARRAY['yoga', 'leggings', 'activewear']),
('Cashmere Cardigan', 'WOM-003', 7, 9, 'Luxurious cashmere cardigan', 199.99, 85.00, 60, 12, 0.350, 'product',
 '{"brand": "LuxuryKnits", "material": "100% Cashmere", "sizes": ["S", "M", "L"], "colors": ["Cream", "Camel", "Gray", "Navy"]}',
 ARRAY['cardigan', 'cashmere', 'luxury']),

-- Books - Technical
('PostgreSQL Mastery Guide', 'BOOK-001', 12, 5, 'Complete guide to PostgreSQL database administration', 59.99, 25.00, 100, 20, 0.950, 'product',
 '{"author": "James Database", "isbn": "978-1234567890", "pages": 650, "publisher": "TechBooks Inc", "edition": 3, "year": 2024, "format": "Paperback"}',
 ARRAY['postgresql', 'database', 'technical']),
('Python for Data Science', 'BOOK-002', 12, 5, 'Learn Python for data analysis and machine learning', 49.99, 20.00, 150, 30, 0.800, 'product',
 '{"author": "Sarah Coder", "isbn": "978-0987654321", "pages": 520, "publisher": "DataPress", "edition": 2, "year": 2023, "format": "Paperback"}',
 ARRAY['python', 'data-science', 'programming']),
('Web Development Bootcamp', 'BOOK-003', 12, 5, 'Full-stack web development from scratch', 44.99, 18.00, 200, 40, 0.720, 'product',
 '{"author": "Mike Developer", "isbn": "978-5678901234", "pages": 480, "publisher": "WebDev Press", "edition": 1, "year": 2024, "topics": ["HTML", "CSS", "JavaScript", "React", "Node.js"]}',
 ARRAY['web-development', 'javascript', 'fullstack']),

-- Books - Fiction
('The Mystery of Echo Lake', 'BOOK-004', 10, 5, 'A thrilling mystery novel', 14.99, 6.00, 300, 60, 0.350, 'product',
 '{"author": "Elena Writer", "isbn": "978-1111222333", "pages": 380, "publisher": "Fiction House", "year": 2023, "genre": "Mystery", "format": "Paperback"}',
 ARRAY['fiction', 'mystery', 'thriller']),
('Journey Through Time', 'BOOK-005', 10, 5, 'Epic science fiction adventure', 16.99, 7.00, 250, 50, 0.420, 'product',
 '{"author": "Robert SciFi", "isbn": "978-4444555666", "pages": 450, "publisher": "Galaxy Books", "year": 2024, "genre": "Science Fiction", "series": "Time Travelers #1"}',
 ARRAY['fiction', 'scifi', 'adventure']),

-- Home & Garden - Furniture
('Ergonomic Office Chair', 'FURN-001', 14, 6, 'Adjustable ergonomic office chair with lumbar support', 399.99, 180.00, 40, 10, 18.500, 'product',
 '{"brand": "ComfortWork", "material": "Mesh back, Foam seat", "features": ["Adjustable height", "Lumbar support", "Armrests", "Tilt lock"], "max_weight": "120kg", "warranty_years": 5}',
 ARRAY['chair', 'office', 'ergonomic']),
('Standing Desk Electric', 'FURN-002', 14, 6, 'Electric height-adjustable standing desk', 599.99, 280.00, 25, 5, 35.000, 'product',
 '{"brand": "DeskPro", "dimensions": "140x70cm", "height_range": "72-120cm", "motor": "Dual motor", "memory_settings": 4, "max_weight": "80kg"}',
 ARRAY['desk', 'standing', 'electric']),
('Bookshelf Oak 5-Tier', 'FURN-003', 14, 6, 'Solid oak bookshelf with 5 shelves', 249.99, 100.00, 35, 8, 25.000, 'product',
 '{"brand": "WoodCraft", "material": "Solid Oak", "dimensions": "180x80x30cm", "shelves": 5, "max_weight_per_shelf": "20kg", "assembly": "Required"}',
 ARRAY['bookshelf', 'oak', 'storage']),

-- Home & Garden - Kitchen
('Smart Coffee Maker', 'KITCH-001', 15, 6, 'WiFi-enabled programmable coffee maker', 149.99, 65.00, 80, 15, 4.200, 'product',
 '{"brand": "BrewSmart", "capacity": "12 cups", "features": ["WiFi control", "Programmable", "Auto shutoff", "Keep warm"], "filter": "Permanent", "voltage": "220V"}',
 ARRAY['coffee', 'smart', 'kitchen']),
('Chef Knife Set Professional', 'KITCH-002', 15, 13, 'Professional 8-piece knife set with block', 199.99, 85.00, 50, 10, 3.500, 'product',
 '{"brand": "SharpEdge", "pieces": 8, "material": "German Steel", "includes": ["Chef knife", "Bread knife", "Santoku", "Utility knife", "Paring knife", "Sharpener", "Scissors", "Block"]}',
 ARRAY['knives', 'professional', 'kitchen']),
('Air Fryer XL', 'KITCH-003', 15, 3, 'Large capacity digital air fryer', 129.99, 55.00, 100, 20, 5.800, 'product',
 '{"brand": "HealthyCook", "capacity": "5.5L", "power": "1700W", "programs": 8, "temp_range": "80-200C", "features": ["Digital display", "Dishwasher safe basket"]}',
 ARRAY['airfryer', 'healthy', 'cooking']),

-- Sports - Fitness
('Adjustable Dumbbell Set', 'FIT-001', 18, 7, 'Adjustable dumbbells 5-52.5 lbs per hand', 399.99, 200.00, 30, 8, 24.000, 'product',
 '{"brand": "PowerLift", "weight_range": "2.5-24kg", "adjustment": "Quick dial", "material": "Steel with rubber coating", "includes": ["2 dumbbells", "Storage tray"]}',
 ARRAY['dumbbells', 'adjustable', 'strength']),
('Yoga Mat Premium', 'FIT-002', 18, 7, 'Extra thick non-slip yoga mat', 49.99, 18.00, 200, 40, 1.200, 'product',
 '{"brand": "ZenFit", "thickness": "6mm", "material": "TPE eco-friendly", "dimensions": "183x61cm", "features": ["Non-slip", "Carrying strap", "Alignment lines"]}',
 ARRAY['yoga', 'mat', 'fitness']),
('Resistance Bands Set', 'FIT-003', 18, 7, 'Set of 5 resistance bands with handles', 34.99, 12.00, 300, 60, 0.800, 'product',
 '{"brand": "FlexFit", "bands": 5, "resistance_levels": ["Extra Light", "Light", "Medium", "Heavy", "Extra Heavy"], "includes": ["Door anchor", "Ankle straps", "Handles", "Carry bag"]}',
 ARRAY['resistance', 'bands', 'workout']),
('Treadmill Home Pro', 'FIT-004', 18, 7, 'Foldable treadmill with incline', 899.99, 450.00, 15, 3, 65.000, 'product',
 '{"brand": "RunFit", "speed_range": "1-16 km/h", "incline_levels": 15, "belt_size": "140x50cm", "motor": "2.5HP", "features": ["Bluetooth", "Heart rate monitor", "Foldable"]}',
 ARRAY['treadmill', 'cardio', 'home-gym']),

-- Sports - Outdoor
('Mountain Bike Pro', 'SPORT-001', 19, 7, 'Full suspension mountain bike', 1299.99, 700.00, 12, 3, 14.500, 'product',
 '{"brand": "TrailRider", "frame": "Aluminum", "suspension": "Full", "gears": 21, "wheel_size": "29 inch", "brakes": "Hydraulic disc", "sizes": ["S", "M", "L", "XL"]}',
 ARRAY['bike', 'mountain', 'outdoor']),
('Camping Tent 4-Person', 'SPORT-002', 19, 11, 'Waterproof family camping tent', 199.99, 85.00, 45, 10, 5.200, 'product',
 '{"brand": "OutdoorLife", "capacity": "4 person", "waterproof": "3000mm", "setup": "Easy pop-up", "dimensions": "240x210x130cm", "weight": "5.2kg", "seasons": 3}',
 ARRAY['tent', 'camping', 'family']),
('Hiking Backpack 50L', 'SPORT-003', 19, 9, 'Large hiking backpack with rain cover', 149.99, 60.00, 70, 15, 1.800, 'product',
 '{"brand": "TrailMaster", "capacity": "50L", "features": ["Rain cover", "Hydration compatible", "Hip belt", "Multiple pockets"], "material": "Ripstop Nylon"}',
 ARRAY['backpack', 'hiking', 'outdoor']),

-- Office Supplies
('Wireless Mouse Ergonomic', 'OFF-001', 22, 8, 'Ergonomic wireless mouse with silent click', 39.99, 15.00, 250, 50, 0.120, 'product',
 '{"brand": "ClickPro", "connectivity": ["Bluetooth", "2.4GHz USB"], "dpi": "800-2400", "buttons": 6, "battery": "AA x 1", "battery_life": "12 months"}',
 ARRAY['mouse', 'wireless', 'ergonomic']),
('Mechanical Keyboard RGB', 'OFF-002', 22, 1, 'RGB mechanical keyboard with hot-swappable switches', 129.99, 55.00, 80, 15, 0.950, 'product',
 '{"brand": "KeyMaster", "switches": "Cherry MX Brown", "layout": "Full size", "backlight": "RGB per-key", "connectivity": "USB-C", "features": ["Hot-swappable", "PBT keycaps"]}',
 ARRAY['keyboard', 'mechanical', 'rgb']),
('Monitor Stand Adjustable', 'OFF-003', 22, 6, 'Adjustable dual monitor stand', 79.99, 32.00, 60, 12, 3.500, 'product',
 '{"brand": "DeskOrganize", "monitors": 2, "screen_size": "13-27 inch", "max_weight": "8kg per arm", "features": ["Height adjust", "Tilt", "Swivel", "Cable management"]}',
 ARRAY['monitor', 'stand', 'ergonomic']),
('Notebook Premium A5', 'OFF-004', 21, 8, 'Premium hardcover notebook 200 pages', 19.99, 6.00, 400, 80, 0.350, 'product',
 '{"brand": "WriteWell", "size": "A5", "pages": 200, "paper": "100gsm ivory", "ruling": "Dotted", "binding": "Sewn", "cover": "Hardcover with ribbon"}',
 ARRAY['notebook', 'premium', 'writing']),
('Pen Set Executive', 'OFF-005', 21, 8, 'Executive pen set with ballpoint and rollerball', 49.99, 18.00, 100, 20, 0.150, 'product',
 '{"brand": "WriteLux", "includes": ["Ballpoint pen", "Rollerball pen", "Gift box"], "material": "Brass with lacquer finish", "refillable": true}',
 ARRAY['pen', 'executive', 'gift']),

-- Low/Zero Stock Items (for inventory exercises)
('Vintage Collector Watch', 'SPEC-001', 1, 10, 'Limited edition collector watch', 2499.99, 1500.00, 0, 1, 0.150, 'product',
 '{"brand": "TimeMaster", "limited": true, "edition_number": 150, "year": 2020}',
 ARRAY['watch', 'collector', 'limited']),
('Discontinued Gadget', 'SPEC-002', 1, 1, 'This product has been discontinued', 199.99, 80.00, 3, 0, 0.500, 'product',
 '{"discontinued": true, "reason": "Model replaced", "replacement_sku": "PHONE-003"}',
 ARRAY['discontinued']),

-- Service type products
('Extended Warranty 2 Years', 'SVC-001', 1, NULL, '2-year extended warranty for electronics', 99.99, 0.00, NULL, NULL, NULL, 'service',
 '{"coverage_years": 2, "covers": ["Defects", "Malfunctions"], "excludes": ["Physical damage", "Water damage"]}',
 ARRAY['warranty', 'service']),
('Premium Support Plan', 'SVC-002', 1, NULL, '24/7 premium technical support', 149.99, 0.00, NULL, NULL, NULL, 'service',
 '{"duration": "1 year", "response_time": "1 hour", "channels": ["Phone", "Email", "Chat"]}',
 ARRAY['support', 'service', 'premium']),

-- Digital products
('Software License Pro', 'DIG-001', 2, 1, 'Professional software license - 1 year', 299.99, 50.00, NULL, NULL, NULL, 'digital',
 '{"type": "Subscription", "duration": "1 year", "users": 1, "features": ["All modules", "Priority support", "Cloud storage"]}',
 ARRAY['software', 'license', 'subscription']),
('E-Book Bundle Tech', 'DIG-002', 12, 5, 'Bundle of 10 technical e-books', 79.99, 20.00, NULL, NULL, NULL, 'digital',
 '{"format": "PDF/EPUB", "books": 10, "topics": ["Python", "JavaScript", "SQL", "Cloud", "DevOps"]}',
 ARRAY['ebook', 'bundle', 'technical']);

-- ============================================================================
-- PART 10: EMPLOYEES (Hierarchical for Recursive CTE)
-- ============================================================================

INSERT INTO employees (id, employee_code, first_name, last_name, email, phone, department, job_title, manager_id, hire_date, salary, commission_rate, city, country_id, active) VALUES
-- Level 1: CEO
(1, 'EMP001', 'Elizabeth', 'Warren', 'elizabeth.warren@company.com', '+1-555-0001', 'Executive', 'Chief Executive Officer', NULL, '2015-01-15', 350000.00, NULL, 'New York', 3, true),

-- Level 2: C-Suite (report to CEO)
(2, 'EMP002', 'Michael', 'Chen', 'michael.chen@company.com', '+1-555-0002', 'Technology', 'Chief Technology Officer', 1, '2016-03-01', 280000.00, NULL, 'San Francisco', 3, true),
(3, 'EMP003', 'Sarah', 'Johnson', 'sarah.johnson@company.com', '+1-555-0003', 'Finance', 'Chief Financial Officer', 1, '2016-06-15', 270000.00, NULL, 'New York', 3, true),
(4, 'EMP004', 'David', 'Williams', 'david.williams@company.com', '+1-555-0004', 'Sales', 'Chief Sales Officer', 1, '2017-01-10', 260000.00, 2.00, 'Chicago', 3, true),
(5, 'EMP005', 'Emma', 'Brown', 'emma.brown@company.com', '+1-555-0005', 'Human Resources', 'Chief HR Officer', 1, '2017-04-20', 220000.00, NULL, 'New York', 3, true),

-- Level 3: Directors (report to C-Suite)
(6, 'EMP006', 'James', 'Miller', 'james.miller@company.com', '+1-555-0006', 'Technology', 'Director of Engineering', 2, '2017-08-01', 180000.00, NULL, 'San Francisco', 3, true),
(7, 'EMP007', 'Lisa', 'Davis', 'lisa.davis@company.com', '+1-555-0007', 'Technology', 'Director of Product', 2, '2018-01-15', 175000.00, NULL, 'San Francisco', 3, true),
(8, 'EMP008', 'Robert', 'Garcia', 'robert.garcia@company.com', '+1-555-0008', 'Finance', 'Director of Accounting', 3, '2018-03-01', 160000.00, NULL, 'New York', 3, true),
(9, 'EMP009', 'Jennifer', 'Martinez', 'jennifer.martinez@company.com', '+1-555-0009', 'Sales', 'Director of Sales - Americas', 4, '2018-05-20', 170000.00, 3.00, 'Chicago', 3, true),
(10, 'EMP010', 'Thomas', 'Anderson', 'thomas.anderson@company.com', '+49-30-0010', 'Sales', 'Director of Sales - EMEA', 4, '2018-07-01', 165000.00, 3.00, 'Berlin', 2, true),
(11, 'EMP011', 'Maria', 'Rodriguez', 'maria.rodriguez@company.com', '+1-555-0011', 'Human Resources', 'Director of Talent', 5, '2018-09-15', 145000.00, NULL, 'New York', 3, true),

-- Level 4: Managers (report to Directors)
(12, 'EMP012', 'Christopher', 'Lee', 'christopher.lee@company.com', '+1-555-0012', 'Technology', 'Engineering Manager - Backend', 6, '2019-01-10', 140000.00, NULL, 'San Francisco', 3, true),
(13, 'EMP013', 'Amanda', 'Wilson', 'amanda.wilson@company.com', '+1-555-0013', 'Technology', 'Engineering Manager - Frontend', 6, '2019-02-15', 140000.00, NULL, 'San Francisco', 3, true),
(14, 'EMP014', 'Daniel', 'Taylor', 'daniel.taylor@company.com', '+1-555-0014', 'Technology', 'Product Manager', 7, '2019-04-01', 130000.00, NULL, 'San Francisco', 3, true),
(15, 'EMP015', 'Michelle', 'Thomas', 'michelle.thomas@company.com', '+1-555-0015', 'Finance', 'Accounting Manager', 8, '2019-06-01', 110000.00, NULL, 'New York', 3, true),
(16, 'EMP016', 'Kevin', 'Jackson', 'kevin.jackson@company.com', '+1-555-0016', 'Sales', 'Regional Sales Manager - East', 9, '2019-08-15', 120000.00, 5.00, 'Boston', 3, true),
(17, 'EMP017', 'Patricia', 'White', 'patricia.white@company.com', '+1-555-0017', 'Sales', 'Regional Sales Manager - West', 9, '2019-09-01', 120000.00, 5.00, 'Los Angeles', 3, true),
(18, 'EMP018', 'Hans', 'Mueller', 'hans.mueller@company.com', '+49-30-0018', 'Sales', 'Regional Sales Manager - Germany', 10, '2019-10-15', 115000.00, 5.00, 'Munich', 2, true),
(19, 'EMP019', 'Sophie', 'Dubois', 'sophie.dubois@company.com', '+33-1-0019', 'Sales', 'Regional Sales Manager - France', 10, '2019-11-01', 112000.00, 5.00, 'Paris', 5, true),
(20, 'EMP020', 'Rachel', 'Green', 'rachel.green@company.com', '+1-555-0020', 'Human Resources', 'HR Manager', 11, '2020-01-15', 95000.00, NULL, 'New York', 3, true),

-- Level 5: Senior Staff (report to Managers)
(21, 'EMP021', 'Brian', 'Adams', 'brian.adams@company.com', '+1-555-0021', 'Technology', 'Senior Software Engineer', 12, '2020-03-01', 115000.00, NULL, 'San Francisco', 3, true),
(22, 'EMP022', 'Laura', 'Clark', 'laura.clark@company.com', '+1-555-0022', 'Technology', 'Senior Software Engineer', 12, '2020-04-15', 118000.00, NULL, 'San Francisco', 3, true),
(23, 'EMP023', 'Steven', 'Hall', 'steven.hall@company.com', '+1-555-0023', 'Technology', 'Senior Frontend Developer', 13, '2020-06-01', 112000.00, NULL, 'San Francisco', 3, true),
(24, 'EMP024', 'Nancy', 'King', 'nancy.king@company.com', '+1-555-0024', 'Technology', 'Senior UX Designer', 13, '2020-07-15', 105000.00, NULL, 'San Francisco', 3, true),
(25, 'EMP025', 'Mark', 'Wright', 'mark.wright@company.com', '+1-555-0025', 'Finance', 'Senior Accountant', 15, '2020-09-01', 85000.00, NULL, 'New York', 3, true),
(26, 'EMP026', 'Susan', 'Lopez', 'susan.lopez@company.com', '+1-555-0026', 'Sales', 'Senior Sales Rep', 16, '2020-10-15', 75000.00, 8.00, 'Boston', 3, true),
(27, 'EMP027', 'Paul', 'Hill', 'paul.hill@company.com', '+1-555-0027', 'Sales', 'Senior Sales Rep', 17, '2020-11-01', 78000.00, 8.00, 'Los Angeles', 3, true),

-- Level 6: Junior Staff (report to Senior Staff or Managers)
(28, 'EMP028', 'Ashley', 'Scott', 'ashley.scott@company.com', '+1-555-0028', 'Technology', 'Software Engineer', 21, '2021-01-15', 90000.00, NULL, 'San Francisco', 3, true),
(29, 'EMP029', 'Jason', 'Young', 'jason.young@company.com', '+1-555-0029', 'Technology', 'Software Engineer', 21, '2021-02-01', 88000.00, NULL, 'San Francisco', 3, true),
(30, 'EMP030', 'Nicole', 'Allen', 'nicole.allen@company.com', '+1-555-0030', 'Technology', 'Software Engineer', 22, '2021-03-15', 92000.00, NULL, 'San Francisco', 3, true),
(31, 'EMP031', 'Eric', 'Torres', 'eric.torres@company.com', '+1-555-0031', 'Technology', 'Frontend Developer', 23, '2021-05-01', 85000.00, NULL, 'San Francisco', 3, true),
(32, 'EMP032', 'Megan', 'Nelson', 'megan.nelson@company.com', '+1-555-0032', 'Technology', 'UX Designer', 24, '2021-06-15', 78000.00, NULL, 'San Francisco', 3, true),
(33, 'EMP033', 'Ryan', 'Carter', 'ryan.carter@company.com', '+1-555-0033', 'Finance', 'Accountant', 25, '2021-08-01', 65000.00, NULL, 'New York', 3, true),
(34, 'EMP034', 'Katie', 'Mitchell', 'katie.mitchell@company.com', '+1-555-0034', 'Sales', 'Sales Representative', 26, '2021-09-15', 55000.00, 10.00, 'Boston', 3, true),
(35, 'EMP035', 'Justin', 'Perez', 'justin.perez@company.com', '+1-555-0035', 'Sales', 'Sales Representative', 27, '2021-10-01', 55000.00, 10.00, 'Los Angeles', 3, true),
(36, 'EMP036', 'Anna', 'Schmidt', 'anna.schmidt@company.com', '+49-30-0036', 'Sales', 'Sales Representative', 18, '2021-11-15', 52000.00, 10.00, 'Berlin', 2, true),
(37, 'EMP037', 'Pierre', 'Bernard', 'pierre.bernard@company.com', '+33-1-0037', 'Sales', 'Sales Representative', 19, '2022-01-10', 50000.00, 10.00, 'Paris', 5, true),
(38, 'EMP038', 'Emily', 'Hughes', 'emily.hughes@company.com', '+1-555-0038', 'Human Resources', 'HR Specialist', 20, '2022-02-15', 58000.00, NULL, 'New York', 3, true),

-- Interns (report to various)
(39, 'EMP039', 'Alex', 'Cooper', 'alex.cooper@company.com', '+1-555-0039', 'Technology', 'Software Engineer Intern', 28, '2024-06-01', 45000.00, NULL, 'San Francisco', 3, true),
(40, 'EMP040', 'Jordan', 'Reed', 'jordan.reed@company.com', '+1-555-0040', 'Technology', 'UX Design Intern', 32, '2024-06-01', 42000.00, NULL, 'San Francisco', 3, true),

-- Inactive/Terminated employees
(41, 'EMP041', 'Former', 'Employee', 'former.employee@company.com', '+1-555-0041', 'Sales', 'Sales Representative', 16, '2019-01-01', 52000.00, 10.00, 'Boston', 3, false),
(42, 'EMP042', 'Left', 'Company', 'left.company@company.com', '+1-555-0042', 'Technology', 'Software Engineer', 12, '2020-06-01', 85000.00, NULL, 'San Francisco', 3, false);

SELECT setval('employees_id_seq', 42);

-- Update hr.departments manager_id now that employees exist
UPDATE hr.departments SET manager_id = 6 WHERE code = 'ENG';
UPDATE hr.departments SET manager_id = 9 WHERE code = 'SALES';
UPDATE hr.departments SET manager_id = 3 WHERE code = 'FIN';

-- ============================================================================
-- PART 11: ACCOUNTS (For Transaction Exercises)
-- ============================================================================

INSERT INTO accounts (id, customer_id, holder_name, account_type, balance, currency, credit_limit, interest_rate, status) VALUES
('ACC-001', 1, 'Acme Corporation', 'checking', 125000.00, 'USD', 50000.00, NULL, 'active'),
('ACC-002', 1, 'Acme Corporation Savings', 'savings', 250000.00, 'USD', NULL, 0.0225, 'active'),
('ACC-003', 2, 'John Doe', 'checking', 5420.50, 'USD', 2000.00, NULL, 'active'),
('ACC-004', 3, 'Jane Smith', 'checking', 3150.75, 'USD', 1500.00, NULL, 'active'),
('ACC-005', 4, 'TechStart GmbH', 'checking', 85000.00, 'EUR', 30000.00, NULL, 'active'),
('ACC-006', 6, 'Global Trade Ltd', 'checking', 450000.00, 'GBP', 100000.00, NULL, 'active'),
('ACC-007', 6, 'Global Trade Investment', 'investment', 1250000.00, 'GBP', NULL, 0.0450, 'active'),
('ACC-008', 10, 'Tokyo Electronics Co', 'checking', 15000000.00, 'JPY', 5000000.00, NULL, 'active'),
('ACC-009', 19, 'Mohammed Al-Hassan', 'checking', 280000.00, 'AED', 100000.00, NULL, 'active'),
('ACC-010', 37, 'Munich Industries GmbH', 'checking', 175000.00, 'EUR', 90000.00, NULL, 'active'),
('ACC-011', 40, 'Inactive Account', 'checking', 0.00, 'USD', 0.00, NULL, 'frozen'),
('ACC-012', 23, 'Emma Wilson', 'savings', 12500.00, 'USD', NULL, 0.0175, 'active'),
('ACC-013', 28, 'Singapore Trading', 'checking', 95000.00, 'SGD', 50000.00, NULL, 'active'),
('ACC-014', 36, 'Emily Chen', 'checking', 8750.25, 'USD', 5000.00, NULL, 'active'),
('ACC-015', 49, 'Marco Bianchi', 'checking', 35000.00, 'EUR', 45000.00, NULL, 'active');

-- Sample account transactions
INSERT INTO account_transactions (transaction_code, from_account_id, to_account_id, transaction_type, amount, fee, description, status, transaction_date) VALUES
('TXN-0001', NULL, 'ACC-001', 'deposit', 50000.00, 0, 'Initial deposit', 'completed', '2023-01-15 09:30:00'),
('TXN-0002', 'ACC-001', 'ACC-002', 'transfer', 25000.00, 5.00, 'Transfer to savings', 'completed', '2023-01-20 14:22:00'),
('TXN-0003', 'ACC-003', NULL, 'withdrawal', 500.00, 2.50, 'ATM withdrawal', 'completed', '2023-02-01 16:45:00'),
('TXN-0004', NULL, 'ACC-005', 'deposit', 30000.00, 0, 'Client payment', 'completed', '2023-02-10 11:00:00'),
('TXN-0005', 'ACC-006', 'ACC-007', 'transfer', 100000.00, 0, 'Investment transfer', 'completed', '2023-02-15 10:30:00'),
('TXN-0006', 'ACC-003', 'ACC-004', 'transfer', 250.00, 0, 'Personal transfer', 'completed', '2023-03-01 09:15:00'),
('TXN-0007', NULL, 'ACC-008', 'deposit', 5000000.00, 0, 'Quarterly revenue', 'completed', '2023-03-10 08:00:00'),
('TXN-0008', 'ACC-001', NULL, 'payment', 15000.00, 25.00, 'Supplier payment', 'completed', '2023-03-15 13:30:00'),
('TXN-0009', 'ACC-009', NULL, 'withdrawal', 5000.00, 10.00, 'Cash withdrawal', 'completed', '2023-03-20 15:00:00'),
('TXN-0010', NULL, 'ACC-010', 'deposit', 75000.00, 0, 'Sales revenue', 'completed', '2023-04-01 09:00:00'),
('TXN-0011', 'ACC-012', NULL, 'interest', 218.75, 0, 'Monthly interest', 'completed', '2023-04-30 23:59:00'),
('TXN-0012', 'ACC-006', 'ACC-001', 'transfer', 50000.00, 50.00, 'International transfer', 'completed', '2023-05-05 11:20:00'),
('TXN-0013', NULL, 'ACC-013', 'deposit', 20000.00, 0, 'Sales deposit', 'completed', '2023-05-10 10:00:00'),
('TXN-0014', 'ACC-014', NULL, 'payment', 1250.00, 5.00, 'Credit card payment', 'completed', '2023-05-15 14:45:00'),
('TXN-0015', 'ACC-001', 'ACC-003', 'refund', 500.00, 0, 'Order refund', 'completed', '2023-06-01 16:00:00'),
-- 2024 transactions
('TXN-0016', NULL, 'ACC-001', 'deposit', 75000.00, 0, 'Q1 2024 revenue deposit', 'completed', '2024-01-31 09:00:00'),
('TXN-0017', NULL, 'ACC-003', 'deposit', 2500.00, 0, 'Salary deposit', 'completed', '2024-01-15 08:00:00'),
('TXN-0018', NULL, 'ACC-004', 'deposit', 1800.00, 0, 'Salary deposit', 'completed', '2024-01-15 08:00:00'),
('TXN-0019', NULL, 'ACC-005', 'deposit', 45000.00, 0, 'Client payment - Project Alpha', 'completed', '2024-02-10 10:00:00'),
-- Withdrawals
('TXN-0020', 'ACC-003', NULL, 'withdrawal', 300.00, 2.50, 'ATM withdrawal', 'completed', '2024-01-20 12:30:00'),
('TXN-0021', 'ACC-004', NULL, 'withdrawal', 200.00, 2.50, 'ATM withdrawal', 'completed', '2024-02-05 14:00:00'),
('TXN-0022', 'ACC-009', NULL, 'withdrawal', 10000.00, 25.00, 'Business expense withdrawal', 'completed', '2024-01-25 11:00:00'),
-- Transfers
('TXN-0023', 'ACC-001', 'ACC-002', 'transfer', 50000.00, 0, 'Monthly savings transfer', 'completed', '2024-02-01 09:00:00'),
('TXN-0024', 'ACC-003', 'ACC-004', 'transfer', 150.00, 0, 'Personal transfer', 'completed', '2024-02-15 10:30:00'),
('TXN-0025', 'ACC-010', 'ACC-015', 'transfer', 25000.00, 15.00, 'Supplier payment', 'completed', '2024-02-20 14:00:00'),
-- Payments
('TXN-0026', 'ACC-001', NULL, 'payment', 8500.00, 25.00, 'Monthly vendor payment', 'completed', '2024-02-28 16:00:00'),
('TXN-0027', 'ACC-005', NULL, 'payment', 12000.00, 30.00, 'Equipment purchase', 'completed', '2024-03-05 11:00:00'),
('TXN-0028', 'ACC-006', NULL, 'payment', 35000.00, 50.00, 'Quarterly supplier payment', 'completed', '2024-03-10 10:00:00'),
-- Interest payments
('TXN-0029', NULL, 'ACC-002', 'interest', 468.75, 0, 'Monthly interest - Feb 2024', 'completed', '2024-02-29 23:59:00'),
('TXN-0030', NULL, 'ACC-007', 'interest', 4687.50, 0, 'Monthly interest - Feb 2024', 'completed', '2024-02-29 23:59:00'),
('TXN-0031', NULL, 'ACC-012', 'interest', 18.23, 0, 'Monthly interest - Feb 2024', 'completed', '2024-02-29 23:59:00'),
-- Fees
('TXN-0032', 'ACC-003', NULL, 'fee', 15.00, 0, 'Monthly account maintenance', 'completed', '2024-02-28 23:59:00'),
('TXN-0033', 'ACC-004', NULL, 'fee', 15.00, 0, 'Monthly account maintenance', 'completed', '2024-02-28 23:59:00'),
-- Failed transaction
('TXN-0034', 'ACC-011', 'ACC-003', 'transfer', 1000.00, 0, 'Transfer attempt from frozen account', 'failed', '2024-03-01 10:00:00'),
-- Refunds
('TXN-0035', NULL, 'ACC-014', 'refund', 89.99, 0, 'Product return refund', 'completed', '2024-03-05 15:00:00');

-- ============================================================================
-- PART 12: ORDERS AND ORDER LINES (High Volume)
-- ============================================================================

INSERT INTO orders (id, order_number, customer_id, order_date, required_date, shipped_date, shipping_city, status, payment_method, payment_status, subtotal, tax_rate, tax_amount, shipping_cost, discount_amount, total_amount, metadata) VALUES
-- 2023 Orders (historical)
(1, 'ORD-2023-0001', 1, '2023-01-15', '2023-01-22', '2023-01-18', 'New York', 'delivered', 'credit_card', 'paid', 2599.98, 18.00, 467.99, 25.00, 0, 3092.97, '{"source": "website", "campaign": "new_year"}'),
(2, 'ORD-2023-0002', 2, '2023-01-20', '2023-01-27', '2023-01-23', 'Los Angeles', 'delivered', 'paypal', 'paid', 349.99, 18.00, 62.99, 15.00, 35.00, 392.98, '{"source": "mobile_app"}'),
(3, 'ORD-2023-0003', 4, '2023-02-05', '2023-02-12', '2023-02-08', 'Berlin', 'delivered', 'bank_transfer', 'paid', 1899.99, 19.00, 360.99, 45.00, 0, 2305.98, '{"source": "website", "b2b": true}'),
(4, 'ORD-2023-0004', 6, '2023-02-10', '2023-02-17', '2023-02-14', 'London', 'delivered', 'credit_card', 'paid', 4299.97, 20.00, 859.99, 0, 429.99, 4729.97, '{"source": "sales_rep", "rep_id": 10}'),
(5, 'ORD-2023-0005', 10, '2023-02-20', '2023-02-27', '2023-02-24', 'Tokyo', 'delivered', 'bank_transfer', 'paid', 8499.95, 10.00, 849.99, 150.00, 0, 9499.94, '{"source": "website", "b2b": true}'),
(6, 'ORD-2023-0006', 3, '2023-03-01', '2023-03-08', '2023-03-04', 'Chicago', 'delivered', 'credit_card', 'paid', 129.99, 18.00, 23.39, 10.00, 0, 163.38, '{"source": "website"}'),
(7, 'ORD-2023-0007', 8, '2023-03-10', '2023-03-17', '2023-03-13', 'Amsterdam', 'delivered', 'credit_card', 'paid', 599.99, 21.00, 125.99, 0, 0, 725.98, '{"source": "website"}'),
(8, 'ORD-2023-0008', 1, '2023-03-15', '2023-03-22', '2023-03-18', 'New York', 'delivered', 'credit_card', 'paid', 1549.98, 18.00, 278.99, 25.00, 155.00, 1698.97, '{"source": "website", "returning_customer": true}'),
(9, 'ORD-2023-0009', 5, '2023-03-25', '2023-04-01', '2023-03-28', 'Paris', 'delivered', 'credit_card', 'paid', 249.99, 20.00, 49.99, 20.00, 0, 319.98, '{"source": "mobile_app"}'),
(10, 'ORD-2023-0010', 7, '2023-04-01', '2023-04-08', '2023-04-04', 'Madrid', 'delivered', 'paypal', 'paid', 89.99, 21.00, 18.89, 15.00, 0, 123.88, '{"source": "website"}'),

-- More 2023 orders
(11, 'ORD-2023-0011', 11, '2023-04-10', '2023-04-17', '2023-04-13', 'Toronto', 'delivered', 'credit_card', 'paid', 399.99, 13.00, 51.99, 20.00, 0, 471.98, NULL),
(12, 'ORD-2023-0012', 13, '2023-04-15', '2023-04-22', '2023-04-18', 'Zurich', 'delivered', 'bank_transfer', 'paid', 2999.98, 7.70, 230.99, 0, 300.00, 2930.97, '{"source": "sales_rep"}'),
(13, 'ORD-2023-0013', 15, '2023-05-01', '2023-05-08', '2023-05-04', 'Rome', 'delivered', 'credit_card', 'paid', 179.98, 22.00, 39.59, 15.00, 0, 234.57, NULL),
(14, 'ORD-2023-0014', 16, '2023-05-10', '2023-05-17', '2023-05-13', 'Helsinki', 'delivered', 'credit_card', 'paid', 799.99, 24.00, 191.99, 30.00, 0, 1021.98, NULL),
(15, 'ORD-2023-0015', 17, '2023-05-20', '2023-05-27', '2023-05-23', 'Shanghai', 'delivered', 'bank_transfer', 'paid', 1599.98, 13.00, 207.99, 50.00, 0, 1857.97, '{"source": "website", "b2b": true}'),
(16, 'ORD-2023-0016', 18, '2023-06-01', '2023-06-08', '2023-06-04', 'Sydney', 'delivered', 'credit_card', 'paid', 549.99, 10.00, 54.99, 35.00, 0, 639.98, NULL),
(17, 'ORD-2023-0017', 19, '2023-06-10', '2023-06-17', '2023-06-13', 'Dubai', 'delivered', 'credit_card', 'paid', 3499.97, 5.00, 174.99, 0, 350.00, 3324.96, '{"source": "sales_rep", "vip": true}'),
(18, 'ORD-2023-0018', 20, '2023-06-20', '2023-06-27', '2023-06-23', 'Sao Paulo', 'delivered', 'paypal', 'paid', 299.99, 18.00, 53.99, 25.00, 0, 378.98, NULL),
(19, 'ORD-2023-0019', 21, '2023-07-01', '2023-07-08', '2023-07-04', 'Vienna', 'delivered', 'credit_card', 'paid', 149.99, 20.00, 29.99, 15.00, 0, 194.98, NULL),
(20, 'ORD-2023-0020', 22, '2023-07-10', '2023-07-17', '2023-07-13', 'Copenhagen', 'delivered', 'bank_transfer', 'paid', 1099.98, 25.00, 274.99, 0, 0, 1374.97, NULL),

-- Mid 2023
(21, 'ORD-2023-0021', 1, '2023-07-15', '2023-07-22', '2023-07-18', 'New York', 'delivered', 'credit_card', 'paid', 449.99, 18.00, 80.99, 0, 0, 530.98, '{"returning_customer": true}'),
(22, 'ORD-2023-0022', 23, '2023-07-25', '2023-08-01', '2023-07-28', 'Boston', 'delivered', 'credit_card', 'paid', 679.98, 18.00, 122.39, 20.00, 0, 822.37, NULL),
(23, 'ORD-2023-0023', 24, '2023-08-01', '2023-08-08', '2023-08-04', 'Berlin', 'delivered', 'paypal', 'paid', 199.99, 19.00, 37.99, 15.00, 0, 252.98, NULL),
(24, 'ORD-2023-0024', 25, '2023-08-10', '2023-08-17', '2023-08-13', 'Osaka', 'delivered', 'credit_card', 'paid', 1199.99, 10.00, 119.99, 40.00, 120.00, 1239.98, NULL),
(25, 'ORD-2023-0025', 26, '2023-08-20', '2023-08-27', '2023-08-23', 'Brussels', 'delivered', 'bank_transfer', 'paid', 2499.97, 21.00, 524.99, 0, 0, 3024.96, '{"source": "sales_rep", "b2b": true}'),
(26, 'ORD-2023-0026', 27, '2023-09-01', '2023-09-08', '2023-09-04', 'Lyon', 'delivered', 'credit_card', 'paid', 89.99, 20.00, 17.99, 10.00, 0, 117.98, NULL),
(27, 'ORD-2023-0027', 28, '2023-09-10', '2023-09-17', '2023-09-13', 'Singapore', 'delivered', 'credit_card', 'paid', 1799.98, 7.00, 125.99, 0, 180.00, 1745.97, '{"source": "website", "b2b": true}'),
(28, 'ORD-2023-0028', 29, '2023-09-20', '2023-09-27', '2023-09-23', 'Prague', 'delivered', 'paypal', 'paid', 349.99, 21.00, 73.49, 20.00, 0, 443.48, NULL),
(29, 'ORD-2023-0029', 30, '2023-10-01', '2023-10-08', '2023-10-04', 'Seoul', 'delivered', 'credit_card', 'paid', 2299.98, 10.00, 229.99, 50.00, 0, 2579.97, '{"source": "website", "b2b": true}'),
(30, 'ORD-2023-0030', 31, '2023-10-10', '2023-10-17', '2023-10-13', 'Auckland', 'delivered', 'credit_card', 'paid', 599.99, 15.00, 89.99, 45.00, 0, 734.98, NULL),

-- Late 2023
(31, 'ORD-2023-0031', 32, '2023-10-20', '2023-10-27', '2023-10-23', 'Lisbon', 'delivered', 'bank_transfer', 'paid', 899.98, 23.00, 206.99, 0, 0, 1106.97, NULL),
(32, 'ORD-2023-0032', 33, '2023-11-01', '2023-11-08', '2023-11-04', 'Mumbai', 'delivered', 'credit_card', 'paid', 449.99, 18.00, 80.99, 30.00, 0, 560.98, NULL),
(33, 'ORD-2023-0033', 6, '2023-11-10', '2023-11-17', '2023-11-13', 'London', 'delivered', 'credit_card', 'paid', 5999.95, 20.00, 1199.99, 0, 599.99, 6599.95, '{"source": "sales_rep", "vip": true}'),
(34, 'ORD-2023-0034', 10, '2023-11-15', '2023-11-22', '2023-11-18', 'Tokyo', 'delivered', 'bank_transfer', 'paid', 12999.90, 10.00, 1299.99, 0, 1300.00, 12999.89, '{"source": "sales_rep", "b2b": true}'),
(35, 'ORD-2023-0035', 34, '2023-11-25', '2023-12-02', '2023-11-28', 'Mexico City', 'delivered', 'credit_card', 'paid', 799.99, 16.00, 127.99, 35.00, 0, 962.98, NULL),
(36, 'ORD-2023-0036', 35, '2023-12-01', '2023-12-08', '2023-12-04', 'Oslo', 'delivered', 'credit_card', 'paid', 1299.99, 25.00, 324.99, 0, 0, 1624.98, NULL),
(37, 'ORD-2023-0037', 1, '2023-12-10', '2023-12-17', '2023-12-13', 'New York', 'delivered', 'credit_card', 'paid', 3499.97, 18.00, 629.99, 0, 350.00, 3779.96, '{"source": "website", "holiday_sale": true}'),
(38, 'ORD-2023-0038', 4, '2023-12-15', '2023-12-22', '2023-12-18', 'Berlin', 'delivered', 'bank_transfer', 'paid', 2199.98, 19.00, 417.99, 45.00, 0, 2662.97, '{"source": "sales_rep", "b2b": true}'),

-- 2024 Orders
(39, 'ORD-2024-0001', 2, '2024-01-05', '2024-01-12', '2024-01-08', 'Los Angeles', 'delivered', 'credit_card', 'paid', 549.99, 18.00, 98.99, 15.00, 0, 663.98, '{"source": "mobile_app"}'),
(40, 'ORD-2024-0002', 36, '2024-01-10', '2024-01-17', '2024-01-13', 'San Francisco', 'delivered', 'paypal', 'paid', 1299.99, 18.00, 233.99, 0, 130.00, 1403.98, NULL),
(41, 'ORD-2024-0003', 37, '2024-01-15', '2024-01-22', '2024-01-18', 'Munich', 'delivered', 'bank_transfer', 'paid', 4599.96, 19.00, 873.99, 0, 460.00, 5013.95, '{"source": "sales_rep", "vip": true}'),
(42, 'ORD-2024-0004', 38, '2024-01-20', '2024-01-27', '2024-01-23', 'Dublin', 'delivered', 'credit_card', 'paid', 179.98, 23.00, 41.39, 20.00, 0, 241.37, NULL),
(43, 'ORD-2024-0005', 39, '2024-02-01', '2024-02-08', '2024-02-04', 'Vancouver', 'delivered', 'credit_card', 'paid', 899.99, 12.00, 107.99, 25.00, 0, 1032.98, '{"source": "website", "b2b": true}'),
(44, 'ORD-2024-0006', 19, '2024-02-05', '2024-02-12', '2024-02-08', 'Dubai', 'delivered', 'credit_card', 'paid', 2999.98, 5.00, 149.99, 0, 300.00, 2849.97, '{"source": "sales_rep", "vip": true}'),
(45, 'ORD-2024-0007', 45, '2024-02-10', '2024-02-17', '2024-02-13', 'Riyadh', 'delivered', 'bank_transfer', 'paid', 1899.99, 15.00, 284.99, 50.00, 0, 2234.98, '{"source": "sales_rep", "b2b": true}'),
(46, 'ORD-2024-0008', 3, '2024-02-15', '2024-02-22', '2024-02-18', 'Chicago', 'delivered', 'credit_card', 'paid', 449.99, 18.00, 80.99, 10.00, 0, 540.98, NULL),
(47, 'ORD-2024-0009', 47, '2024-02-20', '2024-02-27', '2024-02-23', 'Barcelona', 'delivered', 'paypal', 'paid', 299.99, 21.00, 62.99, 15.00, 0, 377.98, NULL),
(48, 'ORD-2024-0010', 48, '2024-03-01', '2024-03-08', '2024-03-04', 'Hamburg', 'delivered', 'bank_transfer', 'paid', 1599.98, 19.00, 303.99, 0, 160.00, 1743.97, '{"source": "website", "b2b": true}'),

-- Recent 2024 orders (various statuses)
(49, 'ORD-2024-0011', 49, '2024-03-05', '2024-03-12', '2024-03-08', 'Milan', 'delivered', 'credit_card', 'paid', 2199.98, 22.00, 483.99, 0, 0, 2683.97, '{"source": "sales_rep", "vip": true}'),
(50, 'ORD-2024-0012', 50, '2024-03-10', '2024-03-17', '2024-03-13', 'Austin', 'delivered', 'credit_card', 'paid', 799.99, 18.00, 143.99, 20.00, 0, 963.98, '{"source": "website", "b2b": true}'),
(51, 'ORD-2024-0013', 1, '2024-03-15', '2024-03-22', '2024-03-18', 'New York', 'delivered', 'credit_card', 'paid', 1999.98, 18.00, 359.99, 0, 200.00, 2159.97, '{"returning_customer": true}'),
(52, 'ORD-2024-0014', 6, '2024-03-20', '2024-03-27', '2024-03-23', 'London', 'delivered', 'bank_transfer', 'paid', 7499.95, 20.00, 1499.99, 0, 750.00, 8249.94, '{"source": "sales_rep", "vip": true}'),
(53, 'ORD-2024-0015', 10, '2024-03-25', '2024-04-01', '2024-03-28', 'Tokyo', 'delivered', 'bank_transfer', 'paid', 9999.95, 10.00, 999.99, 0, 1000.00, 9999.94, '{"source": "sales_rep", "b2b": true}'),
(54, 'ORD-2024-0016', 23, '2024-04-01', '2024-04-08', '2024-04-04', 'Boston', 'shipped', 'credit_card', 'paid', 649.98, 18.00, 116.99, 15.00, 0, 781.97, NULL),
(55, 'ORD-2024-0017', 2, '2024-04-05', '2024-04-12', NULL, 'Los Angeles', 'processing', 'credit_card', 'paid', 1199.99, 18.00, 215.99, 20.00, 0, 1435.98, '{"source": "mobile_app"}'),
(56, 'ORD-2024-0018', 4, '2024-04-08', '2024-04-15', NULL, 'Berlin', 'confirmed', 'bank_transfer', 'pending', 2399.98, 19.00, 455.99, 45.00, 240.00, 2660.97, '{"source": "website", "b2b": true}'),
(57, 'ORD-2024-0019', 5, '2024-04-10', '2024-04-17', NULL, 'Paris', 'draft', 'credit_card', 'pending', 349.99, 20.00, 69.99, 20.00, 0, 439.98, NULL),

-- Cancelled/returned orders
(58, 'ORD-2024-0020', 14, '2024-02-01', '2024-02-08', NULL, 'Dublin', 'cancelled', 'credit_card', 'refunded', 899.99, 23.00, 206.99, 30.00, 0, 1136.98, '{"cancel_reason": "Customer request"}'),
(59, 'ORD-2024-0021', 7, '2024-01-15', '2024-01-22', '2024-01-18', 'Madrid', 'returned', 'paypal', 'refunded', 549.99, 21.00, 115.49, 15.00, 0, 680.48, '{"return_reason": "Defective product"}'),
(60, 'ORD-2024-0022', 40, '2024-03-01', '2024-03-08', NULL, 'Detroit', 'cancelled', 'credit_card', 'failed', 299.99, 18.00, 53.99, 15.00, 0, 368.98, '{"cancel_reason": "Payment failed"}');

SELECT setval('orders_id_seq', 60);

-- Order Lines (multiple items per order)
INSERT INTO order_lines (order_id, product_id, quantity, unit_price, discount_percent) VALUES
-- Order 1
(1, 1, 2, 1299.99, 0),
-- Order 2
(2, 8, 1, 349.99, 10),
-- Order 3
(3, 3, 1, 1899.99, 0),
-- Order 4
(4, 1, 2, 1299.99, 5), (4, 8, 3, 349.99, 5), (4, 9, 2, 129.99, 0),
-- Order 5
(5, 5, 5, 1199.99, 10), (5, 8, 5, 349.99, 5),
-- Order 6
(6, 9, 1, 129.99, 0),
-- Order 7
(7, 26, 1, 599.99, 0),
-- Order 8
(8, 2, 1, 999.99, 10), (8, 10, 1, 79.99, 0), (8, 11, 5, 29.99, 0), (8, 35, 1, 299.99, 0),
-- Order 9
(9, 13, 2, 69.99, 0), (9, 17, 1, 79.99, 0),
-- Order 10
(10, 14, 1, 89.99, 0),
-- Order 11
(11, 26, 1, 399.99, 0),
-- Order 12
(12, 1, 1, 1299.99, 10), (12, 8, 2, 349.99, 5), (12, 26, 2, 399.99, 0),
-- Order 13
(13, 12, 1, 69.99, 0), (13, 14, 1, 89.99, 0), (13, 40, 1, 19.99, 0),
-- Order 14
(14, 27, 1, 599.99, 0), (14, 28, 1, 199.99, 0),
-- Order 15
(15, 6, 2, 299.99, 0), (15, 7, 2, 549.99, 5),
-- Order 16
(16, 7, 1, 549.99, 0),
-- Order 17
(17, 1, 1, 1299.99, 10), (17, 5, 1, 1199.99, 5), (17, 8, 2, 349.99, 5),
-- Order 18
(18, 15, 1, 79.99, 0), (18, 16, 1, 49.99, 0), (18, 33, 1, 129.99, 0), (18, 34, 1, 39.99, 0),
-- Order 19
(19, 36, 1, 149.99, 0),
-- Order 20
(20, 2, 1, 999.99, 5), (20, 35, 1, 149.99, 5),
-- Order 21-30 (variety of products)
(21, 10, 2, 79.99, 0), (21, 21, 1, 59.99, 0), (21, 22, 1, 49.99, 0), (21, 40, 5, 19.99, 0),
(22, 26, 1, 399.99, 0), (22, 32, 1, 49.99, 0), (22, 33, 1, 129.99, 0),
(23, 36, 1, 149.99, 0), (23, 35, 1, 49.99, 0),
(24, 5, 1, 1199.99, 10),
(25, 3, 1, 1899.99, 10), (25, 8, 1, 349.99, 0), (25, 21, 1, 59.99, 0),
(26, 14, 1, 89.99, 0),
(27, 1, 1, 1299.99, 5), (27, 10, 2, 79.99, 0), (27, 34, 3, 39.99, 0),
(28, 8, 1, 349.99, 0),
(29, 3, 1, 1899.99, 5), (29, 26, 1, 399.99, 0),
(30, 27, 1, 599.99, 0),
-- Orders 31-40
(31, 26, 1, 399.99, 0), (31, 27, 1, 599.99, 10),
(32, 10, 1, 79.99, 0), (32, 8, 1, 349.99, 0), (32, 40, 1, 19.99, 0),
(33, 3, 2, 1899.99, 10), (33, 1, 1, 1299.99, 5), (33, 8, 2, 349.99, 0),
(34, 5, 10, 1199.99, 10), (34, 8, 5, 349.99, 5),
(35, 2, 1, 999.99, 20),
(36, 1, 1, 1299.99, 0),
(37, 3, 1, 1899.99, 5), (37, 8, 2, 349.99, 0), (37, 27, 1, 599.99, 5),
(38, 4, 2, 599.99, 0), (38, 34, 5, 39.99, 0), (38, 35, 5, 49.99, 0),
(39, 7, 1, 549.99, 0),
(40, 1, 1, 1299.99, 10),
-- Orders 41-50
(41, 3, 2, 1899.99, 10), (41, 8, 2, 349.99, 5),
(42, 36, 1, 149.99, 0), (42, 12, 1, 29.99, 0),
(43, 26, 1, 399.99, 0), (43, 27, 1, 599.99, 10),
(44, 5, 2, 1199.99, 10), (44, 8, 1, 349.99, 0),
(45, 3, 1, 1899.99, 0),
(46, 10, 2, 79.99, 0), (46, 21, 2, 59.99, 0), (46, 22, 2, 49.99, 0),
(47, 15, 2, 79.99, 0), (47, 17, 1, 79.99, 0), (47, 40, 3, 19.99, 0),
(48, 1, 1, 1299.99, 10), (48, 34, 5, 39.99, 0),
(49, 5, 1, 1199.99, 0), (49, 2, 1, 999.99, 0),
(50, 26, 1, 399.99, 0), (50, 27, 1, 599.99, 20),
-- Orders 51-60
(51, 1, 1, 1299.99, 10), (51, 8, 2, 349.99, 0),
(52, 3, 3, 1899.99, 10), (52, 8, 5, 349.99, 5),
(53, 5, 5, 1199.99, 5), (53, 3, 2, 1899.99, 10),
(54, 26, 1, 399.99, 0), (54, 35, 5, 49.99, 0),
(55, 5, 1, 1199.99, 0),
(56, 3, 1, 1899.99, 10), (56, 34, 5, 39.99, 0), (56, 10, 2, 79.99, 5),
(57, 8, 1, 349.99, 0),
(58, 26, 1, 399.99, 0), (58, 27, 1, 599.99, 10),
(59, 7, 1, 549.99, 0),
(60, 15, 2, 79.99, 0), (60, 17, 1, 79.99, 0), (60, 40, 3, 19.99, 0);

-- ============================================================================
-- PART 13: LIBRARY SCHEMA DATA
-- ============================================================================

-- Authors
INSERT INTO library.authors (first_name, last_name, birth_year, death_year, nationality, biography) VALUES
('George', 'Orwell', 1903, 1950, 'British', 'English novelist and essayist'),
('Jane', 'Austen', 1775, 1817, 'British', 'English novelist known for romantic fiction'),
('Mark', 'Twain', 1835, 1910, 'American', 'American writer and humorist'),
('Virginia', 'Woolf', 1882, 1941, 'British', 'English modernist writer'),
('Ernest', 'Hemingway', 1899, 1961, 'American', 'American novelist and journalist'),
('Gabriel', 'Garcia Marquez', 1927, 2014, 'Colombian', 'Colombian novelist and Nobel laureate'),
('Haruki', 'Murakami', 1949, NULL, 'Japanese', 'Japanese contemporary fiction writer'),
('Toni', 'Morrison', 1931, 2019, 'American', 'American novelist and Nobel laureate'),
('Leo', 'Tolstoy', 1828, 1910, 'Russian', 'Russian writer regarded as one of the greatest'),
('Agatha', 'Christie', 1890, 1976, 'British', 'English mystery writer');

-- Books
INSERT INTO library.books (isbn, title, publication_year, publisher, edition, pages, language, genre, description) VALUES
('978-0451524935', '1984', 1949, 'Signet Classics', 1, 328, 'English', 'Dystopian', 'A dystopian social science fiction novel'),
('978-0141439518', 'Pride and Prejudice', 1813, 'Penguin Classics', 1, 432, 'English', 'Romance', 'A romantic novel of manners'),
('978-0142437179', 'Adventures of Huckleberry Finn', 1884, 'Penguin Classics', 1, 366, 'English', 'Adventure', 'A novel about a boy named Huck'),
('978-0156030359', 'Mrs Dalloway', 1925, 'Harvest Books', 1, 194, 'English', 'Modernist', 'A day in the life of Clarissa Dalloway'),
('978-0684801223', 'The Old Man and the Sea', 1952, 'Scribner', 1, 127, 'English', 'Literary Fiction', 'Story of an aging Cuban fisherman'),
('978-0060883287', 'One Hundred Years of Solitude', 1967, 'Harper Perennial', 1, 417, 'English', 'Magical Realism', 'The multi-generational story of the Buendia family'),
('978-0375704024', 'Norwegian Wood', 1987, 'Vintage', 1, 296, 'English', 'Literary Fiction', 'A nostalgic story of loss and sexuality'),
('978-1400033416', 'Beloved', 1987, 'Vintage', 1, 321, 'English', 'Historical Fiction', 'A novel inspired by the story of Margaret Garner'),
('978-0143039990', 'Anna Karenina', 1877, 'Penguin Classics', 1, 964, 'English', 'Realist Fiction', 'A complex novel exploring themes of family and society'),
('978-0062073488', 'Murder on the Orient Express', 1934, 'William Morrow', 1, 265, 'English', 'Mystery', 'A famous Hercule Poirot mystery');

-- Book Authors (many-to-many relationship)
INSERT INTO library.book_authors (book_id, author_id, author_role) VALUES
(1, 1, 'author'), (2, 2, 'author'), (3, 3, 'author'), (4, 4, 'author'),
(5, 5, 'author'), (6, 6, 'author'), (7, 7, 'author'), (8, 8, 'author'),
(9, 9, 'author'), (10, 10, 'author');

-- Book Copies
INSERT INTO library.book_copies (book_id, copy_number, location, condition, acquisition_date, status) VALUES
(1, 1, 'Shelf A-1', 'good', '2020-01-15', 'available'),
(1, 2, 'Shelf A-1', 'fair', '2020-01-15', 'borrowed'),
(1, 3, 'Shelf A-1', 'new', '2023-06-01', 'available'),
(2, 1, 'Shelf A-2', 'good', '2019-05-20', 'available'),
(2, 2, 'Shelf A-2', 'good', '2021-03-10', 'reserved'),
(3, 1, 'Shelf A-3', 'fair', '2018-08-15', 'available'),
(4, 1, 'Shelf B-1', 'good', '2020-11-01', 'borrowed'),
(5, 1, 'Shelf B-2', 'new', '2023-01-20', 'available'),
(5, 2, 'Shelf B-2', 'good', '2020-04-15', 'available'),
(6, 1, 'Shelf B-3', 'good', '2019-07-22', 'available'),
(7, 1, 'Shelf C-1', 'new', '2024-01-05', 'borrowed'),
(8, 1, 'Shelf C-2', 'good', '2021-09-18', 'available'),
(9, 1, 'Shelf C-3', 'fair', '2017-03-30', 'maintenance'),
(10, 1, 'Shelf D-1', 'good', '2022-02-14', 'available'),
(10, 2, 'Shelf D-1', 'good', '2022-02-14', 'borrowed');

-- Library Members
INSERT INTO library.members (member_code, first_name, last_name, email, phone, membership_type, membership_start, max_books, active) VALUES
('MEM001', 'Alice', 'Johnson', 'alice.johnson@email.com', '+1-555-1001', 'standard', '2022-01-15', 5, true),
('MEM002', 'Bob', 'Williams', 'bob.williams@email.com', '+1-555-1002', 'premium', '2021-06-20', 10, true),
('MEM003', 'Carol', 'Davis', 'carol.davis@email.com', '+1-555-1003', 'student', '2023-09-01', 3, true),
('MEM004', 'David', 'Brown', 'david.brown@email.com', '+1-555-1004', 'senior', '2020-03-10', 7, true),
('MEM005', 'Eva', 'Miller', 'eva.miller@email.com', '+1-555-1005', 'standard', '2022-08-25', 5, true),
('MEM006', 'Frank', 'Wilson', 'frank.wilson@email.com', '+1-555-1006', 'premium', '2019-11-30', 10, true),
('MEM007', 'Grace', 'Taylor', 'grace.taylor@email.com', '+1-555-1007', 'student', '2024-01-10', 3, true),
('MEM008', 'Henry', 'Anderson', NULL, '+1-555-1008', 'standard', '2023-04-05', 5, false);

-- Library Loans
INSERT INTO library.loans (copy_id, member_id, loan_date, due_date, return_date, renewals, fine_amount, status) VALUES
(2, 1, '2024-03-01', '2024-03-15', NULL, 1, 0, 'active'),
(7, 2, '2024-03-05', '2024-03-19', NULL, 0, 0, 'active'),
(11, 3, '2024-03-10', '2024-03-24', NULL, 0, 0, 'active'),
(15, 4, '2024-02-15', '2024-03-01', NULL, 2, 5.00, 'overdue'),
(1, 5, '2024-01-20', '2024-02-03', '2024-02-01', 0, 0, 'returned'),
(3, 6, '2024-02-01', '2024-02-15', '2024-02-14', 0, 0, 'returned'),
(8, 1, '2024-02-10', '2024-02-24', '2024-02-28', 0, 2.00, 'returned'),
(10, 2, '2024-01-05', '2024-01-19', '2024-01-18', 0, 0, 'returned');

-- Library Reservations
INSERT INTO library.reservations (book_id, member_id, reservation_date, expiry_date, status, notification_sent) VALUES
(2, 3, '2024-03-15', '2024-03-22', 'pending', false),
(6, 5, '2024-03-10', '2024-03-17', 'ready', true),
(1, 7, '2024-03-12', '2024-03-19', 'pending', false);

-- ============================================================================
-- PART 14: HR SCHEMA DATA
-- ============================================================================

-- HR Departments
INSERT INTO hr.departments (code, name, description, parent_id, budget, location, active) VALUES
('EXEC', 'Executive', 'Executive leadership team', NULL, 2000000.00, 'New York', true),
('TECH', 'Technology', 'Technology and Engineering', NULL, 5000000.00, 'San Francisco', true),
('ENG', 'Engineering', 'Software Engineering', 2, 3000000.00, 'San Francisco', true),
('PROD', 'Product', 'Product Management', 2, 1500000.00, 'San Francisco', true),
('FIN', 'Finance', 'Finance and Accounting', NULL, 1200000.00, 'New York', true),
('SALES', 'Sales', 'Sales Department', NULL, 3500000.00, 'Chicago', true),
('HR', 'Human Resources', 'People Operations', NULL, 800000.00, 'New York', true);

-- HR Positions
INSERT INTO hr.positions (code, title, department_id, min_salary, max_salary, description, requirements) VALUES
('CEO', 'Chief Executive Officer', 1, 300000.00, 500000.00, 'Lead the company', ARRAY['15+ years experience', 'MBA preferred']),
('CTO', 'Chief Technology Officer', 2, 250000.00, 400000.00, 'Lead technology strategy', ARRAY['12+ years in tech', 'Engineering background']),
('ENG-DIR', 'Director of Engineering', 3, 150000.00, 220000.00, 'Lead engineering teams', ARRAY['10+ years experience', 'Team leadership']),
('SR-ENG', 'Senior Software Engineer', 3, 100000.00, 150000.00, 'Senior development role', ARRAY['5+ years experience', 'Strong coding skills']),
('ENG', 'Software Engineer', 3, 70000.00, 120000.00, 'Development role', ARRAY['2+ years experience', 'CS degree']),
('PM', 'Product Manager', 4, 100000.00, 160000.00, 'Product management', ARRAY['3+ years in product', 'Technical background']),
('SALES-MGR', 'Sales Manager', 6, 90000.00, 140000.00, 'Manage sales team', ARRAY['5+ years sales', 'Leadership skills']),
('SALES-REP', 'Sales Representative', 6, 45000.00, 80000.00, 'Direct sales role', ARRAY['1+ years sales', 'Communication skills']);

-- Salary History (sample)
INSERT INTO hr.salary_history (employee_id, effective_date, salary, change_reason, approved_by) VALUES
(28, '2021-01-15', 85000.00, 'Initial hire', 12),
(28, '2022-01-01', 90000.00, 'Annual raise', 12),
(29, '2021-02-01', 82000.00, 'Initial hire', 12),
(29, '2022-02-01', 88000.00, 'Annual raise', 12),
(30, '2021-03-15', 88000.00, 'Initial hire', 22),
(30, '2022-04-01', 92000.00, 'Promotion', 22);

-- ============================================================================
-- PART 15: VIEWS
-- ============================================================================

-- Customer Order Summary View
CREATE OR REPLACE VIEW customer_order_summary AS
SELECT
    c.id AS customer_id,
    c.name AS customer_name,
    c.customer_type,
    c.city,
    co.name AS country,
    COUNT(o.id) AS order_count,
    COALESCE(SUM(o.total_amount), 0) AS total_spent,
    COALESCE(AVG(o.total_amount), 0) AS avg_order_value,
    MIN(o.order_date) AS first_order_date,
    MAX(o.order_date) AS last_order_date
FROM customers c
LEFT JOIN countries co ON c.country_id = co.id
LEFT JOIN orders o ON c.id = o.customer_id AND o.status NOT IN ('cancelled', 'draft')
GROUP BY c.id, c.name, c.customer_type, c.city, co.name;

-- Product Sales Summary View
CREATE OR REPLACE VIEW product_sales_summary AS
SELECT
    p.id AS product_id,
    p.sku,
    p.name AS product_name,
    cat.name AS category_name,
    p.price AS current_price,
    p.cost,
    p.stock_quantity,
    COALESCE(SUM(ol.quantity), 0) AS total_units_sold,
    COALESCE(SUM(ol.line_total), 0) AS total_revenue,
    COALESCE(SUM(ol.line_total) - SUM(ol.quantity * p.cost), 0) AS gross_profit,
    COUNT(DISTINCT o.id) AS order_count
FROM products p
LEFT JOIN categories cat ON p.category_id = cat.id
LEFT JOIN order_lines ol ON p.id = ol.product_id
LEFT JOIN orders o ON ol.order_id = o.id AND o.status NOT IN ('cancelled', 'draft')
GROUP BY p.id, p.sku, p.name, cat.name, p.price, p.cost, p.stock_quantity;

-- Monthly Sales View
CREATE OR REPLACE VIEW monthly_sales AS
SELECT
    DATE_TRUNC('month', o.order_date)::DATE AS month,
    COUNT(o.id) AS order_count,
    COUNT(DISTINCT o.customer_id) AS unique_customers,
    SUM(o.subtotal) AS gross_revenue,
    SUM(o.discount_amount) AS total_discounts,
    SUM(o.tax_amount) AS total_tax,
    SUM(o.total_amount) AS net_revenue,
    AVG(o.total_amount) AS avg_order_value
FROM orders o
WHERE o.status NOT IN ('cancelled', 'draft')
GROUP BY DATE_TRUNC('month', o.order_date)
ORDER BY month;

-- Employee Hierarchy View
CREATE OR REPLACE VIEW employee_hierarchy AS
WITH RECURSIVE emp_tree AS (
    SELECT
        id, employee_code, first_name, last_name, job_title, department,
        manager_id, salary, 1 AS level,
        ARRAY[id] AS path,
        first_name || ' ' || last_name AS full_name
    FROM employees
    WHERE manager_id IS NULL

    UNION ALL

    SELECT
        e.id, e.employee_code, e.first_name, e.last_name, e.job_title, e.department,
        e.manager_id, e.salary, et.level + 1,
        et.path || e.id,
        e.first_name || ' ' || e.last_name
    FROM employees e
    INNER JOIN emp_tree et ON e.manager_id = et.id
    WHERE e.active = true
)
SELECT
    id, employee_code, full_name, job_title, department,
    manager_id, salary, level, path,
    (SELECT full_name FROM emp_tree m WHERE m.id = emp_tree.manager_id) AS manager_name
FROM emp_tree;

-- Low Stock Products View
CREATE OR REPLACE VIEW low_stock_products AS
SELECT
    p.id,
    p.sku,
    p.name,
    c.name AS category,
    p.stock_quantity,
    p.reorder_level,
    p.reorder_level - p.stock_quantity AS units_needed,
    s.company_name AS supplier,
    s.email AS supplier_email
FROM products p
LEFT JOIN categories c ON p.category_id = c.id
LEFT JOIN suppliers s ON p.supplier_id = s.id
WHERE p.stock_quantity <= p.reorder_level
  AND p.active = true
  AND p.type = 'product'
ORDER BY p.stock_quantity ASC;

-- ============================================================================
-- PART 16: FUNCTIONS AND STORED PROCEDURES
-- ============================================================================

-- Function: Calculate order total
CREATE OR REPLACE FUNCTION calculate_order_total(p_order_id INTEGER)
RETURNS DECIMAL(12,2) AS $$
DECLARE
    v_subtotal DECIMAL(12,2);
    v_tax_rate DECIMAL(5,2);
    v_tax_amount DECIMAL(12,2);
    v_shipping DECIMAL(10,2);
    v_discount DECIMAL(10,2);
    v_total DECIMAL(12,2);
BEGIN
    SELECT
        COALESCE(SUM(line_total), 0),
        o.tax_rate,
        o.shipping_cost,
        o.discount_amount
    INTO v_subtotal, v_tax_rate, v_shipping, v_discount
    FROM orders o
    LEFT JOIN order_lines ol ON o.id = ol.order_id
    WHERE o.id = p_order_id
    GROUP BY o.tax_rate, o.shipping_cost, o.discount_amount;

    v_tax_amount := v_subtotal * (v_tax_rate / 100);
    v_total := v_subtotal + v_tax_amount + v_shipping - v_discount;

    RETURN v_total;
END;
$$ LANGUAGE plpgsql;

-- Function: Get customer lifetime value
CREATE OR REPLACE FUNCTION get_customer_ltv(p_customer_id INTEGER)
RETURNS TABLE (
    customer_name VARCHAR(255),
    total_orders INTEGER,
    total_spent DECIMAL(12,2),
    avg_order_value DECIMAL(10,2),
    customer_since DATE
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.name,
        COUNT(o.id)::INTEGER,
        COALESCE(SUM(o.total_amount), 0),
        COALESCE(AVG(o.total_amount), 0)::DECIMAL(10,2),
        c.created_at::DATE
    FROM customers c
    LEFT JOIN orders o ON c.id = o.customer_id AND o.status NOT IN ('cancelled', 'draft')
    WHERE c.id = p_customer_id
    GROUP BY c.id, c.name, c.created_at;
END;
$$ LANGUAGE plpgsql;

-- Procedure: Transfer money between accounts
CREATE OR REPLACE PROCEDURE transfer_money(
    p_from_account VARCHAR(20),
    p_to_account VARCHAR(20),
    p_amount DECIMAL(15,2),
    p_description TEXT DEFAULT NULL
)
LANGUAGE plpgsql AS $$
DECLARE
    v_from_balance DECIMAL(15,2);
    v_txn_code VARCHAR(30);
BEGIN
    -- Check source account balance
    SELECT balance INTO v_from_balance FROM accounts WHERE id = p_from_account FOR UPDATE;

    IF v_from_balance IS NULL THEN
        RAISE EXCEPTION 'Source account % not found', p_from_account;
    END IF;

    IF v_from_balance < p_amount THEN
        RAISE EXCEPTION 'Insufficient funds. Available: %, Required: %', v_from_balance, p_amount;
    END IF;

    -- Lock destination account
    PERFORM 1 FROM accounts WHERE id = p_to_account FOR UPDATE;

    -- Generate transaction code
    v_txn_code := 'TXN-' || TO_CHAR(CURRENT_TIMESTAMP, 'YYYYMMDDHH24MISS') || '-' || FLOOR(RANDOM() * 1000);

    -- Debit source account
    UPDATE accounts SET balance = balance - p_amount, last_transaction_at = CURRENT_TIMESTAMP
    WHERE id = p_from_account;

    -- Credit destination account
    UPDATE accounts SET balance = balance + p_amount, last_transaction_at = CURRENT_TIMESTAMP
    WHERE id = p_to_account;

    -- Record transaction
    INSERT INTO account_transactions (transaction_code, from_account_id, to_account_id, transaction_type, amount, description, status)
    VALUES (v_txn_code, p_from_account, p_to_account, 'transfer', p_amount, p_description, 'completed');

    RAISE NOTICE 'Transfer completed. Transaction code: %', v_txn_code;
END;
$$;

-- Function: Get employee subordinates (recursive)
CREATE OR REPLACE FUNCTION get_subordinates(p_manager_id INTEGER)
RETURNS TABLE (
    employee_id INTEGER,
    employee_name TEXT,
    job_title VARCHAR(100),
    department VARCHAR(100),
    level INTEGER
) AS $$
BEGIN
    RETURN QUERY
    WITH RECURSIVE subordinates AS (
        SELECT e.id, e.first_name || ' ' || e.last_name AS full_name, e.job_title, e.department, 1 AS lvl
        FROM employees e
        WHERE e.manager_id = p_manager_id AND e.active = true

        UNION ALL

        SELECT e.id, e.first_name || ' ' || e.last_name, e.job_title, e.department, s.lvl + 1
        FROM employees e
        INNER JOIN subordinates s ON e.manager_id = s.id
        WHERE e.active = true
    )
    SELECT s.id, s.full_name, s.job_title, s.department, s.lvl
    FROM subordinates s
    ORDER BY s.lvl, s.full_name;
END;
$$ LANGUAGE plpgsql;

-- Function: Search products by JSON attribute
CREATE OR REPLACE FUNCTION search_products_by_attribute(p_key TEXT, p_value TEXT)
RETURNS TABLE (
    product_id INTEGER,
    product_name VARCHAR(255),
    sku VARCHAR(50),
    price DECIMAL(10,2),
    attribute_value TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT p.id, p.name, p.sku, p.price, p.attributes->>p_key
    FROM products p
    WHERE p.attributes->>p_key ILIKE '%' || p_value || '%'
      AND p.active = true;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- PART 17: TRIGGER FUNCTIONS (Triggers created at end of script)
-- ============================================================================

-- Trigger function: Audit log for customers
CREATE OR REPLACE FUNCTION audit_customer_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO audit_log (table_name, record_id, action, new_values)
        VALUES ('customers', NEW.id, 'INSERT', to_jsonb(NEW));
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO audit_log (table_name, record_id, action, old_values, new_values)
        VALUES ('customers', NEW.id, 'UPDATE', to_jsonb(OLD), to_jsonb(NEW));
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO audit_log (table_name, record_id, action, old_values)
        VALUES ('customers', OLD.id, 'DELETE', to_jsonb(OLD));
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger function: Update product timestamp
CREATE OR REPLACE FUNCTION update_product_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger function: Update customer timestamp
CREATE OR REPLACE FUNCTION update_customer_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger function: Update order timestamp
CREATE OR REPLACE FUNCTION update_order_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger function: Update stock on order
CREATE OR REPLACE FUNCTION update_stock_on_order()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE products SET stock_quantity = stock_quantity - NEW.quantity
        WHERE id = NEW.product_id;

        INSERT INTO stock_movements (product_id, movement_type, quantity, reference_type, reference_id, notes)
        VALUES (NEW.product_id, 'sale', -NEW.quantity, 'order_line', NEW.id, 'Order line created');

        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE products SET stock_quantity = stock_quantity + OLD.quantity
        WHERE id = OLD.product_id;

        INSERT INTO stock_movements (product_id, movement_type, quantity, reference_type, reference_id, notes)
        VALUES (OLD.product_id, 'return', OLD.quantity, 'order_line', OLD.id, 'Order line deleted');

        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- PART 18: INDEXES FOR PERFORMANCE
-- ============================================================================

-- Customers indexes
CREATE INDEX idx_customers_country ON customers(country_id);
CREATE INDEX idx_customers_status ON customers(status);
CREATE INDEX idx_customers_type ON customers(customer_type);
CREATE INDEX idx_customers_created ON customers(created_at);
CREATE INDEX idx_customers_email ON customers(email) WHERE email IS NOT NULL;

-- Products indexes
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_supplier ON products(supplier_id);
CREATE INDEX idx_products_active ON products(active);
CREATE INDEX idx_products_price ON products(price);
CREATE INDEX idx_products_stock ON products(stock_quantity);
CREATE INDEX idx_products_attributes ON products USING GIN (attributes);
CREATE INDEX idx_products_tags ON products USING GIN (tags);

-- Orders indexes
CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_orders_date ON orders(order_date);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_payment_status ON orders(payment_status);
CREATE INDEX idx_orders_total ON orders(total_amount);
CREATE INDEX idx_orders_metadata ON orders USING GIN (metadata);

-- Order lines indexes
CREATE INDEX idx_order_lines_order ON order_lines(order_id);
CREATE INDEX idx_order_lines_product ON order_lines(product_id);

-- Employees indexes
CREATE INDEX idx_employees_manager ON employees(manager_id);
CREATE INDEX idx_employees_department ON employees(department);
CREATE INDEX idx_employees_active ON employees(active);
CREATE INDEX idx_employees_hire_date ON employees(hire_date);

-- Accounts indexes
CREATE INDEX idx_accounts_customer ON accounts(customer_id);
CREATE INDEX idx_accounts_status ON accounts(status);
CREATE INDEX idx_accounts_type ON accounts(account_type);

-- Account transactions indexes
CREATE INDEX idx_transactions_from ON account_transactions(from_account_id);
CREATE INDEX idx_transactions_to ON account_transactions(to_account_id);
CREATE INDEX idx_transactions_date ON account_transactions(transaction_date);
CREATE INDEX idx_transactions_type ON account_transactions(transaction_type);

-- Audit log indexes
CREATE INDEX idx_audit_log_table ON audit_log(table_name);
CREATE INDEX idx_audit_log_record ON audit_log(record_id);
CREATE INDEX idx_audit_log_action ON audit_log(action);
CREATE INDEX idx_audit_log_date ON audit_log(changed_at);

-- Library schema indexes
CREATE INDEX idx_library_books_genre ON library.books(genre);
CREATE INDEX idx_library_copies_book ON library.book_copies(book_id);
CREATE INDEX idx_library_copies_status ON library.book_copies(status);
CREATE INDEX idx_library_loans_member ON library.loans(member_id);
CREATE INDEX idx_library_loans_status ON library.loans(status);

-- Stock movements indexes
CREATE INDEX idx_stock_movements_product ON stock_movements(product_id);
CREATE INDEX idx_stock_movements_date ON stock_movements(movement_date);
CREATE INDEX idx_stock_movements_type ON stock_movements(movement_type);

-- Categories index for hierarchy
CREATE INDEX idx_categories_parent ON categories(parent_id);

-- ============================================================================
-- PART 19: MATERIALIZED VIEW (For Analytics)
-- ============================================================================

CREATE MATERIALIZED VIEW IF NOT EXISTS analytics.sales_dashboard AS
SELECT
    DATE_TRUNC('day', o.order_date)::DATE AS sale_date,
    COUNT(DISTINCT o.id) AS total_orders,
    COUNT(DISTINCT o.customer_id) AS unique_customers,
    SUM(o.subtotal) AS gross_sales,
    SUM(o.discount_amount) AS total_discounts,
    SUM(o.tax_amount) AS total_tax,
    SUM(o.shipping_cost) AS total_shipping,
    SUM(o.total_amount) AS net_sales,
    AVG(o.total_amount) AS avg_order_value,
    SUM(ol.quantity) AS items_sold
FROM orders o
LEFT JOIN order_lines ol ON o.id = ol.order_id
WHERE o.status NOT IN ('cancelled', 'draft')
GROUP BY DATE_TRUNC('day', o.order_date)
ORDER BY sale_date;

CREATE UNIQUE INDEX idx_sales_dashboard_date ON analytics.sales_dashboard(sale_date);

-- ============================================================================
-- PART 20: SAMPLE ANALYTICS DATA
-- ============================================================================

-- Populate daily sales summary
INSERT INTO analytics.daily_sales (sale_date, order_count, item_count, unique_customers, gross_revenue, discounts, tax_collected, net_revenue, avg_order_value)
SELECT
    DATE_TRUNC('day', o.order_date)::DATE,
    COUNT(o.id),
    COALESCE(SUM(ol.quantity), 0),
    COUNT(DISTINCT o.customer_id),
    SUM(o.subtotal),
    SUM(o.discount_amount),
    SUM(o.tax_amount),
    SUM(o.total_amount),
    AVG(o.total_amount)
FROM orders o
LEFT JOIN order_lines ol ON o.id = ol.order_id
WHERE o.status NOT IN ('cancelled', 'draft')
GROUP BY DATE_TRUNC('day', o.order_date)
ON CONFLICT (sale_date) DO UPDATE SET
    order_count = EXCLUDED.order_count,
    item_count = EXCLUDED.item_count,
    unique_customers = EXCLUDED.unique_customers,
    gross_revenue = EXCLUDED.gross_revenue,
    discounts = EXCLUDED.discounts,
    tax_collected = EXCLUDED.tax_collected,
    net_revenue = EXCLUDED.net_revenue,
    avg_order_value = EXCLUDED.avg_order_value;

-- Customer Segments
INSERT INTO analytics.customer_segments (segment_name, description, min_orders, max_orders, min_spend, max_spend, color_code) VALUES
('New', 'New customers with 1 order', 1, 1, 0, 999999, '#90EE90'),
('Regular', 'Regular customers with 2-5 orders', 2, 5, 0, 999999, '#87CEEB'),
('Loyal', 'Loyal customers with 6-10 orders', 6, 10, 0, 999999, '#FFD700'),
('VIP', 'VIP customers with 10+ orders or $10k+ spent', 10, NULL, 10000, NULL, '#FF6347'),
('Dormant', 'Customers with no orders in 6+ months', 0, 0, 0, 0, '#D3D3D3');

-- ============================================================================
-- PART 20B: LOW STOCK PRODUCTS DATA
-- ============================================================================
-- Update products to have low stock for low_stock_products view

UPDATE products SET stock_quantity = 8 WHERE sku = 'COMP-001';  -- reorder_level = 10
UPDATE products SET stock_quantity = 3 WHERE sku = 'COMP-003';  -- reorder_level = 5
UPDATE products SET stock_quantity = 12 WHERE sku = 'PHONE-001'; -- reorder_level = 20
UPDATE products SET stock_quantity = 5 WHERE sku = 'AUDIO-001'; -- reorder_level = 15
UPDATE products SET stock_quantity = 2 WHERE sku = 'AUDIO-004'; -- reorder_level = 5
UPDATE products SET stock_quantity = 25 WHERE sku = 'MEN-001';  -- reorder_level = 100
UPDATE products SET stock_quantity = 8 WHERE sku = 'MEN-004';   -- reorder_level = 10
UPDATE products SET stock_quantity = 5 WHERE sku = 'WOM-003';   -- reorder_level = 12
UPDATE products SET stock_quantity = 5 WHERE sku = 'FURN-002';  -- reorder_level = 5
UPDATE products SET stock_quantity = 4 WHERE sku = 'FURN-003';  -- reorder_level = 8
UPDATE products SET stock_quantity = 2 WHERE sku = 'FIT-001';   -- reorder_level = 8
UPDATE products SET stock_quantity = 1 WHERE sku = 'SPORT-001'; -- reorder_level = 3
UPDATE products SET stock_quantity = 0 WHERE sku = 'SPORT-002'; -- reorder_level = 10

-- ============================================================================
-- PART 20C: STOCK MOVEMENTS DATA
-- ============================================================================
-- Populate stock_movements with inventory transaction history

INSERT INTO stock_movements (product_id, movement_type, quantity, unit_cost, reference_type, reference_id, warehouse_from, warehouse_to, movement_date, performed_by, notes) VALUES
-- Initial stock receipts (purchases)
(1, 'purchase', 100, 850.00, 'purchase_order', 1001, NULL, 'MAIN', '2023-01-15 09:00:00', 'inventory_mgr', 'Initial stock - ProBook Laptop'),
(2, 'purchase', 50, 650.00, 'purchase_order', 1001, NULL, 'MAIN', '2023-01-15 09:15:00', 'inventory_mgr', 'Initial stock - UltraBook Air'),
(3, 'purchase', 30, 1200.00, 'purchase_order', 1002, NULL, 'MAIN', '2023-01-20 10:00:00', 'inventory_mgr', 'Initial stock - Gaming Desktop'),
(5, 'purchase', 150, 750.00, 'purchase_order', 1003, NULL, 'MAIN', '2023-02-01 08:30:00', 'inventory_mgr', 'Initial stock - SmartPhone Pro Max'),
(8, 'purchase', 100, 180.00, 'purchase_order', 1004, NULL, 'MAIN', '2023-02-05 09:00:00', 'inventory_mgr', 'Initial stock - Wireless Headphones'),

-- Sales (outgoing)
(1, 'sale', -5, NULL, 'sales_order', 1, 'MAIN', NULL, '2023-02-10 14:22:00', 'sales_system', 'Order ORD-2023-0001'),
(1, 'sale', -3, NULL, 'sales_order', 8, 'MAIN', NULL, '2023-03-15 11:30:00', 'sales_system', 'Order ORD-2023-0008'),
(3, 'sale', -2, NULL, 'sales_order', 3, 'MAIN', NULL, '2023-02-08 10:45:00', 'sales_system', 'Order ORD-2023-0003'),
(5, 'sale', -10, NULL, 'sales_order', 5, 'MAIN', NULL, '2023-02-24 15:00:00', 'sales_system', 'Order ORD-2023-0005 - bulk order'),
(8, 'sale', -3, NULL, 'sales_order', 4, 'MAIN', NULL, '2023-02-14 09:20:00', 'sales_system', 'Order ORD-2023-0004'),

-- More purchases (restocking)
(1, 'purchase', 50, 840.00, 'purchase_order', 1010, NULL, 'MAIN', '2023-03-01 08:00:00', 'inventory_mgr', 'Restock - ProBook Laptop'),
(5, 'purchase', 80, 745.00, 'purchase_order', 1011, NULL, 'MAIN', '2023-03-10 09:00:00', 'inventory_mgr', 'Restock - SmartPhone Pro Max'),
(8, 'purchase', 50, 175.00, 'purchase_order', 1012, NULL, 'MAIN', '2023-03-15 10:00:00', 'inventory_mgr', 'Restock - Wireless Headphones'),

-- More sales throughout the year
(1, 'sale', -8, NULL, 'sales_order', 12, 'MAIN', NULL, '2023-04-18 13:45:00', 'sales_system', 'Order ORD-2023-0012'),
(3, 'sale', -5, NULL, 'sales_order', 25, 'MAIN', NULL, '2023-08-23 11:00:00', 'sales_system', 'Order ORD-2023-0025'),
(5, 'sale', -15, NULL, 'sales_order', 17, 'MAIN', NULL, '2023-06-13 10:30:00', 'sales_system', 'Order ORD-2023-0017 - VIP customer'),
(8, 'sale', -5, NULL, 'sales_order', 27, 'MAIN', NULL, '2023-09-13 14:15:00', 'sales_system', 'Order ORD-2023-0027'),

-- Adjustments (inventory counts, damages, etc.)
(1, 'adjustment', -2, NULL, NULL, NULL, 'MAIN', NULL, '2023-06-01 16:00:00', 'warehouse_mgr', 'Quarterly inventory count - shrinkage'),
(3, 'adjustment', -1, NULL, NULL, NULL, 'MAIN', NULL, '2023-06-01 16:15:00', 'warehouse_mgr', 'Damaged unit during handling'),
(5, 'adjustment', 3, NULL, NULL, NULL, 'MAIN', NULL, '2023-09-15 10:00:00', 'warehouse_mgr', 'Found units in wrong location'),
(12, 'damage', -2, NULL, NULL, NULL, 'MAIN', NULL, '2023-07-20 11:30:00', 'warehouse_mgr', 'Water damage - clothing items'),
(26, 'damage', -1, NULL, NULL, NULL, 'MAIN', NULL, '2023-08-10 14:00:00', 'warehouse_mgr', 'Damaged office chair - shipping'),

-- Transfers between warehouses
(1, 'transfer', -10, NULL, 'transfer', 5001, 'MAIN', 'WEST', '2023-05-01 08:00:00', 'logistics_mgr', 'Transfer to West warehouse'),
(1, 'transfer', 10, NULL, 'transfer', 5001, 'WEST', NULL, '2023-05-01 08:00:00', 'logistics_mgr', 'Transfer to West warehouse'),
(5, 'transfer', -20, NULL, 'transfer', 5002, 'MAIN', 'EAST', '2023-06-15 09:00:00', 'logistics_mgr', 'Transfer to East warehouse'),
(5, 'transfer', 20, NULL, 'transfer', 5002, 'EAST', NULL, '2023-06-15 09:00:00', 'logistics_mgr', 'Transfer to East warehouse'),

-- Returns
(1, 'return', 1, NULL, 'sales_order', 8, NULL, 'MAIN', '2023-03-25 11:00:00', 'returns_dept', 'Customer return - Order ORD-2023-0008'),
(5, 'return', 2, NULL, 'sales_order', 17, NULL, 'MAIN', '2023-06-25 14:30:00', 'returns_dept', 'Defective units returned'),
(8, 'return', 1, NULL, 'sales_order', 59, NULL, 'MAIN', '2024-01-20 10:00:00', 'returns_dept', 'Order ORD-2024-0021 - full refund'),

-- 2024 movements
(1, 'sale', -12, NULL, 'sales_order', 40, 'MAIN', NULL, '2024-01-13 11:20:00', 'sales_system', 'Order ORD-2024-0002'),
(1, 'sale', -15, NULL, 'sales_order', 51, 'MAIN', NULL, '2024-03-18 09:45:00', 'sales_system', 'Order ORD-2024-0013'),
(3, 'sale', -8, NULL, 'sales_order', 41, 'MAIN', NULL, '2024-01-18 14:00:00', 'sales_system', 'Order ORD-2024-0003'),
(5, 'sale', -20, NULL, 'sales_order', 44, 'MAIN', NULL, '2024-02-08 10:15:00', 'sales_system', 'Order ORD-2024-0006'),
(5, 'sale', -25, NULL, 'sales_order', 53, 'MAIN', NULL, '2024-03-28 11:30:00', 'sales_system', 'Order ORD-2024-0015 - large B2B order'),

-- Recent restocking
(1, 'purchase', 30, 835.00, 'purchase_order', 1050, NULL, 'MAIN', '2024-02-01 08:00:00', 'inventory_mgr', 'February restock - ProBook'),
(3, 'purchase', 15, 1180.00, 'purchase_order', 1051, NULL, 'MAIN', '2024-02-15 09:00:00', 'inventory_mgr', 'February restock - Gaming Desktop'),
(5, 'purchase', 60, 740.00, 'purchase_order', 1052, NULL, 'MAIN', '2024-03-01 08:30:00', 'inventory_mgr', 'March restock - SmartPhone Pro Max'),

-- Low stock alerts triggered movements
(26, 'purchase', 25, 178.00, 'purchase_order', 1055, NULL, 'MAIN', '2024-03-20 10:00:00', 'inventory_mgr', 'Emergency restock - Office Chair low'),
(32, 'purchase', 100, 17.50, 'purchase_order', 1056, NULL, 'MAIN', '2024-03-25 09:00:00', 'inventory_mgr', 'Restock - Yoga Mat Premium');

-- ============================================================================
-- PART 20D: AUDIT LOG DATA
-- ============================================================================
-- Populate audit_log with change history

INSERT INTO audit_log (table_name, record_id, action, old_values, new_values, changed_fields, changed_by, changed_at) VALUES
-- Customer changes
('customers', 1, 'INSERT', NULL,
 '{"id": 1, "name": "Acme Corporation", "email": "orders@acme.com", "status": "active", "customer_type": "business", "credit_limit": 50000.00}',
 ARRAY['id', 'name', 'email', 'status', 'customer_type', 'credit_limit'],
 'admin', '2021-03-15 09:00:00'),

('customers', 1, 'UPDATE',
 '{"credit_limit": 50000.00}',
 '{"credit_limit": 75000.00}',
 ARRAY['credit_limit'],
 'sales_manager', '2022-06-15 14:30:00'),

('customers', 1, 'UPDATE',
 '{"credit_limit": 75000.00}',
 '{"credit_limit": 100000.00}',
 ARRAY['credit_limit'],
 'sales_manager', '2023-12-01 10:00:00'),

('customers', 6, 'UPDATE',
 '{"customer_type": "business"}',
 '{"customer_type": "vip"}',
 ARRAY['customer_type'],
 'account_manager', '2022-01-10 11:15:00'),

('customers', 10, 'UPDATE',
 '{"customer_type": "business", "credit_limit": 50000.00}',
 '{"customer_type": "vip", "credit_limit": 75000.00}',
 ARRAY['customer_type', 'credit_limit'],
 'account_manager', '2022-03-20 09:30:00'),

('customers', 14, 'UPDATE',
 '{"status": "active"}',
 '{"status": "inactive"}',
 ARRAY['status'],
 'admin', '2023-06-01 16:45:00'),

('customers', 40, 'UPDATE',
 '{"status": "active"}',
 '{"status": "inactive"}',
 ARRAY['status'],
 'admin', '2023-01-15 10:00:00'),

('customers', 41, 'UPDATE',
 '{"status": "active"}',
 '{"status": "suspended"}',
 ARRAY['status'],
 'compliance_officer', '2022-08-20 14:00:00'),

-- Product changes
('products', 1, 'INSERT', NULL,
 '{"id": 1, "name": "ProBook Laptop 15\"", "sku": "COMP-001", "price": 1299.99, "stock_quantity": 100, "active": true}',
 ARRAY['id', 'name', 'sku', 'price', 'stock_quantity', 'active'],
 'product_manager', '2023-01-10 08:00:00'),

('products', 1, 'UPDATE',
 '{"price": 1299.99}',
 '{"price": 1199.99}',
 ARRAY['price'],
 'pricing_manager', '2023-06-01 09:00:00'),

('products', 1, 'UPDATE',
 '{"price": 1199.99}',
 '{"price": 1299.99}',
 ARRAY['price'],
 'pricing_manager', '2023-09-01 09:00:00'),

('products', 5, 'UPDATE',
 '{"price": 1099.99, "stock_quantity": 150}',
 '{"price": 1199.99, "stock_quantity": 80}',
 ARRAY['price', 'stock_quantity'],
 'inventory_system', '2023-08-15 10:30:00'),

('products', 47, 'UPDATE',
 '{"active": true}',
 '{"active": false}',
 ARRAY['active'],
 'product_manager', '2024-01-20 11:00:00'),

('products', 48, 'INSERT', NULL,
 '{"id": 48, "name": "Discontinued Gadget", "sku": "SPEC-002", "active": true}',
 ARRAY['id', 'name', 'sku', 'active'],
 'product_manager', '2023-06-01 10:00:00'),

('products', 48, 'UPDATE',
 '{"active": true}',
 '{"active": false}',
 ARRAY['active'],
 'product_manager', '2024-02-01 09:00:00'),

-- Order changes
('orders', 1, 'INSERT', NULL,
 '{"id": 1, "order_number": "ORD-2023-0001", "customer_id": 1, "status": "draft", "total_amount": 3092.97}',
 ARRAY['id', 'order_number', 'customer_id', 'status', 'total_amount'],
 'sales_system', '2023-01-15 10:00:00'),

('orders', 1, 'UPDATE',
 '{"status": "draft"}',
 '{"status": "confirmed"}',
 ARRAY['status'],
 'sales_rep', '2023-01-15 10:30:00'),

('orders', 1, 'UPDATE',
 '{"status": "confirmed"}',
 '{"status": "processing"}',
 ARRAY['status'],
 'warehouse_system', '2023-01-16 08:00:00'),

('orders', 1, 'UPDATE',
 '{"status": "processing", "shipped_date": null}',
 '{"status": "shipped", "shipped_date": "2023-01-18"}',
 ARRAY['status', 'shipped_date'],
 'shipping_dept', '2023-01-18 14:00:00'),

('orders', 1, 'UPDATE',
 '{"status": "shipped"}',
 '{"status": "delivered"}',
 ARRAY['status'],
 'delivery_confirmation', '2023-01-20 11:30:00'),

('orders', 58, 'UPDATE',
 '{"status": "confirmed"}',
 '{"status": "cancelled"}',
 ARRAY['status'],
 'customer_service', '2024-02-02 09:00:00'),

('orders', 59, 'UPDATE',
 '{"status": "delivered"}',
 '{"status": "returned"}',
 ARRAY['status'],
 'returns_dept', '2024-01-22 15:00:00'),

-- Employee changes
('employees', 28, 'INSERT', NULL,
 '{"id": 28, "first_name": "Ashley", "last_name": "Scott", "department": "Technology", "salary": 85000.00}',
 ARRAY['id', 'first_name', 'last_name', 'department', 'salary'],
 'hr_manager', '2021-01-15 09:00:00'),

('employees', 28, 'UPDATE',
 '{"salary": 85000.00}',
 '{"salary": 90000.00}',
 ARRAY['salary'],
 'hr_manager', '2022-01-01 00:00:00'),

('employees', 41, 'UPDATE',
 '{"active": true, "termination_date": null}',
 '{"active": false, "termination_date": "2022-12-31"}',
 ARRAY['active', 'termination_date'],
 'hr_manager', '2022-12-31 17:00:00'),

('employees', 42, 'UPDATE',
 '{"active": true, "termination_date": null}',
 '{"active": false, "termination_date": "2023-06-30"}',
 ARRAY['active', 'termination_date'],
 'hr_manager', '2023-06-30 17:00:00'),

-- Account changes (using customer_id as record_id since account.id is VARCHAR)
('accounts', 1, 'UPDATE',
 '{"account_id": "ACC-001", "balance": 100000.00}',
 '{"account_id": "ACC-001", "balance": 125000.00}',
 ARRAY['balance'],
 'banking_system', '2023-01-20 14:22:00'),

('accounts', 40, 'UPDATE',
 '{"account_id": "ACC-011", "status": "active", "balance": 5000.00}',
 '{"account_id": "ACC-011", "status": "frozen", "balance": 0.00}',
 ARRAY['status', 'balance'],
 'compliance_officer', '2023-09-01 10:00:00'),

-- Supplier changes
('suppliers', 1, 'UPDATE',
 '{"rating": 4.2}',
 '{"rating": 4.5}',
 ARRAY['rating'],
 'procurement_mgr', '2023-12-15 11:00:00'),

('suppliers', 3, 'UPDATE',
 '{"payment_terms": 45}',
 '{"payment_terms": 60}',
 ARRAY['payment_terms'],
 'procurement_mgr', '2023-06-01 14:00:00');

-- ============================================================================
-- REFRESH MATERIALIZED VIEW (after all data is loaded)
-- ============================================================================
REFRESH MATERIALIZED VIEW analytics.sales_dashboard;

-- ============================================================================
-- VERIFICATION QUERIES (commented out for production)
-- ============================================================================

-- Verify data counts
-- SELECT 'countries' AS table_name, COUNT(*) AS row_count FROM countries
-- UNION ALL SELECT 'customers', COUNT(*) FROM customers
-- UNION ALL SELECT 'categories', COUNT(*) FROM categories
-- UNION ALL SELECT 'suppliers', COUNT(*) FROM suppliers
-- UNION ALL SELECT 'products', COUNT(*) FROM products
-- UNION ALL SELECT 'orders', COUNT(*) FROM orders
-- UNION ALL SELECT 'order_lines', COUNT(*) FROM order_lines
-- UNION ALL SELECT 'employees', COUNT(*) FROM employees
-- UNION ALL SELECT 'accounts', COUNT(*) FROM accounts
-- UNION ALL SELECT 'library.books', COUNT(*) FROM library.books
-- UNION ALL SELECT 'library.members', COUNT(*) FROM library.members;

-- ============================================================================
-- PART 21: CREATE TRIGGERS (After all data is loaded)
-- ============================================================================
-- Triggers are created LAST to avoid firing during initial data insertion

-- Audit trigger for customers table
CREATE TRIGGER trg_audit_customers
AFTER INSERT OR UPDATE OR DELETE ON customers
FOR EACH ROW EXECUTE FUNCTION audit_customer_changes();

-- Timestamp update trigger for products
CREATE TRIGGER trg_product_updated
BEFORE UPDATE ON products
FOR EACH ROW EXECUTE FUNCTION update_product_timestamp();

-- Timestamp update trigger for customers
CREATE TRIGGER trg_customer_updated
BEFORE UPDATE ON customers
FOR EACH ROW EXECUTE FUNCTION update_customer_timestamp();

-- Timestamp update trigger for orders
CREATE TRIGGER trg_order_updated
BEFORE UPDATE ON orders
FOR EACH ROW EXECUTE FUNCTION update_order_timestamp();

-- ============================================================================
-- PART 22: ODOO-STYLE TABLES (For ERP training examples)
-- ============================================================================
-- These tables mirror Odoo ERP structure for training exercises

-- Drop existing Odoo tables if they exist
DROP TABLE IF EXISTS sale_order_line CASCADE;
DROP TABLE IF EXISTS sale_order CASCADE;
DROP TABLE IF EXISTS purchase_order_line CASCADE;
DROP TABLE IF EXISTS purchase_order CASCADE;
DROP TABLE IF EXISTS account_move_line CASCADE;
DROP TABLE IF EXISTS account_move CASCADE;
DROP TABLE IF EXISTS stock_move CASCADE;
DROP TABLE IF EXISTS stock_picking CASCADE;
DROP TABLE IF EXISTS stock_quant CASCADE;
DROP TABLE IF EXISTS stock_location CASCADE;
DROP TABLE IF EXISTS stock_warehouse CASCADE;
DROP TABLE IF EXISTS product_product CASCADE;
DROP TABLE IF EXISTS product_template CASCADE;
DROP TABLE IF EXISTS product_category CASCADE;
DROP TABLE IF EXISTS res_partner CASCADE;
DROP TABLE IF EXISTS res_country CASCADE;
DROP VIEW IF EXISTS account_invoice CASCADE;

-- -----------------------------------------------------------------------------
-- RES_COUNTRY TABLE
-- -----------------------------------------------------------------------------
CREATE TABLE res_country (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    code VARCHAR(3) NOT NULL UNIQUE,
    phone_code VARCHAR(10),
    currency_id INTEGER,
    create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    write_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO res_country (id, name, code, phone_code) VALUES
(1, 'United States', 'US', '+1'),
(2, 'Canada', 'CA', '+1'),
(3, 'United Kingdom', 'GB', '+44'),
(4, 'Germany', 'DE', '+49'),
(5, 'France', 'FR', '+33'),
(6, 'Spain', 'ES', '+34'),
(7, 'Italy', 'IT', '+39'),
(8, 'Netherlands', 'NL', '+31'),
(9, 'Belgium', 'BE', '+32'),
(10, 'Switzerland', 'CH', '+41'),
(11, 'Austria', 'AT', '+43'),
(12, 'Australia', 'AU', '+61'),
(13, 'Japan', 'JP', '+81'),
(14, 'China', 'CN', '+86'),
(15, 'South Korea', 'KR', '+82'),
(16, 'Brazil', 'BR', '+55'),
(17, 'Mexico', 'MX', '+52'),
(18, 'India', 'IN', '+91'),
(19, 'Turkey', 'TR', '+90'),
(20, 'Poland', 'PL', '+48'),
(233, 'United States (alt)', 'USA', '+1'),
(38, 'Canada (alt)', 'CAN', '+1'),
(73, 'Germany (alt)', 'DEU', '+49');

SELECT setval('res_country_id_seq', (SELECT MAX(id) FROM res_country));

-- -----------------------------------------------------------------------------
-- RES_PARTNER TABLE
-- -----------------------------------------------------------------------------
CREATE TABLE res_partner (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    display_name VARCHAR(255),
    email VARCHAR(255),
    phone VARCHAR(50),
    mobile VARCHAR(50),
    street VARCHAR(255),
    street2 VARCHAR(255),
    city VARCHAR(100),
    zip VARCHAR(20),
    country_id INTEGER REFERENCES res_country(id),
    vat VARCHAR(50),
    website VARCHAR(255),
    is_company BOOLEAN DEFAULT false,
    company_type VARCHAR(20) DEFAULT 'person' CHECK (company_type IN ('person', 'company')),
    customer_rank INTEGER DEFAULT 0,
    supplier_rank INTEGER DEFAULT 0,
    active BOOLEAN DEFAULT true,
    comment TEXT,
    credit_limit NUMERIC(15,2) DEFAULT 0,
    parent_id INTEGER REFERENCES res_partner(id),
    commercial_partner_id INTEGER,
    create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    write_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO res_partner (id, name, display_name, email, phone, mobile, street, city, zip, country_id, is_company, company_type, customer_rank, supplier_rank, vat, website, credit_limit, active, comment) VALUES
(1, 'Acme Corporation', 'Acme Corporation', 'info@acme.com', '+1-555-0100', '+1-555-0101', '123 Main Street', 'New York', '10001', 1, true, 'company', 10, 0, 'US123456789', 'www.acme.com', 50000.00, true, 'Premium customer since 2020'),
(2, 'Tech Solutions Inc', 'Tech Solutions Inc', 'contact@techsolutions.com', '+1-555-0102', NULL, '456 Tech Park', 'San Francisco', '94105', 1, true, 'company', 8, 0, 'US987654321', 'www.techsolutions.com', 75000.00, true, 'Technology partner'),
(3, 'Global Trading Ltd', 'Global Trading Ltd', 'sales@globaltrading.co.uk', '+44-20-7946-0958', NULL, '10 Commerce Street', 'London', 'EC2A 4NE', 3, true, 'company', 5, 2, 'GB123456789', 'www.globaltrading.co.uk', 100000.00, true, 'International distributor'),
(4, 'Deutsche Industrie GmbH', 'Deutsche Industrie GmbH', 'kontakt@deutscheindustrie.de', '+49-30-1234567', NULL, 'Industriestr. 42', 'Berlin', '10115', 4, true, 'company', 7, 0, 'DE123456789', 'www.deutscheindustrie.de', 60000.00, true, NULL),
(5, 'Maple Leaf Enterprises', 'Maple Leaf Enterprises', 'info@mapleleaf.ca', '+1-416-555-0123', NULL, '789 Queen Street', 'Toronto', 'M5V 2Z5', 2, true, 'company', 4, 0, 'CA987654321', 'www.mapleleaf.ca', 35000.00, true, NULL),
(6, 'Pacific Supply Co', 'Pacific Supply Co', 'orders@pacificsupply.com', '+1-555-0200', NULL, '100 Harbor Drive', 'Los Angeles', '90001', 1, true, 'company', 0, 10, 'US111222333', 'www.pacificsupply.com', 0, true, 'Main supplier for electronics'),
(7, 'Euro Parts Distributor', 'Euro Parts Distributor', 'sales@europarts.eu', '+33-1-2345-6789', NULL, '25 Rue de Commerce', 'Paris', '75001', 5, true, 'company', 0, 8, 'FR987123456', 'www.europarts.eu', 0, true, 'European supplier'),
(8, 'Asia Manufacturing Ltd', 'Asia Manufacturing Ltd', 'export@asiamfg.cn', '+86-21-1234-5678', NULL, '888 Industrial Zone', 'Shanghai', '200000', 14, true, 'company', 0, 15, 'CN123789456', 'www.asiamfg.cn', 0, true, 'Manufacturing partner'),
(9, 'John Smith', 'John Smith', 'john.smith@acme.com', '+1-555-0110', '+1-555-0111', NULL, 'New York', '10001', 1, false, 'person', 0, 0, NULL, NULL, 0, true, 'Purchasing Manager at Acme'),
(10, 'Sarah Johnson', 'Sarah Johnson', 'sarah.johnson@techsolutions.com', '+1-555-0120', NULL, NULL, 'San Francisco', '94105', 1, false, 'person', 0, 0, NULL, NULL, 0, true, 'CTO at Tech Solutions'),
(11, 'Michael Brown', 'Michael Brown', 'michael.brown@example.com', '+1-555-0130', '+1-555-0131', '789 Oak Avenue', 'Chicago', '60601', 1, false, 'person', 3, 0, NULL, NULL, 5000.00, true, 'Individual customer'),
(12, 'Emily Davis', 'Emily Davis', 'emily.davis@example.org', '+44-20-7946-1234', NULL, '5 High Street', 'Manchester', 'M1 1AD', 3, false, 'person', 2, 0, NULL, NULL, 3000.00, true, NULL),
(13, 'Hans Mueller', 'Hans Mueller', 'hans.mueller@deutscheindustrie.de', '+49-30-9876543', NULL, NULL, 'Berlin', '10115', 4, false, 'person', 0, 0, NULL, NULL, 0, true, 'Sales Director'),
(14, 'Marie Dupont', 'Marie Dupont', 'marie.dupont@europarts.eu', '+33-1-9876-5432', NULL, NULL, 'Paris', '75001', 5, false, 'person', 0, 0, NULL, NULL, 0, true, 'Account Manager'),
(15, 'George Wilson', 'George Wilson', 'george.wilson@example.com', '+1-555-0140', NULL, '321 Pine Road', 'Boston', '02101', 1, false, 'person', 1, 0, NULL, NULL, 2000.00, true, NULL),
(16, 'Nordic Systems AB', 'Nordic Systems AB', 'info@nordicsystems.se', '+46-8-123-4567', NULL, 'Sveavagen 100', 'Stockholm', '11350', 10, true, 'company', 6, 0, 'SE123456789', 'www.nordicsystems.se', 45000.00, true, NULL),
(17, 'Iberian Trade SL', 'Iberian Trade SL', 'comercial@iberiantrade.es', '+34-91-123-4567', NULL, 'Gran Via 50', 'Madrid', '28013', 6, true, 'company', 4, 0, 'ES123456789', 'www.iberiantrade.es', 30000.00, true, NULL),
(18, 'Aussie Imports Pty', 'Aussie Imports Pty', 'orders@aussieimports.com.au', '+61-2-1234-5678', NULL, '100 George Street', 'Sydney', '2000', 12, true, 'company', 5, 0, 'AU123456789', 'www.aussieimports.com.au', 40000.00, true, NULL),
(19, 'Tokyo Electronics Co', 'Tokyo Electronics Co', 'sales@tokyoelec.jp', '+81-3-1234-5678', NULL, '1-2-3 Shibuya', 'Tokyo', '150-0002', 13, true, 'company', 8, 3, 'JP123456789', 'www.tokyoelec.jp', 80000.00, true, 'Major Asian customer'),
(20, 'Brazilian Ventures SA', 'Brazilian Ventures SA', 'contato@brazilventures.com.br', '+55-11-1234-5678', NULL, 'Av Paulista 1000', 'Sao Paulo', '01310-100', 16, true, 'company', 3, 0, 'BR123456789', 'www.brazilventures.com.br', 25000.00, true, NULL),
(21, 'Alice Cooper', 'Alice Cooper', 'alice.cooper@example.com', '+1-555-0150', NULL, '555 Elm Street', 'Seattle', '98101', 1, false, 'person', 2, 0, NULL, NULL, 4000.00, true, NULL),
(22, 'Bob Martinez', 'Bob Martinez', NULL, '+1-555-0160', '+1-555-0161', '777 Cedar Lane', 'Miami', '33101', 1, false, 'person', 1, 0, NULL, NULL, 1500.00, true, 'Prefers phone contact'),
(23, 'Catherine Lee', 'Catherine Lee', 'catherine.lee@mapleleaf.ca', '+1-416-555-0456', NULL, NULL, 'Toronto', 'M5V 2Z5', 2, false, 'person', 0, 0, NULL, NULL, 0, true, 'Finance Director'),
(24, 'David Kim', 'David Kim', 'david.kim@tokyoelec.jp', '+81-3-9876-5432', NULL, NULL, 'Tokyo', '150-0002', 13, false, 'person', 0, 0, NULL, NULL, 0, true, 'International Sales'),
(25, 'Elena Rodriguez', 'Elena Rodriguez', 'elena.rodriguez@iberiantrade.es', '+34-91-987-6543', NULL, NULL, 'Madrid', '28013', 6, false, 'person', 0, 0, NULL, NULL, 0, true, NULL),
(26, 'Old Customer LLC', 'Old Customer LLC', 'info@oldcustomer.com', '+1-555-0999', NULL, '999 Past Street', 'Detroit', '48201', 1, true, 'company', 1, 0, 'US999888777', NULL, 10000.00, false, 'Account closed 2022'),
(27, 'Defunct Supplier Inc', 'Defunct Supplier Inc', NULL, NULL, NULL, NULL, 'Cleveland', '44101', 1, true, 'company', 0, 2, NULL, NULL, 0, false, 'Out of business');

UPDATE res_partner SET parent_id = 1, commercial_partner_id = 1 WHERE id = 9;
UPDATE res_partner SET parent_id = 2, commercial_partner_id = 2 WHERE id = 10;
UPDATE res_partner SET parent_id = 4, commercial_partner_id = 4 WHERE id = 13;
UPDATE res_partner SET parent_id = 7, commercial_partner_id = 7 WHERE id = 14;
UPDATE res_partner SET parent_id = 5, commercial_partner_id = 5 WHERE id = 23;
UPDATE res_partner SET parent_id = 19, commercial_partner_id = 19 WHERE id = 24;
UPDATE res_partner SET parent_id = 17, commercial_partner_id = 17 WHERE id = 25;

SELECT setval('res_partner_id_seq', (SELECT MAX(id) FROM res_partner));

-- -----------------------------------------------------------------------------
-- PRODUCT_CATEGORY TABLE
-- -----------------------------------------------------------------------------
CREATE TABLE product_category (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    complete_name VARCHAR(255),
    parent_id INTEGER REFERENCES product_category(id),
    parent_path VARCHAR(255),
    create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    write_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO product_category (id, name, complete_name, parent_id, parent_path) VALUES
(1, 'All', 'All', NULL, '1/'),
(2, 'Saleable', 'All / Saleable', 1, '1/2/'),
(3, 'Electronics', 'All / Saleable / Electronics', 2, '1/2/3/'),
(4, 'Computers', 'All / Saleable / Electronics / Computers', 3, '1/2/3/4/'),
(5, 'Phones', 'All / Saleable / Electronics / Phones', 3, '1/2/3/5/'),
(6, 'Accessories', 'All / Saleable / Electronics / Accessories', 3, '1/2/3/6/'),
(7, 'Office Supplies', 'All / Saleable / Office Supplies', 2, '1/2/7/'),
(8, 'Furniture', 'All / Saleable / Office Supplies / Furniture', 7, '1/2/7/8/'),
(9, 'Stationery', 'All / Saleable / Office Supplies / Stationery', 7, '1/2/7/9/'),
(10, 'Services', 'All / Saleable / Services', 2, '1/2/10/'),
(11, 'Consumables', 'All / Saleable / Consumables', 2, '1/2/11/'),
(12, 'Raw Materials', 'All / Raw Materials', 1, '1/12/'),
(13, 'Components', 'All / Raw Materials / Components', 12, '1/12/13/');

SELECT setval('product_category_id_seq', (SELECT MAX(id) FROM product_category));

-- -----------------------------------------------------------------------------
-- PRODUCT_TEMPLATE TABLE
-- -----------------------------------------------------------------------------
CREATE TABLE product_template (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    description_sale TEXT,
    default_code VARCHAR(50),
    barcode VARCHAR(50),
    list_price NUMERIC(15,2) DEFAULT 0,
    standard_price NUMERIC(15,2) DEFAULT 0,
    categ_id INTEGER REFERENCES product_category(id),
    type VARCHAR(20) DEFAULT 'consu' CHECK (type IN ('consu', 'service', 'product')),
    uom_id INTEGER DEFAULT 1,
    uom_po_id INTEGER DEFAULT 1,
    active BOOLEAN DEFAULT true,
    sale_ok BOOLEAN DEFAULT true,
    purchase_ok BOOLEAN DEFAULT true,
    invoice_policy VARCHAR(20) DEFAULT 'order',
    weight NUMERIC(10,3) DEFAULT 0,
    volume NUMERIC(10,3) DEFAULT 0,
    tracking VARCHAR(20) DEFAULT 'none' CHECK (tracking IN ('none', 'serial', 'lot')),
    create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    write_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO product_template (id, name, description, description_sale, default_code, barcode, list_price, standard_price, categ_id, type, active, sale_ok, purchase_ok, weight, tracking) VALUES
(1, 'Laptop Pro 15', 'High-performance laptop with 15" display', '15" Professional Laptop with Intel i7, 16GB RAM, 512GB SSD', 'COMP-LP15', '1234567890123', 1299.00, 850.00, 4, 'consu', true, true, true, 2.100, 'serial'),
(2, 'Desktop Workstation', 'Powerful desktop for professional use', 'Desktop Workstation with Intel i9, 32GB RAM, 1TB SSD', 'COMP-DW01', '1234567890124', 1899.00, 1200.00, 4, 'consu', true, true, true, 8.500, 'serial'),
(3, 'Laptop Budget 14', 'Entry-level laptop for everyday use', '14" Budget Laptop with Intel i5, 8GB RAM, 256GB SSD', 'COMP-LB14', '1234567890125', 599.00, 380.00, 4, 'consu', true, true, true, 1.800, 'serial'),
(4, 'All-in-One PC', 'Space-saving all-in-one computer', '24" All-in-One with AMD Ryzen, 16GB RAM, 512GB SSD', 'COMP-AIO1', '1234567890126', 999.00, 650.00, 4, 'consu', true, true, true, 6.200, 'serial'),
(5, 'Smartphone X12', 'Flagship smartphone', '6.5" OLED, 128GB, 5G capable smartphone', 'PHONE-X12', '2345678901234', 999.00, 650.00, 5, 'consu', true, true, true, 0.180, 'serial'),
(6, 'Smartphone Lite', 'Budget-friendly smartphone', '6.2" LCD, 64GB, 4G smartphone', 'PHONE-LT1', '2345678901235', 299.00, 180.00, 5, 'consu', true, true, true, 0.165, 'serial'),
(7, 'Business Phone Pro', 'Enterprise-grade smartphone', '6.7" AMOLED, 256GB, 5G, enhanced security', 'PHONE-BP1', '2345678901236', 1199.00, 780.00, 5, 'consu', true, true, true, 0.195, 'serial'),
(8, 'Wireless Mouse', 'Ergonomic wireless mouse', 'Wireless optical mouse with USB receiver', 'ACC-WM01', '3456789012345', 29.99, 12.00, 6, 'consu', true, true, true, 0.085, 'none'),
(9, 'Mechanical Keyboard', 'RGB mechanical keyboard', 'Full-size mechanical keyboard with Cherry MX switches', 'ACC-KB01', '3456789012346', 149.99, 75.00, 6, 'consu', true, true, true, 0.950, 'none'),
(10, 'USB-C Hub', '7-in-1 USB-C hub', 'USB-C hub with HDMI, USB-A, SD card reader', 'ACC-HUB7', '3456789012347', 59.99, 25.00, 6, 'consu', true, true, true, 0.120, 'none'),
(11, 'Laptop Stand', 'Adjustable aluminum laptop stand', 'Ergonomic laptop stand with adjustable height', 'ACC-LS01', '3456789012348', 49.99, 20.00, 6, 'consu', true, true, true, 0.850, 'none'),
(12, 'Webcam HD', '1080p HD webcam', 'HD webcam with built-in microphone', 'ACC-WC01', '3456789012349', 79.99, 35.00, 6, 'consu', true, true, true, 0.150, 'none'),
(13, 'Office Desk Executive', 'Large executive desk', 'Executive desk 180x80cm with cable management', 'FURN-DE01', '4567890123456', 599.00, 320.00, 8, 'consu', true, true, true, 45.000, 'none'),
(14, 'Office Chair Ergonomic', 'Ergonomic office chair', 'Adjustable ergonomic chair with lumbar support', 'FURN-CH01', '4567890123457', 399.00, 180.00, 8, 'consu', true, true, true, 15.000, 'none'),
(15, 'Meeting Table', '8-person meeting table', 'Conference table for 8 people, 240x120cm', 'FURN-MT01', '4567890123458', 899.00, 450.00, 8, 'consu', true, true, true, 65.000, 'none'),
(16, 'Filing Cabinet', '4-drawer filing cabinet', 'Metal filing cabinet with lock', 'FURN-FC01', '4567890123459', 249.00, 120.00, 8, 'consu', true, true, true, 35.000, 'none'),
(17, 'Printer Paper A4', 'A4 copy paper 500 sheets', 'Premium white A4 paper, 80gsm, 500 sheets', 'STAT-PA01', '5678901234567', 9.99, 4.50, 9, 'consu', true, true, true, 2.500, 'none'),
(18, 'Ballpoint Pens Box', 'Box of 50 ballpoint pens', 'Blue ink ballpoint pens, medium point', 'STAT-BP50', '5678901234568', 14.99, 6.00, 9, 'consu', true, true, true, 0.400, 'none'),
(19, 'Sticky Notes Pack', 'Sticky notes 12-pack', 'Yellow sticky notes, 76x76mm, 12 pads', 'STAT-SN12', '5678901234569', 12.99, 5.00, 9, 'consu', true, true, true, 0.350, 'none'),
(20, 'IT Support - Hourly', 'IT support service', 'Remote IT support per hour', 'SERV-IT01', NULL, 75.00, 0, 10, 'service', true, true, false, 0, 'none'),
(21, 'Installation Service', 'Product installation', 'On-site installation and setup service', 'SERV-IN01', NULL, 150.00, 0, 10, 'service', true, true, false, 0, 'none'),
(22, 'Training Session', 'Product training', '2-hour product training session', 'SERV-TR01', NULL, 200.00, 0, 10, 'service', true, true, false, 0, 'none'),
(23, 'Printer Toner Black', 'Black toner cartridge', 'High-yield black toner cartridge', 'CONS-TB01', '6789012345678', 89.99, 45.00, 11, 'consu', true, true, true, 0.800, 'lot'),
(24, 'Printer Toner Color Pack', 'CMY toner cartridge set', 'Cyan, Magenta, Yellow toner set', 'CONS-TC01', '6789012345679', 199.99, 100.00, 11, 'consu', true, true, true, 2.200, 'lot'),
(25, 'Circuit Board A', 'Main circuit board', 'PCB for laptop motherboard', 'RAW-CB01', NULL, 0, 85.00, 13, 'consu', true, false, true, 0.150, 'lot'),
(26, 'Display Panel 15', '15" LCD panel', 'LCD display panel for laptops', 'RAW-DP15', NULL, 0, 120.00, 13, 'consu', true, false, true, 0.450, 'serial'),
(27, 'Battery Pack Standard', 'Laptop battery pack', 'Li-ion battery pack 4500mAh', 'RAW-BP01', NULL, 0, 45.00, 13, 'consu', true, false, true, 0.350, 'lot'),
(28, 'Old Laptop Model', 'Discontinued laptop', 'Previous generation laptop', 'COMP-OLD1', '9999999999999', 499.00, 300.00, 4, 'consu', false, false, false, 2.500, 'serial');

SELECT setval('product_template_id_seq', (SELECT MAX(id) FROM product_template));

-- -----------------------------------------------------------------------------
-- PRODUCT_PRODUCT TABLE
-- -----------------------------------------------------------------------------
CREATE TABLE product_product (
    id SERIAL PRIMARY KEY,
    product_tmpl_id INTEGER NOT NULL REFERENCES product_template(id),
    default_code VARCHAR(50),
    barcode VARCHAR(50),
    active BOOLEAN DEFAULT true,
    combination_indices VARCHAR(255),
    create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    write_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO product_product (id, product_tmpl_id, default_code, barcode, active)
SELECT id, id, default_code, barcode, active FROM product_template;

SELECT setval('product_product_id_seq', (SELECT MAX(id) FROM product_product));

-- -----------------------------------------------------------------------------
-- STOCK_WAREHOUSE TABLE
-- -----------------------------------------------------------------------------
CREATE TABLE stock_warehouse (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    code VARCHAR(10) NOT NULL,
    partner_id INTEGER REFERENCES res_partner(id),
    active BOOLEAN DEFAULT true,
    create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    write_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO stock_warehouse (id, name, code, partner_id, active) VALUES
(1, 'Main Warehouse', 'WH', NULL, true),
(2, 'East Coast Distribution', 'EAST', NULL, true),
(3, 'West Coast Distribution', 'WEST', NULL, true);

SELECT setval('stock_warehouse_id_seq', (SELECT MAX(id) FROM stock_warehouse));

-- -----------------------------------------------------------------------------
-- STOCK_LOCATION TABLE
-- -----------------------------------------------------------------------------
CREATE TABLE stock_location (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    complete_name VARCHAR(255),
    location_id INTEGER REFERENCES stock_location(id),
    usage VARCHAR(20) DEFAULT 'internal' CHECK (usage IN ('supplier', 'view', 'internal', 'customer', 'inventory', 'production', 'transit')),
    warehouse_id INTEGER REFERENCES stock_warehouse(id),
    active BOOLEAN DEFAULT true,
    scrap_location BOOLEAN DEFAULT false,
    return_location BOOLEAN DEFAULT false,
    create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    write_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO stock_location (id, name, complete_name, location_id, usage, warehouse_id, active, scrap_location, return_location) VALUES
(1, 'Physical Locations', 'Physical Locations', NULL, 'view', NULL, true, false, false),
(2, 'Partner Locations', 'Partner Locations', NULL, 'view', NULL, true, false, false),
(3, 'Virtual Locations', 'Virtual Locations', NULL, 'view', NULL, true, false, false),
(4, 'Vendors', 'Partner Locations / Vendors', 2, 'supplier', NULL, true, false, false),
(5, 'Customers', 'Partner Locations / Customers', 2, 'customer', NULL, true, false, false),
(6, 'WH', 'WH', 1, 'view', 1, true, false, false),
(7, 'Stock', 'WH / Stock', 6, 'internal', 1, true, false, false),
(8, 'Input', 'WH / Input', 6, 'internal', 1, true, false, false),
(9, 'Quality Control', 'WH / Quality Control', 6, 'internal', 1, true, false, false),
(10, 'Output', 'WH / Output', 6, 'internal', 1, true, false, false),
(11, 'EAST', 'EAST', 1, 'view', 2, true, false, false),
(12, 'Stock', 'EAST / Stock', 11, 'internal', 2, true, false, false),
(13, 'WEST', 'WEST', 1, 'view', 3, true, false, false),
(14, 'Stock', 'WEST / Stock', 13, 'internal', 3, true, false, false),
(15, 'Inventory Adjustment', 'Virtual Locations / Inventory Adjustment', 3, 'inventory', NULL, true, false, false),
(16, 'Scrap', 'Virtual Locations / Scrap', 3, 'inventory', NULL, true, true, false),
(17, 'Returns', 'Virtual Locations / Returns', 3, 'internal', NULL, true, false, true);

SELECT setval('stock_location_id_seq', (SELECT MAX(id) FROM stock_location));

-- -----------------------------------------------------------------------------
-- STOCK_QUANT TABLE
-- -----------------------------------------------------------------------------
CREATE TABLE stock_quant (
    id SERIAL PRIMARY KEY,
    product_id INTEGER NOT NULL REFERENCES product_product(id),
    location_id INTEGER NOT NULL REFERENCES stock_location(id),
    quantity NUMERIC(15,3) DEFAULT 0,
    reserved_quantity NUMERIC(15,3) DEFAULT 0,
    inventory_quantity NUMERIC(15,3),
    inventory_date DATE,
    lot_id INTEGER,
    package_id INTEGER,
    in_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    write_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO stock_quant (product_id, location_id, quantity, reserved_quantity) VALUES
(1, 7, 25, 3), (2, 7, 10, 1), (3, 7, 45, 5), (4, 7, 15, 2),
(5, 7, 80, 10), (6, 7, 150, 15), (7, 7, 30, 5), (8, 7, 200, 20),
(9, 7, 75, 8), (10, 7, 120, 12), (11, 7, 50, 5), (12, 7, 60, 6),
(13, 7, 8, 1), (14, 7, 20, 3), (15, 7, 4, 0), (16, 7, 12, 2),
(17, 7, 500, 50), (18, 7, 100, 10), (19, 7, 80, 8),
(23, 7, 150, 15), (24, 7, 60, 6), (25, 7, 200, 0), (26, 7, 100, 0), (27, 7, 300, 0),
(1, 12, 15, 2), (3, 12, 30, 4), (5, 12, 50, 8), (6, 12, 100, 10), (8, 12, 150, 15), (17, 12, 300, 30), (23, 12, 80, 8),
(1, 14, 20, 3), (2, 14, 5, 1), (3, 14, 35, 5), (5, 14, 60, 7), (6, 14, 120, 12), (7, 14, 25, 4), (8, 14, 180, 18), (14, 14, 15, 2);

-- -----------------------------------------------------------------------------
-- SALE_ORDER TABLE
-- -----------------------------------------------------------------------------
CREATE TABLE sale_order (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    partner_id INTEGER NOT NULL REFERENCES res_partner(id),
    partner_invoice_id INTEGER REFERENCES res_partner(id),
    partner_shipping_id INTEGER REFERENCES res_partner(id),
    date_order TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    validity_date DATE,
    commitment_date DATE,
    state VARCHAR(20) DEFAULT 'draft' CHECK (state IN ('draft', 'sent', 'sale', 'done', 'cancel')),
    amount_untaxed NUMERIC(15,2) DEFAULT 0,
    amount_tax NUMERIC(15,2) DEFAULT 0,
    amount_total NUMERIC(15,2) DEFAULT 0,
    note TEXT,
    client_order_ref VARCHAR(100),
    origin VARCHAR(100),
    warehouse_id INTEGER REFERENCES stock_warehouse(id),
    user_id INTEGER,
    team_id INTEGER,
    company_id INTEGER DEFAULT 1,
    create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    write_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO sale_order (id, name, partner_id, partner_invoice_id, partner_shipping_id, date_order, validity_date, state, amount_untaxed, amount_tax, amount_total, note, client_order_ref, warehouse_id) VALUES
(1, 'SO001', 1, 1, 1, '2024-01-15 10:30:00', '2024-02-15', 'sale', 3247.00, 324.70, 3571.70, 'Rush delivery requested', 'PO-ACME-001', 1),
(2, 'SO002', 2, 2, 2, '2024-01-18 14:15:00', '2024-02-18', 'sale', 2597.98, 259.80, 2857.78, NULL, 'TS-2024-001', 1),
(3, 'SO003', 3, 3, 3, '2024-01-20 09:00:00', '2024-02-20', 'done', 5695.00, 569.50, 6264.50, 'International shipping', 'GT-UK-001', 1),
(4, 'SO004', 4, 4, 4, '2024-01-22 11:45:00', '2024-02-22', 'sale', 1498.00, 149.80, 1647.80, NULL, 'DI-DE-2024-001', 1),
(5, 'SO005', 5, 5, 5, '2024-01-25 16:30:00', '2024-02-25', 'sale', 899.97, 90.00, 989.97, NULL, NULL, 1),
(6, 'SO006', 11, 11, 11, '2024-02-01 10:00:00', '2024-03-01', 'sale', 1628.98, 162.90, 1791.88, 'Individual customer', NULL, 2),
(7, 'SO007', 16, 16, 16, '2024-02-05 13:20:00', '2024-03-05', 'sale', 4197.00, 419.70, 4616.70, NULL, 'NS-SE-001', 1),
(8, 'SO008', 17, 17, 17, '2024-02-08 09:30:00', '2024-03-08', 'sale', 2398.00, 239.80, 2637.80, NULL, 'IT-ES-001', 1),
(9, 'SO009', 18, 18, 18, '2024-02-10 15:00:00', '2024-03-10', 'done', 3497.00, 349.70, 3846.70, 'Express shipping to Australia', 'AI-AU-001', 3),
(10, 'SO010', 19, 19, 19, '2024-02-12 08:45:00', '2024-03-12', 'sale', 8893.00, 889.30, 9782.30, 'Major order from Tokyo', 'TE-JP-001', 1),
(11, 'SO011', 20, 20, 20, '2024-02-15 11:00:00', '2024-03-15', 'draft', 1798.00, 179.80, 1977.80, NULL, NULL, 1),
(12, 'SO012', 12, 12, 12, '2024-02-18 14:30:00', '2024-03-18', 'draft', 629.98, 63.00, 692.98, 'Awaiting payment confirmation', NULL, 1),
(13, 'SO013', 15, 15, 15, '2024-02-20 10:15:00', '2024-03-20', 'sent', 2897.00, 289.70, 3186.70, 'Quote sent to customer', NULL, 2),
(14, 'SO014', 21, 21, 21, '2024-02-22 09:00:00', '2024-03-22', 'cancel', 599.00, 59.90, 658.90, 'Customer cancelled', NULL, 1),
(15, 'SO015', 1, 1, 1, '2024-02-25 15:30:00', '2024-03-25', 'sale', 5147.97, 514.80, 5662.77, NULL, 'PO-ACME-002', 1),
(16, 'SO016', 2, 2, 2, '2024-02-28 11:20:00', '2024-03-28', 'sale', 1349.97, 135.00, 1484.97, NULL, 'TS-2024-002', 1),
(17, 'SO017', 19, 19, 19, '2024-03-01 09:45:00', '2024-03-31', 'sale', 11990.00, 1199.00, 13189.00, 'Repeat order', 'TE-JP-002', 1),
(18, 'SO018', 3, 3, 3, '2024-03-05 14:00:00', '2024-04-05', 'sale', 4396.00, 439.60, 4835.60, NULL, 'GT-UK-002', 1),
(19, 'SO019', 4, 4, 4, '2024-03-08 10:30:00', '2024-04-08', 'draft', 2198.00, 219.80, 2417.80, 'Pending approval', 'DI-DE-2024-002', 1),
(20, 'SO020', 16, 16, 16, '2024-03-10 16:00:00', '2024-04-10', 'sale', 6595.00, 659.50, 7254.50, NULL, 'NS-SE-002', 1);

SELECT setval('sale_order_id_seq', (SELECT MAX(id) FROM sale_order));

-- -----------------------------------------------------------------------------
-- SALE_ORDER_LINE TABLE
-- -----------------------------------------------------------------------------
CREATE TABLE sale_order_line (
    id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL REFERENCES sale_order(id) ON DELETE CASCADE,
    product_id INTEGER NOT NULL REFERENCES product_product(id),
    name TEXT,
    product_uom_qty NUMERIC(15,3) DEFAULT 1,
    qty_delivered NUMERIC(15,3) DEFAULT 0,
    qty_invoiced NUMERIC(15,3) DEFAULT 0,
    price_unit NUMERIC(15,2) DEFAULT 0,
    discount NUMERIC(5,2) DEFAULT 0,
    price_subtotal NUMERIC(15,2) DEFAULT 0,
    price_tax NUMERIC(15,2) DEFAULT 0,
    price_total NUMERIC(15,2) DEFAULT 0,
    state VARCHAR(20) DEFAULT 'draft',
    create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    write_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO sale_order_line (order_id, product_id, name, product_uom_qty, qty_delivered, qty_invoiced, price_unit, discount, price_subtotal, price_tax, price_total, state) VALUES
(1, 1, 'Laptop Pro 15', 2, 2, 2, 1299.00, 0, 2598.00, 259.80, 2857.80, 'sale'),
(1, 8, 'Wireless Mouse', 3, 3, 3, 29.99, 0, 89.97, 9.00, 98.97, 'sale'),
(1, 9, 'Mechanical Keyboard', 2, 2, 2, 149.99, 0, 299.98, 30.00, 329.98, 'sale'),
(1, 10, 'USB-C Hub', 2, 2, 2, 59.99, 0, 119.98, 12.00, 131.98, 'sale'),
(1, 21, 'Installation Service', 1, 1, 1, 150.00, 0, 150.00, 15.00, 165.00, 'sale'),
(2, 5, 'Smartphone X12', 2, 2, 2, 999.00, 0, 1998.00, 199.80, 2197.80, 'sale'),
(2, 6, 'Smartphone Lite', 2, 2, 2, 299.00, 0, 598.00, 59.80, 657.80, 'sale'),
(3, 1, 'Laptop Pro 15', 3, 3, 3, 1299.00, 0, 3897.00, 389.70, 4286.70, 'done'),
(3, 2, 'Desktop Workstation', 1, 1, 1, 1899.00, 5, 1804.05, 180.41, 1984.46, 'done'),
(4, 3, 'Laptop Budget 14', 2, 1, 1, 599.00, 0, 1198.00, 119.80, 1317.80, 'sale'),
(4, 8, 'Wireless Mouse', 10, 10, 10, 29.99, 0, 299.90, 30.00, 329.90, 'sale'),
(5, 6, 'Smartphone Lite', 3, 3, 3, 299.99, 0, 899.97, 90.00, 989.97, 'sale'),
(6, 1, 'Laptop Pro 15', 1, 1, 1, 1299.00, 0, 1299.00, 129.90, 1428.90, 'sale'),
(6, 8, 'Wireless Mouse', 1, 1, 1, 29.99, 0, 29.99, 3.00, 32.99, 'sale'),
(6, 9, 'Mechanical Keyboard', 1, 1, 1, 149.99, 0, 149.99, 15.00, 164.99, 'sale'),
(6, 11, 'Laptop Stand', 1, 1, 1, 49.99, 0, 49.99, 5.00, 54.99, 'sale'),
(7, 2, 'Desktop Workstation', 2, 2, 2, 1899.00, 0, 3798.00, 379.80, 4177.80, 'sale'),
(7, 14, 'Office Chair Ergonomic', 1, 1, 1, 399.00, 0, 399.00, 39.90, 438.90, 'sale'),
(8, 4, 'All-in-One PC', 2, 2, 2, 999.00, 0, 1998.00, 199.80, 2197.80, 'sale'),
(8, 14, 'Office Chair Ergonomic', 1, 1, 1, 399.00, 0, 399.00, 39.90, 438.90, 'sale'),
(9, 1, 'Laptop Pro 15', 2, 2, 2, 1299.00, 0, 2598.00, 259.80, 2857.80, 'done'),
(9, 7, 'Business Phone Pro', 1, 1, 1, 1199.00, 5, 1139.05, 113.91, 1252.96, 'done'),
(10, 1, 'Laptop Pro 15', 5, 3, 3, 1299.00, 0, 6495.00, 649.50, 7144.50, 'sale'),
(10, 5, 'Smartphone X12', 2, 2, 2, 999.00, 0, 1998.00, 199.80, 2197.80, 'sale'),
(10, 14, 'Office Chair Ergonomic', 1, 1, 1, 399.00, 0, 399.00, 39.90, 438.90, 'sale'),
(11, 3, 'Laptop Budget 14', 3, 0, 0, 599.00, 0, 1797.00, 179.70, 1976.70, 'draft'),
(12, 8, 'Wireless Mouse', 5, 0, 0, 29.99, 0, 149.95, 15.00, 164.95, 'draft'),
(12, 10, 'USB-C Hub', 3, 0, 0, 59.99, 0, 179.97, 18.00, 197.97, 'draft'),
(12, 17, 'Printer Paper A4', 10, 0, 0, 9.99, 0, 99.90, 10.00, 109.90, 'draft'),
(12, 18, 'Ballpoint Pens Box', 5, 0, 0, 14.99, 0, 74.95, 7.50, 82.45, 'draft'),
(12, 19, 'Sticky Notes Pack', 10, 0, 0, 12.99, 0, 129.90, 13.00, 142.90, 'draft'),
(13, 1, 'Laptop Pro 15', 2, 0, 0, 1299.00, 0, 2598.00, 259.80, 2857.80, 'sent'),
(13, 6, 'Smartphone Lite', 1, 0, 0, 299.00, 0, 299.00, 29.90, 328.90, 'sent'),
(14, 3, 'Laptop Budget 14', 1, 0, 0, 599.00, 0, 599.00, 59.90, 658.90, 'cancel'),
(15, 5, 'Smartphone X12', 3, 3, 3, 999.00, 0, 2997.00, 299.70, 3296.70, 'sale'),
(15, 7, 'Business Phone Pro', 2, 2, 2, 1199.00, 5, 2278.10, 227.81, 2505.91, 'sale'),
(16, 8, 'Wireless Mouse', 15, 15, 15, 29.99, 0, 449.85, 45.00, 494.85, 'sale'),
(16, 10, 'USB-C Hub', 15, 15, 15, 59.99, 0, 899.85, 90.00, 989.85, 'sale'),
(17, 1, 'Laptop Pro 15', 5, 5, 5, 1299.00, 0, 6495.00, 649.50, 7144.50, 'sale'),
(17, 2, 'Desktop Workstation', 2, 2, 2, 1899.00, 0, 3798.00, 379.80, 4177.80, 'sale'),
(17, 7, 'Business Phone Pro', 1, 1, 1, 1199.00, 0, 1199.00, 119.90, 1318.90, 'sale'),
(18, 4, 'All-in-One PC', 4, 4, 4, 999.00, 0, 3996.00, 399.60, 4395.60, 'sale'),
(18, 14, 'Office Chair Ergonomic', 1, 1, 1, 399.00, 0, 399.00, 39.90, 438.90, 'sale'),
(19, 2, 'Desktop Workstation', 1, 0, 0, 1899.00, 0, 1899.00, 189.90, 2088.90, 'draft'),
(19, 6, 'Smartphone Lite', 1, 0, 0, 299.00, 0, 299.00, 29.90, 328.90, 'draft'),
(20, 2, 'Desktop Workstation', 3, 3, 3, 1899.00, 0, 5697.00, 569.70, 6266.70, 'sale'),
(20, 14, 'Office Chair Ergonomic', 2, 2, 2, 399.00, 0, 798.00, 79.80, 877.80, 'sale');

-- -----------------------------------------------------------------------------
-- PURCHASE_ORDER TABLE
-- -----------------------------------------------------------------------------
CREATE TABLE purchase_order (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    partner_id INTEGER NOT NULL REFERENCES res_partner(id),
    date_order TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_approve TIMESTAMP,
    date_planned TIMESTAMP,
    state VARCHAR(20) DEFAULT 'draft' CHECK (state IN ('draft', 'sent', 'to approve', 'purchase', 'done', 'cancel')),
    amount_untaxed NUMERIC(15,2) DEFAULT 0,
    amount_tax NUMERIC(15,2) DEFAULT 0,
    amount_total NUMERIC(15,2) DEFAULT 0,
    notes TEXT,
    origin VARCHAR(100),
    warehouse_id INTEGER REFERENCES stock_warehouse(id),
    company_id INTEGER DEFAULT 1,
    create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    write_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO purchase_order (id, name, partner_id, date_order, date_approve, date_planned, state, amount_untaxed, amount_tax, amount_total, notes, origin, warehouse_id) VALUES
(1, 'PO001', 6, '2024-01-10 09:00:00', '2024-01-11 10:00:00', '2024-01-20 09:00:00', 'done', 25500.00, 2550.00, 28050.00, 'Monthly electronics order', NULL, 1),
(2, 'PO002', 7, '2024-01-15 11:30:00', '2024-01-16 09:00:00', '2024-01-30 09:00:00', 'done', 18750.00, 1875.00, 20625.00, 'European parts order', NULL, 1),
(3, 'PO003', 8, '2024-01-20 14:00:00', '2024-01-22 10:00:00', '2024-02-15 09:00:00', 'purchase', 42500.00, 4250.00, 46750.00, 'Manufacturing components - Q1', NULL, 1),
(4, 'PO004', 6, '2024-02-01 10:00:00', '2024-02-02 11:00:00', '2024-02-10 09:00:00', 'done', 17000.00, 1700.00, 18700.00, 'Urgent restock', 'SO010', 1),
(5, 'PO005', 7, '2024-02-15 09:30:00', NULL, '2024-03-01 09:00:00', 'sent', 22500.00, 2250.00, 24750.00, 'Pending supplier confirmation', NULL, 1),
(6, 'PO006', 8, '2024-02-20 13:00:00', NULL, '2024-03-15 09:00:00', 'draft', 35000.00, 3500.00, 38500.00, 'Q2 planning order', NULL, 1);

SELECT setval('purchase_order_id_seq', (SELECT MAX(id) FROM purchase_order));

-- -----------------------------------------------------------------------------
-- PURCHASE_ORDER_LINE TABLE
-- -----------------------------------------------------------------------------
CREATE TABLE purchase_order_line (
    id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL REFERENCES purchase_order(id) ON DELETE CASCADE,
    product_id INTEGER NOT NULL REFERENCES product_product(id),
    name TEXT,
    product_qty NUMERIC(15,3) DEFAULT 1,
    qty_received NUMERIC(15,3) DEFAULT 0,
    qty_invoiced NUMERIC(15,3) DEFAULT 0,
    price_unit NUMERIC(15,2) DEFAULT 0,
    price_subtotal NUMERIC(15,2) DEFAULT 0,
    state VARCHAR(20) DEFAULT 'draft',
    create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    write_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO purchase_order_line (order_id, product_id, name, product_qty, qty_received, qty_invoiced, price_unit, price_subtotal, state) VALUES
(1, 1, 'Laptop Pro 15', 20, 20, 20, 850.00, 17000.00, 'done'),
(1, 3, 'Laptop Budget 14', 20, 20, 20, 380.00, 7600.00, 'done'),
(1, 8, 'Wireless Mouse', 75, 75, 75, 12.00, 900.00, 'done'),
(2, 9, 'Mechanical Keyboard', 50, 50, 50, 75.00, 3750.00, 'done'),
(2, 10, 'USB-C Hub', 100, 100, 100, 25.00, 2500.00, 'done'),
(2, 11, 'Laptop Stand', 50, 50, 50, 20.00, 1000.00, 'done'),
(2, 12, 'Webcam HD', 50, 50, 50, 35.00, 1750.00, 'done'),
(2, 23, 'Printer Toner Black', 100, 100, 100, 45.00, 4500.00, 'done'),
(2, 24, 'Printer Toner Color Pack', 50, 50, 50, 100.00, 5000.00, 'done'),
(3, 25, 'Circuit Board A', 200, 100, 100, 85.00, 17000.00, 'purchase'),
(3, 26, 'Display Panel 15', 100, 50, 50, 120.00, 12000.00, 'purchase'),
(3, 27, 'Battery Pack Standard', 300, 150, 150, 45.00, 13500.00, 'purchase'),
(4, 5, 'Smartphone X12', 20, 20, 20, 650.00, 13000.00, 'done'),
(4, 6, 'Smartphone Lite', 20, 20, 20, 180.00, 3600.00, 'done'),
(5, 9, 'Mechanical Keyboard', 100, 0, 0, 75.00, 7500.00, 'sent'),
(5, 10, 'USB-C Hub', 200, 0, 0, 25.00, 5000.00, 'sent'),
(5, 11, 'Laptop Stand', 100, 0, 0, 20.00, 2000.00, 'sent'),
(5, 23, 'Printer Toner Black', 150, 0, 0, 45.00, 6750.00, 'sent'),
(6, 25, 'Circuit Board A', 300, 0, 0, 85.00, 25500.00, 'draft'),
(6, 27, 'Battery Pack Standard', 200, 0, 0, 45.00, 9000.00, 'draft');

-- -----------------------------------------------------------------------------
-- STOCK_PICKING TABLE
-- -----------------------------------------------------------------------------
CREATE TABLE stock_picking (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    partner_id INTEGER REFERENCES res_partner(id),
    origin VARCHAR(100),
    location_id INTEGER NOT NULL REFERENCES stock_location(id),
    location_dest_id INTEGER NOT NULL REFERENCES stock_location(id),
    picking_type_code VARCHAR(20) CHECK (picking_type_code IN ('incoming', 'outgoing', 'internal')),
    state VARCHAR(20) DEFAULT 'draft' CHECK (state IN ('draft', 'waiting', 'confirmed', 'assigned', 'done', 'cancel')),
    scheduled_date TIMESTAMP,
    date_done TIMESTAMP,
    note TEXT,
    create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    write_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO stock_picking (id, name, partner_id, origin, location_id, location_dest_id, picking_type_code, state, scheduled_date, date_done, note) VALUES
(1, 'WH/IN/00001', 6, 'PO001', 4, 7, 'incoming', 'done', '2024-01-20 09:00:00', '2024-01-20 14:30:00', 'Received from Pacific Supply'),
(2, 'WH/IN/00002', 7, 'PO002', 4, 7, 'incoming', 'done', '2024-01-30 09:00:00', '2024-01-30 11:00:00', 'Received from Euro Parts'),
(3, 'WH/IN/00003', 8, 'PO003', 4, 7, 'incoming', 'assigned', '2024-02-15 09:00:00', NULL, 'Partial delivery expected'),
(4, 'WH/IN/00004', 6, 'PO004', 4, 7, 'incoming', 'done', '2024-02-10 09:00:00', '2024-02-10 16:00:00', 'Urgent restock received'),
(5, 'WH/OUT/00001', 1, 'SO001', 7, 5, 'outgoing', 'done', '2024-01-17 09:00:00', '2024-01-17 15:00:00', 'Delivered to Acme Corporation'),
(6, 'WH/OUT/00002', 2, 'SO002', 7, 5, 'outgoing', 'done', '2024-01-20 09:00:00', '2024-01-20 14:00:00', 'Delivered to Tech Solutions'),
(7, 'WH/OUT/00003', 3, 'SO003', 7, 5, 'outgoing', 'done', '2024-01-25 09:00:00', '2024-01-25 12:00:00', 'International shipment'),
(8, 'WH/OUT/00004', 4, 'SO004', 7, 5, 'outgoing', 'assigned', '2024-01-25 09:00:00', NULL, 'Partial delivery'),
(9, 'WH/OUT/00005', 5, 'SO005', 7, 5, 'outgoing', 'done', '2024-01-27 09:00:00', '2024-01-27 11:00:00', NULL),
(10, 'WH/OUT/00006', 11, 'SO006', 12, 5, 'outgoing', 'done', '2024-02-03 09:00:00', '2024-02-03 14:00:00', 'East Coast delivery'),
(11, 'WH/OUT/00007', 16, 'SO007', 7, 5, 'outgoing', 'done', '2024-02-07 09:00:00', '2024-02-07 16:00:00', NULL),
(12, 'WH/OUT/00008', 17, 'SO008', 7, 5, 'outgoing', 'done', '2024-02-10 09:00:00', '2024-02-10 13:00:00', NULL),
(13, 'WH/OUT/00009', 18, 'SO009', 14, 5, 'outgoing', 'done', '2024-02-12 09:00:00', '2024-02-12 17:00:00', 'West Coast to Australia'),
(14, 'WH/OUT/00010', 19, 'SO010', 7, 5, 'outgoing', 'assigned', '2024-02-15 09:00:00', NULL, 'Large order - partial shipment'),
(15, 'WH/INT/00001', NULL, NULL, 7, 12, 'internal', 'done', '2024-02-01 09:00:00', '2024-02-01 11:00:00', 'Transfer to East Coast'),
(16, 'WH/INT/00002', NULL, NULL, 7, 14, 'internal', 'done', '2024-02-05 09:00:00', '2024-02-05 10:00:00', 'Transfer to West Coast'),
(17, 'WH/INT/00003', NULL, NULL, 7, 12, 'internal', 'confirmed', '2024-02-20 09:00:00', NULL, 'Scheduled transfer');

SELECT setval('stock_picking_id_seq', (SELECT MAX(id) FROM stock_picking));

-- -----------------------------------------------------------------------------
-- STOCK_MOVE TABLE
-- -----------------------------------------------------------------------------
CREATE TABLE stock_move (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255),
    picking_id INTEGER REFERENCES stock_picking(id),
    product_id INTEGER NOT NULL REFERENCES product_product(id),
    product_uom_qty NUMERIC(15,3) DEFAULT 0,
    quantity_done NUMERIC(15,3) DEFAULT 0,
    location_id INTEGER NOT NULL REFERENCES stock_location(id),
    location_dest_id INTEGER NOT NULL REFERENCES stock_location(id),
    state VARCHAR(20) DEFAULT 'draft' CHECK (state IN ('draft', 'waiting', 'confirmed', 'assigned', 'done', 'cancel')),
    origin VARCHAR(100),
    date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    write_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO stock_move (picking_id, name, product_id, product_uom_qty, quantity_done, location_id, location_dest_id, state, origin, date) VALUES
(1, 'Laptop Pro 15', 1, 20, 20, 4, 7, 'done', 'PO001', '2024-01-20 14:30:00'),
(1, 'Laptop Budget 14', 3, 20, 20, 4, 7, 'done', 'PO001', '2024-01-20 14:30:00'),
(1, 'Wireless Mouse', 8, 75, 75, 4, 7, 'done', 'PO001', '2024-01-20 14:30:00'),
(2, 'Mechanical Keyboard', 9, 50, 50, 4, 7, 'done', 'PO002', '2024-01-30 11:00:00'),
(2, 'USB-C Hub', 10, 100, 100, 4, 7, 'done', 'PO002', '2024-01-30 11:00:00'),
(2, 'Laptop Stand', 11, 50, 50, 4, 7, 'done', 'PO002', '2024-01-30 11:00:00'),
(5, 'Laptop Pro 15', 1, 2, 2, 7, 5, 'done', 'SO001', '2024-01-17 15:00:00'),
(5, 'Wireless Mouse', 8, 3, 3, 7, 5, 'done', 'SO001', '2024-01-17 15:00:00'),
(5, 'Mechanical Keyboard', 9, 2, 2, 7, 5, 'done', 'SO001', '2024-01-17 15:00:00'),
(6, 'Smartphone X12', 5, 2, 2, 7, 5, 'done', 'SO002', '2024-01-20 14:00:00'),
(6, 'Smartphone Lite', 6, 2, 2, 7, 5, 'done', 'SO002', '2024-01-20 14:00:00'),
(7, 'Laptop Pro 15', 1, 3, 3, 7, 5, 'done', 'SO003', '2024-01-25 12:00:00'),
(7, 'Desktop Workstation', 2, 1, 1, 7, 5, 'done', 'SO003', '2024-01-25 12:00:00'),
(15, 'Laptop Pro 15', 1, 15, 15, 7, 12, 'done', NULL, '2024-02-01 11:00:00'),
(15, 'Laptop Budget 14', 3, 30, 30, 7, 12, 'done', NULL, '2024-02-01 11:00:00'),
(15, 'Smartphone X12', 5, 50, 50, 7, 12, 'done', NULL, '2024-02-01 11:00:00'),
(16, 'Laptop Pro 15', 1, 20, 20, 7, 14, 'done', NULL, '2024-02-05 10:00:00'),
(16, 'Desktop Workstation', 2, 5, 5, 7, 14, 'done', NULL, '2024-02-05 10:00:00'),
(16, 'Business Phone Pro', 7, 25, 25, 7, 14, 'done', NULL, '2024-02-05 10:00:00');

-- -----------------------------------------------------------------------------
-- ACCOUNT_MOVE TABLE
-- -----------------------------------------------------------------------------
CREATE TABLE account_move (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50),
    move_type VARCHAR(20) DEFAULT 'entry' CHECK (move_type IN ('entry', 'out_invoice', 'out_refund', 'in_invoice', 'in_refund', 'out_receipt', 'in_receipt')),
    partner_id INTEGER REFERENCES res_partner(id),
    invoice_origin VARCHAR(100),
    invoice_date DATE,
    invoice_date_due DATE,
    state VARCHAR(20) DEFAULT 'draft' CHECK (state IN ('draft', 'posted', 'cancel')),
    payment_state VARCHAR(20) DEFAULT 'not_paid' CHECK (payment_state IN ('not_paid', 'in_payment', 'paid', 'partial', 'reversed', 'invoicing_legacy')),
    amount_untaxed NUMERIC(15,2) DEFAULT 0,
    amount_tax NUMERIC(15,2) DEFAULT 0,
    amount_total NUMERIC(15,2) DEFAULT 0,
    amount_residual NUMERIC(15,2) DEFAULT 0,
    currency_id INTEGER DEFAULT 1,
    company_id INTEGER DEFAULT 1,
    ref VARCHAR(255),
    narration TEXT,
    create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    write_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO account_move (id, name, move_type, partner_id, invoice_origin, invoice_date, invoice_date_due, state, payment_state, amount_untaxed, amount_tax, amount_total, amount_residual, ref) VALUES
(1, 'INV/2024/0001', 'out_invoice', 1, 'SO001', '2024-01-17', '2024-02-17', 'posted', 'paid', 3247.00, 324.70, 3571.70, 0, 'PO-ACME-001'),
(2, 'INV/2024/0002', 'out_invoice', 2, 'SO002', '2024-01-20', '2024-02-20', 'posted', 'paid', 2597.98, 259.80, 2857.78, 0, 'TS-2024-001'),
(3, 'INV/2024/0003', 'out_invoice', 3, 'SO003', '2024-01-25', '2024-02-25', 'posted', 'paid', 5695.00, 569.50, 6264.50, 0, 'GT-UK-001'),
(4, 'INV/2024/0004', 'out_invoice', 4, 'SO004', '2024-01-25', '2024-02-25', 'posted', 'partial', 1498.00, 149.80, 1647.80, 823.90, 'DI-DE-2024-001'),
(5, 'INV/2024/0005', 'out_invoice', 5, 'SO005', '2024-01-27', '2024-02-27', 'posted', 'paid', 899.97, 90.00, 989.97, 0, NULL),
(6, 'INV/2024/0006', 'out_invoice', 11, 'SO006', '2024-02-03', '2024-03-03', 'posted', 'paid', 1628.98, 162.90, 1791.88, 0, NULL),
(7, 'INV/2024/0007', 'out_invoice', 16, 'SO007', '2024-02-07', '2024-03-07', 'posted', 'not_paid', 4197.00, 419.70, 4616.70, 4616.70, 'NS-SE-001'),
(8, 'INV/2024/0008', 'out_invoice', 17, 'SO008', '2024-02-10', '2024-03-10', 'posted', 'not_paid', 2398.00, 239.80, 2637.80, 2637.80, 'IT-ES-001'),
(9, 'INV/2024/0009', 'out_invoice', 18, 'SO009', '2024-02-12', '2024-03-12', 'posted', 'paid', 3497.00, 349.70, 3846.70, 0, 'AI-AU-001'),
(10, 'INV/2024/0010', 'out_invoice', 19, 'SO010', '2024-02-15', '2024-03-15', 'posted', 'partial', 8893.00, 889.30, 9782.30, 4891.15, 'TE-JP-001'),
(11, 'BILL/2024/0001', 'in_invoice', 6, 'PO001', '2024-01-22', '2024-02-22', 'posted', 'paid', 25500.00, 2550.00, 28050.00, 0, 'PS-INV-2024-001'),
(12, 'BILL/2024/0002', 'in_invoice', 7, 'PO002', '2024-02-01', '2024-03-01', 'posted', 'paid', 18750.00, 1875.00, 20625.00, 0, 'EP-INV-2024-001'),
(13, 'BILL/2024/0003', 'in_invoice', 8, 'PO003', '2024-02-20', '2024-03-20', 'posted', 'partial', 21250.00, 2125.00, 23375.00, 11687.50, 'AM-INV-2024-001'),
(14, 'BILL/2024/0004', 'in_invoice', 6, 'PO004', '2024-02-12', '2024-03-12', 'posted', 'paid', 17000.00, 1700.00, 18700.00, 0, 'PS-INV-2024-002'),
(15, 'RINV/2024/0001', 'out_refund', 21, 'SO014', '2024-02-25', '2024-02-25', 'posted', 'paid', 599.00, 59.90, 658.90, 0, 'Cancellation credit');

SELECT setval('account_move_id_seq', (SELECT MAX(id) FROM account_move));

-- -----------------------------------------------------------------------------
-- ACCOUNT_MOVE_LINE TABLE
-- -----------------------------------------------------------------------------
CREATE TABLE account_move_line (
    id SERIAL PRIMARY KEY,
    move_id INTEGER NOT NULL REFERENCES account_move(id) ON DELETE CASCADE,
    product_id INTEGER REFERENCES product_product(id),
    name TEXT,
    quantity NUMERIC(15,3) DEFAULT 1,
    price_unit NUMERIC(15,2) DEFAULT 0,
    discount NUMERIC(5,2) DEFAULT 0,
    price_subtotal NUMERIC(15,2) DEFAULT 0,
    price_total NUMERIC(15,2) DEFAULT 0,
    account_id INTEGER,
    partner_id INTEGER REFERENCES res_partner(id),
    debit NUMERIC(15,2) DEFAULT 0,
    credit NUMERIC(15,2) DEFAULT 0,
    balance NUMERIC(15,2) DEFAULT 0,
    exclude_from_invoice_tab BOOLEAN DEFAULT false,
    create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    write_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO account_move_line (move_id, product_id, name, quantity, price_unit, discount, price_subtotal, price_total, partner_id, debit, credit, balance, exclude_from_invoice_tab) VALUES
(1, 1, 'Laptop Pro 15', 2, 1299.00, 0, 2598.00, 2857.80, 1, 2857.80, 0, 2857.80, false),
(1, 8, 'Wireless Mouse', 3, 29.99, 0, 89.97, 98.97, 1, 98.97, 0, 98.97, false),
(1, 9, 'Mechanical Keyboard', 2, 149.99, 0, 299.98, 329.98, 1, 329.98, 0, 329.98, false),
(1, NULL, 'Accounts Receivable', 1, 0, 0, 0, 0, 1, 0, 3571.70, -3571.70, true),
(2, 5, 'Smartphone X12', 2, 999.00, 0, 1998.00, 2197.80, 2, 2197.80, 0, 2197.80, false),
(2, 6, 'Smartphone Lite', 2, 299.00, 0, 598.00, 657.80, 2, 657.80, 0, 657.80, false),
(2, NULL, 'Accounts Receivable', 1, 0, 0, 0, 0, 2, 0, 2857.78, -2857.78, true),
(11, 1, 'Laptop Pro 15', 20, 850.00, 0, 17000.00, 18700.00, 6, 0, 18700.00, -18700.00, false),
(11, 3, 'Laptop Budget 14', 20, 380.00, 0, 7600.00, 8360.00, 6, 0, 8360.00, -8360.00, false),
(11, 8, 'Wireless Mouse', 75, 12.00, 0, 900.00, 990.00, 6, 0, 990.00, -990.00, false),
(11, NULL, 'Accounts Payable', 1, 0, 0, 0, 0, 6, 28050.00, 0, 28050.00, true);

-- -----------------------------------------------------------------------------
-- ACCOUNT_INVOICE VIEW (Compatibility)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW account_invoice AS
SELECT
    id,
    name AS number,
    partner_id,
    invoice_date AS date_invoice,
    invoice_date_due AS date_due,
    amount_untaxed,
    amount_tax,
    amount_total,
    amount_residual AS residual,
    state,
    move_type AS type
FROM account_move
WHERE move_type IN ('out_invoice', 'out_refund', 'in_invoice', 'in_refund');

-- -----------------------------------------------------------------------------
-- INDEXES FOR ODOO TABLES
-- -----------------------------------------------------------------------------
CREATE INDEX idx_res_partner_active ON res_partner(active);
CREATE INDEX idx_res_partner_country ON res_partner(country_id);
CREATE INDEX idx_res_partner_customer ON res_partner(customer_rank) WHERE customer_rank > 0;
CREATE INDEX idx_res_partner_supplier ON res_partner(supplier_rank) WHERE supplier_rank > 0;
CREATE INDEX idx_res_partner_email ON res_partner(email) WHERE email IS NOT NULL;
CREATE INDEX idx_product_template_categ ON product_template(categ_id);
CREATE INDEX idx_product_template_active ON product_template(active);
CREATE INDEX idx_product_template_type ON product_template(type);
CREATE INDEX idx_stock_quant_product ON stock_quant(product_id);
CREATE INDEX idx_stock_quant_location ON stock_quant(location_id);
CREATE INDEX idx_sale_order_partner ON sale_order(partner_id);
CREATE INDEX idx_sale_order_state ON sale_order(state);
CREATE INDEX idx_sale_order_date ON sale_order(date_order);
CREATE INDEX idx_sale_order_line_order ON sale_order_line(order_id);
CREATE INDEX idx_sale_order_line_product ON sale_order_line(product_id);
CREATE INDEX idx_purchase_order_partner ON purchase_order(partner_id);
CREATE INDEX idx_purchase_order_state ON purchase_order(state);
CREATE INDEX idx_stock_picking_partner ON stock_picking(partner_id);
CREATE INDEX idx_stock_picking_state ON stock_picking(state);
CREATE INDEX idx_account_move_partner ON account_move(partner_id);
CREATE INDEX idx_account_move_state ON account_move(state);
CREATE INDEX idx_account_move_type ON account_move(move_type);

-- ============================================================================
-- END OF SQL BOOTCAMP DATABASE SETUP
-- ============================================================================

-- Usage:
-- createdb bootcamp
-- psql -U postgres -d bootcamp -f bootcamp_db.sql

-- Connection string:
-- postgresql://localhost:5432/bootcamp

-- COMMENT ON DATABASE bootcamp IS 'SQL Bootcamp unified database for Day 1-5 exercises';
-- Note: Commented out for Neon compatibility (database-level comments may be restricted)
