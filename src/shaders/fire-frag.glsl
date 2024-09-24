#version 300 es

precision highp float;

uniform vec4 u_Color; // The color with which to render this instance of geometry.
uniform vec4 u_Color2; // The color with which to render this instance of geometry.

//uniform vec3 u_RandomPoints[200];
//uniform int u_RandomPointsSize; 

uniform float u_DeltaTime; 
uniform int u_Octaves; 

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Pos;
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in float offset; 


out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

// got the values from here https://lygia.xyz/generative/srandom and 4600 slides 
vec3 random(vec3 p) {
    p = (vec3(dot(p, vec3(127.1, 311.7,70.0)),
                 dot(p, vec3(269.5,183.3,250.0)),
                 dot(p, vec3(100.5,270.3,120.0))));

    return fract(sin(p)*43758.5453);
}

// used 4600 lec slides as ref 
// and used this: https://www.youtube.com/watch?v=4066MndcyCk 
float computeWorleyNoise(vec3 currPos)
{
    vec3 posInt = floor(currPos);
    vec3 posFract = fract(currPos); 
    float minDist = 1.0f; // max val
    
    for (int z = -1; z <= 1; z++){
        for (int y = -1; y <= 1; y++){
            for (int x = -1; x <= 1; x++){
                vec3 neighbor = vec3(float(x), float(y), float(z)); // dir of neighbor 
                vec3 point = random(posInt + neighbor); // gets voronoi point in neighboring cell 
                point = 0.5 + 0.5*sin(u_DeltaTime + 6.2831*point);
                vec3 diff = neighbor + point - posFract; // gets distance of point and currPos
                float dist = length(diff); 
                minDist = min(minDist, dist); // updates min if new min reached 
            }
        } 
    }

    return minDist; 
}

// borrowed code!
// https://gist.github.com/patriciogonzalezvivo/670c22f3966e662d2f83
float fbm(vec3 x, int octaves) {
	float v = 0.0f;
	float a = 0.5f;
	vec3 shift = vec3(100);
	for (int i = 0; i < octaves; ++i) {
		v += a * computeWorleyNoise(x);
		x = x * 2.0 + shift;
		a *= 0.5;
	}
	return v;
}

void main()
{
    // Material base color (before shading)
        vec4 outColor = u_Color;
        vec4 centerColor = u_Color2;

        
        //float dist = computeWorleyNoise(vec3(fs_Pos[0], fs_Pos[1], fs_Pos[2])); // adjusts the color to create noise effect 

        //vec3 color = diffuseColor.rgb * lightIntensity; 

        // Compute final shaded color

        //float zdist = length(fs_Pos.xyz);
        //vec3 newColor = (1.0f-zdist)*diffuseColor.rgb + zdist*vec3(1.f, 1.f, 1.f);

        vec3 newColor = vec3(0.f, 0.f, 0.f);

        //float dist = length(fs_Pos.z);
        /*
        if(dist <= 1.0f)
        {
            newColor = vec3(1.0f, 1.0f, 1.0f);
        }
        */
        float normalizedDistance = clamp(fs_Pos.y, 0.0, 1.0);
        newColor = (1.0f-fs_Pos.z)*outColor.rgb + fs_Pos.z*centerColor.rgb;

        float fbmval = fbm(fs_Pos.xyz, 8) /** clamp(sin(u_DeltaTime), 0.f, 1.f)*/;

        // mixing based on dist
        vec3 color = mix(outColor.rgb, centerColor.rgb, normalizedDistance);

        //vec4 tempTest = vec4(newColor[0], newColor[1], newColor[2], 0.3f);

        //newColor = mix(vec4(newColor.rgb, outColor.a), tempTest*fbmval, fbmval);
        float r = smoothstep(newColor.r, newColor.r*fbmval, 0.1f);
        float g = smoothstep(newColor.g, newColor.g*fbmval, 0.5f);
        float b = smoothstep(newColor.b, newColor.b*fbmval, 0.1f);

        newColor = mix(newColor.rgb, vec3(r, g, b), fbmval);

        //out_Col = vec4(diffuseColor.rgb * dist, diffuseColor.a);

        out_Col = vec4(newColor.xyz, outColor.a);



}
