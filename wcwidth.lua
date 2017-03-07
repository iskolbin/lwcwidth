--[[

 wcwidth -- v0.4.0 public domain wcwidth function Lua implementation
 no warranty implied; use at your own risk

 Implements wcwidth function, returns number of column positions
 to be occupied by the wide-characters, for details see:
	 http://man7.org/linux/man-pages/man3/wcwidth.3.html

 author: Ilya Kolbin (iskolbin@gmail.com)
 url: github.com/iskolbin/lbase64

 COMPATIBILITY

 Lua 5.1, 5.2, 5.3, LuaJIT 1, 2

 LICENSE

 This software is dual-licensed to the public domain and under the following
 license: you are granted a perpetual, irrevocable license to copy, modify,
 publish, and distribute this file as you see fit.

--]]

local function iswindows()
	return package.config:sub( 1, 1 ) == '\\'
end

local extract = bit32 and bit32.extract
if not extract then
	if bit then
		local lshift, rshift, band = bit.lshift, bit.rshift, bit.band
		extract = function( v, from, width )
			return band( lshift( v, from ), rshift( 1, width ) - 1 )
		end
	elseif _G._VERSION >= "Lua 5.3" then
		extract = load[[return function( v, from, width )
			return ( v >> from ) & ((1 << width) - 1)
		end]]()
	else
		extract = function( v, from, width )
			local w = 0
			local flag = 2^from
			for i = 0, width-1 do
				local flag2 = flag + flag
				if v % flag2 >= flag then
					w = w + 2^i
				end
				flag = flag2
			end
			return w
		end
	end
end

local wcwidth = {}

