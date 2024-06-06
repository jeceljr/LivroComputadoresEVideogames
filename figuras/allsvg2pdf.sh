for fname in *.svg
do
	rsvg-convert -f pdf -o `basename $fname svg`pdf $fname
done
