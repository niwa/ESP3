function s = double_to_complex_single(combined_double)

sz = size(combined_double);

retrieved_bits = typecast(combined_double(:), 'uint64');

real_bits_retrieved = bitshift(retrieved_bits, -32);
imag_bits_retrieved =  bitand(retrieved_bits, uint64(2^32-1));

real_retrieved = typecast(uint32(real_bits_retrieved), 'single');
imag_retrieved = typecast(uint32(imag_bits_retrieved), 'single');

s = reshape(real_retrieved + 1i * imag_retrieved,sz);