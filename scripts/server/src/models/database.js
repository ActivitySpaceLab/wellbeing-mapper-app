const { Pool } = require('pg');

// PostgreSQL connection pool
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
  max: 20, // Maximum number of connections in pool
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

// Database initialization
const initializeDatabase = async () => {
  try {
    console.log('🔧 Initializing Barcelona research database...');
    
    // Create tables if they don't exist
    await pool.query(`
      CREATE TABLE IF NOT EXISTS participants (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        participant_id VARCHAR(255) UNIQUE NOT NULL,
        study_id VARCHAR(255) NOT NULL,
        registration_timestamp TIMESTAMP WITH TIME ZONE,
        app_version VARCHAR(50),
        platform VARCHAR(20),
        source_ip INET,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
      );
    `);

    await pool.query(`
      CREATE TABLE IF NOT EXISTS survey_responses (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        participant_id VARCHAR(255),
        survey_type VARCHAR(50) NOT NULL,
        encrypted_responses TEXT NOT NULL,
        data_type VARCHAR(50),
        study_id VARCHAR(255) NOT NULL,
        received_at TIMESTAMP WITH TIME ZONE,
        source_ip INET,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
      );
    `);

    await pool.query(`
      CREATE TABLE IF NOT EXISTS consent_responses (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        participant_id VARCHAR(255),
        encrypted_consent TEXT NOT NULL,
        study_id VARCHAR(255) NOT NULL,
        received_at TIMESTAMP WITH TIME ZONE,
        source_ip INET,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
      );
    `);

    await pool.query(`
      CREATE TABLE IF NOT EXISTS location_data (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        participant_id VARCHAR(255),
        encrypted_location_batch TEXT NOT NULL,
        batch_size INTEGER,
        study_id VARCHAR(255) NOT NULL,
        received_at TIMESTAMP WITH TIME ZONE,
        source_ip INET,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
      );
    `);

    // Create indexes for performance
    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_survey_responses_study_id ON survey_responses(study_id);
      CREATE INDEX IF NOT EXISTS idx_survey_responses_type ON survey_responses(survey_type);
      CREATE INDEX IF NOT EXISTS idx_survey_responses_created ON survey_responses(created_at);
      CREATE INDEX IF NOT EXISTS idx_participants_study_id ON participants(study_id);
      CREATE INDEX IF NOT EXISTS idx_location_data_study_id ON location_data(study_id);
      CREATE INDEX IF NOT EXISTS idx_consent_responses_study_id ON consent_responses(study_id);
    `);

    console.log('✅ Database initialized successfully');
  } catch (error) {
    console.error('❌ Database initialization failed:', error);
    process.exit(1);
  }
};

// Store encrypted data in database
const storeEncryptedData = async ({ table, data }) => {
  const client = await pool.connect();
  try {
    let query, values;

    switch (table) {
      case 'survey_responses':
        query = `
          INSERT INTO survey_responses (
            participant_id, survey_type, encrypted_responses, 
            data_type, study_id, received_at, source_ip
          ) VALUES ($1, $2, $3, $4, $5, $6, $7)
          RETURNING id, created_at
        `;
        values = [
          data.participant_id || null,
          data.survey_type,
          data.encrypted_responses,
          data.data_type,
          data.study_id,
          data.received_at,
          data.source_ip
        ];
        break;

      case 'consent_responses':
        query = `
          INSERT INTO consent_responses (
            participant_id, encrypted_consent, study_id, received_at, source_ip
          ) VALUES ($1, $2, $3, $4, $5)
          RETURNING id, created_at
        `;
        values = [
          data.participant_id,
          data.encrypted_consent,
          data.study_id,
          data.received_at,
          data.source_ip
        ];
        break;

      case 'location_data':
        query = `
          INSERT INTO location_data (
            participant_id, encrypted_location_batch, batch_size,
            study_id, received_at, source_ip
          ) VALUES ($1, $2, $3, $4, $5, $6)
          RETURNING id, created_at
        `;
        values = [
          data.participant_id,
          data.encrypted_location_batch,
          data.batch_size,
          data.study_id,
          data.received_at,
          data.source_ip
        ];
        break;

      case 'participants':
        query = `
          INSERT INTO participants (
            participant_id, study_id, registration_timestamp,
            app_version, platform, source_ip
          ) VALUES ($1, $2, $3, $4, $5, $6)
          ON CONFLICT (participant_id) DO UPDATE SET
            registration_timestamp = EXCLUDED.registration_timestamp,
            app_version = EXCLUDED.app_version
          RETURNING id, created_at
        `;
        values = [
          data.participant_id,
          data.study_id,
          data.registration_timestamp,
          data.app_version,
          data.platform,
          data.source_ip
        ];
        break;

      default:
        throw new Error(`Unsupported table: ${table}`);
    }

    const result = await client.query(query, values);
    return result.rows[0];

  } finally {
    client.release();
  }
};

// Get database statistics (for monitoring)
const getDatabaseStats = async () => {
  const client = await pool.connect();
  try {
    const surveyCount = await client.query('SELECT COUNT(*) FROM survey_responses');
    const participantCount = await client.query('SELECT COUNT(DISTINCT participant_id) FROM participants');
    const locationBatches = await client.query('SELECT COUNT(*) FROM location_data');
    const consentCount = await client.query('SELECT COUNT(*) FROM consent_responses');

    return {
      total_surveys: parseInt(surveyCount.rows[0].count),
      total_participants: parseInt(participantCount.rows[0].count),
      total_location_batches: parseInt(locationBatches.rows[0].count),
      total_consents: parseInt(consentCount.rows[0].count),
      last_updated: new Date().toISOString()
    };
  } finally {
    client.release();
  }
};

module.exports = {
  pool,
  initializeDatabase,
  storeEncryptedData,
  getDatabaseStats
};