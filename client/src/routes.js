import Home from "./components/Home/Home.svelte";
import CreateToken from "./components/CreateToken/CreateToken.svelte";
import TokenPage from "./components/TokenPage/TokenPage.svelte";
import NotFound from "./components/NotFound/NotFound.svelte";
import Exchange from "./components/Exchange/Exchange.svelte";

export default {
  "/": Home,
  "/createtoken": CreateToken,
  "/token/:id?": TokenPage,
  "/exchange/:orderID?": Exchange,
  "*": NotFound
};
