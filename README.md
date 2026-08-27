# Billetto assignment

Rails app that pulls events from the Billetto API, lists them, and lets signed-in
users vote. Votes are recorded with Rails Event Store rather than as rows in a
votes table. Auth is Clerk.

## Setup

You'll need PostgreSQL 16 and Ruby 3.4.7.

```bash
brew install postgresql@16 && brew services start postgresql@16

bundle install
bin/rails db:prepare
bin/rails billetto:import
bin/rails server
```

`database.yml` connects to `localhost:5432` as your shell user with no password.
Override with `DATABASE_HOST`, `DATABASE_PORT`, `DATABASE_USERNAME`,
`DATABASE_PASSWORD`. Production reads `DATABASE_URL`.

### Credentials

`config/master.key` is gitignored, so you'll need it from me before the app will
boot. Or use your own keys with `bin/rails credentials:edit`:

```yaml
billetto:
  api_key: ...      # organiser dashboard > Integrate > Developers
  api_secret: ...   # only shown once
clerk:
  publishable_key: pk_test_...
  secret_key: sk_test_...
```

Without Clerk keys the app still boots and the events page renders. Nobody is
signed in, so nobody can vote.

## Tests

```bash
bin/rails test
```

12 tests covering the Event model validations, the importer (mapping, dedupe on
re-run, API failures), and the voting subscriber (counting, changing a vote,
rebuilding from the stream).

## Design notes

```
app/services/billetto/client.rb          HTTP only
app/services/billetto/event_importer.rb  payloads -> Event rows
app/events/                              EventUpvoted, EventDownvoted
app/subscribers/update_vote_count.rb     projection
app/models/vote_count.rb                 read model
app/controllers/concerns/clerk_authentication.rb
```

### Billetto

`Client` makes the request and nothing else. Auth is the `Api-Keypair` header:
access key and secret joined with a colon. Faraday errors come back out as
`Billetto::Client::Error`, so nothing above it cares which HTTP library we use.

`EventImporter` upserts on `billetto_id`, which has a unique index, so running
the import twice updates rather than duplicates. Safe to schedule.

The live API returns `organiser` and `categorization`. The docs say `organizer`
and `categorisation`. The importer accepts either.

### Voting

A vote gets published as a fact into a stream per event:

```ruby
event_store.publish(
  EventUpvoted.new(data: { event_id: event.id, user_id: current_user_id }),
  stream_name: "Event$#{event.id}"
)
```

`UpdateVoteCount` subscribes to both vote types and maintains `vote_counts`, so
rendering reads one column instead of counting the stream. Those counts are
derived, so they can be deleted and replayed:

```bash
bin/rails vote_counts:rebuild
```

`vote_counts` also stores which way each user voted, which is what lets someone
change their mind and move the count instead of adding to it.

Payloads live in `jsonb` with the JSON serializer, so events stay readable:

```sql
select event_type, data->>'user_id' from event_store_events;
```

Two RES 3 things that cost me time. Events subclass `RubyEventStore::Event` (the
`RailsEventStore::Event` alias is gone) and `subscribe` wants an instance, not
the class. Handlers also need indifferent key access: a published event has
symbol keys, a replayed one comes back from JSON with strings, so
`fetch(:event_id)` works when voting and blows up on rebuild.

### Clerk

The Rack middleware verifies the session and leaves a proxy in the Rack env, so
`ClerkAuthentication` just reads `request.env["clerk"].user_id`. Sign-in and
sign-up are Clerk's hosted pages. No auth controllers and no users table; the
only thing stored is the user id arriving on each vote event.

Clerk's railtie inserts the middleware whether or not keys are configured, and
then every request 500s. `config/initializers/clerk.rb` inserts it manually,
guarded on the keys being present.

## Assumptions

`/public/events` returns every public event on the platform, not the ones you
created as an organiser; the keypair authenticates you as an API consumer. The
import pulls 100 of roughly 1,350.

Votes are last-write-wins per user and order doesn't affect the result, so
there's no `expected_version` check. The real race is two people voting on the
same event at once, which the projection handles with a row lock.

## Not done

- Authentication and browser tests. The brief asks for both. Capybara and
  Selenium are configured but no system test is written.
- Pagination. The endpoint does have a cursor (`after`, plus `has_more` and
  `total`), so this is a scope decision, not a limitation. One page of 100 is
  enough to exercise ingest, voting and display.
- Background processing. The subscriber runs synchronously in the request. In
  production it'd be an ActiveJob handler dispatched after commit, at the cost of
  the voter briefly seeing a stale count.
- Any real UI. It's a plain ERB list.
