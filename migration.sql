-- ========================================
-- MIGRATION COMPLETA E PERFEITA - LogiWMS-Pro
-- Database: armazem
-- Autor: Sistema Automatizado
-- Data: 2026-02-07
-- ========================================
-- Este script cria TODAS as 12 tabelas necessárias para o LogiWMS-Pro
-- Execute este script no banco de dados 'armazem' no EC2
-- Comando: psql -U dmitry -d armazem -f migration.sql

-- Conectar ao banco
\c armazem

-- Extensões necessárias
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

\echo '🚀 Iniciando criação das tabelas...'
\echo ''

-- ========================================
-- TABELAS PRINCIPAIS (12 tabelas)
-- ========================================

-- 1. Tabela de Armazéns (PRIMEIRA - outras tabelas dependem dela)
\echo '📦 Criando tabela: warehouses'
CREATE TABLE IF NOT EXISTS warehouses (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    location VARCHAR(255),
    manager_name VARCHAR(255),
    manager_email VARCHAR(255),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Tabela de Usuários
\echo '👤 Criando tabela: users'
CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    role TEXT NOT NULL,
    status TEXT DEFAULT 'Ativo',
    last_access TEXT,
    avatar TEXT,
    password TEXT NOT NULL,
    modules TEXT, -- Armazenado como JSON string
    allowed_warehouses TEXT, -- Armazenado como JSON string
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Tabela de Centros de Custo
\echo '💰 Criando tabela: cost_centers'
CREATE TABLE IF NOT EXISTS cost_centers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    manager TEXT,
    budget DECIMAL(15, 2) DEFAULT 0,
    status TEXT DEFAULT 'Ativo',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Tabela de Fornecedores
\echo '🏢 Criando tabela: vendors'
CREATE TABLE IF NOT EXISTS vendors (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    cnpj TEXT,
    category TEXT,
    contact TEXT,
    email TEXT,
    status TEXT DEFAULT 'Ativo',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Tabela de Veículos
\echo '🚚 Criando tabela: vehicles'
CREATE TABLE IF NOT EXISTS vehicles (
    plate VARCHAR(20) PRIMARY KEY,
    model TEXT,
    type TEXT,
    status TEXT DEFAULT 'Disponível',
    last_maintenance TEXT,
    cost_center TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. Tabela de Inventário (Estoque) - DEPENDE de warehouses
\echo '📊 Criando tabela: inventory'
CREATE TABLE IF NOT EXISTS inventory (
    sku VARCHAR(50) PRIMARY KEY,
    name TEXT NOT NULL,
    location TEXT,
    batch TEXT,
    expiry TEXT,
    quantity INTEGER DEFAULT 0,
    status TEXT DEFAULT 'disponivel',
    image_url TEXT,
    category TEXT,
    min_qty INTEGER DEFAULT 0,
    max_qty INTEGER DEFAULT 0,
    unit TEXT DEFAULT 'UN',
    lead_time INTEGER DEFAULT 7,
    safety_stock INTEGER DEFAULT 5,
    abc_category TEXT,
    last_counted_at TEXT,
    warehouse_id VARCHAR(50) REFERENCES warehouses(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 7. Tabela de Movimentações - DEPENDE de inventory e warehouses
\echo '🔄 Criando tabela: movements'
CREATE TABLE IF NOT EXISTS movements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sku VARCHAR(50) REFERENCES inventory(sku),
    product_name TEXT,
    type TEXT NOT NULL,
    quantity INTEGER NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    "user" TEXT,
    location TEXT,
    reason TEXT,
    order_id TEXT,
    warehouse_id VARCHAR(50) REFERENCES warehouses(id)
);

-- 8. Tabela de Pedidos de Compra - DEPENDE de warehouses
\echo '🛒 Criando tabela: purchase_orders'
CREATE TABLE IF NOT EXISTS purchase_orders (
    id TEXT PRIMARY KEY,
    vendor TEXT,
    request_date TEXT,
    status TEXT DEFAULT 'requisicao',
    priority TEXT DEFAULT 'normal',
    total DECIMAL(15, 2) DEFAULT 0,
    requester TEXT,
    items TEXT,
    quotes TEXT,
    selected_quote_id TEXT,
    sent_to_vendor_at TEXT,
    received_at TEXT,
    quotes_added_at TEXT,
    approved_at TEXT,
    rejected_at TEXT,
    vendor_order_number TEXT,
    approval_history TEXT,
    plate TEXT,
    cost_center TEXT,
    warehouse_id VARCHAR(50) REFERENCES warehouses(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 9. Tabela de Requisições de Materiais - DEPENDE de inventory e warehouses
\echo '📋 Criando tabela: material_requests'
CREATE TABLE IF NOT EXISTS material_requests (
    id TEXT PRIMARY KEY,
    sku VARCHAR(50) REFERENCES inventory(sku),
    name TEXT,
    qty INTEGER NOT NULL,
    plate TEXT,
    dept TEXT,
    priority TEXT,
    status TEXT DEFAULT 'aprovacao',
    cost_center TEXT,
    warehouse_id VARCHAR(50) REFERENCES warehouses(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 10. Lotes de Inventário Cíclico - DEPENDE de warehouses
\echo '🔍 Criando tabela: cyclic_batches'
CREATE TABLE IF NOT EXISTS cyclic_batches (
    id TEXT PRIMARY KEY,
    status TEXT DEFAULT 'aberto',
    scheduled_date TEXT,
    completed_at TEXT,
    accuracy_rate DECIMAL(5, 2),
    total_items INTEGER DEFAULT 0,
    divergent_items INTEGER DEFAULT 0,
    warehouse_id VARCHAR(50) REFERENCES warehouses(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 11. Contagens do Inventário Cíclico - DEPENDE de cyclic_batches, inventory e warehouses
\echo '✅ Criando tabela: cyclic_counts'
CREATE TABLE IF NOT EXISTS cyclic_counts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_id TEXT REFERENCES cyclic_batches(id),
    sku VARCHAR(50) REFERENCES inventory(sku),
    expected_qty INTEGER NOT NULL,
    counted_qty INTEGER,
    status TEXT DEFAULT 'pendente',
    notes TEXT,
    counted_at TEXT,
    warehouse_id VARCHAR(50) REFERENCES warehouses(id)
);

-- 12. Tabela de Notificações
\echo '🔔 Criando tabela: notifications'
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT DEFAULT 'info',
    read BOOLEAN DEFAULT false,
    user_id TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

\echo ''
\echo '✅ Todas as 12 tabelas criadas com sucesso!'
\echo ''

-- ========================================
-- DADOS INICIAIS (SEED)
-- ========================================

\echo '🌱 Inserindo dados iniciais...'
\echo ''

-- Inserir Armazéns
\echo '  📦 Armazéns: ARMZ28, ARMZ33'
INSERT INTO warehouses (id, name, description, location, manager_name, is_active)
VALUES 
('ARMZ28', 'Armazém Principal', 'Operações gerais de armazenamento e distribuição', 'Manaus - AM', 'Administrador', true),
('ARMZ33', 'Conferência de Carga em Tempo Real', 'Recebimento, conferência e validação de carga', 'Manaus - AM', 'Administrador', true)
ON CONFLICT (id) DO NOTHING;

-- Inserir Usuário Administrador
\echo '  👤 Usuário: admin@nortetech.com'
INSERT INTO users (id, name, email, role, status, password, modules, allowed_warehouses)
VALUES (
    '1', 
    'Administrador', 
    'admin@nortetech.com', 
    'admin', 
    'Ativo', 
    'admin', 
    '["dashboard","recebimento","movimentacoes","estoque","expedicao","inventario_ciclico","compras","cadastro","relatorios","configuracoes"]', 
    '["ARMZ28","ARMZ33"]'
) ON CONFLICT (email) DO NOTHING;

-- Inserir Usuário Gerente
\echo '  👤 Usuário: MATIAS@G.COM'
INSERT INTO users (id, name, email, role, status, password, modules, allowed_warehouses)
VALUES (
    'ocv3aoy40',
    'MATIAS',
    'MATIAS@G.COM',
    'manager',
    'Ativo',
    '1234',
    '["dashboard","recebimento","movimentacoes","estoque","expedicao","compras","inventario_ciclico","cadastro","relatorios","configuracoes"]',
    '["ARMZ33"]'
) ON CONFLICT (email) DO NOTHING;

-- Inserir Centros de Custo
\echo '  💰 Centros de Custo: CC-LOG, CC-OPS, CC-MAN'
INSERT INTO cost_centers (code, name, manager, budget, status) VALUES
('CC-LOG', 'Logística', 'Administrador', 500000.00, 'Ativo'),
('CC-OPS', 'Operações', 'MATIAS', 300000.00, 'Ativo'),
('CC-MAN', 'Manutenção', 'Administrador', 150000.00, 'Ativo')
ON CONFLICT (code) DO NOTHING;

\echo ''
\echo '✅ Dados iniciais inseridos com sucesso!'
\echo ''

-- ========================================
-- VERIFICAÇÃO E RELATÓRIO
-- ========================================

\echo '📊 RELATÓRIO DE VERIFICAÇÃO'
\echo '================================'
\echo ''

-- Listar todas as tabelas
\echo '📋 Tabelas criadas:'
\dt

\echo ''
\echo '📊 Contagem de registros por tabela:'
\echo ''

SELECT 
    'warehouses' as tabela, 
    COUNT(*) as registros,
    CASE WHEN COUNT(*) > 0 THEN '✅' ELSE '⚠️' END as status
FROM warehouses
UNION ALL
SELECT 'users', COUNT(*), CASE WHEN COUNT(*) > 0 THEN '✅' ELSE '⚠️' END FROM users
UNION ALL
SELECT 'cost_centers', COUNT(*), CASE WHEN COUNT(*) > 0 THEN '✅' ELSE '⚠️' END FROM cost_centers
UNION ALL
SELECT 'vendors', COUNT(*), CASE WHEN COUNT(*) > 0 THEN '✅' ELSE '⚠️' END FROM vendors
UNION ALL
SELECT 'vehicles', COUNT(*), CASE WHEN COUNT(*) > 0 THEN '✅' ELSE '⚠️' END FROM vehicles
UNION ALL
SELECT 'inventory', COUNT(*), CASE WHEN COUNT(*) > 0 THEN '✅' ELSE '⚠️' END FROM inventory
UNION ALL
SELECT 'movements', COUNT(*), CASE WHEN COUNT(*) > 0 THEN '✅' ELSE '⚠️' END FROM movements
UNION ALL
SELECT 'purchase_orders', COUNT(*), CASE WHEN COUNT(*) > 0 THEN '✅' ELSE '⚠️' END FROM purchase_orders
UNION ALL
SELECT 'material_requests', COUNT(*), CASE WHEN COUNT(*) > 0 THEN '✅' ELSE '⚠️' END FROM material_requests
UNION ALL
SELECT 'cyclic_batches', COUNT(*), CASE WHEN COUNT(*) > 0 THEN '✅' ELSE '⚠️' END FROM cyclic_batches
UNION ALL
SELECT 'cyclic_counts', COUNT(*), CASE WHEN COUNT(*) > 0 THEN '✅' ELSE '⚠️' END FROM cyclic_counts
UNION ALL
SELECT 'notifications', COUNT(*), CASE WHEN COUNT(*) > 0 THEN '✅' ELSE '⚠️' END FROM notifications
ORDER BY tabela;

-- Verificar usuários criados
\echo ''
\echo '👥 Usuários cadastrados:'
SELECT id, name, email, role FROM users;

-- Verificar armazéns criados
\echo ''
\echo '📦 Armazéns cadastrados:'
SELECT id, name, location FROM warehouses;

-- Mensagem final
\echo ''
\echo '================================'
\echo '✅ MIGRATION CONCLUÍDA COM SUCESSO!'
\echo '================================'
\echo ''
\echo '📊 Resumo:'
\echo '  - 12 tabelas criadas'
\echo '  - 2 armazéns (ARMZ28, ARMZ33)'
\echo '  - 2 usuários (admin, MATIAS)'
\echo '  - 3 centros de custo'
\echo ''
\echo '🔐 Credenciais de acesso:'
\echo '  Admin: admin@nortetech.com / admin'
\echo '  Gerente: MATIAS@G.COM / 1234'
\echo ''
\echo '🌐 Próximo passo: Iniciar o backend'
\echo '  cd api-backend'
\echo '  pm2 restart logiwms-api'
\echo ''