local ZEROSPACE = {
	{0x300,0x36f},{0x483,0x489},{0x591,0x5bd},{0x5bf,0x5bf},
	{0x5c1,0x5c2},{0x5c4,0x5c5},{0x5c7,0x5c7},{0x610,0x61a},
	{0x64b,0x65f},{0x670,0x670},{0x6d6,0x6dc},{0x6df,0x6e4},
	{0x6e7,0x6e8},{0x6ea,0x6ed},{0x711,0x711},{0x730,0x74a},
	{0x7a6,0x7b0},{0x7eb,0x7f3},{0x816,0x819},{0x81b,0x823},
	{0x825,0x827},{0x829,0x82d},{0x859,0x85b},{0x8d4,0x8e1},
	{0x8e3,0x902},{0x93a,0x93a},{0x93c,0x93c},{0x941,0x948},
	{0x94d,0x94d},{0x951,0x957},{0x962,0x963},{0x981,0x981},
	{0x9bc,0x9bc},{0x9c1,0x9c4},{0x9cd,0x9cd},{0x9e2,0x9e3},
	{0xa01,0xa02},{0xa3c,0xa3c},{0xa41,0xa42},{0xa47,0xa48},
	{0xa4b,0xa4d},{0xa51,0xa51},{0xa70,0xa71},{0xa75,0xa75},
	{0xa81,0xa82},{0xabc,0xabc},{0xac1,0xac5},{0xac7,0xac8},
	{0xacd,0xacd},{0xae2,0xae3},{0xb01,0xb01},{0xb3c,0xb3c},
	{0xb3f,0xb3f},{0xb41,0xb44},{0xb4d,0xb4d},{0xb56,0xb56},
	{0xb62,0xb63},{0xb82,0xb82},{0xbc0,0xbc0},{0xbcd,0xbcd},
	{0xc00,0xc00},{0xc3e,0xc40},{0xc46,0xc48},{0xc4a,0xc4d},
	{0xc55,0xc56},{0xc62,0xc63},{0xc81,0xc81},{0xcbc,0xcbc},
	{0xcbf,0xcbf},{0xcc6,0xcc6},{0xccc,0xccd},{0xce2,0xce3},
	{0xd01,0xd01},{0xd41,0xd44},{0xd4d,0xd4d},{0xd62,0xd63},
	{0xdca,0xdca},{0xdd2,0xdd4},{0xdd6,0xdd6},{0xe31,0xe31},
	{0xe34,0xe3a},{0xe47,0xe4e},{0xeb1,0xeb1},{0xeb4,0xeb9},
	{0xebb,0xebc},{0xec8,0xecd},{0xf18,0xf19},{0xf35,0xf35},
	{0xf37,0xf37},{0xf39,0xf39},{0xf71,0xf7e},{0xf80,0xf84},
	{0xf86,0xf87},{0xf8d,0xf97},{0xf99,0xfbc},{0xfc6,0xfc6},
	{0x102d,0x1030},{0x1032,0x1037},{0x1039,0x103a},{0x103d,0x103e},
	{0x1058,0x1059},{0x105e,0x1060},{0x1071,0x1074},{0x1082,0x1082},
	{0x1085,0x1086},{0x108d,0x108d},{0x109d,0x109d},{0x135d,0x135f},
	{0x1712,0x1714},{0x1732,0x1734},{0x1752,0x1753},{0x1772,0x1773},
	{0x17b4,0x17b5},{0x17b7,0x17bd},{0x17c6,0x17c6},{0x17c9,0x17d3},
	{0x17dd,0x17dd},{0x180b,0x180d},{0x1885,0x1886},{0x18a9,0x18a9},
	{0x1920,0x1922},{0x1927,0x1928},{0x1932,0x1932},{0x1939,0x193b},
	{0x1a17,0x1a18},{0x1a1b,0x1a1b},{0x1a56,0x1a56},{0x1a58,0x1a5e},
	{0x1a60,0x1a60},{0x1a62,0x1a62},{0x1a65,0x1a6c},{0x1a73,0x1a7c},
	{0x1a7f,0x1a7f},{0x1ab0,0x1abe},{0x1b00,0x1b03},{0x1b34,0x1b34},
	{0x1b36,0x1b3a},{0x1b3c,0x1b3c},{0x1b42,0x1b42},{0x1b6b,0x1b73},
	{0x1b80,0x1b81},{0x1ba2,0x1ba5},{0x1ba8,0x1ba9},{0x1bab,0x1bad},
	{0x1be6,0x1be6},{0x1be8,0x1be9},{0x1bed,0x1bed},{0x1bef,0x1bf1},
	{0x1c2c,0x1c33},{0x1c36,0x1c37},{0x1cd0,0x1cd2},{0x1cd4,0x1ce0},
	{0x1ce2,0x1ce8},{0x1ced,0x1ced},{0x1cf4,0x1cf4},{0x1cf8,0x1cf9},
	{0x1dc0,0x1df5},{0x1dfb,0x1dff},{0x20d0,0x20f0},{0x2cef,0x2cf1},
	{0x2d7f,0x2d7f},{0x2de0,0x2dff},{0x302a,0x302d},{0x3099,0x309a},
	{0xa66f,0xa672},{0xa674,0xa67d},{0xa69e,0xa69f},{0xa6f0,0xa6f1},
	{0xa802,0xa802},{0xa806,0xa806},{0xa80b,0xa80b},{0xa825,0xa826},
	{0xa8c4,0xa8c5},{0xa8e0,0xa8f1},{0xa926,0xa92d},{0xa947,0xa951},
	{0xa980,0xa982},{0xa9b3,0xa9b3},{0xa9b6,0xa9b9},{0xa9bc,0xa9bc},
	{0xa9e5,0xa9e5},{0xaa29,0xaa2e},{0xaa31,0xaa32},{0xaa35,0xaa36},
	{0xaa43,0xaa43},{0xaa4c,0xaa4c},{0xaa7c,0xaa7c},{0xaab0,0xaab0},
	{0xaab2,0xaab4},{0xaab7,0xaab8},{0xaabe,0xaabf},{0xaac1,0xaac1},
	{0xaaec,0xaaed},{0xaaf6,0xaaf6},{0xabe5,0xabe5},{0xabe8,0xabe8},
	{0xabed,0xabed},{0xfb1e,0xfb1e},{0xfe00,0xfe0f},{0xfe20,0xfe2f},
	{0x101fd,0x101fd},{0x102e0,0x102e0},{0x10376,0x1037a},{0x10a01,0x10a03},
	{0x10a05,0x10a06},{0x10a0c,0x10a0f},{0x10a38,0x10a3a},{0x10a3f,0x10a3f},
	{0x10ae5,0x10ae6},{0x11001,0x11001},{0x11038,0x11046},{0x1107f,0x11081},
	{0x110b3,0x110b6},{0x110b9,0x110ba},{0x11100,0x11102},{0x11127,0x1112b},
	{0x1112d,0x11134},{0x11173,0x11173},{0x11180,0x11181},{0x111b6,0x111be},
	{0x111ca,0x111cc},{0x1122f,0x11231},{0x11234,0x11234},{0x11236,0x11237},
	{0x1123e,0x1123e},{0x112df,0x112df},{0x112e3,0x112ea},{0x11300,0x11301},
	{0x1133c,0x1133c},{0x11340,0x11340},{0x11366,0x1136c},{0x11370,0x11374},
	{0x11438,0x1143f},{0x11442,0x11444},{0x11446,0x11446},{0x114b3,0x114b8},
	{0x114ba,0x114ba},{0x114bf,0x114c0},{0x114c2,0x114c3},{0x115b2,0x115b5},
	{0x115bc,0x115bd},{0x115bf,0x115c0},{0x115dc,0x115dd},{0x11633,0x1163a},
	{0x1163d,0x1163d},{0x1163f,0x11640},{0x116ab,0x116ab},{0x116ad,0x116ad},
	{0x116b0,0x116b5},{0x116b7,0x116b7},{0x1171d,0x1171f},{0x11722,0x11725},
	{0x11727,0x1172b},{0x11c30,0x11c36},{0x11c38,0x11c3d},{0x11c3f,0x11c3f},
	{0x11c92,0x11ca7},{0x11caa,0x11cb0},{0x11cb2,0x11cb3},{0x11cb5,0x11cb6},
	{0x16af0,0x16af4},{0x16b30,0x16b36},{0x16f8f,0x16f92},{0x1bc9d,0x1bc9e},
	{0x1d167,0x1d169},{0x1d17b,0x1d182},{0x1d185,0x1d18b},{0x1d1aa,0x1d1ad},
	{0x1d242,0x1d244},{0x1da00,0x1da36},{0x1da3b,0x1da6c},{0x1da75,0x1da75},
	{0x1da84,0x1da84},{0x1da9b,0x1da9f},{0x1daa1,0x1daaf},{0x1e000,0x1e006},
	{0x1e008,0x1e018},{0x1e01b,0x1e021},{0x1e023,0x1e024},{0x1e026,0x1e02a},
	{0x1e8d0,0x1e8d6},{0x1e944,0x1e94a},{0xe0100,0xe01ef}
}

