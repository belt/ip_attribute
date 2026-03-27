# IP Addressing Standards Reference

Reference for contributors. Covers the IP addressing standards
this gem implements: address formats, integer ranges, text
representations, and special addresses. External links carry
the full spec weight.

## Standards Lineage

| Date     | Standard       | Scope                              |
| -------- | -------------- | ---------------------------------- |
| Sep 1981 | [RFC 791][r1]  | IPv4 protocol, 32-bit addressing   |
| Feb 1996 | [RFC 1918][r2] | Private IPv4 address space         |
| Mar 2005 | [RFC 4038][r3] | IPv6/IPv4 transition mechanisms    |
| Feb 2006 | [RFC 4291][r4] | IPv6 addressing architecture       |
| Aug 2010 | [RFC 5952][r5] | IPv6 canonical text representation |
| Apr 2013 | [RFC 6890][r6] | Special-purpose IP registries      |

RFC 791 and RFC 4291 are the canonical sources for address
format and integer range. RFC 5952 standardizes text output.

[r1]: https://www.rfc-editor.org/rfc/rfc791.txt
[r2]: https://www.rfc-editor.org/rfc/rfc1918.txt
[r3]: https://www.rfc-editor.org/rfc/rfc4038.txt
[r4]: https://www.rfc-editor.org/rfc/rfc4291.txt
[r5]: https://www.rfc-editor.org/rfc/rfc5952.txt
[r6]: https://www.rfc-editor.org/rfc/rfc6890.txt

## IPv4 Address Space (RFC 791)

32-bit unsigned integer. Four octets.

```text
Addresses are fixed length of four octets (32 bits).
    — RFC 791 §2.3
```

| Property  | Value                  |
| --------- | ---------------------- |
| Bit width | 32                     |
| Minimum   | 0 (`0.0.0.0`)          |
| Maximum   | 2^32 - 1 (`255...255`) |
| Max (hex) | `0xFFFFFFFF`           |
| Max (dec) | 4,294,967,295          |

### Address Classes (historical, RFC 791 §3.1)

```text
A:  0nnn.hhhh.hhhh.hhhh      0.x – 127.x
B:  10nn.nnnn.hhhh.hhhh    128.x – 191.x
C:  110n.nnnn.nnnn.hhhh    192.x – 223.x
D:  1110 (multicast)       224.x – 239.x
E:  1111 (reserved)        240.x – 255.x
```

n = network, h = host. Classful addressing is obsolete
(replaced by CIDR, RFC 4632) but integer ranges hold.

### Text Representation

Dotted-decimal: four decimal octets separated by periods.

```text
192.168.0.1
0.0.0.0
255.255.255.255
```

Each octet is 0-255 decimal. No leading zeros in standard
form (leading zeros may be interpreted as octal by some
implementations — known ambiguity).

### Special Addresses (RFC 6890, RFC 1918)

| Address           | Integer         | Purpose   |
| ----------------- | --------------- | --------- |
| `0.0.0.0`         | 0               | This host |
| `127.0.0.1`       | 2,130,706,433   | Loopback  |
| `10.0.0.0/8`      | 167M – 184M     | Private   |
| `172.16/12`       | 2,886M – 2,887M | Private   |
| `192.168/16`      | 3,232M – 3,232M | Private   |
| `255.255.255.255` | 4,294,967,295   | Broadcast |

## IPv6 Address Space (RFC 4291)

128-bit unsigned integer. Eight groups of 16-bit hex.

```text
IPv6 addresses are 128-bit identifiers for
interfaces and sets of interfaces.
    — RFC 4291 §2
```

| Property  | Value                       |
| --------- | --------------------------- |
| Bit width | 128                         |
| Minimum   | 0 (`::`)                    |
| Maximum   | 2^128 - 1 (`ffff:...:ffff`) |
| Max (dec) | 3.4 × 10^38                 |

### Text Representation (RFC 4291 §2.2, RFC 5952)

