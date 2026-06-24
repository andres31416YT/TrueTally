CREATE TABLE IF NOT EXISTS elections (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT TRUE,
    is_published BOOLEAN DEFAULT FALSE,
    visibility VARCHAR(20) DEFAULT 'public',
    election_type VARCHAR(50) DEFAULT 'general',
    election_category VARCHAR(50) DEFAULT 'general',
    password VARCHAR(255),
    is_official BOOLEAN DEFAULT FALSE,
    created_by VARCHAR(255),
    status VARCHAR(20) DEFAULT 'Borrador'
);

CREATE TABLE IF NOT EXISTS candidates (
    id BIGSERIAL PRIMARY KEY,
    election_id VARCHAR(50) NOT NULL REFERENCES elections(id),
    candidate_external_id VARCHAR(50),
    party_id VARCHAR(50),
    name VARCHAR(50) NOT NULL,
    party VARCHAR(50) NOT NULL,
    category VARCHAR(50) DEFAULT 'general',
    bio TEXT,
    photo_url TEXT,
    code VARCHAR(10)
);

CREATE TABLE IF NOT EXISTS voters (
    id BIGSERIAL PRIMARY KEY,
    election_id VARCHAR(50) NOT NULL REFERENCES elections(id),
    email VARCHAR(255) NOT NULL,
    public_key VARCHAR(255) NOT NULL,
    password_hash VARCHAR(255),
    role VARCHAR(20) DEFAULT 'user',
    registered_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    has_voted BOOLEAN DEFAULT FALSE,
    has_created_password BOOLEAN DEFAULT FALSE,
    UNIQUE(election_id, email),
    UNIQUE(election_id, public_key)
);

CREATE TABLE IF NOT EXISTS users (
    id BIGSERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    public_key VARCHAR(255),
    password_hash VARCHAR(255),
    role VARCHAR(20) DEFAULT 'user',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS audit_log (
    id BIGSERIAL PRIMARY KEY,
    action VARCHAR(100) NOT NULL,
    details TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
