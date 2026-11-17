# E-Commerce for Automotive Parts (Topic 4 – Group 05)

Java Swing desktop application on top of a MySQL database for an automotive / motorbike parts shop.
Course: IT079IU – Principles of Database Management, Semester 1, 2026–2027.

The application has five tabs: **Browse Data**, **Search Catalogue**, **Orders (Master-Detail)**,
**Manage Records (CRUD)** and **Reports & Topic Queries**. Every screen reads or writes the database
through SQL (PreparedStatement with parameters); nothing is hard-coded.

## 1. JDK version

**Java SE Development Kit 21.0.12.1** (any JDK 21 works; the project is compiled with `release 21`).

Check with: `java -version`

## 2. JDBC driver

**MySQL Connector/J – `mysql-connector-j-26.7.0`** (Maven artifact `com.mysql:mysql-connector-j:26.7.0`).
Maven downloads it automatically and the build bundles it inside the JAR, so nothing needs to be installed by hand.

## 3. Database and connection settings

- Database system: **MySQL Community Server 8.0.46**
- Database name: `automotive_parts_db`

**Step A – create the database.** Run the master script once (it drops and re-creates the database, so it can be run again at any time):

```
mysql -u root -p < database/01_schema_and_data.sql
```

or open `database/01_schema_and_data.sql` in MySQL Workbench and execute the whole file.
It creates 10 tables and loads 329 sample rows.

**Step B – edit `db.properties`.** The file sits in the project root, next to `pom.xml` and the JAR.
The connection settings are read from this file when the program runs, so the database can be changed
**without recompiling**:

```properties
db.url=jdbc:mysql://localhost:3306/automotive_parts_db?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC
db.user=root
db.password=your_password_here
```

| Setting | Meaning |
|---|---|
| `db.url` | JDBC URL: host, port and database name |
| `db.user` | MySQL user name |
| `db.password` | MySQL password (replace `your_password_here`) |

The program looks for `db.properties` in the folder it is started from.
To use a file somewhere else: `java -Ddb.properties=C:\path\to\db.properties -jar AutomotivePartsApp.jar`.

## 4. Build and run

Requirements: JDK 21 and Apache Maven 3.9+ installed, MySQL running with the database from Step A.

**Build** (from the project root):

```
mvn clean package
```

This produces the runnable "fat" JAR `target/AutomotivePartsApp.jar` (our classes + the MySQL driver).
Copy it to the project root, next to `db.properties`:

```
copy target\AutomotivePartsApp.jar .        (Windows)
cp target/AutomotivePartsApp.jar .          (macOS / Linux)
```

**Run** (from the project root, so that `db.properties` is found):

```
java -jar AutomotivePartsApp.jar
```

A ready-built `AutomotivePartsApp.jar` is already included in the project root, so the marker can skip the build and
only edit `db.properties` and run the command above.

The status line at the bottom of the window shows whether the database connection works
(for example `Connected to database 'automotive_parts_db' on MySQL 8.0.46`).

## Troubleshooting

| Message | Cause / fix |
|---|---|
| `Cannot read db.properties: ...` | Start the program from the folder that contains `db.properties`, or use `-Ddb.properties=...`. |
| `Access denied for user ...` | Wrong `db.user` / `db.password` in `db.properties`. |
| `Communications link failure` | MySQL is not running, or host/port in `db.url` is wrong. |
| `Unknown database 'automotive_parts_db'` | Step A was not run yet. |

## Project layout

```
pom.xml                      Maven build (Java 21, Connector/J, maven-shade-plugin)
db.properties                External connection settings
database/                    SQL scripts (01 schema + data, 02 queries, 03 transactions/CRUD, 04 constraint tests)
src/main/java/com/group05/autoparts/
    Main.java                Main window with the five tabs
    config/DBConnection.java Connection layer (reads db.properties) + table-model helpers
    ui/                      The five screens (BrowsePanel, SearchPanel, MasterDetailPanel, CrudEditPanel, AnalyticsReportPanel)
docs/                        Report sections, diagrams, screenshots
```
