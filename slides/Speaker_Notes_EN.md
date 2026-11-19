# Airport Database — Part 1
## Speaker notes · 15 minutes · 4 speakers

| Part | Speaker | Time | Slides |
|---|---|---|---|
| Context & scope | Speaker 1 | 0:00 – 3:40 | 1–5 |
| The conceptual model | Speaker 2 | 3:40 – 8:35 | 6–9 |
| Who can do what | Speaker 3 | 8:35 – 11:40 | 10–12 |
| Technology & next steps | Speaker 4 | 11:40 – 15:00 | 13–17 |

_Replace `[Speaker 4]` on the title slide with the fourth presenter's name._


---

### Slide 01 — Designing a Secure Airport Database

[SPEAKER 1 · 0:00]
Good morning everyone. We are Dmytro, Ngan, Chiamaka and [Speaker 4], and this is Part 1 of our project for the Security of Databases course.

We designed the database of an international airport. In the next fifteen minutes we will explain why we chose this scenario, present the conceptual model, show who is allowed to do what, and justify our choice of database system.

Part 1 is the design. The concrete security mechanisms — row-level security, encryption, auditing — are Part 2, and we will show at the end how the design already prepares them. Each of us covers one section, and we take questions at the end.

---

### Slide 02 — Four parts, fifteen minutes

[SPEAKER 1 · 0:20]
The talk has four parts. I will set the context and the scope. [Speaker 2] will then open the model and walk through the entities and relationships. [Speaker 3] will explain the six actors and the permission matrix. [Speaker 4] will justify our DBMS choice and close with the plan for Part 2.

We keep three minutes and a half per speaker, which leaves a little room for questions at the end.

---

### Slide 03 — Why an airport?

[SPEAKER 1 · 1:00]
Why an airport? Two reasons.

First, we know the domain. All four of us have travelled, queued at check-in, lost a gate, waited for a delayed flight. That means we did not have to spend the project discovering what a flight or a boarding pass is; we could spend the time on database security.

Second, an airport concentrates exactly the data a security course cares about: identity documents, contact details, travel history, salaries, and a ban list. It is also a critical transport infrastructure, so the legal obligations are real, not theoretical.

The panel on the right summarises the size of the result: nineteen entities, six actors, five object groups, one DBMS.

---

### Slide 04 — What the database does — and what it does not

[SPEAKER 1 · 1:45]
The scope is the daily operation of one international airport. In scope: people and identity documents, flight operations, sales, the ban list and the workforce.

Out of scope: payment card data, live aircraft positions and air traffic control. Other systems already handle them, and pulling them in would add risk without adding value for this course.

Because the airport is in the European Union, two frameworks apply. GDPR governs personal data — passengers and staff. NIS2 covers air transport as an essential sector and adds cybersecurity duties on top of data protection. That is why we treat protection as a design goal from the first diagram. [1:45] This is a good point to hand over to [Speaker 2].

---

### Slide 05 — Nineteen entities, five groups

[SPEAKER 2 · 3:40]
Thank you. Here is the model at a glance.

We have nineteen entities, grouped in five families. Personal holds the identity of any human being and their documents. Operational is the physical running of the airport: flights, planes, routes, airports, terminals, gates and crew assignments. Commercial covers passengers, tickets and luggage. Security holds the ban list and the audit log. Workforce holds employees, departments and licences.

The grouping is not cosmetic. The same five groups become the columns of the permission matrix later, so the model and the security design speak the same language.

The audit log is system-filled: users never write to it, so it is not in the entity-relationship diagram.

---

### Slide 06 — One person, several roles

[SPEAKER 2 · 4:55]
The first thing we had to solve is that a human being can be several things at once.

Person is the supertype. It stores the shared fields once: name, date of birth, place of birth, contact details. Passenger and Employee are subtypes that add only what is specific to the role.

