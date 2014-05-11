#!/bin/bash
shopt -s nullglob

rm -r new-data
mkdir new-data

echo "[*] Levels..."
mkdir new-data/levels
cp levels/perso000.txt new-data/levels/perso.txt
cp levels/lost000.txt new-data/levels/lost.txt
help_to_remove=()
diagrams_to_remove=()
for f in levels/*; do
	[[ $f =~ levels/(scene|free|train|defi)([0-9]{1})([0-9]{2}).txt ]]
	cat=${BASH_REMATCH[1]}
	grp=${BASH_REMATCH[2]}
	idx=${BASH_REMATCH[3]}

	if [[ "$cat" == "" ]]; then continue; fi
	cat_char="?"
	case "$cat" in
		scene) cat_char="S" ;;
		free) cat_char="F" ;;
		train) cat_char="E" ;;
		defi) cat_char="C" ;;
	esac
	
        if [[ "$idx" == "00" ]]; then
			echo "    -> Moving chapter descriptor for ${cat}${grp} ... "
			cp $f new-data/levels/${cat_char}0${grp}.txt
			continue
        fi

	new_f=${cat_char}0${grp}L${idx}
	echo "    -> Converting ${cat}${grp}${idx} to ${new_f} ... "

	mkdir new-data/levels/${new_f}

	target=new-data/levels/${new_f}/scene.txt
	scriptrank=0
	scripts=()
	diagramrank=0
	diagrams=()
	while read -r line; do
		[[ $line =~ ^([a-zA-Z]+) ]]
		cmd=${BASH_REMATCH[1]}
		
		case "$cmd" in
			"Instructions" | "Satellite" | "Loading" | "SoluceFile")
				filename=""
				case "$cmd" in
					Instructions) filename="help" ;;
					Satellite) filename="report" ;;
					Loading) filename="prog" ;;
					SoluceFile) filename="soluce" ;;
				esac
				
				echo "       -> Converting ${cmd} help file ..."
				
				[[ "$line" =~ name=\"([a-zA-Z0-9.]+)\" ]]
				file=${BASH_REMATCH[1]}
				for lang in E P F D R; do
					in="help/${lang}/${file}"
					out="new-data/levels/${new_f}/${filename}.${lang}.txt"
					while read -r line2; do
						[[ "$line2" =~ \\image[[:space:]]([a-zA-Z0-9]+)[[:space:]]([0-9]+)[[:space:]]([0-9]+)\; ]]
						fname=${BASH_REMATCH[1]}
						sizex=${BASH_REMATCH[2]}
						sizey=${BASH_REMATCH[3]}
						if [[ "$fname" != "" ]]; then
							diagram=$diagramrank
							for i in "${!diagrams[@]}"; do
								if [[ "$fname" == "${diagrams[$i]}" ]]; then
									diagram=$i
									break
								fi
							done
							if [[ $diagram == $diagramrank ]]; then
								echo "          -> Converting diagram ${fname}.png ..."
							fi
							formatted_diagram=`printf "%03d" $diagram`
							cp "icons/${fname}.png" "new-data/levels/${new_f}/diagram${formatted_diagram}.png"
							line2=`echo $line2 | sed -e "s@\\image [a-zA-Z0-9]* [0-9]* [0-9]*;@image ${diagram} ${sizex} ${sizey};@g"`
							diagrams[$diagram]="$fname"
							diagrams_to_remove+=("${fname}.png")
							if [[ $diagram == $diagramrank ]]; then
								diagramrank=$(($diagramrank+1))
							fi
						fi
						echo "$line2" >> $out
						help_to_remove+=("${file}")
					done < "$in"
				done
				echo $line | sed -e "s@name=\"[a-zA-Z0-9.]*\"@name=\"%lvl%/${filename}.%lng%.txt\"@g" >> $target
			;;
			
			"EndingFile")
				[[ "$line" =~ win=([0-9]+) ]]
				winfile=${BASH_REMATCH[1]}
				[[ "$line" =~ lost=([0-9]+) ]]
				lostfile=${BASH_REMATCH[1]}
				
				line="EndingFile "
				if [[ $winfile != "" ]]; then
					echo "       -> Converting win mission script win`printf "%03d" $winfile`.txt ..."
					in="levels/win`printf "%03d" $winfile`.txt"
					out="new-data/levels/${new_f}/win.txt"
					while read -r line2; do
						[[ $line2 =~ ^([a-zA-Z]+) ]]
						cmd=${BASH_REMATCH[1]}
		
						case "$cmd" in
							"CreateObject")
								for scriptid in 1 2 3 4 5 6 7 8 9 10; do
									[[ "$line2" =~ script${scriptid}=\"([a-zA-Z0-9.]+)\" ]]
									file=${BASH_REMATCH[1]}
									if [[ "$file" != "" ]]; then
										script=$scriptrank
										for i in "${!scripts[@]}"; do
											if [[ "$file" == "${scripts[$i]}" ]]; then
												script=$i
												break
											fi
										done
										if [[ $script == $scriptrank ]]; then
											echo "          -> Converting script ${file} ..."
										fi
										formatted_script=`printf "%03d" $script`
										cp "ai/${file}" "new-data/levels/${new_f}/script${formatted_script}.txt"
										line2=`echo $line2 | sed -e "s@script${scriptid}=\"[a-zA-Z0-9.]*\"@script${scriptid}=\"%lvl%/script${formatted_script}.txt\"@g"`
										scripts[$script]="$file"
										if [[ $script == $scriptrank ]]; then
											scriptrank=$(($scriptrank+1))
										fi
									fi
								done
								echo "$line2" >> $out
							;;
			
							*)
								echo "$line2" >> $out
							;;
						esac
					done < "$in"
					line="$line win=\"%lvl%/win.txt\""
				fi
				if [[ $lostfile != "" ]]; then
					line="$line lost=\"lost.txt\""
				fi
				echo $line >> $target
			;;
			
			"TerrainRelief" | "TerrainResource")
				[[ "$line" =~ image=\"([a-zA-Z0-9.]+)\" ]]
				file=${BASH_REMATCH[1]}
				
				filename=""
				case "$cmd" in
					TerrainRelief) filename="relief"; echo "       -> Converting relief file ${file} ..." ;;
					TerrainResource) filename="resource"; echo "       -> Converting resource file ${file} ..." ;;
				esac
				
				cp "textures/${file}" "new-data/levels/${new_f}/${filename}.png"
				echo $line | sed -e "s@image=\"[a-zA-Z0-9.]*\"@image=\"%lvl%/${filename}.png\"@g" >> $target
			;;
			
			"CreateObject")
				for scriptid in 1 2 3 4 5 6 7 8 9 10; do
					[[ "$line" =~ script${scriptid}=\"([a-zA-Z0-9.]+)\" ]]
					file=${BASH_REMATCH[1]}
					if [[ "$file" != "" ]]; then
						script=$scriptrank
						for i in "${!scripts[@]}"; do
							if [[ "$file" == "${scripts[$i]}" ]]; then
								script=$i
								break
							fi
						done
						if [[ $script == $scriptrank ]]; then
							echo "       -> Converting script ${file} ..."
						fi
						formatted_script=`printf "%03d" $script`
						cp "ai/${file}" "new-data/levels/${new_f}/script${formatted_script}.txt"
						line=`echo $line | sed -e "s@script${scriptid}=\"[a-zA-Z0-9.]*\"@script${scriptid}=\"%lvl%/script${formatted_script}.txt\"@g"`
						scripts[$script]="$file"
						if [[ $script == $scriptrank ]]; then
							scriptrank=$(($scriptrank+1))
						fi
					fi
				done
				echo "$line" >> $target
			;;
			
			"NewScript")
				[[ "$line" =~ name=\"([a-zA-Z0-9.]+)\" ]]
				file=${BASH_REMATCH[1]}
				if [[ "$file" != "" ]]; then
					script=$scriptrank
					for i in "${!scripts[@]}"; do
						if [[ "$file" == "${scripts[$i]}" ]]; then
							script=$i
							break
						fi
					done
					if [[ $script == $scriptrank ]]; then
						echo "       -> Converting script ${file} ..."
					fi
					formatted_script=`printf "%03d" $script`
					cp "ai/${file}" "new-data/levels/${new_f}/script${formatted_script}.txt"
					line=`echo $line | sed -e "s@name=\"[a-zA-Z0-9.]*\"@name=\"%lvl%/script${formatted_script}.txt\"@g"`
					scripts[$script]="$file"
					if [[ $script == $scriptrank ]]; then
						scriptrank=$(($scriptrank+1))
					fi
				fi
				echo "$line" >> $target
			;;
			
			*)
				echo "$line" >> $target
			;;
		esac
	done < "$f"
done

echo "[*] Music..."
mkdir new-data/music
for f in music/*; do
	[[ $f =~ music/music([0-9]{3}).ogg ]]
	track=${BASH_REMATCH[1]}
	if [[ $track != "" ]]; then
		echo -n "    -> Old track $track ... "
		cp "$f" "new-data/music/track`printf "%02d" ${track#00}`.ogg"
		echo "ok"
	else
		[[ $f =~ music/([a-zA-Z0-9]*).ogg ]]
		file=${BASH_REMATCH[1]}
		echo -n "    -> New track $file ... "
		cp "$f" "new-data/music/$file.ogg"
		echo "ok"
	fi
done

echo "[*] Models..."
echo "    -> Old model format"
mkdir new-data/models-old
cp models/* new-data/models-old/
echo "    -> New model format"
mkdir new-data/models
cp models-new/* new-data/models/

echo "[*] Textures..."
mkdir new-data/textures
echo "    -> Copying all"
cp textures/* new-data/textures/
echo "    -> Removing old" #TODO: Waste of time :d
rm new-data/textures/relief*.png
rm new-data/textures/res*.png

echo "[*] Sounds..."
echo "    -> Copying"
mkdir new-data/sounds
cp sounds/* new-data/sounds/

echo "[*] Fonts..."
echo "    -> Copying"
mkdir new-data/fonts
cp fonts/* new-data/fonts/

echo "[*] Help..."
echo "    -> Copying text files"
mkdir new-data/help
help_to_remove=($(printf "%s\n" "${help_to_remove[@]}" | sort -u))
diagrams=()
for f in $(find help/E/ -name '*'); do
	if [ -d "$f" ]; then
		continue
	fi
	
	[[ "$f" =~ help/E/([a-zA-Z0-9./]+) ]]
	file=${BASH_REMATCH[1]}
	found=false
	for i in "${help_to_remove[@]}"; do
		if [[ "$file" == "$i" ]]; then
			found=true
			break
		fi
	done
	if [ "$found" = false ]; then
		echo "       -> ${file}"
		for lang in E P F D R; do
			mkdir -p `dirname "new-data/help/${lang}/${file}"`
			while read -r line; do
				[[ "$line" =~ \\image[[:space:]]([a-zA-Z0-9]+)[[:space:]]([0-9]+)[[:space:]]([0-9]+)\; ]]
				fname=${BASH_REMATCH[1]}
				sizex=${BASH_REMATCH[2]}
				sizey=${BASH_REMATCH[3]}
		
				if [[ "$fname" != "" ]]; then
					found=false
					for i in "${diagrams[@]}"; do
						if [[ "$fname" == "$i" ]]; then
							found=true
							break
						fi
					done
					if [ "$found" = false ]; then
						diagrams+=("${fname}")
					fi
				fi
				echo "$line" >> "new-data/help/${lang}/${file}"
			done < "help/${lang}/${file}"
		done
	fi
done
echo "    -> Copying images"
mkdir new-data/help/images
for fname in "${diagrams[@]}"; do
	echo "       -> ${fname}.png"
	cp "icons/${fname}.png" "new-data/help/images/"
done
