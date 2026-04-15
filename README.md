# IpAttribute

ActiveRecord IP address attributes stored as integers. Auto-converts
columns between human-readable IP strings and integer storage.
Supports IPv4 and IPv6 per RFC 791 and RFC 4291.

## Installation

```ruby
gem "ip_attribute"
```

## Storage Strategies

The gem auto-detects which strategy to use based on column naming.

### Strategy A: dual column (recommended for new projects)

`_ipv4` (bigint) + `_ipv6` (decimal 39,0). Unambiguous family.
Native integer indexing for IPv4. `::ffff:x.x.x.x` normalizes
to IPv4 automatically.

```ruby
class Session < ActiveRecord::Base
  # has client_ipv4 (bigint) + client_ipv6 (decimal) columns
  include IpAttribute::ActiveRecordIntegration
end

session.client_ip = "::1"
session.client_ip.to_s     # => "::1" (correct — stored in _ipv6)
session.client_ip.ipv6?    # => true
```

### Strategy B: single column + optional family

`_ip` (decimal 39,0) with optional `_ip_family` (smallint).
If the family column exists, perfect round-trip. If missing,
falls back to range inference (v0.1.0 compatible).

```ruby
class User < ActiveRecord::Base
  # has login_ip (decimal) + login_ip_family (smallint, optional)
  include IpAttribute::ActiveRecordIntegration
end

user.login_ip = "127.0.0.1"
user.login_ip.to_s     # => "127.0.0.1"
user.login_ip_display  # => "127.0.0.1" (string shortcut)
```

Without `_ip_family`, integer 1 maps to IPv4 `0.0.0.1` (not
IPv6 `::1`). Add the family column for disambiguation.

## Subnet Queries

```ruby
User.where_ip(:login_ip, "192.168.0.0/24")
Session.where_ip(:client_ipv4, "10.0.0.0/8")
```

## ActiveModel Type (no database required)

```ruby
class Request
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :client_ip, IpAttribute::Type.new
end

req = Request.new(client_ip: "10.0.0.1")
req.client_ip  # => #<IPAddr: IPv4:10.0.0.1/...>
```

With Rails, `:ip_address` is auto-registered via Railtie:

```ruby
attribute :login_ip, :ip_address
```

## Standalone Converter

```ruby
IpAttribute::Converter.to_integer("192.168.0.1")  # => 3232235521
IpAttribute::Converter.to_ipaddr(2130706433)      # => #<IPAddr: IPv4:127.0.0.1/...>
```

### IPv4-mapped normalization

```ruby
IpAttribute::Converter.to_integer("::ffff:10.0.0.1", normalize_mapped: true)
# => 167772161 (IPv4, not IPv6)
```

## Opt-in Refinements

```ruby
require "ip_attribute/core_ext"
using IpAttribute::CoreExt

"192.168.0.1".to_ip  # => 3232235521
```

Lexically scoped — no global monkey-patching.

## Migration Generators

```bash
# Dual column (recommended) + indexes
rails generate ip_attribute:column sessions client --dual

# Single column + indexes
rails generate ip_attribute:column users login_ip

# Single column + family (perfect round-trip) + indexes
rails generate ip_attribute:column users login_ip --family

# Add indexes to existing columns (production-safe)
rails generate ip_attribute:index users login_ip
rails generate ip_attribute:index sessions client --dual
```

All migrations use `disable_ddl_transaction!` and detect
PostgreSQL at runtime for `algorithm: :concurrently`.

### Generated Indexes

All generators create partial indexes (`WHERE col IS NOT NULL`)
for space efficiency on nullable columns. The `--family` flag
adds per-family conditional indexes for IPv4/IPv6 filtering.

For time-scoped queries (rate limiting, audit logs), add a
composite index manually:

```ruby
# Web server: "requests from this IP in the last hour"
add_index :requests, [:client_ip, :created_at],
  order: { created_at: :desc }

# Dual column variant
add_index :requests, [:client_ipv4, :created_at],
  where: "client_ipv4 IS NOT NULL",
  order: { created_at: :desc }
```

## Column Types

No SQL database has a native 128-bit integer. `bigint` is
64 bits (max 2^63-1) — sufficient for IPv4 but not IPv6.
`decimal(39,0)` is the only portable type for the full range.

| Strategy | Column       | Type            | Range              |
| -------- | ------------ | --------------- | ------------------ |
| Dual     | `pre_ipv4`   | `bigint`        | 0 – 2^32-1         |
| Dual     | `pre_ipv6`   | `decimal(39,0)` | 0 – 2^128-1        |
| Single   | `col_ip`     | `decimal(39,0)` | 0 – 2^128-1 (both) |
| Single   | `col_family` | `tinyint`       | 4 or 6             |

### Family Enum (RFC protocol versions)

| Value | Meaning | RFC  |
| ----- | ------- | ---- |
| 4     | IPv4    | 791  |
| 6     | IPv6    | 4291 |
| NULL  | Unknown | —    |

Uses IP protocol version numbers (4/6), not OS-specific
`Socket::AF_*` constants (which vary: `AF_INET6` is 10
on Linux, 30 on macOS, 23 on Windows).

The family column is optional in Strategy B. When absent,
family is inferred from the integer range (lossy for the
`[0, 2^32-1]` overlap). When present, perfect round-trip
for all addresses including `::1` vs `0.0.0.1`.

## Requirements

- Ruby >= 3.4.0
- ActiveRecord >= 7.2 (for AR integration)

Tested: Ruby 3.4 + 4.0 × ActiveRecord 7.2 + 8.1.

See `doc/rfc-ip-addressing.md` for the full RFC reference.

## License

MIT — see LICENSE.
