<style lang="scss">
  main {
    height: 100%;

    .banner {
      height: 60%;
      color: white;
      padding: 120px 50px;
      background-image: url("images/background.png");
      background-repeat: no-repeat;
      background-position: center;
      background-size: cover;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: space-between;

      .title {
        font-size: 3rem;
        font-weight: bold;
        text-shadow: 2px 2px #a0aec0;
      }

      .subtitle {
        font-size: 1.6rem;
        font-weight: bold;
        text-shadow: 1px 1px #a0aec0;
      }
    }

    .features {
      text-align: center;
      display: flex;
      flex-direction: column;
      align-items: center;

      h1 {
        font-size: 2rem;
      }

      div {
        margin: 50px;
        max-width: 700px;

        img {
          max-width: 400px;
        }
      }
    }

    .credits {
      text-align: right;
      font-size: 0.6rem;
      padding: 5px;
    }
  }
</style>

<main>
  <section class="banner">
    <div class="title">Tezos Token Factory</div>
    <div class="subtitle">
      Easily create, browse and exchange FA2 tokens on the Tezos blockchain
    </div>
  </section>
  <section class="features">
    <div>
      <h1>Browse tokens</h1>
      <img src="images/search.png" alt="search-tokens" />
      <div>
        Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod
        tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim
        veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea
        commodo consequat. Duis aute irure dolor in reprehenderit in voluptate
        velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint
        occaecat cupidatat non proident, sunt in culpa qui officia deserunt
        mollit anim id est laborum.
      </div>
    </div>
    <div>
      <h1>Create tokens</h1>
      <img src="images/create.png" alt="search-tokens" />
      <div>
        Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod
        tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim
        veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea
        commodo consequat. Duis aute irure dolor in reprehenderit in voluptate
        velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint
        occaecat cupidatat non proident, sunt in culpa qui officia deserunt
        mollit anim id est laborum.
      </div>
    </div>
    <div>
      <h1>Exchange tokens</h1>
      <img src="images/exchange-xtz.png" alt="exchange-tokens" />
      <div>
        Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod
        tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim
        veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea
        commodo consequat. Duis aute irure dolor in reprehenderit in voluptate
        velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint
        occaecat cupidatat non proident, sunt in culpa qui officia deserunt
        mollit anim id est laborum.
      </div>
    </div>
  </section>
  <section class="credits">
    <a
      href="https://stories.freepik.com/web"
      target="_blank"
      rel="noreferrer noopener">Illustrations by Freepik Stories</a>
  </section>
</main>