The circle with an "o" means overlapping: the same person can be both. Our example is a pilot who travels as a passenger on holiday. Without inheritance we would store her twice and an address update could leave the two records inconsistent.

The second level is disjoint, marked "d": an employee is either ground staff or air crew, never both.

Passport is deliberately not in the hierarchy. One person can hold several documents, so it is a separate one-to-many entity. This also concentrates all identity data in one table, which is exactly what we want to protect.

---

### Slide 07 — Flight is the hub

[SPEAKER 2 · 5:55]
Flight is the centre of the operational model, and three paths lead into it.

A route connects exactly two airports: one origin, one destination. A flight follows exactly one route and is operated by exactly one plane. A gate serves many flights, but a flight has zero or one gate, because the gate is often assigned only shortly before departure. Terminals contain gates, and also host departments.

Crew is a many-to-many relationship between flights and air employees, resolved by Crew member, which also records the role on board: captain, first officer, purser or cabin crew.

The same pattern is used for tickets between passengers and flights. That keeps the schema normalised and gives every row a single, unambiguous owner.

---

### Slide 08 — From a passenger to a ban

[SPEAKER 2 · 6:50]
On the commercial side, a ticket resolves the many-to-many relationship between passengers and flights: one ticket belongs to exactly one passenger and exactly one flight. Luggage hangs off the ticket, so a bag can never exist without the journey it belongs to.

On the security side, the ban list is deliberately small but sensitive: the passenger, the period, the reason, and the employee who added the entry. That last link matters: it makes every ban attributable to a person, which is exactly what an auditor will ask for.

The audit log completes the picture. It is filled by the system and records access to data, not business events, so it is a technical table rather than a conceptual entity — which is why it is absent from the diagram.

[7:30] I now hand over to [Speaker 3].

---

### Slide 09 — Reading the diagram in both directions

[SPEAKER 2 · 7:35]
A word on notation, because it is a design decision too.

Our model has almost one hundred attributes. In Chen notation every attribute would be an oval, and the diagram would be unreadable. We therefore use crow's foot: the attributes sit inside the entity box, primary keys and foreign keys are marked, and the same picture shows entities, attributes and relationships.

Crow's foot has no inheritance symbol, so we borrowed the circles with o and d from extended entity-relationship notation and explained them in the legend.

Every relationship is read in both directions. For example: a terminal contains zero or many gates, and every gate belongs to exactly one terminal. A flight has zero or one gate, while a gate serves zero or many flights. Saying both directions is what forces us to decide whether each side is mandatory or optional — and that decision matters when we write constraints later.

---

### Slide 10 — Six roles, never six people

[SPEAKER 3 · 8:35]
Thanks. Part 3 is about people — or rather, about roles.

We identified six actors. A passenger sees their own data and tickets. A check-in agent works on the flights assigned to them. A flight coordinator plans flights and assigns planes, gates and crew. A security officer screens passengers and owns the ban list. An HR manager manages staff and licences. The database administrator keeps the system running, but must not read business data.

Two points are important. First, an actor is a role, not a person: everyone logs in with a personal account, never a shared one. Second, a person can be a passenger and an employee at the same time. In that case they hold two accounts, so the rights of the passenger role can never leak into the staff role.

---

### Slide 11 — The permission matrix

[SPEAKER 3 · 9:30]
This is the heart of Part 1: the permission matrix.

Rows are actors, columns are the five object groups. C, R, U and D are create, read, update and delete; a dash means no access at all.

Read it as a story. The passenger only touches Personal and Commercial rows that are theirs. The check-in agent works on Operational and Commercial rows tied to assigned flights, and can only read whether a passenger is banned. The coordinator creates and updates flights and crew, but on Commercial sees only aggregated figures. The security officer is the only one who can change the ban list. HR owns Workforce, including deletion. The DBA has no business data at all — only structure, backups and the audit log.

This is least privilege: every actor receives exactly the actions their job requires, and nothing more.

---

### Slide 12 — Rights depend on the row, not only the role

