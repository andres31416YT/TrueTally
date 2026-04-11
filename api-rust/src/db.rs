use sqlx::{PgPool, Row};

pub async fn init_db(database_url: &str) -> Result<PgPool, sqlx::Error> {
    let pool = PgPool::connect(database_url).await?;
    
    sqlx::query(
        r#"
        CREATE TABLE IF NOT EXISTS elections (
            id VARCHAR(50) PRIMARY KEY,
            name VARCHAR(255) NOT NULL,
            description TEXT,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            is_active BOOLEAN DEFAULT TRUE,
            admin_code VARCHAR(50) NOT NULL,
            election_type VARCHAR(50) DEFAULT 'general',
            election_category VARCHAR(50) DEFAULT 'general',
            password VARCHAR(255),
            is_official BOOLEAN DEFAULT FALSE,
            created_by VARCHAR(255)
        )
        "#,
    )
    .execute(&pool)
    .await?;

    sqlx::query(
        r#"
        CREATE TABLE IF NOT EXISTS candidates (
            id BIGSERIAL PRIMARY KEY,
            election_id VARCHAR(50) NOT NULL REFERENCES elections(id),
            candidate_external_id VARCHAR(50),
            party_id VARCHAR(50),
            name VARCHAR(255) NOT NULL,
            party VARCHAR(255) NOT NULL,
            category VARCHAR(50) DEFAULT 'general',
            bio TEXT,
            photo_url TEXT
        )
        "#,
    )
    .execute(&pool)
    .await?;

    sqlx::query(
        r#"
        CREATE TABLE IF NOT EXISTS voters (
            id BIGSERIAL PRIMARY KEY,
            election_id VARCHAR(50) NOT NULL REFERENCES elections(id),
            dni VARCHAR(20) NOT NULL,
            dni_verifier VARCHAR(1) NOT NULL,
            public_key VARCHAR(255) NOT NULL,
            email VARCHAR(255),
            password_hash VARCHAR(255),
            role VARCHAR(20) DEFAULT 'user',
            registered_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            has_voted BOOLEAN DEFAULT FALSE,
            has_created_password BOOLEAN DEFAULT FALSE,
            UNIQUE(election_id, dni),
            UNIQUE(election_id, public_key)
        )
        "#,
    )
    .execute(&pool)
    .await?;

    sqlx::query("ALTER TABLE voters ALTER COLUMN dni DROP NOT NULL")
        .execute(&pool)
        .await?;

    sqlx::query("ALTER TABLE voters ALTER COLUMN election_id DROP NOT NULL")
        .execute(&pool)
        .await?;

    sqlx::query(
        r#"
        DO $$
        BEGIN
            IF NOT EXISTS (
                SELECT 1 FROM information_schema.columns 
                WHERE table_name = 'voters' AND column_name = 'dni'
            ) THEN
                ALTER TABLE voters ADD COLUMN dni VARCHAR(20);
            END IF;
        END $$;
        "#,
    )
    .execute(&pool)
    .await?;

    sqlx::query(
        r#"
        DO $$
        BEGIN
            IF NOT EXISTS (
                SELECT 1 FROM information_schema.columns 
                WHERE table_name = 'voters' AND column_name = 'election_id'
            ) THEN
                ALTER TABLE voters ADD COLUMN election_id VARCHAR(50);
            END IF;
        END $$;
        "#,
    )
    .execute(&pool)
    .await?;

    sqlx::query(
        r#"
        DO $$
        BEGIN
            IF NOT EXISTS (
                SELECT 1 FROM information_schema.table_constraints 
                WHERE constraint_name = 'voters_election_id_dni_key'
            ) THEN
                ALTER TABLE voters ADD UNIQUE(election_id, dni);
            END IF;
        END $$;
        "#,
    )
    .execute(&pool)
    .await?;

    sqlx::query(
        r#"
        CREATE TABLE IF NOT EXISTS users (
            id BIGSERIAL PRIMARY KEY,
            dni VARCHAR(20) UNIQUE NOT NULL,
            dni_verifier VARCHAR(1) NOT NULL,
            public_key VARCHAR(255),
            password_hash VARCHAR(255),
            role VARCHAR(20) DEFAULT 'user',
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        )
        "#,
    )
    .execute(&pool)
    .await?;

    sqlx::query(
        r#"
        DO $$
        BEGIN
            IF NOT EXISTS (
                SELECT 1 FROM users WHERE dni = '00000000'
            ) THEN
                INSERT INTO users (dni, dni_verifier, role) VALUES ('00000000', '0', 'sudo_admin');
            END IF;
        END $$;
        "#,
    )
    .execute(&pool)
    .await?;

    sqlx::query(
        r#"
        CREATE TABLE IF NOT EXISTS audit_log (
            id SERIAL PRIMARY KEY,
            action VARCHAR(255) NOT NULL,
            details TEXT,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        )
        "#,
    )
    .execute(&pool)
    .await?;

    Ok(pool)
}

pub async fn create_election(
    pool: &PgPool,
    id: &str,
    name: &str,
    description: Option<&str>,
    admin_code: &str,
    election_type: &str,
    election_category: &str,
    password: Option<&str>,
    created_by: Option<&str>,
) -> Result<(), sqlx::Error> {
    let is_official = matches!(created_by, Some("sudo_admin") | Some("admin"));
    
    sqlx::query(
        r#"
        INSERT INTO elections (id, name, description, admin_code, election_type, election_category, password, is_official, created_by)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
        "#,
    )
    .bind(id)
    .bind(name)
    .bind(description)
    .bind(admin_code)
    .bind(election_type)
    .bind(election_category)
    .bind(password)
    .bind(is_official)
    .bind(created_by)
    .execute(pool)
    .await?;

    Ok(())
}

