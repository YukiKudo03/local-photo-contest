# Disaster Recovery Runbook

## Recovery Objectives

| Metric | Target | Notes |
|--------|--------|-------|
| RPO (Recovery Point Objective) | 24 hours | Daily backups at 03:30 JST |
| RTO (Recovery Time Objective) - DB | 1 hour | Database restore from backup |
| RTO (Recovery Time Objective) - Full | 4 hours | Full system recovery including storage |

## Backup Architecture

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   PostgreSQL    │────▶│ DatabaseBackupJob │────▶│   S3 Bucket     │
│   Database      │     │ (Daily 03:30 JST) │     │ (STANDARD_IA)   │
└─────────────────┘     └──────────────────┘     └─────────────────┘
                              │                         │
                              ▼                         ▼
                        ┌──────────┐           ┌──────────────┐
                        │ Encrypt  │           │ Cross-Region │
                        │ AES-256  │           │ Replication  │
                        └──────────┘           └──────────────┘

┌─────────────────┐     ┌──────────────────────────┐
│ Active Storage  │────▶│ ActiveStorageMaintenanceJob│
│ Files           │     │ (Weekly Sun 04:30 JST)    │
└─────────────────┘     └──────────────────────────┘
```

### Backup Schedule

| Job | Schedule | Retention |
|-----|----------|-----------|
| Daily DB Backup | 03:30 JST daily | 7 generations |
| Weekly DB Backup | 03:30 JST Sunday | 4 generations |
| Storage Maintenance | 04:30 JST Sunday | N/A |

### Backup Storage Locations

- **Local**: `tmp/backups/` (temporary, cleaned after S3 upload)
- **S3**: `s3://{BACKUP_S3_BUCKET}/backups/{daily|weekly|manual}/`
- **Encryption**: AES-256-GCM (when `backup.encryption_key` is set in credentials)

## Restore Procedures

### Prerequisites

- Access to the production server or a machine with PostgreSQL client tools
- AWS CLI configured with appropriate permissions
- `RAILS_MASTER_KEY` for credential decryption

### Step 1: Identify the Backup to Restore

```bash
# List recent backups
bin/rails backup:list

# Or list from S3
bin/rails backup:download[backups/daily/backup_YYYYMMDD_HHMMSS.sql.gz.enc]
```

### Step 2: Download from S3 (if needed)

```bash
bin/rails "backup:download[backups/daily/backup_20260307_033000.sql.gz.enc]"
```

The file will be downloaded to `tmp/backups/`.

### Step 3: Restore the Database

```bash
bin/rails "backup:restore[tmp/backups/backup_20260307_033000.sql.gz.enc]"
```

This command will:
1. Decrypt the file (if `.enc` extension)
2. Decompress the file (if `.gz` extension)
3. Restore using `pg_restore` (PostgreSQL) or `sqlite3 .restore` (SQLite)
4. Ask for confirmation before proceeding

### Step 4: Verify the Restore

```bash
# Check database connectivity
bin/rails dbconsole

# Verify record counts
bin/rails runner "puts User.count; puts Contest.count; puts Entry.count"

# Check Active Storage integrity
bin/rails storage:check_integrity
```

### Step 5: Restart the Application

```bash
bin/kamal app boot
```

## Recovery Verification Checklist

- [ ] Database is accessible and queries return expected results
- [ ] User authentication works (try logging in)
- [ ] Active Storage files are accessible (check image display)
- [ ] Background jobs are processing (check Solid Queue)
- [ ] Email notifications are being sent
- [ ] WebSocket connections work (Action Cable)
- [ ] No errors in application logs

## Escalation Contacts

| Role | Contact | When |
|------|---------|------|
| Primary On-Call | (Configure in ENV) | First response |
| Database Admin | (Configure in ENV) | DB corruption/restore issues |
| AWS Support | AWS Support Console | S3/infrastructure issues |

## Common Scenarios

### Scenario 1: Accidental Data Deletion

1. Identify the most recent backup before the deletion
2. Download and restore that backup
3. Note: Data created after the backup will be lost (RPO: 24h)

### Scenario 2: Database Corruption

1. Stop the application: `bin/kamal app stop`
2. Download the latest successful backup
3. Drop and recreate the database
4. Restore from backup
5. Restart the application

### Scenario 3: Storage Volume Loss

1. Database: Restore from S3 backup (see above)
2. Active Storage files: Restore from S3 bucket (if using S3 storage)
3. For local storage: Files may be unrecoverable if no volume backup exists

### Scenario 4: Complete Server Loss

1. Provision a new server
2. Deploy the application: `bin/kamal setup`
3. Restore the database from S3 backup
4. Verify Active Storage connectivity
5. Run the verification checklist
