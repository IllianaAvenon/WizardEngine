
struct VertexToPixel
{
	// Data type
	//  |
	//  |   Name          Semantic
	//  |    |                |
	//  v    v                v
	float4 position		: SV_POSITION;
	float3 normal		: NORMAL;
	float2 uv			: TEXCOORD;
	float3 tangent		: TANGENT;
};

struct DirectionalLight
{
	float4 AmbientColour;
	float4 DiffuseColour;
	float3 Direction;
};

Texture2D diffuseTexture	: register(t0);
Texture2D normalTexture		: register(t1);
SamplerState basicSampler	: register(s0);


cbuffer externalData : register(b1)
{
	DirectionalLight light;
	DirectionalLight topLight;
};

float4 LightValue(DirectionalLight newLight, VertexToPixel input)
{
	input.normal = normalize(input.normal);

	float3 toLight = normalize(newLight.Direction);
	float NdotL = dot(input.normal, -toLight);
	NdotL = saturate(NdotL);

	return newLight.AmbientColour + (newLight.DiffuseColour * NdotL);
}

float3 TangentToWorldSpace(float3 aTangent, float3 aNormal, float2 aInput)
{
	float3 normalFromMap = normalTexture.Sample(basicSampler, aInput).rgb;

	// Unpack normal from texture sample. (
	float3 unpackedNormal = normalFromMap * 2.0f - 1.0f;

	// Create TBN matrix
	float3 N = aNormal;
	float3 T = aTangent - (dot(aTangent, N) * N);
	float3 B = cross(N, T);

	float3x3 TBN = float3x3(T, B, N);

	// Transform normal from map
	float3 finalNormal = mul(unpackedNormal, TBN);

	return finalNormal;
}

float4 main(VertexToPixel input) : SV_TARGET
{
	float3 finalNormal = TangentToWorldSpace(normalize(input.tangent), input.normal, input.uv);

	float4 surfaceColour = diffuseTexture.Sample(basicSampler, finalNormal);

	return  float4(surfaceColour.rgb * (LightValue(light, input) + LightValue(topLight, input)), 1);
}

