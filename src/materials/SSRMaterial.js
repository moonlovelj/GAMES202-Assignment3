class SSRMaterial extends Material {
    constructor(diffuseMap, specularMap, light, camera, vertexShader, fragmentShader) {
        let lightIntensity = light.mat.GetIntensity();
        let lightVP = light.CalcLightVP();
        let lightDir = light.CalcShadingDirection();

        super({
            'uLightRadiance': { type: '3fv', value: lightIntensity },
            'uLightDir': { type: '3fv', value: lightDir },

            'uGDiffuse': { type: 'texture', value: camera.fbo.textures[0] },
            'uGDepth': { type: 'textureMipmap', value: camera.fbo.textures[1] },
            'uGNormalWorld': { type: 'texture', value: camera.fbo.textures[2] },
            'uGShadow': { type: 'texture', value: camera.fbo.textures[3] },
            'uGPosWorld': { type: 'texture', value: camera.fbo.textures[4] },
        }, [], vertexShader, fragmentShader);
    }

    // ganerateMipmap(gl, texture, fbo, textureIndex) {
    //     //gl.texImage2D(gl.TEXTURE_2D, 1, gl.RGBA, canvas_width, canvas_height, 0, gl.RGBA, gl.FLOAT, pixels);
    // }

    
    generateMipmaps(gl, gbuffer) {
        return;
        // depth
        gl.readBuffer(gbuffer.attachments[1]);
        const pixels = new Float32Array(4*canvas_width*canvas_height);
        gl.readPixels(0, 0, canvas_width, canvas_height, gl.RGBA, gl.FLOAT, pixels);

        var width = canvas_width;
        var mipmaps = [];
        mipmaps.push(pixels);
        while (width > 1) {
            const parentPixel = mipmaps[mipmaps.length-1];
            var parentWidth = width;
            width /= 2;
            const levelPixels = new Float32Array(4*width*width);
            for (var i = 0; i < width; i++) {
                for (var j=0; i < width; j++) {
                    var row0 = i*2, row1 = i*2+1;
                    var col0 = j*2, col1 = j*2+1;
                    levelPixels[j+i*width] = Math.min(parentPixel[row0*parentWidth+col0], 
                        parentPixel[row0*parentWidth+col1],
                        parentPixel[row1*parentWidth+col0],
                        parentPixel[row1*parentWidth+col1]);
                }
            }

            mipmaps.push(levelPixels);
        }
    }
}

async function buildSSRMaterial(diffuseMap, specularMap, light, camera,  vertexPath, fragmentPath) {
    let vertexShader = await getShaderString(vertexPath);
    let fragmentShader = await getShaderString(fragmentPath);

    return new SSRMaterial(diffuseMap, specularMap, light, camera, vertexShader, fragmentShader);
}