local WIDESPACE = {
	{0x1100,0x115f},{0x231a,0x231b},{0x2329,0x232a},{0x23e9,0x23ec},
	{0x23f0,0x23f0},{0x23f3,0x23f3},{0x25fd,0x25fe},{0x2614,0x2615},
	{0x2648,0x2653},{0x267f,0x267f},{0x2693,0x2693},{0x26a1,0x26a1},
	{0x26aa,0x26ab},{0x26bd,0x26be},{0x26c4,0x26c5},{0x26ce,0x26ce},
	{0x26d4,0x26d4},{0x26ea,0x26ea},{0x26f2,0x26f3},{0x26f5,0x26f5},
	{0x26fa,0x26fa},{0x26fd,0x26fd},{0x2705,0x2705},{0x270a,0x270b},
	{0x2728,0x2728},{0x274c,0x274c},{0x274e,0x274e},{0x2753,0x2755},
	{0x2757,0x2757},{0x2795,0x2797},{0x27b0,0x27b0},{0x27bf,0x27bf},
	{0x2b1b,0x2b1c},{0x2b50,0x2b50},{0x2b55,0x2b55},{0x2e80,0x2e99},
	{0x2e9b,0x2ef3},{0x2f00,0x2fd5},{0x2ff0,0x2ffb},{0x3000,0x303e},
	{0x3041,0x3096},{0x3099,0x30ff},{0x3105,0x312d},{0x3131,0x318e},
	{0x3190,0x31ba},{0x31c0,0x31e3},{0x31f0,0x321e},{0x3220,0x3247},
	{0x3250,0x32fe},{0x3300,0x4dbf},{0x4e00,0xa48c},{0xa490,0xa4c6},
	{0xa960,0xa97c},{0xac00,0xd7a3},{0xf900,0xfaff},{0xfe10,0xfe19},
	{0xfe30,0xfe52},{0xfe54,0xfe66},{0xfe68,0xfe6b},{0xff01,0xff60},
	{0xffe0,0xffe6},{0x16fe0,0x16fe0},{0x17000,0x187ec},{0x18800,0x18af2},
	{0x1b000,0x1b001},{0x1f004,0x1f004},{0x1f0cf,0x1f0cf},{0x1f18e,0x1f18e},
	{0x1f191,0x1f19a},{0x1f200,0x1f202},{0x1f210,0x1f23b},{0x1f240,0x1f248},
	{0x1f250,0x1f251},{0x1f300,0x1f320},{0x1f32d,0x1f335},{0x1f337,0x1f37c},
	{0x1f37e,0x1f393},{0x1f3a0,0x1f3ca},{0x1f3cf,0x1f3d3},{0x1f3e0,0x1f3f0},
	{0x1f3f4,0x1f3f4},{0x1f3f8,0x1f43e},{0x1f440,0x1f440},{0x1f442,0x1f4fc},
	{0x1f4ff,0x1f53d},{0x1f54b,0x1f54e},{0x1f550,0x1f567},{0x1f57a,0x1f57a},
	{0x1f595,0x1f596},{0x1f5a4,0x1f5a4},{0x1f5fb,0x1f64f},{0x1f680,0x1f6c5},
	{0x1f6cc,0x1f6cc},{0x1f6d0,0x1f6d2},{0x1f6eb,0x1f6ec},{0x1f6f4,0x1f6f6},
	{0x1f910,0x1f91e},{0x1f920,0x1f927},{0x1f930,0x1f930},{0x1f933,0x1f93e},
	{0x1f940,0x1f94b},{0x1f950,0x1f95e},{0x1f980,0x1f991},{0x1f9c0,0x1f9c0},
	{0x20000,0x2fffd},{0x30000,0x3fffd}
}

local ceil = math.ceil

local function ininterval( ucs, tbl )
	local min, mid, max = 1, 1, #tbl

	if ucs < tbl[min][1] or ucs > tbl[max][2] then
		return false
	end

	while max >= min do
		mid = ceil( (min + max) / 2 )
		if ucs > tbl[mid][2] then
			min = mid + 1
		elseif ucs < tbl[mid][1] then
			max = mid - 1
		else
			return true
		end
	end

	return false
end

return function( ucs )
	if ucs == 0 or ucs == 0x034F or ucs == 0x2028 or ucs == 0x2029 or
		(0x200B <= ucs and ucs <= 0x200F) or 
		(0x202A <= ucs and ucs <= 0x202E) or 
		(0x2060 <= ucs and ucs <= 0x2063) then
		return 0
	elseif ucs < 32 or (ucs >= 0x7f and ucs < 0xa0) then
		return -1
	elseif ininterval( ucs, ZEROSPACE ) then
		return 0
	else
		return ininterval( ucs, WIDESPACE ) and 2 or 1 
	end
end