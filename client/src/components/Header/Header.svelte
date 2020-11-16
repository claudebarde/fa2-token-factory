<script lang="ts">
</script>

<style lang="scss">
  header {
    margin: 0px;
    padding: 0px;
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    display: flex;
    justify-content: space-between;
    align-items: center;
    font-size: 1.2rem;
    background-color: #2d3748;
    color: white;

    div {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 0px 10px;
      height: 50px;
    }
  }

  .navigation {
    padding: 0;
    margin: 0;
    height: 100%;
    font-size: 1.1rem;

    div {
      cursor: pointer;
      background-color: #2d3748;
      transition: 0.3s;

      &:hover {
        background-color: lighten(#2d3748, 10);
      }
    }
  }

  .taquito-logo {
    width: 40px;
  }
</style>

<header>
  <div>Tezos Token Factory</div>
  <div>
    <div class="navigation">
      <div>Create Token</div>
      <div>Find Token</div>
    </div>
    <div>
      <a
        href="https://tezostaquito.io"
        target="_blank"
        rel="noreferrer noopener"><img
          src="images/Built-with-square.png"
          alt="built with Taquito"
          class="taquito-logo" /></a>
    </div>
  </div>
</header>
