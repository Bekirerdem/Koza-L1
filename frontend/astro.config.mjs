// @ts-check
import {defineConfig} from "astro/config";
import tailwindcss from "@tailwindcss/vite";

export default defineConfig({
    site: "https://koza.bekirerdem.dev",
    vite: {
        // Astro 5 ships its own pinned Vite, while @tailwindcss/vite resolves
        // the user-installed Vite. Both expose Vite Plugin types from
        // different copies, so structural compatibility check fails. The
        // plugin is fully compatible at runtime; we only bypass the type
        // mismatch here.
        plugins: [/** @type {any} */ (tailwindcss())],
    },
    build: {
        inlineStylesheets: "auto",
    },
    image: {
        domains: [],
    },
});
