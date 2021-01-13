<script lang="ts">
    import { fly } from "svelte/transition";
    import { expoInOut } from "svelte/easing";
    import store from "../../store";

    export let opHash, show;
</script>

<style lang="scss">
    .toast {
        background-color: white;
        padding: 10px;
        border-radius: 10px;
        position: absolute;
        bottom: 30px;
        left: 0;
        right: 0;
        margin: auto;
        width: 20%;
        text-align: center;
        border: solid 1px #a0aec0;
    }
</style>

{#if show}
    <div
        class="toast"
        in:fly={{ duration: 1500, x: -1000, easing: expoInOut }}
        out:fly={{ duration: 1500, x: 1000, easing: expoInOut }}>
        <a
            href={`https://better-call.dev/${$store.network === 'testnet' ? 'delphinet' : 'mainnet'}/opg/${opHash}/contents`}
            target="_blank"
            rel="noopener noreferrer nofollow">
            View Transaction
        </a>
    </div>
{/if}
