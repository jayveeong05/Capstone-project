import sqlite3
import os
import json
import csv
from tabulate import tabulate
from datetime import datetime
import shutil

class NextGenFitnessDB:
    def __init__(self):
        # Get the directory where the script is located
        self.script_dir = os.path.dirname(os.path.abspath(__file__))
        # Set the database path relative to the script location
        self.db_path = os.path.join(self.script_dir, "NextGenFitness.db")
        self.conn = None
        self.cursor = None
        self.connect()

    def connect(self):
        """Connect to the database and enable foreign key enforcement"""
        try:
            # Ensure the database directory exists
            os.makedirs(os.path.dirname(self.db_path), exist_ok=True)
            
            self.conn = sqlite3.connect(self.db_path)
            self.cursor = self.conn.cursor()
            # Enable foreign key enforcement
            self.cursor.execute("PRAGMA foreign_keys = ON;")
            print(f"Successfully connected to database at: {self.db_path}")
        except sqlite3.Error as e:
            print(f"Error connecting to database: {e}")

    def close(self):
        """Close the database connection"""
        if self.conn:
            self.conn.close()
            print("Database connection closed")

    def view_all_tables(self):
        """View all tables in the database"""
        try:
            self.cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
            tables = self.cursor.fetchall()
            if tables:
                print("\nAvailable tables:")
                for table in tables:
                    print(f"- {table[0]}")
            else:
                print("No tables found in the database")
        except sqlite3.Error as e:
            print(f"Error viewing tables: {e}")

    def view_table_data(self, table_name):
        """View all data in a specific table"""
        try:
            self.cursor.execute(f"SELECT * FROM {table_name}")
            rows = self.cursor.fetchall()
            
            # Get column names
            self.cursor.execute(f"PRAGMA table_info({table_name})")
            columns = [column[1] for column in self.cursor.fetchall()]
            
            if rows:
                print(f"\nData in {table_name} table:")
                print(tabulate(rows, headers=columns, tablefmt="grid"))
            else:
                print(f"No data found in {table_name} table")
        except sqlite3.Error as e:
            print(f"Error viewing table data: {e}")

    def insert_record(self, table_name):
        """Insert a new record into a table"""
        try:
            # Get table structure
            self.cursor.execute(f"PRAGMA table_info({table_name})")
            columns = self.cursor.fetchall()
            
            # Get values from user
            values = []
            for column in columns:
                col_name = column[1]
                col_type = column[2]
                value = input(f"Enter {col_name} ({col_type}): ")
                
                # Convert value based on column type
                if col_type == "INTEGER":
                    value = int(value) if value else None
                elif col_type == "REAL":
                    value = float(value) if value else None
                
                values.append(value)
            
            # Create the INSERT query
            placeholders = ", ".join(["?" for _ in columns])
            columns_str = ", ".join([col[1] for col in columns])
            query = f"INSERT INTO {table_name} ({columns_str}) VALUES ({placeholders})"
            
            self.cursor.execute(query, values)
            self.conn.commit()
            print("Record inserted successfully")
        except sqlite3.Error as e:
            print(f"Error inserting record: {e}")

    def update_record(self, table_name):
        """Update a record in a table"""
        try:
            # Get table structure
            self.cursor.execute(f"PRAGMA table_info({table_name})")
            columns = self.cursor.fetchall()
            
            # Show current data
            self.view_table_data(table_name)
            
            # Get primary key
            primary_key = input("\nEnter the ID of the record to update: ")
            
            # Get new values
            print("\nEnter new values (press Enter to keep current value):")
            updates = []
            values = []
            for column in columns:
                col_name = column[1]
                if col_name.lower() != "id":  # Skip primary key
                    new_value = input(f"New {col_name}: ")
                    if new_value:
                        updates.append(f"{col_name} = ?")
                        values.append(new_value)
            
            if updates:
                query = f"UPDATE {table_name} SET {', '.join(updates)} WHERE id = ?"
                values.append(primary_key)
                self.cursor.execute(query, values)
                self.conn.commit()
                print("Record updated successfully")
            else:
                print("No changes made")
        except sqlite3.Error as e:
            print(f"Error updating record: {e}")

    def delete_record(self, table_name):
        """Delete a record from a table"""
        try:
            # Show current data
            self.view_table_data(table_name)
            
            # Get record ID to delete
            record_id = input("\nEnter the ID of the record to delete: ")

            attr = input("Enter the attribute name to delete: ")
            
            # Confirm deletion
            confirm = input(f"Are you sure you want to delete record {record_id}? (y/n): ")
            if confirm.lower() == 'y':
                self.cursor.execute(f"DELETE FROM {table_name} WHERE {attr} = ?", (record_id,))
                self.conn.commit()
                print("Record deleted successfully")
            else:
                print("Deletion cancelled")
        except sqlite3.Error as e:
            print(f"Error deleting record: {e}")

    def delete_user_and_dependencies(self, user_id):
        tables = [
            "ChatbotInteraction", "ExerciseLibrary", "Feedback", "FeedbackResponse", "Goal",
            "MealScan", "Notification", "Profile", "ProgressLog", "RecipeLibrary", "Reminder",
            "Report", "SystemLog", "UserDietPlan", "UserDietPreference", "UserWorkoutPlan",
            "VoiceLog", "WorkoutPreference"
        ]

        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            cursor.execute("PRAGMA foreign_keys = ON;")

            print(f"🔍 Checking and deleting user_id = {user_id}...")

            for table in tables:
                try:
                    cursor.execute(f"DELETE FROM {table} WHERE user_id = ?", (user_id,))
                    print(f"✔ Deleted from {table}")
                except sqlite3.OperationalError as e:
                    print(f"⚠️ Table `{table}` error: {e}")

            # Delete from User table
            try:
                cursor.execute("DELETE FROM User WHERE user_id = ?", (user_id,))
                print("✔ Deleted from User table")
            except sqlite3.OperationalError as e:
                print(f"❌ Error deleting from User: {e}")

            conn.commit()
            print("✅ All deletions done.")

        except sqlite3.Error as e:
            print(f"❌ SQLite general error: {e}")

        finally:
            conn.close()

    def create_new_table(self):
        """Create a new table in the database with a user-friendly interface, including foreign key support"""
        try:
            print("\n=== Create New Table ===")
            table_name = input("\nEnter the name for the new table: ").strip()
            
            # Validate table name
            if not table_name or not table_name.replace('_', '').isalnum():
                print("Error: Table name must contain only letters, numbers, and underscores")
                return

            # Get columns
            columns = []
            print("\nLet's define the columns for your table.")
            print("First, let's add the primary key column (usually 'id'):")
            
            # Add primary key column
            pk_name = input("Enter primary key (default: 'id'): ").strip() or "id"
            columns.append(f"{pk_name} INTEGER PRIMARY KEY AUTOINCREMENT") # Added AUTOINCREMENT for convenience
            
            print("\nNow, let's add other columns to your table.")
            print("Available data types:")
            print("1. TEXT - For text data")
            print("2. INTEGER - For whole numbers")
            print("3. REAL - For decimal numbers")
            print("4. BOOLEAN - For true/false values (stored as INTEGER 0 or 1)")
            print("5. TIMESTAMP - For date and time (stored as TEXT)")
            print("6. BLOB - For binary data")
            
            while True:
                print("\nColumn Definition:")
                print("-----------------")
                
                # Get column name
                col_name = input("Enter attribute name (or 'done' to finish): ").strip()
                if col_name.lower() == 'done':
                    break
                
                if not col_name or not col_name.replace('_', '').isalnum():
                    print("Error: Attribute name must contain only letters, numbers, and underscores")
                    continue
                
                # Get data type
                while True:
                    print("\nSelect data type:")
                    print("1. TEXT")
                    print("2. INTEGER")
                    print("3. REAL")
                    print("4. BOOLEAN")
                    print("5. TIMESTAMP")
                    print("6. BLOB")
                    
                    type_choice = input("Enter your choice (1-6): ").strip()
                    
                    data_types = {
                        "1": "TEXT",
                        "2": "INTEGER",
                        "3": "REAL",
                        "4": "INTEGER", # SQLite stores BOOLEAN as INTEGER (0 or 1)
                        "5": "TEXT",    # SQLite stores TIMESTAMP as TEXT
                        "6": "BLOB"
                    }
                    
                    if type_choice in data_types:
                        data_type = data_types[type_choice]
                        break
                    else:
                        print("Invalid choice. Please try again.")
                
                # Get constraints
                constraints = []
                
                # NOT NULL constraint
                not_null = input("Should this column be required? (y/n): ").strip().lower()
                if not_null == 'y':
                    constraints.append("NOT NULL")
                
                # UNIQUE constraint
                unique = input("Should this column have unique values? (y/n): ").strip().lower()
                if unique == 'y':
                    constraints.append("UNIQUE")
                
                # DEFAULT value
                default_val_input = input("Should this column have a default value? (y/n): ").strip().lower()
                if default_val_input == 'y':
                    if data_type == "TEXT":
                        default_value = input("Enter default text value: ").strip()
                        constraints.append(f"DEFAULT '{default_value}'")
                    elif data_type == "INTEGER":
                        try:
                            default_value = int(input("Enter default integer value: ").strip())
                            constraints.append(f"DEFAULT {default_value}")
                        except ValueError:
                            print("Invalid integer. No default set.")
                    elif data_type == "REAL":
                        try:
                            default_value = float(input("Enter default real value: ").strip())
                            constraints.append(f"DEFAULT {default_value}")
                        except ValueError:
                            print("Invalid real number. No default set.")
                    elif data_type == "TIMESTAMP":
                         constraints.append("DEFAULT CURRENT_TIMESTAMP")
                
                # Build column definition
                column_def = f"{col_name} {data_type}"
                if constraints:
                    column_def += " " + " ".join(constraints)
                
                columns.append(column_def)
                print(f"\nColumn '{col_name}' added successfully!")
            
            if len(columns) < 1: # We already added primary key, so minimum 1 is fine
                print("Error: Table must have at least a primary key column.")
                return

            # --- Foreign Key Section ---
            foreign_keys = []
            if len(columns) > 1: # Only ask for FKs if there are other columns besides the PK
                while True:
                    add_fk = input("\nDo you want to add a foreign key constraint? (y/n): ").strip().lower()
                    if add_fk != 'y':
                        break

                    # Show available columns for foreign key
                    print("\nAvailable columns in this new table for foreign key:")
                    for i, col_def in enumerate(columns):
                        # Extract column name from definition (e.g., "user_id INTEGER NOT NULL")
                        col_name = col_def.split(" ")[0]
                        if col_name.lower() != pk_name.lower(): # Don't allow PK to be a FK for itself
                            print(f"- {col_name}")

                    fk_col = input("Enter the column name in THIS table that will be the foreign key: ").strip()
                    
                    # Validate if fk_col exists in the current table's columns
                    if not any(fk_col == col_def.split(" ")[0] for col_def in columns):
                        print(f"Error: Column '{fk_col}' not found in the new table. Please try again.")
                        continue

                    # Get available tables for reference
                    self.cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
                    available_tables = [t[0] for t in self.cursor.fetchall() if t[0] != table_name] # Exclude current table
                    
                    if not available_tables:
                        print("No other tables available to reference. Cannot add foreign key.")
                        continue

                    print("\nAvailable tables to reference for foreign key:")
                    for t in available_tables:
                        print(f"- {t}")

                    ref_table = input("Enter the name of the table to reference (parent table): ").strip()

                    if ref_table not in available_tables:
                        print(f"Error: Table '{ref_table}' does not exist or is the current table. Please try again.")
                        continue

                    # Get columns of the referenced table
                    self.cursor.execute(f"PRAGMA table_info({ref_table})")
                    ref_columns = [col[1] for col in self.cursor.fetchall()]

                    if not ref_columns:
                        print(f"Error: No columns found in referenced table '{ref_table}'. Cannot add foreign key.")
                        continue

                    print(f"\nAvailable columns in '{ref_table}' to reference (usually a primary key):")
                    for r_col in ref_columns:
                        print(f"- {r_col}")

                    ref_col = input(f"Enter the column name in '{ref_table}' to reference: ").strip()
                    
                    if ref_col not in ref_columns:
                        print(f"Error: Column '{ref_col}' not found in table '{ref_table}'. Please try again.")
                        continue

                    # ON DELETE / ON UPDATE actions
                    print("\nChoose ON DELETE action:")
                    print("1. NO ACTION (default)")
                    print("2. CASCADE (delete child rows when parent is deleted)")
                    print("3. SET NULL (set foreign key to NULL when parent is deleted)")
                    print("4. RESTRICT (prevent parent deletion if child rows exist)")
                    print("5. SET DEFAULT (set foreign key to default value when parent is deleted)")
                    on_delete_choice = input("Enter your choice (1-5, or press Enter for NO ACTION): ").strip() or "1"
                    
                    on_delete_actions = {
                        "1": "",
                        "2": "ON DELETE CASCADE",
                        "3": "ON DELETE SET NULL",
                        "4": "ON DELETE RESTRICT",
                        "5": "ON DELETE SET DEFAULT"
                    }
                    on_delete_clause = on_delete_actions.get(on_delete_choice, "")

                    print("\nChoose ON UPDATE action:")
                    print("1. NO ACTION (default)")
                    print("2. CASCADE (update child rows when parent is updated)")
                    print("3. SET NULL (set foreign key to NULL when parent is updated)")
                    print("4. RESTRICT (prevent parent update if child rows exist)")
                    print("5. SET DEFAULT (set foreign key to default value when parent is updated)")
                    on_update_choice = input("Enter your choice (1-5, or press Enter for NO ACTION): ").strip() or "1"

                    on_update_actions = {
                        "1": "",
                        "2": "ON UPDATE CASCADE",
                        "3": "ON UPDATE SET NULL",
                        "4": "ON UPDATE RESTRICT",
                        "5": "ON UPDATE SET DEFAULT"
                    }
                    on_update_clause = on_update_actions.get(on_update_choice, "")

                    fk_constraint = f"FOREIGN KEY ({fk_col}) REFERENCES {ref_table} ({ref_col}) {on_delete_clause} {on_update_clause}".strip()
                    foreign_keys.append(fk_constraint)
                    print(f"Foreign key added: {fk_constraint}")

            # Combine columns and foreign keys for the CREATE TABLE statement
            all_definitions = columns + foreign_keys
            
            if len(all_definitions) < 1:
                print("Error: Table cannot be created without any column definitions.")
                return

            # Show table preview
            print("\nTable Preview:")
            print("-------------")
            print(f"CREATE TABLE {table_name} (")
            for i, definition in enumerate(all_definitions):
                print(f"    {definition}{',' if i < len(all_definitions) - 1 else ''}")
            print(")")
            
            # Confirm creation
            confirm = input("\nDo you want to create this table? (y/n): ").strip().lower()
            if confirm != 'y':
                print("Table creation cancelled.")
                return
            
            # Create the table
            create_query = f"CREATE TABLE {table_name} (\n    {',\n    '.join(all_definitions)}\n)"
            self.cursor.execute(create_query)
            self.conn.commit()
            print(f"\nTable '{table_name}' created successfully!")
            
            # Show table structure
            self.cursor.execute(f"PRAGMA table_info({table_name})")
            table_info = self.cursor.fetchall()
            print("\nTable structure:")
            print(tabulate(table_info, headers=['cid', 'name', 'type', 'notnull', 'dflt_value', 'pk'], tablefmt="grid"))
            
            # Show foreign key list
            self.cursor.execute(f"PRAGMA foreign_key_list({table_name})")
            fk_list = self.cursor.fetchall()
            if fk_list:
                print("\nForeign Key Constraints:")
                print(tabulate(fk_list, headers=['id', 'seq', 'table', 'from', 'to', 'on_update', 'on_delete', 'match'], tablefmt="grid"))
            
        except sqlite3.Error as e:
            print(f"Error creating table: {e}")
        except Exception as e:
            print(f"An unexpected error occurred: {e}")


    def delete_table(self):
        """Delete a table from the database"""
        try:
            print("\n=== Delete Table ===")
            
            # Show all tables
            self.cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
            tables = self.cursor.fetchall()
            
            if not tables:
                print("No tables found in the database")
                return
            
            print("\nAvailable tables:")
            for i, table in enumerate(tables, 1):
                print(f"{i}. {table[0]}")
            
            # Get table selection
            while True:
                try:
                    choice = input("\nEnter the number of the table to delete (or 'cancel' to go back): ").strip()
                    if choice.lower() == 'cancel':
                        print("Table deletion cancelled.")
                        return
                    
                    choice = int(choice)
                    if 1 <= choice <= len(tables):
                        table_name = tables[choice-1][0]
                        break
                    else:
                        print("Invalid selection. Please try again.")
                except ValueError:
                    print("Please enter a valid number.")
            
            # Show table structure before deletion
            print(f"\nTable structure of '{table_name}':")
            self.cursor.execute(f"PRAGMA table_info({table_name})")
            table_info = self.cursor.fetchall()
            print(tabulate(table_info, headers=['cid', 'name', 'type', 'notnull', 'dflt_value', 'pk'], tablefmt="grid"))
            
            # Show row count
            self.cursor.execute(f"SELECT COUNT(*) FROM {table_name}")
            row_count = self.cursor.fetchone()[0]
            print(f"\nThis table contains {row_count} rows.")
            
            # Confirm deletion
            confirm = input(f"\nAre you sure you want to delete the table '{table_name}'? This action cannot be undone! (yes/no): ").strip().lower()
            if confirm == 'yes':
                self.cursor.execute(f"DROP TABLE {table_name}")
                self.conn.commit()
                print(f"\nTable '{table_name}' has been successfully deleted.")
            else:
                print("Table deletion cancelled.")
                
        except sqlite3.Error as e:
            print(f"Error deleting table: {e}")

    def backup_database(self):
        """Create a backup of the entire database"""
        try:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            backup_dir = os.path.join(self.script_dir, "backups")
            os.makedirs(backup_dir, exist_ok=True)
            backup_path = os.path.join(backup_dir, f"NextGenFitness_backup_{timestamp}.db")
            
            # Create backup
            shutil.copy2(self.db_path, backup_path)
            print(f"\nDatabase backup created successfully: {backup_path}")
            
            # Show backup size
            backup_size = os.path.getsize(backup_path) / 1024  # Size in KB
            print(f"Backup size: {backup_size:.2f} KB")
            
        except Exception as e:
            print(f"Error creating backup: {e}")

    def export_table(self, table_name):
        """Export table data to CSV or JSON"""
        try:
            print("\n=== Export Table Data ===")
            print("1. Export to CSV")
            print("2. Export to JSON")
            
            format_choice = input("\nChoose export format (1-2): ").strip()
            
            # Get data
            self.cursor.execute(f"SELECT * FROM {table_name}")
            rows = self.cursor.fetchall()
            
            # Get column names
            self.cursor.execute(f"PRAGMA table_info({table_name})")
            columns = [column[1] for column in self.cursor.fetchall()]
            
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            export_dir = os.path.join(self.script_dir, "exports")
            os.makedirs(export_dir, exist_ok=True)
            
            if format_choice == "1":
                # Export to CSV
                filename = os.path.join(export_dir, f"{table_name}_{timestamp}.csv")
                with open(filename, 'w', newline='') as csvfile:
                    writer = csv.writer(csvfile)
                    writer.writerow(columns)
                    writer.writerows(rows)
                print(f"\nData exported to {filename}")
                
            elif format_choice == "2":
                # Export to JSON
                filename = os.path.join(export_dir, f"{table_name}_{timestamp}.json")
                data = [dict(zip(columns, row)) for row in rows]
                with open(filename, 'w') as jsonfile:
                    json.dump(data, jsonfile, indent=2)
                print(f"\nData exported to {filename}")
                
            else:
                print("Invalid choice")
                return
                
        except Exception as e:
            print(f"Error exporting data: {e}")

    def analyze_table(self, table_name):
        """Show detailed analysis of a table"""
        try:
            print(f"\n=== Table Analysis: {table_name} ===")
            
            # Get table info
            self.cursor.execute(f"PRAGMA table_info({table_name})")
            columns = self.cursor.fetchall()
            
            # Get row count
            self.cursor.execute(f"SELECT COUNT(*) FROM {table_name}")
            row_count = self.cursor.fetchone()[0]
            
            # Calculate table size (approximate)
            # This is a rough estimate and might not reflect actual disk space used by a single table
            # SQLite stores data in pages, and this will give total DB size.
            # A more accurate per-table size is complex and often not directly exposed in PRAGMA.
            self.cursor.execute("PRAGMA page_count;")
            page_count = self.cursor.fetchone()[0]
            self.cursor.execute("PRAGMA page_size;")
            page_size = self.cursor.fetchone()[0]
            
            total_db_size_bytes = page_count * page_size
            total_db_size_kb = total_db_size_bytes / 1024
            
            print(f"\nTable Statistics:")
            print(f"Total Rows: {row_count}")
            print(f"Approximate Database Size: {total_db_size_kb:.2f} KB (total DB, not just this table)")
            print(f"Number of Columns: {len(columns)}")
            
            print("\nColumn Analysis:")
            for col in columns:
                col_name = col[1]
                col_type = col[2]
                
                # Get null count
                self.cursor.execute(f"SELECT COUNT(*) FROM {table_name} WHERE {col_name} IS NULL")
                null_count = self.cursor.fetchone()[0]
                
                # Get unique values count
                self.cursor.execute(f"SELECT COUNT(DISTINCT {col_name}) FROM {table_name}")
                unique_count = self.cursor.fetchone()[0]
                
                print(f"\n{col_name} ({col_type}):")
                print(f"  Null values: {null_count}")
                print(f"  Unique values: {unique_count}")
                
                # For numeric columns, show min, max, avg
                if col_type in ["INTEGER", "REAL"]:
                    self.cursor.execute(f"SELECT MIN({col_name}), MAX({col_name}), AVG({col_name}) FROM {table_name}")
                    min_val, max_val, avg_val = self.cursor.fetchone()
                    print(f"  Min value: {min_val}")
                    print(f"  Max value: {max_val}")
                    if avg_val is not None:
                        print(f"  Average value: {avg_val:.2f}")
                    else:
                        print(f"  Average value: N/A (no numeric data)")

            # Foreign key analysis
            self.cursor.execute(f"PRAGMA foreign_key_list({table_name})")
            fk_list = self.cursor.fetchall()
            if fk_list:
                print("\nForeign Key Constraints:")
                print(tabulate(fk_list, headers=['id', 'seq', 'table', 'from', 'to', 'on_update', 'on_delete', 'match'], tablefmt="grid"))
            else:
                print("\nNo foreign key constraints found for this table.")
                
        except sqlite3.Error as e:
            print(f"Error analyzing table: {e}")
        except Exception as e:
            print(f"An unexpected error occurred during analysis: {e}")


    def modify_table(self, table_name):
        """Modify table structure"""
        try:
            print(f"\n=== Modify Table: {table_name} ===")
            print("1. Add new column")
            print("2. Rename column")
            print("3. Drop column")
            print("4. Return to previous menu")
            
            choice = input("\nEnter your choice (1-4): ").strip()
            
            if choice == "1":
                # Add new column
                col_name = input("\nEnter new attribute name: ").strip()
                if not col_name or not col_name.replace('_', '').isalnum():
                    print("Error: Attribute name must contain only letters, numbers, and underscores")
                    return

                print("\nSelect data type:")
                print("1. TEXT")
                print("2. INTEGER")
                print("3. REAL")
                print("4. BOOLEAN")
                print("5. TIMESTAMP")
                
                type_choice = input("Enter your choice (1-5): ").strip()
                data_types = {
                    "1": "TEXT",
                    "2": "INTEGER",
                    "3": "REAL",
                    "4": "INTEGER", # BOOLEAN in SQLite
                    "5": "TEXT" # TIMESTAMP in SQLite
                }
                
                if type_choice in data_types:
                    data_type = data_types[type_choice]
                    constraints = []
                    not_null = input("Should this column be required? (y/n): ").strip().lower()
                    if not_null == 'y':
                        constraints.append("NOT NULL")

                    # Add default value prompt for new column
                    default_val_input = input("Should this column have a default value? (y/n): ").strip().lower()
                    if default_val_input == 'y':
                        if data_type == "TEXT":
                            default_value = input("Enter default text value: ").strip()
                            constraints.append(f"DEFAULT '{default_value}'")
                        elif data_type == "INTEGER":
                            try:
                                default_value = int(input("Enter default integer value: ").strip())
                                constraints.append(f"DEFAULT {default_value}")
                            except ValueError:
                                print("Invalid integer. No default set.")
                        elif data_type == "REAL":
                            try:
                                default_value = float(input("Enter default real value: ").strip())
                                constraints.append(f"DEFAULT {default_value}")
                            except ValueError:
                                print("Invalid real number. No default set.")
                        elif data_type == "TEXT" and type_choice == "5": # For TIMESTAMP (stored as TEXT)
                            constraints.append("DEFAULT CURRENT_TIMESTAMP")


                    column_def_sql = f"{col_name} {data_type}"
                    if constraints:
                        column_def_sql += " " + " ".join(constraints)

                    self.cursor.execute(f"ALTER TABLE {table_name} ADD COLUMN {column_def_sql}")
                    self.conn.commit()
                    print(f"Column '{col_name}' added successfully")
                else:
                    print("Invalid data type choice")
                    
            elif choice == "2":
                # Rename column
                print("\nCurrent columns:")
                self.cursor.execute(f"PRAGMA table_info({table_name})")
                columns = self.cursor.fetchall()
                for col in columns:
                    print(f"- {col[1]}")
                
                old_name = input("\nEnter attribute name to rename: ").strip()
                new_name = input("Enter new attribute name: ").strip()
                
                # Check if old_name exists
                if not any(col[1] == old_name for col in columns):
                    print(f"Error: Column '{old_name}' does not exist in table '{table_name}'.")
                    return

                # Check if new_name is valid
                if not new_name or not new_name.replace('_', '').isalnum():
                    print("Error: New attribute name must contain only letters, numbers, and underscores.")
                    return

                try:
                    # SQLite supports RENAME COLUMN from version 3.25.0
                    self.cursor.execute(f"ALTER TABLE {table_name} RENAME COLUMN {old_name} TO {new_name}")
                    self.conn.commit()
                    print(f"Column '{old_name}' renamed to '{new_name}' successfully.")
                except sqlite3.OperationalError as e:
                    print(f"Error renaming column directly (might be an older SQLite version or other issue): {e}")
                    print("Attempting to rename by recreating table (less ideal for large tables/complex constraints)...")
                    # Fallback for older SQLite versions if direct rename fails
                    self.cursor.execute(f"PRAGMA table_info({table_name})")
                    current_columns_info = self.cursor.fetchall()
                    
                    column_defs = []
                    select_cols = []
                    for col in current_columns_info:
                        col_name_orig = col[1]
                        col_type = col[2]
                        not_null = "NOT NULL" if col[3] else ""
                        default_val = f"DEFAULT {col[4]}" if col[4] is not None else ""
                        pk = "PRIMARY KEY" if col[5] else "" # Assuming simple PK, not composite

                        if col_name_orig == old_name:
                            new_col_name = new_name
                        else:
                            new_col_name = col_name_orig
                        
                        column_defs.append(f"{new_col_name} {col_type} {not_null} {default_val} {pk}".strip())
                        select_cols.append(f"{col_name_orig} AS {new_col_name}")

                    # Get foreign key constraints
                    self.cursor.execute(f"PRAGMA foreign_key_list({table_name})")
                    fk_list = self.cursor.fetchall()
                    fk_constraints_rebuild = []
                    for fk in fk_list:
                        id, seq, parent_table, from_col, to_col, on_update, on_delete, match = fk
                        # Adjust from_col if it's the renamed column
                        adjusted_from_col = new_name if from_col == old_name else from_col
                        fk_constraints_rebuild.append(f"FOREIGN KEY ({adjusted_from_col}) REFERENCES {parent_table} ({to_col}) ON UPDATE {on_update} ON DELETE {on_delete}")


                    temp_table_name = f"{table_name}_temp_rename"
                    create_temp_query = f"CREATE TABLE {temp_table_name} (\n    {',\n    '.join(column_defs + fk_constraints_rebuild)}\n)"
                    
                    self.cursor.execute(create_temp_query)
                    self.cursor.execute(f"INSERT INTO {temp_table_name} ({', '.join([c.split(' AS ')[1] for c in select_cols])}) SELECT {', '.join([c.split(' AS ')[0] for c in select_cols])} FROM {table_name}")
                    self.cursor.execute(f"DROP TABLE {table_name}")
                    self.cursor.execute(f"ALTER TABLE {temp_table_name} RENAME TO {table_name}")
                    self.conn.commit()
                    print(f"Column '{old_name}' renamed to '{new_name}' successfully by recreating table.")

            elif choice == "3":
                # Drop column
                print("\nCurrent columns:")
                self.cursor.execute(f"PRAGMA table_info({table_name})")
                columns = self.cursor.fetchall()
                for col in columns:
                    print(f"- {col[1]}")
                
                col_name_to_drop = input("\nEnter attribute name to drop: ").strip()
                
                # Check if column exists and is not the primary key
                self.cursor.execute(f"PRAGMA table_info({table_name})")
                col_info = next((col for col in self.cursor.fetchall() if col[1] == col_name_to_drop), None)
                if not col_info:
                    print(f"Error: Column '{col_name_to_drop}' does not exist in table '{table_name}'.")
                    return
                if col_info[5] == 1: # pk column index is 5
                    print("Error: Cannot drop a primary key column directly. Consider recreating the table.")
                    return

                try:
                    # SQLite supports DROP COLUMN from version 3.35.0
                    self.cursor.execute(f"ALTER TABLE {table_name} DROP COLUMN {col_name_to_drop}")
                    self.conn.commit()
                    print(f"Column '{col_name_to_drop}' dropped successfully.")
                except sqlite3.OperationalError as e:
                    print(f"Error dropping column directly (might be an older SQLite version or other issue): {e}")
                    print("Attempting to drop by recreating table (less ideal for large tables/complex constraints)...")
                    # Fallback for older SQLite versions
                    self.cursor.execute(f"PRAGMA table_info({table_name})")
                    current_columns_info = self.cursor.fetchall()
                    
                    column_defs = []
                    select_cols = []
                    for col in current_columns_info:
                        col_name_orig = col[1]
                        if col_name_orig == col_name_to_drop:
                            continue # Skip the column to be dropped
                        
                        col_type = col[2]
                        not_null = "NOT NULL" if col[3] else ""
                        default_val = f"DEFAULT {col[4]}" if col[4] is not None else ""
                        pk = "PRIMARY KEY" if col[5] else ""

                        column_defs.append(f"{col_name_orig} {col_type} {not_null} {default_val} {pk}".strip())
                        select_cols.append(col_name_orig)

                    # Get foreign key constraints, excluding those related to the dropped column
                    self.cursor.execute(f"PRAGMA foreign_key_list({table_name})")
                    fk_list = self.cursor.fetchall()
                    fk_constraints_rebuild = []
                    for fk in fk_list:
                        id, seq, parent_table, from_col, to_col, on_update, on_delete, match = fk
                        if from_col != col_name_to_drop: # Only keep FKs not involving the dropped column
                             fk_constraints_rebuild.append(f"FOREIGN KEY ({from_col}) REFERENCES {parent_table} ({to_col}) ON UPDATE {on_update} ON DELETE {on_delete}")

                    temp_table_name = f"{table_name}_temp_drop"
                    create_temp_query = f"CREATE TABLE {temp_table_name} (\n    {',\n    '.join(column_defs + fk_constraints_rebuild)}\n)"
                    
                    self.cursor.execute(create_temp_query)
                    self.cursor.execute(f"INSERT INTO {temp_table_name} ({', '.join(select_cols)}) SELECT {', '.join(select_cols)} FROM {table_name}")
                    self.cursor.execute(f"DROP TABLE {table_name}")
                    self.cursor.execute(f"ALTER TABLE {temp_table_name} RENAME TO {table_name}")
                    self.conn.commit()
                    print(f"Column '{col_name_to_drop}' dropped successfully by recreating table.")

            elif choice == "4":
                return
                
            else:
                print("Invalid choice")
                
        except sqlite3.Error as e:
            print(f"Error modifying table: {e}")
        except Exception as e:
            print(f"An unexpected error occurred during table modification: {e}")

