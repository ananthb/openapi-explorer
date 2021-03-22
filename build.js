import {build, serve} from "esbuild";
import ElmPlugin from "esbuild-plugin-elm";

const productionBuild = process.env.NODE_ENV === "production";
const buildOpts = {
    entryPoints: ["index.js"],
    bundle: true,
    outdir: "public",
    plugins: [ElmPlugin({ debug: !productionBuild })],
    minify: productionBuild,
}

try {
    productionBuild ?
        await build(buildOpts) :
        await serve({ servedir: "public" }, buildOpts);
} catch (error) {
    console.error(error);
    process.exit(1);
}