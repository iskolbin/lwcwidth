if _VERSION == 'Lua 5.3' then
	bit32 = nil
end

local wcwidth = require 'wcwidth'

local str = 'abcdefghijklmnopqrstuwwxyzABCDEFGHIJKLMNOPQRSTUWWXYZ1234567890[]{}-=_+*/\\\'";:,.?<>!@#$%^&*()'

for i = 1, #str do
	assert( wcwidth(str:sub(i,i):byte()) == 1)
end

for _, x in pairs{0x30b3,0x30f3,0x30cb,0x30c1,0x30cf,0x30bb,0x30ab,0x30a4} do
	assert( wcwidth( x ) == 2)
end

for i = 1, 31 do
	assert( wcwidth( i ) == -1 )
end

for _, x in pairs{0x05bf,0x0301,0x0488} do
	assert( wcwidth( x ) == 0)
end

for _, x in pairs{0x1b13,0x1b28,0x1b2e,0x1b44} do
	assert( wcwidth( x ) == 1)
end

for _, xy in pairs{{0x400,0x482},{0x48a,0x4ff},{0x500,0x52f}} do
	for i = xy[1], xy[2] do
		assert( wcwidth( i ) == 1 )
	end
end
