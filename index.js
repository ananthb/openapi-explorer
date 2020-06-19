import Elm from "./src/Main.elm";
import "rapidoc";

const serversKey = "servers";
const storedServers = window.localStorage.getItem(serversKey);
const flags = storedServers ? JSON.parse(storedServers) : null;
const program = Elm.Main.init({flags: flags});
program.ports.saveServers
    .subscribe(servers => window.localStorage.setItem(serversKey, JSON.stringify(servers)));
