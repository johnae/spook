-- http://lua-users.org/wiki/SecureHashAlgorithm
{:tobit, :lshift, :rshift, :band, :bor, :bnot, :bxor, ror: rrotate} = require "bit"

-- SHA-256 code in Lua 5.2; based on the pseudo-code from
-- Wikipedia (http://en.wikipedia.org/wiki/SHA-2)

-- Initialize table of round constants
-- (first 32 bits of the fractional parts of the cube roots of the first
-- 64 primes 2..311):
k = {
   0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,
   0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
   0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
   0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
   0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
   0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
   0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
   0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
   0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
   0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
   0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
   0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
   0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5,
   0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
   0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
   0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
}

-- transform a string of bytes to a string of hexadecimal digits
str2hexa = (s) ->
  s = string.gsub s, ".", (c) -> string.format("%02x", string.byte(c))
  s

-- transform number 'l' in a big-endian sequence of 'n' bytes
-- (coded as a string)
num2s = (l, n) ->
  s = ""
  for i = 1, n
    rem = l % 256
    s = string.char(rem) .. s
    l = (l - rem) / 256
  s

-- transform the big-endian sequence of four bytes starting at
-- index 'i' in 's' into a number
s232num = (s, i) ->
  n = 0
  for i = i, i + 3
    n = n*256 + string.byte(s, i)
  n

-- append the bit '1' to the message
-- append k bits '0', where k is the minimum number >= 0 such that the
-- resulting message length (in bits) is congruent to 448 (mod 512)
-- append length of message (before pre-processing), in bits, as 64-bit
-- big-endian integer
preproc = (msg, len) ->
  extra = 64 - ((len + 1 + 8) % 64)
  len = num2s(8 * len, 8)    -- original len in bits, coded
  msg = msg .. "\128" .. string.rep("\0", extra) .. len
  assert(#msg % 64 == 0)
  msg

initH256 = (H) ->
  -- (first 32 bits of the fractional parts of the square roots of the
  -- first 8 primes 2..19):
  H[1] = 0x6a09e667
  H[2] = 0xbb67ae85
  H[3] = 0x3c6ef372
  H[4] = 0xa54ff53a
  H[5] = 0x510e527f
  H[6] = 0x9b05688c
  H[7] = 0x1f83d9ab
  H[8] = 0x5be0cd19
  H

digestblock = (msg, i, H) ->
    -- break chunk into sixteen 32-bit big-endian words w[1..16]
  w = {}
  for j = 1, 16
    w[j] = s232num(msg, i + (j - 1)*4)

  -- Extend the sixteen 32-bit words into sixty-four 32-bit words:
  for j = 17, 64
    s0 = bxor(rrotate(w[j - 15], 7), rrotate(w[j - 15], 18), rshift(w[j - 15], 3))
    s1 = bxor(rrotate(w[j - 2], 17), rrotate(w[j - 2], 19), rshift(w[j - 2], 10))
    w[j] = w[j - 16] + s0 + w[j - 7] + s1

  -- Initialize hash value for this chunk:
  a, b, c, d, e, f, g, h = H[1], H[2], H[3], H[4], H[5], H[6], H[7], H[8]
  -- Main loop:
  for i = 1, 64
    s0 = bxor(rrotate(a, 2), rrotate(a, 13), rrotate(a, 22))
    maj = bxor(band(a, b), band(a, c), band(b, c))
    t2 = s0 + maj
    s1 = bxor(rrotate(e, 6), rrotate(e, 11), rrotate(e, 25))
    ch = bxor(band(e, f), band(bnot(e), g))
    t1 = h + s1 + ch + k[i] + w[i]
    h = g
    g = f
    f = e
    e = d + t1
    d = c
    c = b
    b = a
    a = t1 + t2

  -- Add (mod 2^32) this chunk's hash to result so far:
  H[1] = tobit(H[1] + a)
  H[2] = tobit(H[2] + b)
  H[3] = tobit(H[3] + c)
  H[4] = tobit(H[4] + d)
  H[5] = tobit(H[5] + e)
  H[6] = tobit(H[6] + f)
  H[7] = tobit(H[7] + g)
  H[8] = tobit(H[8] + h)

-- Produce the final hash value (big-endian):
finalresult256 = (H) ->
  str2hexa(num2s(H[1], 4)..num2s(H[2], 4)..num2s(H[3], 4)..num2s(H[4], 4)..
             num2s(H[5], 4)..num2s(H[6], 4)..num2s(H[7], 4)..num2s(H[8], 4))

----------------------------------------------------------------------
HH = {}    -- to reuse

(msg) ->
  msg = preproc(msg, #msg)
  H = initH256 HH
  -- Process the message in successive 512-bit (64 bytes) chunks:
  for i = 1, #msg, 64
    digestblock msg, i, H

  finalresult256 H
