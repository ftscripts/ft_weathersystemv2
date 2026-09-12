<script>
    import { onMount } from 'svelte';

    let isVisible = false;
    let totalMinutes = 780;
    let isTimeFrozen = false;
    let isDynamicWeather = true;
    let isBlackout = false;
    let currentWeather = 'EXTRASUNNY';
    let isDraggingSlider = false;
    let dragTimeout = null;

    let showWeatherInterval = false;
    let weatherInterval = 10;
    let showTimeSpeed = false;
    let timeSpeed = 1;

    $: formattedTime = (() => {
        const hours = Math.floor(totalMinutes / 60) % 24;
        const minutes = Math.floor(totalMinutes % 60);
        return `${String(hours).padStart(2, '0')}:${String(minutes).padStart(2, '0')}`;
    })();

    function postNUI(endpoint, data = {}) {
        const resourceName = window.GetParentResourceName ? window.GetParentResourceName() : 'ft_weathersystem';
        return fetch(`https://${resourceName}/${endpoint}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(data)
        }).catch(() => {});
    }

    function selectWeather(mode) {
        currentWeather = mode;
        postNUI('setWeather', { mode });
    }

    function setTime() {
        const hour = Math.floor(totalMinutes / 60) % 24;
        const minute = Math.floor(totalMinutes % 60);
        postNUI('setTime', { hour, minute });
        isDraggingSlider = false;
        if (dragTimeout) clearTimeout(dragTimeout);
    }

    function toggleFreezeTime() {
        isTimeFrozen = !isTimeFrozen;
        postNUI('freezeTime', {});
    }

    function toggleDynamicWeather() {
        isDynamicWeather = !isDynamicWeather;
        postNUI('dynamicweather', {});
    }

    function toggleDynamicTime() {
        isTimeFrozen = !isTimeFrozen;
        postNUI('dynamictime', {});
    }

    function toggleBlackout() {
        isBlackout = !isBlackout;
        postNUI('toggleBlackout', { state: isBlackout });
    }

    function saveWeatherInterval() {
        postNUI('setWeatherInterval', { interval: weatherInterval });
        showWeatherInterval = false;
    }

    function saveTimeSpeed() {
        postNUI('setTimeSpeed', { speed: timeSpeed });
        showTimeSpeed = false;
    }

    function closeUI() {
        isVisible = false;
        isDraggingSlider = false;
        showWeatherInterval = false;
        showTimeSpeed = false;
        if (dragTimeout) clearTimeout(dragTimeout);
        postNUI('close', {});
    }

    function handleSliderInput() {
        isDraggingSlider = true;
        if (dragTimeout) clearTimeout(dragTimeout);
        dragTimeout = setTimeout(() => {
            isDraggingSlider = false;
        }, 5000);
    }

    onMount(() => {
        const handleMessage = (event) => {
            const data = event.data;
            if (!data) return;

            if (data.action === 'openWeather') {
                isVisible = true;
                isDraggingSlider = false;
                if (data.weather) {
                    currentWeather = data.weather;
                }
                if (typeof data.blackout === 'boolean') {
                    isBlackout = data.blackout;
                }
                if (typeof data.hour === 'number') {
                    totalMinutes = (data.hour * 60) + (data.minute || 0);
                }
                if (typeof data.freezeTime === 'boolean') {
                    isTimeFrozen = data.freezeTime;
                }
                if (typeof data.dynamicWeather === 'boolean') {
                    isDynamicWeather = data.dynamicWeather;
                }
                if (typeof data.weatherInterval === 'number') {
                    weatherInterval = data.weatherInterval;
                }
                if (typeof data.timeSpeed === 'number') {
                    timeSpeed = data.timeSpeed;
                }
            } else if (data.action === 'syncWeather') {
                if (data.weather) {
                    currentWeather = data.weather;
                }
                if (typeof data.blackout === 'boolean') {
                    isBlackout = data.blackout;
                }
            } else if (data.action === 'updateTime') {
                if (typeof data.hour === 'number' && !isDraggingSlider) {
                    totalMinutes = (data.hour * 60) + (data.minute || 0);
                }
            } else if (data.action === 'syncState') {
                if (data.weather) {
                    currentWeather = data.weather;
                }
                if (typeof data.blackout === 'boolean') {
                    isBlackout = data.blackout;
                }
                if (typeof data.freezeTime === 'boolean') {
                    isTimeFrozen = data.freezeTime;
                }
                if (typeof data.dynamicWeather === 'boolean') {
                    isDynamicWeather = data.dynamicWeather;
                }
                if (typeof data.weatherInterval === 'number') {
                    weatherInterval = data.weatherInterval;
                }
                if (typeof data.timeSpeed === 'number') {
                    timeSpeed = data.timeSpeed;
                }
            }
        };

        const handleKey = (e) => {
            if (e.key === 'Escape' || e.keyCode === 27) {
                closeUI();
            }
        };

        window.addEventListener('message', handleMessage);
        window.addEventListener('keyup', handleKey);

        return () => {
            window.removeEventListener('message', handleMessage);
            window.removeEventListener('keyup', handleKey);
        };
    });

    const weatherOptions = [
        { id: 'EXTRASUNNY', label: 'Extrasunny', icon: 'fas fa-sun', class: 'extrasunny' },
        { id: 'CLEAR', label: 'Clear', icon: 'fas fa-cloud-sun', class: 'clear' },
        { id: 'NEUTRAL', label: 'Neutral', icon: 'fas fa-adjust', class: 'neutral' },
        { id: 'SMOG', label: 'Smog', icon: 'fas fa-smog', class: 'smog' },
        { id: 'FOGGY', label: 'Foggy', icon: 'fas fa-smog', class: 'foggy' },
        { id: 'OVERCAST', label: 'Overcast', icon: 'fas fa-cloud-showers-heavy', class: 'overcast' },
        { id: 'CLOUDS', label: 'Clouds', icon: 'fas fa-cloud', class: 'clouds' },
        { id: 'CLEARING', label: 'Clearing', icon: 'fas fa-wind', class: 'clearing' },
        { id: 'RAIN', label: 'Rain', icon: 'fas fa-cloud-rain', class: 'rain' },
        { id: 'THUNDER', label: 'Thunder', icon: 'fas fa-bolt', class: 'thunder' },
        { id: 'SNOW', label: 'Snow', icon: 'fas fa-snowplow', class: 'snow' },
        { id: 'BLIZZARD', label: 'Blizzard', icon: 'fas fa-icicles', class: 'blizzard' },
        { id: 'SNOWLIGHT', label: 'Snowlight', icon: 'fas fa-snowflake', class: 'snowlight' },
        { id: 'XMAS', label: 'Xmas', icon: 'fas fa-snowflake', class: 'xmas' },
        { id: 'HALLOWEEN', label: 'Halloween', icon: 'fas fa-ghost', class: 'halloween' },
    ];
</script>

{#if isVisible}
<div class="layout">
    <div class="main">

        <div class="weather-container">
            <div class="weather-grid">
                {#each weatherOptions as w}
                    <button
                        class="weather-btn {w.class} {currentWeather === w.id ? 'active' : ''}"
                        on:click={() => selectWeather(w.id)}
                    >
                        <i class={w.icon}></i>
                        <span>{w.label}</span>
                        {#if currentWeather === w.id}
                            <div class="active-badge"><i class="fas fa-check"></i></div>
                        {/if}
                    </button>
                {/each}
            </div>
        </div>

        <div class="controls-container">
            <button class="btn controls {isDynamicWeather ? 'active' : 'inactive'}" on:click={toggleDynamicWeather}>
                <i class="fas fa-cloud-sun"></i>
                <span>Dynamic Weather</span>
            </button>
            <button class="btn controls {!isTimeFrozen ? 'active' : 'inactive'}" on:click={toggleDynamicTime}>
                <i class="fas fa-clock"></i>
                <span>Dynamic Time</span>
            </button>
            <button class="btn controls blackout {isBlackout ? 'active' : 'inactive'}" on:click={toggleBlackout}>
                <i class="fas fa-power-off"></i>
                <span>Blackout</span>
            </button>
            <button class="btn controls" on:click={() => { showWeatherInterval = !showWeatherInterval; showTimeSpeed = false; }}>
                <i class="fas fa-stopwatch"></i>
                <span>Weather Interval</span>
            </button>
            <button class="btn controls" on:click={() => { showTimeSpeed = !showTimeSpeed; showWeatherInterval = false; }}>
                <i class="fas fa-tachometer-alt"></i>
                <span>Time Speed</span>
            </button>
        </div>

        <div class="time-container">
            <div class="time-slider">
                <span class="time-label top">23:00</span>
                <input
                    type="range"
                    min="0"
                    max="1380"
                    step="1"
                    class="vertical-range"
                    bind:value={totalMinutes}
                    on:input={handleSliderInput}
                    on:mousedown={() => { isDraggingSlider = true; }}
                    on:mouseup={() => { if (dragTimeout) clearTimeout(dragTimeout); dragTimeout = setTimeout(() => isDraggingSlider = false, 3000); }}
                >
                <span class="time-label mid">12:00</span>
                <span class="time-label bottom">00:00</span>
            </div>

            <div class="time-display">
                <div class="time-title">TIME</div>
                <div class="time-value">{formattedTime}</div>
            </div>

            <div class="time-buttons">
                <button class="btn set" on:click={setTime}>SET</button>
                <button class="btn freeze" on:click={toggleFreezeTime}>{isTimeFrozen ? 'UNFREEZE' : 'FREEZE'}</button>
            </div>
        </div>
    </div>
</div>

{#if showWeatherInterval}
<div class="slider-popup center-screen">
    <label for="weatherIntSlider">Weather Interval: {weatherInterval} min</label>
    <input id="weatherIntSlider" type="range" min="1" max="120" bind:value={weatherInterval}>
    <button class="btn small" on:click={saveWeatherInterval}>Set</button>
</div>
{/if}

{#if showTimeSpeed}
<div class="slider-popup center-screen">
    <label for="timeSpdSlider">Time Speed: {timeSpeed}x</label>
    <input id="timeSpdSlider" type="range" min="1" max="60" bind:value={timeSpeed}>
    <button class="btn small" on:click={saveTimeSpeed}>Set</button>
</div>
{/if}
{/if}

<style>

:global(:root) {
    --u: min(calc(100vh / 800), calc(100vw / 1300));

    font-size: calc(16 * var(--u));
}

:global(body) {
    margin: 0;
    padding: 0;
    background: transparent;
    color: #ecf0f1;
    width: 100vw;
    height: 100vh;
    overflow: hidden;
    box-sizing: border-box;
    font-family: 'Poppins', sans-serif;
    user-select: none;
}

.layout {
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    display: flex;
    align-items: center;
    justify-content: center;
    box-sizing: border-box;
}

.main {
    position: relative;
    width: calc(1200 * var(--u));
    height: calc(700 * var(--u));
    padding: calc(24 * var(--u));
    background: #12375a;
    box-sizing: border-box;
    flex: none;
    border-radius: calc(40 * var(--u));
    outline: calc(4 * var(--u)) solid #000;
    gap: calc(10 * var(--u));
    box-shadow: 0 calc(20 * var(--u)) calc(50 * var(--u)) rgba(0, 0, 0, 0.6);
}

.weather-container {
    position: absolute;
    top: calc(45 * var(--u));
    left: calc(40 * var(--u));
    width: calc(800 * var(--u));
    height: calc(500 * var(--u));
    background: #00000080;
    border-radius: calc(25 * var(--u));
    box-sizing: border-box;
    padding: calc(32 * var(--u));
    display: flex;
    flex-direction: column;
    gap: calc(24 * var(--u));
    -webkit-backdrop-filter: blur(calc(6 * var(--u)));
    backdrop-filter: blur(calc(6 * var(--u)));
    border: calc(1 * var(--u)) solid rgba(255,255,255,.06);
}

.weather-grid {
    display: grid;
    grid-template-columns: repeat(5, 1fr);
    grid-template-rows: repeat(3, 1fr);
    gap: calc(16 * var(--u));
    flex: 1;
}

.weather-btn {
    position: relative;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    border: none;
    border-radius: calc(14 * var(--u));
    padding: calc(14 * var(--u));
    cursor: pointer;
    transition: all .15s ease-in-out;
    color: #fff;
    text-align: center;
    line-height: 1;
    box-shadow: 0 calc(2 * var(--u)) calc(10 * var(--u)) #00000040;
}

.weather-btn.active {
    outline: calc(3 * var(--u)) solid #6df5ff;
    box-shadow: 0 0 calc(20 * var(--u)) rgba(109, 245, 255, 0.75),
                0 calc(6 * var(--u)) calc(18 * var(--u)) rgba(0, 0, 0, 0.5);
    transform: scale(1.03);
    z-index: 2;
}

.active-badge {
    position: absolute;
    top: calc(7 * var(--u));
    right: calc(7 * var(--u));
    width: calc(22 * var(--u));
    height: calc(22 * var(--u));
    background: linear-gradient(135deg, #103454, #091a2a);
    border: calc(2 * var(--u)) solid #6df5ff;
    color: #6df5ff;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: calc(11 * var(--u));
    box-shadow: 0 calc(3 * var(--u)) calc(8 * var(--u)) rgba(0, 0, 0, 0.7),
                0 0 calc(10 * var(--u)) rgba(109, 245, 255, 0.6);
    animation: badge-pop 0.22s cubic-bezier(0.175, 0.885, 0.32, 1.275);
    pointer-events: none;
}

.active-badge i {
    font-size: calc(11 * var(--u)) !important;
    margin-bottom: 0 !important;
    line-height: 1;
    color: #6df5ff;
}

@keyframes badge-pop {
    0% { transform: scale(0.4); opacity: 0; }
    100% { transform: scale(1); opacity: 1; }
}

.weather-btn i {
    font-size: 1.6rem;
    line-height: 1;
    margin-bottom: calc(6 * var(--u));
}

.weather-btn span {
    font-size: .75rem;
    font-weight: 700;
    line-height: 1;
    text-transform: uppercase;
    letter-spacing: calc(.5 * var(--u));
}

.weather-btn:hover {
    transform: translateY(calc(-3 * var(--u))) scale(1.02);
    box-shadow: 0 calc(6 * var(--u)) calc(16 * var(--u)) rgba(0,0,0,.35);
}

.weather-btn:active {
    transform: translateY(0) scale(0.98);
}

.weather-btn.extrasunny { background: linear-gradient(135deg, #ffe066, #ffba08); }
.weather-btn.extrasunny:hover { background: linear-gradient(135deg, #ffec99, #ffc107); }

.weather-btn.clear { background: linear-gradient(135deg, #66e0ff, #00bfa5); }
.weather-btn.clear:hover { background: linear-gradient(135deg, #99f2ff, #26c6da); }

.weather-btn.neutral { background: linear-gradient(135deg, #eee, #bdbdbd); color: #fff; text-shadow: 0 calc(1 * var(--u)) calc(2 * var(--u)) rgba(0,0,0,0.3); }
.weather-btn.neutral:hover { background: linear-gradient(135deg, #f5f5f5, #d6d6d6); }

.weather-btn.smog { background: linear-gradient(135deg, #bcaaa4, #8d6e63); }
.weather-btn.smog:hover { background: linear-gradient(135deg, #d7ccc8, #a1887f); }

.weather-btn.foggy { background: linear-gradient(135deg, #c5e1a5, #7cb342); }
.weather-btn.foggy:hover { background: linear-gradient(135deg, #dcedc8, #9ccc65); }

.weather-btn.overcast { background: linear-gradient(135deg, #78909c, #546e7a); }
.weather-btn.overcast:hover { background: linear-gradient(135deg, #90a4ae, #607d8b); }

.weather-btn.clouds { background: linear-gradient(135deg, #b0bec5, #90a4ae); }
.weather-btn.clouds:hover { background: linear-gradient(135deg, #cfd8dc, #b0bec5); }

.weather-btn.clearing { background: linear-gradient(135deg, #aed581, #7cb342); }
.weather-btn.clearing:hover { background: linear-gradient(135deg, #c5e1a5, #9ccc65); }

.weather-btn.rain { background: linear-gradient(135deg, #4fc3f7, #0288d1); }
.weather-btn.rain:hover { background: linear-gradient(135deg, #81d4fa, #03a9f4); }

.weather-btn.thunder { background: linear-gradient(135deg, #9575cd, #5e35b1); }
.weather-btn.thunder:hover { background: linear-gradient(135deg, #b39ddb, #7e57c2); }

.weather-btn.snow { background: linear-gradient(135deg, #81d4fa, #29b6f6); }
.weather-btn.snow:hover { background: linear-gradient(135deg, #b3e5fc, #03a9f4); }

.weather-btn.blizzard { background: linear-gradient(135deg, #90caf9, #42a5f5); }
.weather-btn.blizzard:hover { background: linear-gradient(135deg, #bbdefb, #64b5f6); }

.weather-btn.snowlight { background: linear-gradient(135deg, #80deea, #26c6da); }
.weather-btn.snowlight:hover { background: linear-gradient(135deg, #b2ebf2, #4dd0e1); }

.weather-btn.xmas { background: linear-gradient(135deg, #e57373, #c62828); }
.weather-btn.xmas:hover { background: linear-gradient(135deg, #ef9a9a, #d32f2f); }

.weather-btn.halloween { background: linear-gradient(135deg, #ff6f00, #d84315); }
.weather-btn.halloween:hover { background: linear-gradient(135deg, #ff8f00, #e64a19); }

.time-container {
    position: absolute;
    top: 0;
    left: calc(880 * var(--u));
    width: calc(320 * var(--u));
    height: calc(700 * var(--u));
    background: #000c;
    border-radius: 0 calc(40 * var(--u)) calc(40 * var(--u)) 0;
    box-sizing: border-box;
    padding: calc(32 * var(--u));
    display: flex;
    flex-direction: column;
    gap: calc(32 * var(--u));
}

.time-slider {
    display: flex;
    flex-direction: column;
    align-items: center;
    margin-right: calc(1 * var(--u));
}

.time-label {
    color: #fff;
    font-size: .9rem;
    font-weight: 600;
    line-height: 1;
    margin-top: calc(-10 * var(--u));
    margin-right: calc(250 * var(--u));
    pointer-events: none;
}

.time-label.top { position: absolute; top: 14%; transform: translateY(-50%); }
.time-label.mid { position: absolute; top: 50%; transform: translateY(-50%); }
.time-label.bottom { position: absolute; top: 90%; transform: translateY(-50%); }

.vertical-range {
    -webkit-appearance: none;
    appearance: none;
    width: calc(600 * var(--u));
    height: calc(30 * var(--u));
    transform: rotate(270deg);
    transform-origin: center;
    cursor: pointer;
    background: transparent;
    outline: none;
    margin-top: calc(300 * var(--u));
    margin-right: calc(150 * var(--u));
    border-radius: calc(25 * var(--u));
}

.vertical-range::-webkit-slider-runnable-track {
    width: calc(300 * var(--u));
    height: calc(28 * var(--u));
    background: linear-gradient(90deg, #127d7d, #6df5ff, #127d7d);
    border-radius: calc(25 * var(--u));
    box-shadow: inset 0 calc(4 * var(--u)) calc(10 * var(--u)) #00000080,
                inset 0 calc(1 * var(--u)) calc(14 * var(--u)) #ffffffc1;
}

.vertical-range::-webkit-slider-thumb {
    -webkit-appearance: none;
    appearance: none;
    width: calc(50 * var(--u));
    height: calc(26 * var(--u));
    background: linear-gradient(90deg, #000, #4b4b4b, #000);
    border-radius: calc(25 * var(--u));
    margin-top: calc(1 * var(--u));
    cursor: pointer;
    box-shadow: 0 0 calc(10 * var(--u)) rgba(0,0,0,0.8);
}

.time-display {
    text-align: center;
    font-size: 1.4rem;
    margin-top: calc(-190 * var(--u));
    margin-left: calc(80 * var(--u));
}

.time-title {
    color: #6df5ff;
    font-weight: 700;
    line-height: 1;
    letter-spacing: calc(1 * var(--u));
    margin-bottom: calc(4 * var(--u));
}

.time-value {
    color: #fff;
    font-size: 2.2rem;
    font-weight: 800;
    line-height: 1;
}

.time-buttons {
    display: flex;
    flex-direction: column;
    gap: calc(12 * var(--u));
    margin-left: calc(100 * var(--u));
}

.btn {
    width: calc(150 * var(--u));
    height: calc(60 * var(--u));
    padding: calc(12 * var(--u)) 0;
    font-size: calc(20 * var(--u));
    font-weight: 700;
    line-height: 1;
    border: none;
    border-radius: calc(50 * var(--u));
    cursor: pointer;
    transition: transform .1s, filter .2s;
    text-align: center;
    display: flex;
    align-items: center;
    justify-content: center;
}

.btn.set { background: #6df5ff; color: #000; }
.btn.set:hover { filter: brightness(1.1); }

.btn.freeze { background: #ff4c4c; color: #fff; }
.btn.freeze:hover { filter: brightness(1.1); }

.btn:active { transform: translateY(calc(1 * var(--u))) scale(0.98); }

.controls-container {
    position: absolute;
    top: calc(565 * var(--u));
    left: calc(40 * var(--u));
    width: calc(800 * var(--u));
    height: calc(90 * var(--u));
    background: transparent;
    padding: 0;
    box-sizing: border-box;
    display: flex;
    flex-direction: row;
    align-items: center;
    justify-content: space-between;
    gap: calc(10 * var(--u));
    text-transform: uppercase;
    -webkit-backdrop-filter: blur(calc(10 * var(--u)));
    backdrop-filter: blur(calc(10 * var(--u)));
}

.btn.controls {
    flex: 1 1 0;
    width: 0;
    min-width: 0;
    height: calc(72 * var(--u));
    font-size: calc(10 * var(--u));
    border-radius: calc(12 * var(--u));
    background: linear-gradient(135deg, #1fdbe9, #17b6d0);
    color: #002e35;
    font-weight: 800;
    line-height: 1;
    letter-spacing: calc(.5 * var(--u));
    text-transform: uppercase;
    cursor: pointer;
    border: none;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    padding: calc(6 * var(--u)) calc(2 * var(--u));
    box-sizing: border-box;
    transition: all .2s ease-in-out;
    box-shadow: 0 calc(4 * var(--u)) calc(12 * var(--u)) #0003;
}

.btn.controls.inactive {
    opacity: 0.65;
    filter: grayscale(0.3);
}

.btn.controls.active {
    opacity: 1;
    box-shadow: 0 0 calc(14 * var(--u)) rgba(31, 219, 233, 0.6);
}

.btn.controls.blackout {
    background: linear-gradient(135deg, #37474f, #263238);
    color: #90a4ae;
}

.btn.controls.blackout.active {
    background: linear-gradient(135deg, #ff416c, #ff4b2b);
    color: #fff;
    opacity: 1;
    box-shadow: 0 0 calc(16 * var(--u)) rgba(255, 65, 108, 0.75);
}

.btn.controls.blackout.inactive {
    background: linear-gradient(135deg, #37474f, #263238);
    color: #90a4ae;
    opacity: 0.75;
    box-shadow: 0 calc(4 * var(--u)) calc(12 * var(--u)) #0003;
}

.btn.controls i {
    font-size: 1.15rem;
    line-height: 1;
    margin-bottom: calc(4 * var(--u));
}

.btn.controls:hover {
    background: linear-gradient(135deg, #23e7f3, #1aa5c0);
    color: #002e35;
    transform: translateY(calc(-2 * var(--u)));
    box-shadow: 0 calc(6 * var(--u)) calc(16 * var(--u)) #0000004d;
}

.btn.controls.blackout:hover {
    background: linear-gradient(135deg, #ff5252, #e53935);
    color: #fff;
}

.btn.controls:active { transform: scale(.98); }

.slider-popup.center-screen {
    position: fixed;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    width: calc(380 * var(--u));
    padding: calc(32 * var(--u)) calc(36 * var(--u));
    background: #12375aea;
    -webkit-backdrop-filter: blur(calc(16 * var(--u)));
    backdrop-filter: blur(calc(16 * var(--u)));
    border-radius: calc(18 * var(--u));
    z-index: 9999;
    animation: popup-slide .35s ease-out;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    text-align: center;
    gap: calc(26 * var(--u));
    color: #fff;
    border: calc(1 * var(--u)) solid rgba(255,255,255,.15);
    box-shadow: 0 calc(20 * var(--u)) calc(40 * var(--u)) rgba(0,0,0,0.8);
}

@keyframes popup-slide {
    0% { opacity: 0; transform: translate(-50%, -60%); }
    100% { opacity: 1; transform: translate(-50%, -50%); }
}

.slider-popup.center-screen label {
    font-size: calc(15 * var(--u));
    font-weight: 700;
    line-height: 1;
    text-transform: uppercase;
    letter-spacing: calc(1 * var(--u));
    color: #c9f3f6;
    margin-bottom: calc(4 * var(--u));
}

.slider-popup.center-screen input[type=range] {
    -webkit-appearance: none;
    appearance: none;
    width: 100%;
    height: calc(8 * var(--u));
    background: #1f1f1f;
    border-radius: calc(8 * var(--u));
    outline: none;
    cursor: pointer;
    accent-color: #1fdbe9;
}

.slider-popup.center-screen input[type=range]::-webkit-slider-thumb {
    -webkit-appearance: none;
    appearance: none;
    height: calc(18 * var(--u));
    width: calc(18 * var(--u));
    border-radius: 50%;
    background: #1fdbe9;
    box-shadow: 0 0 calc(10 * var(--u)) #1fdbe9b3;
    border: none;
    transition: transform .2s ease;
}

.slider-popup.center-screen input[type=range]::-webkit-slider-thumb:hover { transform: scale(1.25); }

.slider-popup.center-screen .btn.small {
    width: auto;
    height: auto;
    margin-top: calc(6 * var(--u));
    background: linear-gradient(135deg, #1fdbe9, #17b6d0);
    color: #001d1f;
    padding: calc(12 * var(--u)) calc(28 * var(--u));
    border: none;
    border-radius: calc(10 * var(--u));
    font-size: calc(14 * var(--u));
    font-weight: 700;
    line-height: 1;
    cursor: pointer;
    text-transform: uppercase;
    letter-spacing: calc(.8 * var(--u));
    box-shadow: 0 calc(4 * var(--u)) calc(12 * var(--u)) #0000004d;
    transition: all .2s ease-in-out;
}

.slider-popup.center-screen .btn.small:hover {
    background: linear-gradient(135deg, #23e7f3, #1aa5c0);
    transform: translateY(calc(-1 * var(--u)));
}
</style>
