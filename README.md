# Billetto assignment

A small Rails app showing how the three moving parts fit together: pulling
events from the Billetto API, recording votes with Rails Event Store, and
authenticating with Clerk.

This is a structural sketch, not a finished product. The pieces work end to end,
but there is no pagination, no background processing and no UI to speak of.

## Setup

Needs PostgreSQL running locally (`brew install postgresql@16 && brew services
start postgresql@16`). `database.yml` defaults to `localhost:5432` as your shell
user with no password; override with `DATABASE_HOST`, `DATABASE_PORT`,
`DATABASE_USERNAME`, `DATABASE_PASSWORD`, or point `DATABASE_URL` at it in
production.

```bash
bundle install
bin/rails db:prepare
bin/rails billetto:import
bin/rails server
```

Credentials go in `bin/rails credentials:edit`:

```yaml
billetto:
  api_key: ...      # organiser dashboard -> Integrate -> Developers
  api_secret: ...   # only shown once
clerk:
  publishable_key: pk_test_...
  secret_key: sk_test_...
```

Without Clerk keys the app still boots and the events page renders; nobody is
signed in, so nobody can vote.

```bash
bin/rails test
```

## How it fits together

```
app/services/billetto/client.rb          talks to the API
app/services/billetto/event_importer.rb  turns payloads into Event rows
app/models/event.rb
app/models/vote_count.rb                 read model
app/events/                              EventUpvoted, EventDownvoted
app/subscribers/update_vote_count.rb     keeps vote_count in step
app/controllers/concerns/clerk_authentication.rb
```

### Billetto

`Client` owns the HTTP call and nothing else. Auth is the `Api-Keypair` header —
access key and secret joined with a colon. Faraday errors are re-raised as
`Billetto::Client::Error`, so the importer never has to know what Faraday is.

`EventImporter` maps payloads onto `Event` and upserts on `billetto_id`, which
has a unique index. That is what makes a second run update rather than
duplicate, and therefore what makes it safe to schedule.

One gotcha: the live API returns `organiser` and `categorization` while the
published docs show `organizer` and `categorisation`. The importer accepts
either.

### Rails Event Store

A vote is not a row, it is an event:

```ruby
event_store.publish(
  EventUpvoted.new(data: { event_id: event.id, user_id: current_user_id }),
  stream_name: "Event$#{event.id}"
)
```

Payloads are stored in `jsonb` columns with the JSON serializer, so events stay
readable in psql rather than sitting there as opaque blobs:

```sql
select event_type, data->>'user_id' from event_store_events;
```

`UpdateVoteCount` subscribes to both vote events and maintains the `vote_counts`
table, so the page reads a counter instead of counting the stream. Because the
counts are derived, they can be thrown away and rebuilt:

```bash
bin/rails vote_counts:rebuild
```

Storing which way each user voted is what lets a changed vote move the count
rather than add to it.

Three RES 3 details worth knowing: events subclass `RubyEventStore::Event` (the
`RailsEventStore::Event` alias was removed), `subscribe` needs a callable
instance — passing the class raises `InvalidHandler` — and a handler must read
its payload with indifferent keys. A freshly published event carries the symbol
keys it was built with; one replayed off the stream comes back from JSON with
string keys, so `fetch(:event_id)` works live and raises on rebuild.

### Clerk

Clerk's Rack middleware verifies the session and leaves a proxy in the Rack env,
so `ClerkAuthentication` only reads `request.env["clerk"].user_id`. Sign-up and
sign-in are Clerk's hosted pages; there are no auth controllers here.

The railtie inserts that middleware whether or not keys are configured, and then
every request 500s, so `config/initializers/clerk.rb` inserts it instead.

## Not done

- Pagination. The endpoint does expose a cursor (`after=<last_id>`, alongside
  `has_more` and `total`), so it is implementable — we cap at the max `limit` of
  100 of the ~1350 public events on purpose, which is ample to exercise the
  ingest, voting and display paths.
- Background jobs. The subscriber runs synchronously; in production it would be
  an ActiveJob handler on Sidekiq, dispatched after commit.
- Anything beyond a plain ERB list.
