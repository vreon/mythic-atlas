<script>
  import { onMount } from "svelte";  
  import { fakeHeightFactor } from "./stores/globalControls.js";
  onMount(() => {
    fakeHeightFactor.set(0.0, { duration: 0 });
    setTimeout(() => {
      fakeHeightFactor.set(1.0, { duration: 8000 });
    }, 0);
  });
</script>

<div>
  <p class="title">Mythic Atlas</p>
  <p class="subtitle">&mdash; Fantasy Cartography App &mdash;</p>
</div>

<style>
  @keyframes hoverup {
    from {
      transform: translate(0px, 5px) scale(0.9);
    }
    to {
      transform: translate(0px, -5px) scale(1.0);
    }
  }

  @keyframes fadein {
    from {
      opacity: 0;
    }
    to {
      opacity: 1;
    }
  }

  div {
    position: absolute;
    width: 100%;
    height: 100%;
    display: flex;
    flex-direction: column;
    pointer-events: none;
    align-items: center;
    justify-content: center;
    animation: 8s ease-out hoverup, 2s ease-in fadein, 2s reverse 5s ease-out forwards fadein;
  }

  p {
    margin: 0;
    font-family: "Patua One";
    color: white;
    text-shadow: 0px 0px 3px #000, 0px 0px 30px #fff;
  }

  .title {
    text-align: center;
    font-size: 6rem;
  }

  .subtitle {
    text-align: center;
    font-size: 2rem;
    font-variant: small-caps;
    letter-spacing: 0.35rem;
  }
</style>
