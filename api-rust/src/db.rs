use sqlx::{PgPool, Row};
use std::sync::Arc;
use tokio::sync::Mutex;

pub type DbPool = Arc<Mutex<Option<PgPool>>>;

pub async fn init_db(database_url: &str) -> Result<PgPool, sqlx::Error> {
    let pool = PgPool::connect(database_url).await?;
    
    sqlx::query(
        r#"
        CREATE TABLE IF NOT EXISTS voters (
            id SERIAL PRIMARY KEY,
            public_key VARCHAR(255) UNIQUE NOT NULL,
            name VARCHAR(255) NOT NULL,
            email VARCHAR(255) UNIQUE NOT NULL,
            registered_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            has_voted BOOLEAN DEFAULT FALSE
        )
        "#,
    )
    .execute(&pool)
    .await?;

    sqlx::query(
        r#"
        CREATE TABLE IF NOT EXISTS candidates (
            id SERIAL PRIMARY KEY,
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

pub async fn register_voter(
    pool: &PgPool,
    public_key: &str,
    name: &str,
    email: &str,
) -> Result<i64, sqlx::Error> {
    let row = sqlx::query(
        r#"
        INSERT INTO voters (public_key, name, email)
        VALUES ($1, $2, $3)
        RETURNING id
        "#,
    )
    .bind(public_key)
    .bind(name)
    .bind(email)
    .fetch_one(pool)
    .await?;

    Ok(row.get("id"))
}

pub async fn get_voter_by_public_key(
    pool: &PgPool,
    public_key: &str,
) -> Result<Option<(String, String, bool)>, sqlx::Error> {
    let row = sqlx::query(
        r#"
        SELECT name, email, has_voted FROM voters WHERE public_key = $1
        "#,
    )
    .bind(public_key)
    .fetch_optional(pool)
    .await?;

    Ok(row.map(|r| (r.get("name"), r.get("email"), r.get("has_voted"))))
}

pub async fn mark_voter_voted(pool: &PgPool, public_key: &str) -> Result<(), sqlx::Error> {
    sqlx::query(
        r#"
        UPDATE voters SET has_voted = TRUE WHERE public_key = $1
        "#,
    )
    .bind(public_key)
    .execute(pool)
    .await?;

    Ok(())
}

pub async fn list_candidates(pool: &PgPool) -> Result<Vec<(i64, String, String, Option<String>)>, sqlx::Error> {
    let rows = sqlx::query(
        r#"
        SELECT id, name, party, bio FROM candidates ORDER BY id
        "#,
    )
    .fetch_all(pool)
    .await?;

    Ok(rows.into_iter().map(|r| (r.get("id"), r.get("name"), r.get("party"), r.get("bio"))).collect())
}

pub async fn add_candidate(
    pool: &PgPool,
    name: &str,
    party: &str,
    bio: Option<&str>,
) -> Result<i64, sqlx::Error> {
    let row = sqlx::query(
        r#"
        INSERT INTO candidates (name, party, bio)
        VALUES ($1, $2, $3)
        RETURNING id
        "#,
    )
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