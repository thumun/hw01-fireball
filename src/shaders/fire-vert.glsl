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

out float offset; 

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

// parameterize amplitude --> expose to outside 
// test !! 

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

float ease_in_quadratic(float t)
{
    return t * t; 
}

float ease_in_out_quadratic(float t)
{
    if (t < 0.5)
    {
        return ease_in_quadratic(1.0f - t);
    }
    else {
        return 1.0 - ease_in_quadratic((1.0f - t) * 2.0f / 2.0f);
    }
}

float bias(float b, float t){
    return pow(t, log(b) / log(0.5f));
}

float gain (float g, float t){
    if (t < 0.5f){
        return bias(1.0f-g, 2.0*t) / 2.0f; 
    }
    else {
        return 1.0f - bias(1.0f-g, 2.0f - 2.0f*t);
    }
}

/*
float smoothstep(float edge0, float edge1, float x){
    x = clamp((x -  edge0)/(edge1 - edge0), 0.0, 1.0);
    return x*x*(3.0-2.0*x);
}
*/


// need to add 3 more 

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

    //float xVal = fs_Nor.x * 5.0f * sin(u_DeltaTime*0.1f*pos.x);
    //float yVal = fs_Nor.y * 5.0f * cos(u_DeltaTime*0.2f*pos.y);
    //float zVal = fs_Nor.z * 5.0f * sin(u_DeltaTime*0.1f*pos.z);

    //pos = vec4(pos[0], yVal, pos[1], pos[3]);

/*
    vec3 flame = vec3(0.f, 0.f, 1.f);
    float dotProd = dot(flame, fs_Nor.xyz);

    float fbmVal = fbm(pos.xyz, 5);

    if (dotProd > 0.f){
        //pos = vec4(pos.x, pos.y, -0.2f * sin(u_DeltaTime*20.0f * pos.z*dotProd) + clamp(pos.z*sin(u_DeltaTime * dotProd), 0.f, 1.0f), pos[3]);

        float offset = pos.z + fbmVal;
        pos = vec4(pos.x, pos.y, -0.2f * sin(u_DeltaTime*20.0f * fbmVal) + clamp(offset*sin(u_DeltaTime * dotProd), 0.f, 1.0f), pos[3]);


        //float noiseVal = 2.0 * sin(0.4 * u_DeltaTime);
        //pos = vec4(pos.xyz*dotProd, pos[3]);
        //pos += vec4(noiseVal*flame, pos[3])/*vec4(sinusodialNoise(pos.xyz, 0.5f, 0.2f), pos[3])*/;
    //}*/
    

    // initial deform w/ sinusodial: 

    // debugging --> just try frequency 
    // then try playing with the frequency and see whwat happens 
    // then doubble check the implementation 

    // fbm check the implementation -- if between 0,1 or -1,1
    // add vals for freq and amplitude 
    // in order to animate, scale for every point what input is --> add to component pos some small amount 

    vec3 lowfrqnoise = 2.0 * sin(0.4 * pos.xyz + u_DeltaTime) + 1.0f;

    float fbmVal = fbm(pos.xyz, u_Octaves); // how to change the freq of this? 

    pos = pos + fs_Nor * fbmVal/7.0f;

    // only affects the top of the sphere --> so flames concentrated on top 
    if (pos.z > 0.f)
    {
        // to make the long flames -- high freq, low amplitude 
        pos[2] = pos[2] * fbmVal * 3.0f; 

        // adding a slight bit of movement -> borrowed from last homework 
        // ease in/ease out - makes it wobble/pulse 
        // high freq, low amplitude to make bumps  
        pos[0] = pos[0] + 0.1 * sin(3.14 * ease_in_out_quadratic(u_DeltaTime * 0.1f) + pos[0]); // moving the verticies based on sin & time
        pos[1] = pos[1] + 0.1 * sin(3.14 * ease_in_out_quadratic(u_DeltaTime * 0.1f) + pos[1]); // moving the verticies based on sin & time

    } 

    offset = fbmVal;

    vec4 modelposition = u_Model * pos;   // Temporarily store the transformed vertex positions for use below

    fs_LightVec = lightPos - modelposition;  // Compute the direction in which the light source lies

    gl_Position = u_ViewProj * modelposition;// gl_Position is a built-in variable of OpenGL which is
                                             // used to render the final positions of the geometry's vertices
                                             

   fs_Pos = gl_Position;
}