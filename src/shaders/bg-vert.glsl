#version 300 es

uniform mat4 u_Model;       // The matrix that defines the transformation of the
                            // object we're rendering. In this assignment,
                            // this will be the result of traversing your scene graph.

uniform mat4 u_ModelInvTr;  // The inverse transpose of the model matrix.
                            // This allows us to transform the object's normals properly
                            // if the object has been non-uniformly scaled.

uniform mat4 u_ViewProj;    // The matrix that defines the camera's transformation.
                            // We've written a static matrix for you to use for HW2,
                            // but in HW3 you'll have to generate one yourself

uniform float u_DeltaTime; 
uniform int u_Octaves; 

in vec4 vs_Pos;             // The array of vertex positions passed to the shader

in vec4 vs_Nor;             // The array of vertex normals passed to the shader

in vec4 vs_Col;             // The array of vertex colors passed to the shader.

out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Pos;

const vec4 lightPos = vec4(5, 5, 3, 1); //The position of our virtual light, which is used to compute the shading of
                                        //the geometry in the fragment shader.

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

vec3 sinusodialNoise(vec3 pos, float amp, float freq)
{
    return pos + vec3(amp * sin(3.14 * freq * u_DeltaTime + pos.x), 
                    amp * sin(3.14 * freq * u_DeltaTime + pos.y),
                    amp * sin(3.14 * freq * u_DeltaTime + pos.z));
}

// toolbox funcs from lec slides!
/*
float bias(float b, float t){
    return pow(t, log(b) / log(0.5f));
}

float gain (float g, float t){
    if (t < 0.5f){
        return bias(1.0f-g, 2*t) / 2.0f; 
    }
    else {
        return 1.0f - bias(1.0f-g, 2.0f - 2.0f*t);
    }
}
*/


void main()
{
    fs_Col = vs_Col;                         // Pass the vertex colors to the fragment shader for interpolation

    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);          // Pass the vertex normals to the fragment shader for interpolation.
                                                            // Transform the geometry's normals by the inverse transpose of the
                                                            // model matrix. This is necessary to ensure the normals remain
                                                            // perpendicular to the surface after the surface is transformed by
                                                            // the model matrix.

    vec4 pos = vs_Pos; 

    //vec3 dir = vec3(0.0, 1.0, 0.0);
    //float dotProd = dot(fs_Nor.xyz, dir);
    //pos = vec4(pos.x, pos.y, -0.2f * sin(u_DeltaTime*20.0f * pos.z*dotProd) + clamp(pos.z*sin(u_DeltaTime * dotProd), 0.f, 1.0f), pos[3]);

    vec4 modelposition = u_Model * pos;   // Temporarily store the transformed vertex positions for use below

    fs_LightVec = lightPos - modelposition;  // Compute the direction in which the light source lies

    gl_Position = u_ViewProj * modelposition;// gl_Position is a built-in variable of OpenGL which is
                                             // used to render the final positions of the geometry's vertices
                                             

   fs_Pos = gl_Position;
}