pub async fn get_election(pool: &PgPool, id: &str) -> Result<Option<(String, String, Option<String>, bool)>, sqlx::Error> {
    let row = sqlx::query(
        r#"
        SELECT id, name, description, is_active FROM elections WHERE id = $1
        "#,
    )
    .bind(id)
    .fetch_optional(pool)
    .await?;

    Ok(row.map(|r| (
        r.get::<String, _>("id"),
        r.get::<String, _>("name"),
        r.get::<Option<String>, _>("description"),
        r.get::<bool, _>("is_active"),
    )))
}

pub async fn list_elections(pool: &PgPool) -> Result<Vec<(String, String, Option<String>, bool)>, sqlx::Error> {
    let rows = sqlx::query(
        r#"
        SELECT id, name, description, is_active FROM elections ORDER BY created_at DESC
        "#,
    )
    .fetch_all(pool)
    .await?;

    Ok(rows.into_iter().map(|r| (
        r.get::<String, _>("id"),
        r.get::<String, _>("name"),
        r.get::<Option<String>, _>("description"),
        r.get::<bool, _>("is_active"),
    )).collect())
}

pub async fn register_voter(
    pool: &PgPool,
    election_id: &str,
    dni: &str,
    dni_verifier: &str,
    public_key: &str,
    email: Option<&str>,
) -> Result<i64, sqlx::Error> {
    let row = sqlx::query(
        r#"
        INSERT INTO voters (election_id, dni, dni_verifier, public_key, email)
        VALUES ($1, $2, $3, $4, $5)
        RETURNING id
        "#,
    )
    .bind(election_id)
    .bind(dni)
    .bind(dni_verifier)
    .bind(public_key)
    .bind(email)
    .fetch_one(pool)
    .await?;

    Ok(row.get("id"))
}

pub async fn get_voter_by_public_key(
    pool: &PgPool,
    election_id: &str,
    public_key: &str,
) -> Result<Option<(String, String, bool)>, sqlx::Error> {
    let row = sqlx::query(
        r#"
        SELECT name, email, has_voted FROM voters WHERE election_id = $1 AND public_key = $2
        "#,
    )
    .bind(election_id)
    .bind(public_key)
    .fetch_optional(pool)
    .await?;

    Ok(row.map(|r| (r.get("name"), r.get("email"), r.get("has_voted"))))
}

pub async fn check_voter_by_dni(
    pool: &PgPool,
    election_id: &str,
    dni: &str,
) -> Result<Option<(String, bool)>, sqlx::Error> {
    let row = sqlx::query(
        r#"
        SELECT name, has_voted FROM voters WHERE election_id = $1 AND dni = $2
        "#,
    )
    .bind(election_id)
    .bind(dni)
    .fetch_optional(pool)
    .await?;

    Ok(row.map(|r| (r.get("name"), r.get("has_voted"))))
}

pub async fn candidate_exists(
    pool: &PgPool,
    election_id: &str,
    name: &str,
) -> Result<bool, sqlx::Error> {
    let row = sqlx::query(
        r#"
        SELECT EXISTS(SELECT 1 FROM candidates WHERE election_id = $1 AND LOWER(name) = LOWER($2)) as exists
        "#,
    )
    .bind(election_id)
    .bind(name)
    .fetch_one(pool)
    .await?;

    Ok(row.get("exists"))
}

pub async fn mark_voter_voted(pool: &PgPool, election_id: &str, public_key: &str) -> Result<(), sqlx::Error> {
    sqlx::query(
        r#"
        UPDATE voters SET has_voted = TRUE WHERE election_id = $1 AND public_key = $2
        "#,
    )
    .bind(election_id)
    .bind(public_key)
    .execute(pool)
    .await?;

    Ok(())
}

pub async fn list_candidates(pool: &PgPool, election_id: &str) -> Result<Vec<(i64, String, String, Option<String>, Option<String>, String, Option<String>, Option<String>)>, sqlx::Error> {
    let rows = sqlx::query(
        r#"
        SELECT id, candidate_external_id, party_id, name, party, category, bio, photo_url FROM candidates WHERE election_id = $1 ORDER BY id
        "#,
    )
    .bind(election_id)
    .fetch_all(pool)
    .await?;

    Ok(rows.into_iter().map(|r| (
        r.get::<i64, _>("id"),
        r.get::<Option<String>, _>("candidate_external_id").unwrap_or_default(),
        r.get::<Option<String>, _>("party_id").unwrap_or_default(),
        r.get("name"),
        r.get("party"),
        r.get("category"),
        r.get("bio"),
        r.get("photo_url")
    )).collect())
}

pub async fn add_candidate(
    pool: &PgPool,
    election_id: &str,
    candidate_external_id: Option<&str>,
    party_id: Option<&str>,
    name: &str,
    party: &str,
    category: &str,
    bio: Option<&str>,
    photo_url: Option<&str>,
) -> Result<i64, sqlx::Error> {
    let row = sqlx::query(
        r#"
        INSERT INTO candidates (election_id, candidate_external_id, party_id, name, party, category, bio, photo_url)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
        RETURNING id
        "#,
    )
    .bind(election_id)
    .bind(candidate_external_id)
    .bind(party_id)
    .bind(name)
    .bind(party)
    .bind(category)
    .bind(bio)
    .bind(photo_url)
    .fetch_one(pool)
    .await?;

    Ok(row.get("id"))
}

pub async fn log_audit(pool: &PgPool, action: &str, details: &str) -> Result<(), sqlx::Error> {
    sqlx::query(
        r#"
        INSERT INTO audit_log (action, details) VALUES ($1, $2)
        "#,
    )
    .bind(action)
    .bind(details)
    .execute(pool)
    .await?;

    Ok(())
}
