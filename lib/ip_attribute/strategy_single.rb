# frozen_string_literal: true

module IpAttribute
  # Strategy B installer: single column + optional family.
  # If family column exists: explicit family, perfect round-trip.
  # If family column missing: range inference fallback.
  module StrategySingle
    private

    def _install_single(cfg)
      col, family_col = cfg.col, cfg.family_col
      _install_single_validations(col, family_col)
      _install_single_reader(col, family_col)
      _install_single_writer(col, family_col)

      define_method(:"#{col}_display") { public_send(col)&.to_s }
    end

    def _install_single_validations(col, family_col)
      validates_numericality_of col,
        only_integer: true, allow_nil: true,
        greater_than_or_equal_to: 0, less_than_or_equal_to: Converter::MAX_IP

      return unless family_col

      validates_inclusion_of family_col,
        in: [Converter::FAMILY_IPV4, Converter::FAMILY_IPV6],
        allow_nil: true
    end

    def _install_single_reader(col, family_col)
      define_method(col) do
        raw = read_attribute_before_type_cast(col)
        return nil if raw.nil?
        fam = family_col ? read_attribute_before_type_cast(family_col)&.to_i : nil
        Converter.to_ipaddr(raw, family: fam)
      rescue RangeError
        nil
      end
    end

    def _install_single_writer(col, family_col)
      define_method(:"#{col}=") do |addr|
        if addr.nil?
          write_attribute(col, nil)
          write_attribute(family_col, nil) if family_col
          return
        end

        write_attribute(col, Converter.to_integer(addr))
        return unless family_col

        ip_addr = _ip_parse(addr)
        write_attribute(family_col, ip_addr ? AddressFamily.from_socket(ip_addr.family) : nil)
      end
    end
  end
end
