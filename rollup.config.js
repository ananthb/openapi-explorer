import {terser} from "rollup-plugin-terser";
import resolve from "@rollup/plugin-node-resolve";
import elm from "rollup-plugin-elm";

const terse = Boolean(process.env.TERSE)

let plugins = [
    resolve(),
    elm({compiler: {debug: !terse, optimize: terse}}),
];

if (terse) {
    plugins.push(
        terser({
            ecma: 6,
            output: {comments: false},
            compress: {
                pure_funcs: [
                    "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9",
                    "A2", "A3", "A4", "A5", "A6", "A7", "A8", "A9"
                ],
                pure_getters: true,
                keep_fargs: false,
                unsafe_comps: true,
                unsafe: true,
                passes: 2
            },
            mangle: true
        })
    )
}

export default {
    input: ["index.js"],
    output: {
        dir: "public",
        format: "esm",
        sourcemap: false,
    },
    plugins: plugins
};
