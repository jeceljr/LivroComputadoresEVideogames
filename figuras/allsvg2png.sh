for fname in *.svg
do
	rsvg-convert -f png -o $fname.png $fname
done