def manage_current_tables(db):
    """Manage existing tables"""
    while True:
        print("\n=== Current Tables Management ===")
        print("1. View all tables")
        print("2. View table data")
        print("3. Insert record")
        print("4. Update record")
        print("5. Delete record")
        print("6. Delete user and dependencies")
        print("7. Delete table")
        print("8. Export table data")
        print("9. Analyze table")
        print("10. Modify table")
        print("11. Return to main menu")
        
        choice = input("\nEnter your choice (1-11): ")
        
        if choice == "1":
            db.view_all_tables()
        
        elif choice == "2":
            table_name = input("Enter table name: ")
            db.view_table_data(table_name)
        
        elif choice == "3":
            table_name = input("Enter table name: ")
            db.insert_record(table_name)
        
        elif choice == "4":
            table_name = input("Enter table name: ")
            db.update_record(table_name)
        
        elif choice == "5":
            table_name = input("Enter table name: ")
            db.delete_record(table_name)
        
        elif choice == "6":
            user_id = input("Enter user ID to delete: ")
            db.delete_user_and_dependencies(user_id)

        elif choice == "7":
            db.delete_table()
        
        elif choice == "8":
            table_name = input("Enter table name: ")
            db.export_table(table_name)
        
        elif choice == "9":
            table_name = input("Enter table name: ")
            db.analyze_table(table_name)
        
        elif choice == "10":
            table_name = input("Enter table name: ")
            db.modify_table(table_name)
        
        elif choice == "11":
            break
        
        else:
            print("Invalid choice. Please try again.")

def main():
    db = NextGenFitnessDB()
    
    while True:
        print("\n=== NextGenFitness Database Manager ===")
        print("1. Manage Current Tables")
        print("2. Add New Table")
        print("3. Backup Database")
        print("4. Exit")
        
        choice = input("\nEnter your choice (1-4): ")
        
        if choice == "1":
            manage_current_tables(db)
        
        elif choice == "2":
            db.create_new_table()
        
        elif choice == "3":
            db.backup_database()
        
        elif choice == "4":
            db.close()
            print("Goodbye!")
            break
        
        else:
            print("Invalid choice. Please try again.")

if __name__ == "__main__":
    main()