Three forms defined in RFC 4291:

1. Preferred: `x:x:x:x:x:x:x:x` (eight hex groups)
2. Compressed: `::` replaces consecutive zero groups
3. Mixed: `x:x:x:x:x:x:d.d.d.d` (IPv4-mapped)

RFC 5952 canonical rules (output, not parsing):

- Leading zeros MUST be suppressed
- `::` MUST shorten the longest zero run
- `::` MUST NOT compress a single zero group
- Hex digits MUST be lowercase
- Equal-length runs: `::` replaces the first

```text
All implementations must accept and be able to
handle any legitimate RFC 4291 format.
    — RFC 5952 Abstract
```

### IPv4-Mapped IPv6 (RFC 4291 §2.5.5.2)

```text
|       80 bits (zeros)      | 16   | 32 bits   |
+----------------------------+------+-----------+
| 0000..................0000 | FFFF | IPv4 addr |
+----------------------------+------+-----------+
```

Example: `::ffff:192.168.0.1` maps IPv4 into IPv6.
The IPv4 integer + `0xFFFF00000000` prefix.

Relevant to this gem: an IPv4 address stored as its
mapped IPv6 integer displays as IPv6, losing the
original IPv4 intent. The gem infers address family
from the integer range at read time.

### Special Addresses (RFC 4291 §2.5, §2.7)

| Address         | Purpose            |
| --------------- | ------------------ |
| `::`            | Unspecified        |
| `::1`           | Loopback           |
| `fe80::/10`     | Link-local unicast |
| `ff00::/8`      | Multicast          |
| `::ffff:0:0/96` | IPv4-mapped IPv6   |

## Integer Storage Model

This gem stores IP addresses as unsigned integers.
Address family inferred from value at read time
(single-column), or from column name (dual-column).

### Dual-Stack Interfaces (RFC 4291 §2.1)

A network interface can have both an IPv4 and an IPv6
address simultaneously. These are independent addresses
in different families — not mapped equivalents.

```text
eth0: 192.168.0.50 (IPv4) + 2001:db8::50 (IPv6)
lo:   127.0.0.1    (IPv4) + ::1          (IPv6)
```

`::1` is NOT `127.0.0.1`. Both are loopback, but in
different address families with different integers
(1 vs 2,130,706,433). The dual-column strategy stores
each independently.

`::ffff:192.168.0.1` IS the IPv4-mapped representation
of `192.168.0.1` (RFC 4291 §2.5.5.2). The gem normalizes
mapped addresses to their IPv4 native form.

### Boundary Values

| Value     | Family | Address           |
| --------- | ------ | ----------------- |
| 0         | IPv4   | `0.0.0.0`         |
| 2^32 - 1  | IPv4   | `255.255.255.255` |
| 2^32      | IPv6   | `::1:0:0`         |
| 2^128 - 1 | IPv6   | `ffff:...:ffff`   |

### Validation Range

Valid: `[0, 2^128 - 1]`. Negative integers and values
exceeding 2^128 - 1 have no IP interpretation per
RFC 791 or RFC 4291.

### CIDR Notation

`IPAddr.new("192.168.0.0/24")` succeeds and `.to_i`
returns the network address. This gem rejects CIDR
in `Converter.to_integer` — strings containing "/"
return nil. Prevents silent data loss where a network
prefix is stored when a host address was intended.

## Ruby IPAddr Behavior

Ruby's `IPAddr` (stdlib) follows RFC 4291 for parsing
and RFC 5952 loosely for output:

```ruby
IPAddr.new("127.0.0.1").to_i          # => 2130706433
IPAddr.new("::1").to_i                # => 1
IPAddr.new(2130706433, AF_INET).to_s  # => "127.0.0.1"
IPAddr.new("::ffff:127.0.0.1").to_i   # => 281473913978881
IPAddr.new("invalid")                 # => InvalidAddressError
IPAddr.new("192.168.0.0/24").to_i     # => 3232235520
```
