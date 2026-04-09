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
            admin_code VARCHAR(50) NOT NULL
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
            name VARCHAR(255) NOT NULL,
            party VARCHAR(255) NOT NULL,
            bio TEXT
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
            public_key VARCHAR(255) NOT NULL,
            name VARCHAR(255) NOT NULL,
            email VARCHAR(255) NOT NULL,
            registered_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            has_voted BOOLEAN DEFAULT FALSE,
            UNIQUE(election_id, public_key)
        )
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
) -> Result<(), sqlx::Error> {
    sqlx::query(
        r#"
        INSERT INTO elections (id, name, description, admin_code)
        VALUES ($1, $2, $3, $4)
        "#,
    )
    .bind(id)
    .bind(name)
    .bind(description)
    .bind(admin_code)
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
    public_key: &str,
    name: &str,
    email: &str,
) -> Result<i64, sqlx::Error> {
    let row = sqlx::query(
        r#"
        INSERT INTO voters (election_id, public_key, name, email)
        VALUES ($1, $2, $3, $4)
        RETURNING id
        "#,
    )
    .bind(election_id)
    .bind(public_key)
    .bind(name)
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

pub async fn list_candidates(pool: &PgPool, election_id: &str) -> Result<Vec<(i64, String, String, Option<String>)>, sqlx::Error> {
    let rows = sqlx::query(
        r#"
        SELECT id, name, party, bio FROM candidates WHERE election_id = $1 ORDER BY id
        "#,
    )
    .bind(election_id)
    .fetch_all(pool)
    .await?;

    Ok(rows.into_iter().map(|r| (r.get::<i64, _>("id"), r.get("name"), r.get("party"), r.get("bio"))).collect())
}

pub async fn add_candidate(
    pool: &PgPool,
    election_id: &str,
    name: &str,
    party: &str,
    bio: Option<&str>,
) -> Result<i64, sqlx::Error> {
    let row = sqlx::query(
        r#"
        INSERT INTO candidates (election_id, name, party, bio)
        VALUES ($1, $2, $3, $4)
        RETURNING id
        "#,
    )
    .bind(election_id)
    .bind(name)
    .bind(party)
    .bind(bio)
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
