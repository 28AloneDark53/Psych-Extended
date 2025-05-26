function onBeatHit()
	if curBeat >= 224 and curBeat < 256 then
	if curBeat % 2 == 0 then
		noteTweenAngle('ZO', 0, 15, 0.2, 'circOut')
		noteTweenAngle('ZI', 1, 15, 0.2, 'circOut')
		noteTweenAngle('ZU', 2, 15, 0.2, 'circOut')
		noteTweenAngle('ZY', 3, 15, 0.2, 'circOut')
		noteTweenAngle('ZT', 4, 15, 0.2, 'circOut')
		noteTweenAngle('ZR', 5, 15, 0.2, 'circOut')
		noteTweenAngle('ZE', 6, 15, 0.2, 'circOut')
		noteTweenAngle('ZW', 7, 15, 0.2, 'circOut')
		noteTweenAngle('ZQ', 8, 15, 0.2, 'circOut')
		noteTweenAngle('Z', 9, 15, 0.2, 'circOut')
	else
		noteTweenAngle('WE', 0, -15, 0.2, 'circOut')
		noteTweenAngle('WA', 1, -15, 0.2, 'circOut')
		noteTweenAngle('W', 2, -15, 0.2, 'circOut')
		noteTweenAngle('YS', 3, -15, 0.2, 'circOut')
		noteTweenAngle('YJ', 4, -15, 0.2, 'circOut')
		noteTweenAngle('YH', 5, -15, 0.2, 'circOut')
		noteTweenAngle('YV', 6, -15, 0.2, 'circOut')
		noteTweenAngle('YX1', 7, -15, 0.2, 'circOut')
		noteTweenAngle('YY', 8, -15, 0.2, 'circOut')
		noteTweenAngle('YX', 9, -15, 0.2, 'circOut')
	end
	end
	if curBeat == 256 then
		noteTweenAngle('UU', 0, 0, 0.2, 'circOut')
		noteTweenAngle('TT', 1, 0, 0.2, 'circOut')
		noteTweenAngle('RR', 2, 0, 0.2, 'circOut')
		noteTweenAngle('EE', 3, 0, 0.2, 'circOut')
		noteTweenAngle('WW', 4, 0, 0.2, 'circOut')
		noteTweenAngle('QQ', 5, 0, 0.2, 'circOut')
		noteTweenAngle('MM', 6, 0, 0.2, 'circOut')
		noteTweenAngle('NN', 7, 0, 0.2, 'circOut')
		noteTweenAngle('BB', 8, 0, 0.2, 'circOut')
		noteTweenAngle('VV', 9, 0, 0.2, 'circOut')
	end
end