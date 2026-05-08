const std = @import("std");

pub const ShaderStage = enum {
    vertex,
    fragment,
    compute,
};

pub const Shader = struct {
    name: []const u8,
    vertex_src: []const u8,
    fragment_src: []const u8,

    pub fn init(name: []const u8) Shader {
        return Shader{
            .name = name,
            .vertex_src = defaultVertexSrc(),
            .fragment_src = defaultFragmentSrc(),
        };
    }

    fn defaultVertexSrc() []const u8 {
        return \\struct VSInput {
        \\  @location(0) position: vec2<f32>,
        \\  @location(1) color: vec4<f32>,
        \\  @location(2) uv: vec2<f32>,
        \\}
        \\struct VSOutput {
        \\  @builtin(position) position: vec4<f32>,
        \\  @location(0) color: vec4<f32>,
        \\  @location(1) uv: vec2<f32>,
        \\}
        \\@vertex fn main(input: VSInput) -> VSOutput {
        \\  var output: VSOutput;
        \\  output.position = vec4<f32>(input.position, 0.0, 1.0);
        \\  output.color = input.color;
        \\  output.uv = input.uv;
        \\  return output;
        \\}
        ;
    }

    fn defaultFragmentSrc() []const u8 {
        return \\@fragment fn main(input: VSOutput) -> @location(0) vec4<f32> {
        \\  return input.color;
        \\}
        ;
    }
};
