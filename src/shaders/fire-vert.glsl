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

in vec4 vs_Pos;             // The array of vertex positions passed to the shader

in vec4 vs_Nor;             // The array of vertex normals passed to the shader

in vec4 vs_Col;             // The array of vertex colors passed to the shader.

out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Pos;

const vec4 lightPos = vec4(5, 5, 3, 1); //The position of our virtual light, which is used to compute the shading of
                                        //the geometry in the fragment shader.

vec3 sinusodialNoise(vec3 pos, float amp, float freq)
{
    return pos + vec3(amp * sin(3.14 * freq * u_DeltaTime + pos.x), 
                    amp * sin(3.14 * freq * u_DeltaTime + pos.y),
                    amp * sin(3.14 * freq * u_DeltaTime + pos.z));
}

void main()
{
    fs_Col = vs_Col;                         // Pass the vertex colors to the fragment shader for interpolation

    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);          // Pass the vertex normals to the fragment shader for interpolation.
                                                            // Transform the geometry's normals by the inverse transpose of the
                                                            // model matrix. This is necessary to ensure the normals remain
                                                            // perpendicular to the surface after the surface is transformed by
                                                            // the model matrix.

    vec4 modelposition = u_Model * vs_Pos;   // Temporarily store the transformed vertex positions for use below

    vec4 pos = modelposition; 

    vec3 flame = vec3(0.f, 0.f, 1.f);
    float dotProd = dot(flame, fs_Nor.xyz);

    if (dotProd > 0.f){
        pos = vec4(pos.x, pos.y, -0.2f * sin(u_DeltaTime*20.0f * pos.z*dotProd) + clamp(pos.z*sin(u_DeltaTime * dotProd), 0.f, 1.0f), pos[3]);

        //float noiseVal = 2.0 * sin(0.4 * u_DeltaTime);
        //pos = vec4(pos.xyz*dotProd, pos[3]);
        //pos += vec4(noiseVal*flame, pos[3])/*vec4(sinusodialNoise(pos.xyz, 0.5f, 0.2f), pos[3])*/;
    }


    fs_LightVec = lightPos - pos;  // Compute the direction in which the light source lies

    gl_Position = u_ViewProj * pos;// gl_Position is a built-in variable of OpenGL which is
                                             // used to render the final positions of the geometry's vertices
                                             

   fs_Pos = gl_Position;
}