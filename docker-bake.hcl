variable "TS" {
  default = "unknown"
}

variable "CACHE_BUMP" { default = "" }

target "matrix" {
  name = "ruby-${replace(item.ruby, ".", "-")}-ar-${replace(item.ar, ".", "-")}"
  matrix = {
    item = [
      { ruby = "3.4.9", ar = "7.2" },
      { ruby = "3.4.9", ar = "8.1" },
      { ruby = "4.0.1", ar = "8.1" }
    ]
  }

  target     = "base"
  dockerfile = "Dockerfile"
  args = {
    RUBY_VERSION = item.ruby
    AR_VERSION   = item.ar
  }
  tags = ["ip_attribute:ruby${item.ruby}-ar${item.ar}"]

  cache-from = ["type=local,src=tmp/buildkit-cache"]
  cache-to   = ["type=local,dest=tmp/buildkit-cache-new,mode=max"]
}

group "default" {
  targets = ["matrix"]
}
