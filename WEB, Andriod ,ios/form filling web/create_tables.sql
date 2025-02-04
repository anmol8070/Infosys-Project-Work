-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create the stored procedure
CREATE OR REPLACE FUNCTION create_form_responses_table()
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
    -- Create the table if it doesn't exist
    CREATE TABLE IF NOT EXISTS form_responses (
        id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
        form_id bigint REFERENCES forms(id) ON DELETE CASCADE,
        response_data jsonb NOT NULL,
        created_at timestamptz DEFAULT now()
    );
    
    -- Grant necessary permissions
    GRANT ALL ON form_responses TO authenticated;
    GRANT ALL ON form_responses TO service_role;
END;
$$; 