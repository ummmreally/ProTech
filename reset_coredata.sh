#!/bin/bash

# Reset Core Data database
# This deletes the existing database so it can be recreated with the latest schema

echo "🗑️  Resetting Core Data database..."

# ProTech database location
DB_PATH="$HOME/Library/Containers/Nugentic.ProTech/Data/Library/Application Support/ProTech"

if [ -d "$DB_PATH" ]; then
    echo "📁 Found database at: $DB_PATH"
    rm -f "$DB_PATH/ProTech.sqlite"*
    echo "✅ Database files deleted"
    echo "🔄 The app will create a fresh database on next launch"
else
    echo "⚠️  Database directory not found - may not exist yet"
fi

echo ""
echo "✅ Reset complete!"
echo "ℹ️  Next steps:"
echo "   1. Build and run the app"
echo "   2. The default admin will be recreated"
echo "   3. Username: admin"
echo "   4. Password: admin123"
