<script lang="ts">
  import Router from "svelte-spa-router";
  import routes from "./routes";
  import Header from "./components/Header/Header.svelte";
</script>

<style lang="scss">
  main {
    height: 100%;
  }
</style>

<main>
  <Header />
  <Router {routes} />
</main>
