#!/bin/bash
QSB='../../../ext/6.7.3/msvc2019_64/bin/qsb.exe --glsl "120,300 es,310 es,320 es,310,320,330,400,410,420" --hlsl 50 --msl 12'

NO_DIGITAL_LENS="vec2 digital_undistort_point(vec2 uv) { return uv; } vec2 digital_distort_point(vec2 uv) { return uv; }"

DISTORTION_MODELS=( "opencv_fisheye" "opencv_standard" "poly3" "poly5" "ptlens" "insta360" "sony" )
DIGITAL_LENSES=( "" "gopro_superview" "gopro_hyperview" "digital_stretch" )

for i in "${DISTORTION_MODELS[@]}"
do
    for d in "${DIGITAL_LENSES[@]}"
    do
        # GoPro superview/hyperview is only used with opencv_fisheye
        if [ "$d" = "gopro_superview" -o "$d" = "gopro_hyperview" ] && [ "$i" != "opencv_fisheye" ]; then
            continue
        fi

        if [ -z "$d" ]; then
            FUNCS="$NO_DIGITAL_LENS"
        else
            FUNCS=`cat ../../core/stabilization/distortion_models/$d.glsl`
            d=_$d
        fi

        if [ "$i" != "sony" ]; then
            FUNCS="$FUNCS vec2 process_coord(vec2 uv, float idx) { return uv; } "
        fi

        FUNCS="$FUNCS `cat ../../core/stabilization/distortion_models/$i.glsl`"
        SHADER=`cat ../undistort.frag`

        echo "${SHADER/LENS_MODEL_FUNCTIONS;/"$FUNCS"}" > tmp.frag

        if [ "$i" = "sony" ]; then
           echo " float get_mesh_data(int idx) { return texture(texMeshData, vec2(0, idx / 1023.0)).r; } " >> tmp.frag
        fi

        eval "$QSB -o undistort_$i$d.frag.qsb tmp.frag"
        rm tmp.frag
    done
done

eval "$QSB -o texture.vert.qsb ../texture.vert"