[SPEAKER 3 · 10:40]
The matrix is necessary, but it is not sufficient.

Look at the footnotes: most rights depend on the row, not just the table. "Own" means a passenger sees their own tickets. "Assigned" means an agent sees only the flights they handle. "Aggregate" means the coordinator sees a count, never an identity. "Need to know" means the agent sees that a passenger is banned, but not why. And separation means the administrator can back up the database without being able to read it.

Classic GRANT and DENY operate on tables and columns; they cannot say "only rows that belong to you". So Part 2 will implement these rules with row-level security, filtered views and encryption. The design already anticipates them, because we know exactly which rule applies where.

---

### Slide 13 — Why relational, and why SQL Server 2019

[SPEAKER 4 · 11:40]
Thank you. The last part is the technology choice.

Our data is strongly structured: entities with clear attributes, explicit links, and integrity rules. When a passenger buys a ticket, the ticket, the flight and the seat must be saved completely or not at all — that is atomicity, one of the ACID properties. Both points make a relational database the natural fit.

We chose SQL Server 2019 for two practical reasons. First, most of us have worked with it, and it was already installed, so we spend our time on security rather than on learning a new system. Second, the free Developer edition has the same features as Standard and is licensed for development and testing — exactly our case. Everything we need is in the engine, which gives us a clean path to Part 2.

---

### Slide 14 — Every security need maps to one feature

[SPEAKER 4 · 12:30]
Here is the mapping between our requirements and the engine.

Roles and schemas give different rights to different user types, with GRANT and DENY down to a single column. Row-Level Security limits a user to certain rows — for instance, an agent sees only the passengers of assigned flights. Dynamic Data Masking hides part of a value, such as all but the last digits of a document number.

Always Encrypted protects sensitive columns even from administrators, because the keys stay on the client. Transparent Data Encryption protects the files and backups at rest. SQL Server Audit records who did what, and the standard backup chain allows a point-in-time restore.

Seven needs, seven features, all in the free Developer edition. That is the core of our argument.

---

### Slide 15 — Why not PostgreSQL, MySQL or MongoDB?

[SPEAKER 4 · 13:20]
We did not pick SQL Server blindly; we compared it.

PostgreSQL is the closest alternative. It has roles and row-level security, but its community edition has no transparent encryption of data files; auditing needs the pgAudit extension; and pgcrypto decrypts inside the server, so the server and its administrators can see the keys and the plain data.

MySQL Community has no row-level security at all, and its audit plugin is paid. A rule like "only the passengers of assigned flights" would have to live in the application.

MongoDB stores documents, while our data is strongly structured and linked, and both encryption at rest and auditing are Enterprise features.

So SQL Server is the only candidate that covers all seven needs in the free edition.

---

### Slide 16 — Part 2 turns the design into an enforced system

[SPEAKER 4 · 14:05]
Part 2 is where the design becomes enforceable. Six steps: create the schema with all keys and constraints; create the six roles and grant the matrix; add row-level security for "own" and "assigned"; apply masking, Always Encrypted and TDE; configure server audit and a backup chain with a restore test; and finally attack our own database — try to read what each role must not see.

Our success criterion is simple: every actor can do their job, and cannot see a single row they do not need.

We have already built a working prototype of the schema and the role model, which gave us confidence that the design can be implemented as specified.

---

### Slide 17 — Security is a design goal, not a layer added at the end

[SPEAKER 4 · 14:50]
To conclude: security is a design goal, not a layer added at the end. The scenario gave us sensitive data, the model gave us clear boundaries, and the permission matrix made those boundaries explicit before we wrote a single line of code.

For transparency: we used AI assistants to rephrase and structure our text, check DBMS features and improve the diagram's presentation. The scenario, the model and the analysis are ours, and we reviewed every sentence.

We delivered nineteen entities, six actors, a least-privilege matrix and a DBMS whose free edition covers every control we need.

Thank you — we are happy to take your questions.
