function ls()
	l = file.list();
    for k,v in pairs(l) do
      print("name:"..k..", size:"..v)
    end
end

function hsv2rgb(h, s, v)
	if s == 0 then
		return v, v, v
	end

	local i = h / 43
	local rem = (h - (i * 43)) * 6

	local p = bit.rshift(v * (255 - s), 8)
	local q = bit.rshift(v * (255 - bit.rshift(rem * s, 8)), 8)
	local t = bit.rshift(v * (255 - bit.rshift((255 - rem) * s, 8)), 8)

	if i == 0 then
		return v, t, p
	elseif i == 1 then
		return q, v, p
	elseif i == 2 then
		return p, v, t
	elseif i == 3 then
		return p, q, v
	elseif i == 4 then
		return t, p, v
	else
		return v, p, q
	end
end
