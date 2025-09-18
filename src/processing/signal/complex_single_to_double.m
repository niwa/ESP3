function combined_double = complex_single_to_double(s)

sz = size(s);

real_bits = typecast(single(real(s(:))), 'uint32'); % Convert to uint32 to get the bit pattern
imag_bits = typecast(single(imag(s(:))), 'uint32'); % Convert to uint32 to get the bit pattern

combined_bits = bitor(bitshift(uint64(real_bits), 32), uint64(imag_bits)); % Shift a_bits and combine with b_bits

combined_double = reshape(typecast(combined_bits, 'double'),sz);

