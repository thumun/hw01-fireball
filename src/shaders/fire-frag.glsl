#version 300 es

precision highp float;

uniform vec4 u_Color; // The color with which to render this instance of geometry.
//uniform vec3 u_RandomPoints[200];
//uniform int u_RandomPointsSize; 

uniform float u_DeltaTime; 

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Pos;
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;

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
        vec4 diffuseColor = u_Color;

        // Calculate the diffuse term for Lambert shading
        //float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
        // Avoid negative lighting values
        //diffuseTerm = clamp(diffuseTerm, 0, 1);

        //float ambientTerm = 0.2;

        //float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier
                                                            //to simulate ambient lighting. This ensures that faces that are not
                                                            //lit by our point light are not completely black.

        //float dist = computeWorleyNoise(vec3(fs_Pos[0], fs_Pos[1], fs_Pos[2])); // adjusts the color to create noise effect 
        float dist = fbm(fs_Pos.xyz, 8) /** clamp(sin(u_DeltaTime), 0.f, 1.f)*/;

        //vec3 color = diffuseColor.rgb * lightIntensity; 

        // Compute final shaded color
        out_Col = vec4(diffuseColor.rgb * dist, diffuseColor.a);
}
