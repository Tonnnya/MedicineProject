-- Ініціалізація бази даних для CHIEF
-- PostgreSQL Schema

-- Створення розширень
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Таблиця пацієнтів (анонімізована)
CREATE TABLE IF NOT EXISTS patients (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    anonymous_id VARCHAR(50) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Таблиця зразків (слайдів)
CREATE TABLE IF NOT EXISTS slides (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    slide_id VARCHAR(100) UNIQUE NOT NULL,
    patient_id UUID REFERENCES patients(id),
    anatomic_site INTEGER NOT NULL CHECK (anatomic_site >= 0 AND anatomic_site <= 18),
    anatomic_site_name_uk VARCHAR(100),
    anatomic_site_name_en VARCHAR(100),
    collection_date DATE,
    scanner_type VARCHAR(100),
    magnification VARCHAR(20),
    file_path TEXT,
    file_size_bytes BIGINT,
    status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Таблиця результатів аналізу
CREATE TABLE IF NOT EXISTS analysis_results (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    slide_id UUID REFERENCES slides(id),
    model_version VARCHAR(50),
    analysis_type VARCHAR(100),

    -- Результати
    prediction_class INTEGER,
    confidence_score FLOAT,
    wsi_features JSONB,
    attention_weights JSONB,

    -- Час обробки
    processing_started_at TIMESTAMP,
    processing_completed_at TIMESTAMP,
    processing_time_seconds FLOAT,

    -- Метадані
    gpu_used VARCHAR(50),
    error_message TEXT,
    status VARCHAR(50) DEFAULT 'pending',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Таблиця звітів патологоанатомів
CREATE TABLE IF NOT EXISTS pathologist_reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    slide_id UUID REFERENCES slides(id),
    analysis_result_id UUID REFERENCES analysis_results(id),

    -- Інформація про лікаря
    pathologist_id VARCHAR(50),
    pathologist_name VARCHAR(100),

    -- Діагноз
    diagnosis TEXT,
    diagnosis_date DATE,

    -- Чи згоден з AI
    agrees_with_ai BOOLEAN,
    ai_helpful BOOLEAN,
    comments TEXT,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Таблиця аудиту (логування дій)
CREATE TABLE IF NOT EXISTS audit_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id VARCHAR(50),
    action VARCHAR(100),
    entity_type VARCHAR(50),
    entity_id UUID,
    details JSONB,
    ip_address VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Таблиця метрик системи
CREATE TABLE IF NOT EXISTS system_metrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    metric_type VARCHAR(50),
    metric_name VARCHAR(100),
    metric_value FLOAT,
    metric_unit VARCHAR(20),
    additional_data JSONB,
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Індекси для оптимізації
CREATE INDEX idx_slides_patient_id ON slides(patient_id);
CREATE INDEX idx_slides_status ON slides(status);
CREATE INDEX idx_slides_anatomic_site ON slides(anatomic_site);
CREATE INDEX idx_analysis_results_slide_id ON analysis_results(slide_id);
CREATE INDEX idx_analysis_results_status ON analysis_results(status);
CREATE INDEX idx_pathologist_reports_slide_id ON pathologist_reports(slide_id);
CREATE INDEX idx_audit_log_created_at ON audit_log(created_at);
CREATE INDEX idx_system_metrics_recorded_at ON system_metrics(recorded_at);

-- Функція для оновлення updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Тригери для автоматичного оновлення updated_at
CREATE TRIGGER update_patients_updated_at BEFORE UPDATE ON patients
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_slides_updated_at BEFORE UPDATE ON slides
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_analysis_results_updated_at BEFORE UPDATE ON analysis_results
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_pathologist_reports_updated_at BEFORE UPDATE ON pathologist_reports
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Вставка тестових даних (опціонально, для розробки)
-- INSERT INTO patients (anonymous_id) VALUES ('PATIENT_001');

-- Коментарі до таблиць
COMMENT ON TABLE patients IS 'Анонімізована інформація про пацієнтів';
COMMENT ON TABLE slides IS 'Інформація про гістопатологічні слайди';
COMMENT ON TABLE analysis_results IS 'Результати аналізу CHIEF';
COMMENT ON TABLE pathologist_reports IS 'Звіти патологоанатомів';
COMMENT ON TABLE audit_log IS 'Аудит всіх дій в системі';
COMMENT ON TABLE system_metrics IS 'Метрики продуктивності системи';
