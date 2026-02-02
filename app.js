// INTARIUS App - Main Application Logic

// --- State ---
const tg = window.Telegram.WebApp;
const KEYS = { LAST_DRAW: 'mystic_tarot_state', IS_PREMIUM: 'mt_is_premium', AD_WATCHED: 'mt_ad_watched' };

let state = {
    isPremium: false,
    selectedSpread: 'three',
    adWatched: false,
    lastSynthesisHTML: '',
    lastSynthesisText: ''
};

const SPREAD_INFO = {
    'one': { name: 'Карта Дня', count: 1, labels: ['Карта Дня'], descriptions: ['Главное послание дня'] },
    'three': { name: 'Три Карты', count: 3, labels: ['Причина', 'Ситуация', 'Исход'], descriptions: ['Корень вопроса', 'Текущее положение', 'Куда всё движется'] },
    'cross': {
        name: 'Кельтский Крест',
        count: 10,
        labels: [
            '🎯 Сердце вопроса',
            '⚔️ Препятствие',
            '👑 Идеал',
            '🌙 Корни',
            '⏪ Прошлое',
            '⏩ Ближайшее будущее',
            '🧘 Ты сейчас',
            '👥 Окружение',
            '💭 Надежды и страхи',
            '✨ Итог'
        ],
        descriptions: [
            'Суть твоей ситуации прямо сейчас',
            'Что стоит на пути или помогает',
            'Лучший возможный исход',
            'Глубинные причины ситуации',
            'Что привело тебя сюда',
            'Что произойдёт в ближайшие дни',
            'Как ты относишься к ситуации',
            'Как на тебя влияют другие люди',
            'Твои скрытые желания и опасения',
            'Финальный результат, если всё оставить как есть'
        ]
    }
};

// --- Init ---
document.addEventListener('DOMContentLoaded', () => {
    tg.expand();
    tg.ready();

    // 1. Auto-Detect Telegram Premium
    const user = tg.initDataUnsafe?.user;
    const hasTelegramPremium = user?.is_premium === true;

    // 2. Load Local State
    const storedPremium = localStorage.getItem(KEYS.IS_PREMIUM) === 'true';

    // 3. Final State
    state.isPremium = hasTelegramPremium || storedPremium;
    localStorage.setItem(KEYS.IS_PREMIUM, state.isPremium);

    if (hasTelegramPremium) {
        console.log("Telegram Premium Detected -> Granting Access");
    }

    updateUI();

    // Restore Draw - but always animate! (user request)
    const today = new Date().toISOString().split('T')[0];
    const lastDraw = JSON.parse(localStorage.getItem(KEYS.LAST_DRAW));

    if (lastDraw && lastDraw.date === today) {
        state.selectedSpread = lastDraw.spreadType;
        state.adWatched = localStorage.getItem(KEYS.AD_WATCHED) === 'true';
        if (state.isPremium) state.adWatched = true;

        // Always animate - даже при восстановлении
        showResult(lastDraw.cards, lastDraw.spreadType, true);
    } else {
        localStorage.setItem(KEYS.AD_WATCHED, 'false');
        showScreen('home-screen');
    }

    // Create particles
    createParticles();
});

// --- UI Functions ---
function togglePremium() {
    state.isPremium = !state.isPremium;
    localStorage.setItem(KEYS.IS_PREMIUM, state.isPremium);
    updateUI();

    const resultScreen = document.getElementById('result-screen');
    if (resultScreen.classList.contains('active')) {
        const lastDraw = JSON.parse(localStorage.getItem(KEYS.LAST_DRAW));
        if (lastDraw) showResult(lastDraw.cards, state.selectedSpread, true);
    }
}

function updateUI() {
    const btn = document.getElementById('dev-btn');
    if (btn) {
        btn.textContent = state.isPremium ? 'DEV: Premium User' : 'DEV: Free User';
        btn.classList.toggle('premium-badge', state.isPremium);
    }
}

function showScreen(id) {
    document.querySelectorAll('.screen').forEach(s => s.classList.remove('active'));
    document.getElementById(id).classList.add('active');

    // Scroll to top when showing result screen
    if (id === 'result-screen') {
        window.scrollTo({ top: 0, behavior: 'smooth' });
    }
}

// --- Draw Logic ---
function tryDraw() {
    state.selectedSpread = 'three';
    performDraw();
}

function startCrossReading() {
    state.selectedSpread = 'cross';
    performDraw();
}

function performDraw() {
    const deck = document.getElementById('deck');
    if (deck.classList.contains('processing')) return;
    deck.classList.add('processing');

    const cardBack = deck.querySelector('.card-back');

    setTimeout(() => {
        cardBack.classList.add('card-shaking');
    }, 300);

    setTimeout(() => {
        cardBack.classList.remove('card-shaking');
        deck.classList.remove('processing');

        const srcDeck = state.isPremium ? FULL_DECK : MAJOR_ARCANA;
        const spreadMeta = SPREAD_INFO[state.selectedSpread];
        const count = spreadMeta.count;

        const shuffled = [...srcDeck].sort(() => 0.5 - Math.random());
        const resultCards = shuffled.slice(0, count).map(card => ({
            ...card,
            isReversed: Math.random() < 0.2  // 20% шанс перевёрнутой карты
        }));

        const today = new Date().toISOString().split('T')[0];
        localStorage.setItem(KEYS.LAST_DRAW, JSON.stringify({
            date: today,
            spreadType: state.selectedSpread,
            cards: resultCards
        }));

        state.adWatched = false;
        localStorage.setItem(KEYS.AD_WATCHED, 'false');

        showResult(resultCards, state.selectedSpread, true);
    }, 1800);
}

// --- Narrative Engine ---
function generateSynthesis(cards) {
    const getNarrative = (c) => {
        if (c.isReversed) {
            // Для перевёрнутых — используем reversedShort или fallback
            return `преодолеть "${(c.reversedShort || c.short).toLowerCase()}"`;
        }
        if (c.narrative) return c.narrative;
        return `прожить энергию "${c.short.toLowerCase()}"`;
    };

    const n0 = getNarrative(cards[0]);
    const n1 = getNarrative(cards[1]);
    const n2 = getNarrative(cards[2]);

    const templates = [
        `Всё начинается с того, что вы готовы <strong>${n0}</strong>. Сейчас ситуация требует от вас <strong>${n1}</strong>. В конечном итоге это приведет к возможности <strong>${n2}</strong>.`,
        `Суть происходящего — это необходимость <strong>${n0}</strong>. Ваша следующая задача — <strong>${n1}</strong>, и финалом этого этапа станет шанс <strong>${n2}</strong>.`,
        `Ключ к ситуации — ваша готовность <strong>${n0}</strong>. Не бойтесь <strong>${n1}</strong> — именно этот шаг позволит вам <strong>${n2}</strong>.`,
        `В основе ситуации — внутреннее стремление <strong>${n0}</strong>. Это приводит к необходимости <strong>${n1}</strong>. Если вы справитесь, то сможете <strong>${n2}</strong>.`
    ];

    const text = templates[Math.floor(Math.random() * templates.length)];

    const k0 = cards[0].keywords[Math.floor(Math.random() * cards[0].keywords.length)];
    const k1 = cards[1].keywords[Math.floor(Math.random() * cards[1].keywords.length)];
    const k2 = cards[2].keywords[Math.floor(Math.random() * cards[2].keywords.length)];

    const adviceTemplates = [
        `✨ Ваши ресурсы сейчас: <strong>${k0}</strong> и <strong>${k1}</strong>. Главная цель — <strong>${k2}</strong>.`,
        `🔮 Магическая формула успеха: <strong>${k0}</strong> + <strong>${k1}</strong> = <strong>${k2}</strong>.`,
        `🗝️ Три ключа к ситуации: <strong>${k0}</strong>, <strong>${k1}</strong> и <strong>${k2}</strong>.`,
        `🧘 Точки концентрации: <strong>${k0}</strong> и <strong>${k1}</strong>. Это приведет к состоянию: <strong>${k2}</strong>.`
    ];

    const synthesizedAdvice = adviceTemplates[Math.floor(Math.random() * adviceTemplates.length)];

    return `
        <div style="font-size:0.95rem; line-height:1.6; color:#e0e0e0; margin-bottom:15px; text-align: justify;">
            ${text}
        </div>
        <div style="border-left: 3px solid var(--accent-gold); padding-left: 10px; color: rgba(255,255,255,0.7); font-style: italic; font-size: 0.9rem;">
             ${synthesizedAdvice}
        </div>
    `;
}

// --- Result Display ---
function showResult(cards, spreadType, animate) {
    const container = document.getElementById('cards-container');
    container.innerHTML = '';
    const spreadMeta = SPREAD_INFO[spreadType];

    let visibleCount = cards.length;
    let showAdButton = false;

    if (spreadType === 'three') {
        if (!state.isPremium && !state.adWatched) {
            visibleCount = 1;
            showAdButton = true;
        }
    }

    const cardsToShow = cards.slice(0, visibleCount);

    cardsToShow.forEach((card, index) => {
        const wrapper = document.createElement('div');
        wrapper.style.display = 'flex';
        wrapper.style.flexDirection = 'column';
        wrapper.style.alignItems = 'center';
        wrapper.style.width = '100%';

        if (animate) {
            wrapper.style.opacity = '0';
            wrapper.style.transform = 'translateY(30px)';
            wrapper.style.transition = 'opacity 0.6s ease-out, transform 0.6s ease-out';
        }

        // Label
        const badge = document.createElement('div');
        badge.className = 'spread-position-label';
        if (visibleCount === 1 && index === 0) {
            badge.textContent = 'Карта Дня';
        } else {
            badge.textContent = spreadMeta.labels[index] || `Карта ${index + 1}`;
        }
        wrapper.appendChild(badge);

        // Position Description
        if (spreadMeta.descriptions && spreadMeta.descriptions[index]) {
            const desc = document.createElement('div');
            desc.style.cssText = 'font-size: 0.75rem; color: rgba(255,255,255,0.6); margin-bottom: 8px; font-style: italic;';
            desc.textContent = spreadMeta.descriptions[index];
            wrapper.appendChild(desc);
        }

        // Card - add reversed rotation if applicable
        const el = document.createElement('div');
        el.className = 'result-card-container';
        const isReversed = card.isReversed;
        const imgStyle = isReversed ? 'transform: rotate(180deg);' : '';
        el.innerHTML = `
            <div class="result-card">
                <div class="card-face back"><i class="fa-solid fa-eye"></i></div>
                <div class="card-face front">
                    <img src="${card.image}" class="card-image" style="${imgStyle}">
                </div>
            </div>
        `;
        wrapper.appendChild(el);

        // Info - show reversed meanings if applicable
        const info = document.createElement('div');
        info.className = 'card-info';
        const cardName = isReversed ? `${card.name} ↺` : card.name;
        const shortText = isReversed ? (card.reversedShort || card.short) : card.short;
        const fullText = isReversed ? (card.reversedFull || card.full) : card.full;
        const adviceText = isReversed ? (card.reversedAdvice || card.advice) : card.advice;
        const reversedBadge = isReversed ? '<span style="background:#8b0000; color:#fff; padding:2px 8px; border-radius:4px; font-size:0.7rem; margin-left:8px;">Перевёрнута</span>' : '';

        info.innerHTML = `
            <h3 style="margin-top:15px">${cardName}${reversedBadge}</h3>
            <p class="card-short">${shortText}</p>
            <div style="background:rgba(255,255,255,0.05); padding:10px; border-radius:8px; width:100%; text-align:left; font-size:0.9rem; line-height:1.5;">
                <strong style="color:var(--accent-gold);">Значение:</strong> ${fullText}<br><br>
                <strong style="color:var(--accent-gold);">Совет:</strong> ${adviceText}
            </div>
        `;
        wrapper.appendChild(info);

        container.appendChild(wrapper);

        wrapper.dataset.cardIndex = index;
        wrapper._cardEl = el;
        wrapper._infoEl = info;
    });

    // --- Interactive Card Reveal ---
    if (animate && cardsToShow.length > 0) {
        const wrappers = Array.from(container.querySelectorAll('[data-card-index]'));
        let currentCardIndex = 0;

        if (wrappers.length === 1) {
            // Single card
            setTimeout(() => {
                const wrapper = wrappers[0];
                const cardEl = wrapper._cardEl?.querySelector('.result-card');
                const infoEl = wrapper._infoEl;

                setTimeout(() => {
                    wrapper.style.opacity = '1';
                    wrapper.style.transform = 'translateY(0)';

                    setTimeout(() => {
                        if (cardEl) cardEl.classList.add('flipped');

                        setTimeout(() => {
                            if (infoEl) infoEl.classList.add('visible');

                            setTimeout(() => {
                                const actionsEl = container.querySelector('.actions-block');
                                if (actionsEl) {
                                    actionsEl.style.opacity = '1';
                                    actionsEl.style.transform = 'translateY(0)';
                                }
                            }, 1500);
                        }, 800);
                    }, 500);
                }, 300);
            }, 600);
        } else {
            // Multiple cards - button-driven reveal
            const nextCardBtn = document.createElement('button');
            nextCardBtn.className = 'btn btn-gold next-card-btn';
            nextCardBtn.innerHTML = '<i class="fa-solid fa-eye"></i> Следующая карта';
            nextCardBtn.style.cssText = 'margin: 5px auto 0 auto; opacity: 0; transform: translateY(10px); transition: opacity 0.4s ease, transform 0.4s ease;';

            function revealCard(idx) {
                if (idx >= wrappers.length) {
                    nextCardBtn.style.display = 'none';

                    setTimeout(() => {
                        const synthEl = container.querySelector('.synthesis-block');
                        if (synthEl) {
                            synthEl.classList.add('visible');
                            setTimeout(() => {
                                synthEl.scrollIntoView({ behavior: 'smooth', block: 'start' });
                            }, 600);
                        }
                    }, 800);

                    setTimeout(() => {
                        const actionsEl = container.querySelector('.actions-block');
                        if (actionsEl) {
                            actionsEl.style.opacity = '1';
                            actionsEl.style.transform = 'translateY(0)';
                        }
                    }, 1200);
                    return;
                }

                const wrapper = wrappers[idx];
                const cardEl = wrapper._cardEl?.querySelector('.result-card');
                const infoEl = wrapper._infoEl;

                if (nextCardBtn.parentNode) {
                    nextCardBtn.style.opacity = '0';
                    nextCardBtn.style.pointerEvents = 'none';
                }

                setTimeout(() => {
                    wrapper.style.opacity = '1';
                    wrapper.style.transform = 'translateY(0)';

                    setTimeout(() => {
                        if (cardEl) cardEl.classList.add('flipped');

                        setTimeout(() => {
                            if (infoEl) infoEl.classList.add('visible');

                            setTimeout(() => {
                                wrapper.after(nextCardBtn);

                                if (idx < wrappers.length - 1) {
                                    const ordinals = ['', '', 'вторую', 'третью', 'четвёртую', 'пятую', 'шестую', 'седьмую', 'восьмую', 'девятую', 'десятую'];
                                    const cardWord = ordinals[idx + 2] || `${idx + 2}-ю`;
                                    nextCardBtn.innerHTML = `<i class="fa-solid fa-eye"></i> Открыть ${cardWord} карту`;
                                } else {
                                    nextCardBtn.innerHTML = '<i class="fa-solid fa-sparkles"></i> Узнать толкование';
                                }
                                nextCardBtn.style.opacity = '1';
                                nextCardBtn.style.pointerEvents = 'auto';
                            }, 500);
                        }, 800);
                    }, 500);
                }, 300);

                currentCardIndex = idx;
            }

            nextCardBtn.onclick = () => {
                currentCardIndex++;
                if (currentCardIndex < wrappers.length) {
                    wrappers[currentCardIndex].scrollIntoView({ behavior: 'smooth', block: 'start' });
                }
                setTimeout(() => {
                    revealCard(currentCardIndex);
                }, 300);
            };

            wrappers[0].after(nextCardBtn);
            setTimeout(() => {
                revealCard(0);
            }, 600);
        }
    } else {
        // No animation
        container.querySelectorAll('[data-card-index]').forEach(w => {
            w.style.opacity = '1';
            w.style.transform = 'translateY(0)';
        });
        container.querySelectorAll('.result-card').forEach(c => c.classList.add('flipped'));
        container.querySelectorAll('.card-info').forEach(info => info.classList.add('visible'));
        const actionsEl = container.querySelector('.actions-block');
        if (actionsEl) {
            actionsEl.style.opacity = '1';
            actionsEl.style.transform = 'translateY(0)';
        }
    }

    // --- Synthesis Block ---
    if (!showAdButton && cardsToShow.length > 1) {
        const synthesisDiv = document.createElement('div');
        synthesisDiv.style.width = '100%';
        synthesisDiv.style.marginTop = '10px';
        synthesisDiv.style.padding = '20px';
        synthesisDiv.style.background = 'linear-gradient(180deg, rgba(75, 0, 130, 0.4) 0%, rgba(26, 11, 46, 0.6) 100%)';
        synthesisDiv.style.border = '1px solid var(--accent-gold)';
        synthesisDiv.style.borderRadius = '12px';
        synthesisDiv.style.boxShadow = '0 0 15px rgba(255, 215, 0, 0.1)';

        let synthesisHTML = '';

        if (spreadType === 'three') {
            synthesisHTML = `
                <h3 style="color:var(--accent-gold); margin-top:0; border-bottom:1px solid rgba(255,255,255,0.1); padding-bottom:10px;">
                    <i class="fa-solid fa-scroll"></i> Общее толкование
                </h3>
                ${generateSynthesis(cards)}
            `;
        } else if (spreadType === 'cross') {
            synthesisHTML = `
                <h3 style="color:var(--accent-gold); margin-top:0; border-bottom:1px solid rgba(255,255,255,0.1); padding-bottom:10px;">
                    <i class="fa-solid fa-scroll"></i> Общее толкование Кельтского Креста
                </h3>
                
                <div style="margin-bottom:15px;">
                    <h4 style="color:var(--accent-gold); margin:0 0 8px 0; font-size:0.9rem;">🎯 Суть ситуации</h4>
                    <p style="font-size:0.9rem; line-height:1.6; color:#e0e0e0; margin:0;">
                        <strong>${cards[0].name}</strong>: ${cards[0].full} 
                        ${cards[1] ? `<br><br><strong>${cards[1].name}</strong> указывает на ${cards[1].short.toLowerCase()}.` : ''}
                    </p>
                </div>

                <div style="margin-bottom:15px;">
                    <h4 style="color:var(--accent-gold); margin:0 0 8px 0; font-size:0.9rem;">🌙 Глубинные силы</h4>
                    <p style="font-size:0.9rem; line-height:1.6; color:#e0e0e0; margin:0;">
                        ${cards[2] ? `Твой идеал — <strong>${cards[2].name}</strong>: ${cards[2].short.toLowerCase()}.` : ''} 
                        ${cards[3] ? `Корни ситуации скрыты в энергии <strong>${cards[3].name}</strong> — ${cards[3].full}` : ''}
                    </p>
                </div>

                <div style="margin-bottom:15px;">
                    <h4 style="color:var(--accent-gold); margin:0 0 8px 0; font-size:0.9rem;">⏪ Прошлое → ⏩ Будущее</h4>
                    <p style="font-size:0.9rem; line-height:1.6; color:#e0e0e0; margin:0;">
                        ${cards[4] ? `Тебя сюда привела энергия <strong>${cards[4].name}</strong>.` : ''} 
                        ${cards[5] ? `В ближайшем будущем появится влияние <strong>${cards[5].name}</strong> — ${cards[5].short.toLowerCase()}.` : ''}
                    </p>
                </div>

                <div style="margin-bottom:15px;">
                    <h4 style="color:var(--accent-gold); margin:0 0 8px 0; font-size:0.9rem;">🧘 Ты и твоё окружение</h4>
                    <p style="font-size:0.9rem; line-height:1.6; color:#e0e0e0; margin:0;">
                        ${cards[6] ? `Сейчас ты — <strong>${cards[6].name}</strong>: ${cards[6].short.toLowerCase()}.` : ''} 
                        ${cards[7] ? `Окружающие влияют через энергию <strong>${cards[7].name}</strong> — ${cards[7].advice}` : ''}
                    </p>
                </div>

                <div style="margin-bottom:15px;">
                    <h4 style="color:var(--accent-gold); margin:0 0 8px 0; font-size:0.9rem;">💭 Надежды и страхи</h4>
                    <p style="font-size:0.9rem; line-height:1.6; color:#e0e0e0; margin:0;">
                        ${cards[8] ? `Твои скрытые желания и опасения выражены в <strong>${cards[8].name}</strong>: ${cards[8].full}` : ''}
                    </p>
                </div>

                <div style="background:rgba(255,215,0,0.1); padding:15px; border-radius:8px; border-left:3px solid var(--accent-gold);">
                    <h4 style="color:var(--accent-gold); margin:0 0 8px 0; font-size:1rem;">✨ Финальный итог</h4>
                    <p style="font-size:1rem; line-height:1.7; color:#fff; margin:0; font-weight:500;">
                        ${cards[9] ? `<strong>${cards[9].name}</strong>: ${cards[9].full}` : 'Итог раскроется после полного расклада.'}
                    </p>
                    <p style="font-size:0.85rem; color:var(--accent-gold); margin:10px 0 0 0; font-style:italic;">
                        ${cards[9] ? `💡 Совет: ${cards[9].advice}` : ''}
                    </p>
                </div>
            `;
        }

        synthesisDiv.innerHTML = synthesisHTML;
        synthesisDiv.classList.add('synthesis-block');
        container.appendChild(synthesisDiv);

        state.lastSynthesisHTML = synthesisHTML;
        state.lastSynthesisText = synthesisDiv.innerText;
    }

    // --- Actions Block ---
    const actionsDiv = document.createElement('div');
    actionsDiv.className = 'actions-block';
    actionsDiv.style.width = '100%';
    actionsDiv.style.marginTop = '20px';
    actionsDiv.style.display = 'flex';
    actionsDiv.style.flexDirection = 'column';
    actionsDiv.style.gap = '15px';

    if (animate) {
        actionsDiv.style.opacity = '0';
        actionsDiv.style.transform = 'translateY(30px)';
        actionsDiv.style.transition = 'opacity 0.8s ease-out, transform 0.8s ease-out';
    }

    if (showAdButton) {
        const premiumBlock = document.createElement('div');
        premiumBlock.className = 'premium-block';
        premiumBlock.style.cssText = 'background: rgba(255, 255, 255, 0.05); border-radius: 12px; padding: 15px; width: 100%; margin-bottom: 20px; position: relative; overflow: hidden; border: 1px solid rgba(255, 215, 0, 0.2);';

        const previewCard = cards[0];

        premiumBlock.innerHTML = `
            <h3 style="color:var(--accent-gold); margin:0 0 10px 0; font-family:'Cinzel',serif;">Глубинный смысл</h3>

            <div class="unlock-overlay">
                <button class="btn btn-gold" onclick="watchAd()">
                    <i class="fa-solid fa-play"></i> Открыть за рекламу
                </button>
                <p style="font-size: 0.8rem; margin-top: 10px; opacity: 0.8;">Просмотр видео (3 сек)</p>
            </div>

            <div class="premium-content blurred">
                <p style="color:#e0e0e0; font-size:0.9rem; line-height:1.6; margin:0;">${previewCard.full}</p>
                <div class="advice-box">
                    <span class="advice-label">Совет карт:</span>
                    <span style="color:#ccc;">${previewCard.advice}</span>
                </div>
            </div>
        `;
        actionsDiv.appendChild(premiumBlock);
    } else {
        const shareBtn = document.createElement('button');
        shareBtn.className = 'btn btn-share';
        shareBtn.innerHTML = '<i class="fa-brands fa-telegram"></i> Поделиться предсказанием';
        shareBtn.onclick = sharePrediction;
        actionsDiv.appendChild(shareBtn);

        const resetBtn = document.createElement('button');
        resetBtn.className = 'btn btn-share';
        resetBtn.style.border = 'none';
        resetBtn.style.background = 'transparent';
        resetBtn.style.opacity = '0.5';
        resetBtn.textContent = 'Сброс (Новый день)';
        resetBtn.onclick = resetApp;
        actionsDiv.appendChild(resetBtn);

        // Premium Upsell
        const upsellDiv = document.createElement('div');
        upsellDiv.className = 'premium-block';
        upsellDiv.style.marginTop = '20px';
        upsellDiv.style.border = '1px solid var(--accent-gold)';
        upsellDiv.style.padding = '20px';
        upsellDiv.style.borderRadius = '12px';
        upsellDiv.style.background = 'rgba(255, 215, 0, 0.05)';
        upsellDiv.style.textAlign = 'center';

        if (!state.isPremium) {
            upsellDiv.innerHTML = `
                <h3 style="color:var(--accent-gold); margin:0 0 10px 0;"><i class="fa-solid fa-crown"></i> INTARIUS Premium</h3>
                <p style="font-size:0.9rem; color:#ccc; margin-bottom:15px;">
                    Хочешь узнать больше? Оформи Premium и открой расклад <strong>"Кельтский Крест"</strong> (10 карт) с полным анализом.
                </p>
                <button class="btn" style="width:100%; justify-content:center;" onclick="tg.showPopup({title:'Premium', message:'Покупка в разработке'})">
                    Оформить Premium
                </button>
            `;
            actionsDiv.appendChild(upsellDiv);
        } else if (spreadType !== 'cross') {
            upsellDiv.innerHTML = `
                <h3 style="color:var(--accent-gold); margin:0 0 10px 0;"><i class="fa-solid fa-crown"></i> INTARIUS Premium</h3>
                <p style="font-size:0.9rem; color:#ccc; margin-bottom:15px;">
                    Ваш статус позволяет использовать полный расклад <strong>"Кельтский Крест"</strong>.
                </p>
                <button class="btn" style="width:100%; justify-content:center;" onclick="startCrossReading()">
                    Открыть Кельтский Крест (10 карт)
                </button>
            `;
            actionsDiv.appendChild(upsellDiv);
        }
    }

    container.appendChild(actionsDiv);
    document.getElementById('result-title').textContent = spreadMeta.name;
    showScreen('result-screen');
}

// --- Ad Integration ---
function watchAd() {
    const unlockContent = () => {
        state.adWatched = true;
        localStorage.setItem(KEYS.AD_WATCHED, 'true');
        const lastDraw = JSON.parse(localStorage.getItem(KEYS.LAST_DRAW));
        if (lastDraw) showResult(lastDraw.cards, state.selectedSpread, true);
    };

    if (!window.Adsgram) {
        console.warn("Adsgram SDK not loaded - fallback unlock");
        unlockContent();
        return;
    }

    const AdController = window.Adsgram.init({ blockId: "int-22202" });

    AdController.show()
        .then((result) => {
            console.log("Ad watched successfully:", result);
            tg.showPopup({ title: 'Судьба открыта', message: 'Вселенная благодарит вас за терпение.' });
            unlockContent();
        })
        .catch((result) => {
            console.log("Ad skipped or error:", result);
            if (result.error) {
                unlockContent();
            } else {
                tg.showPopup({ title: 'Внимание', message: 'Чтобы узнать судьбу, нужно досмотреть видео до конца.' });
            }
        });
}

// --- Share ---
function sharePrediction() {
    const url = "https://t.me/Intarius_bot";

    function htmlToTelegramMarkdown(html) {
        if (!html) return "Карты открыли мне многое.";

        let text = html
            .replace(/<strong[^>]*>(.*?)<\/strong>/gi, '*$1*')
            .replace(/<b[^>]*>(.*?)<\/b>/gi, '*$1*')
            .replace(/<em[^>]*>(.*?)<\/em>/gi, '_$1_')
            .replace(/<i[^>]*>(.*?)<\/i>/gi, '_$1_')
            .replace(/<br\s*\/?>/gi, '\n')
            .replace(/<\/(p|div|h[1-6])>/gi, '\n')
            .replace(/<[^>]+>/g, '')
            .replace(/\n{3,}/g, '\n\n')
            .replace(/&nbsp;/g, ' ')
            .replace(/&amp;/g, '&')
            .replace(/&lt;/g, '<')
            .replace(/&gt;/g, '>')
            .replace(/&quot;/g, '"')
            .trim();

        return text;
    }

    let shareBody = htmlToTelegramMarkdown(state.lastSynthesisHTML);

    if (shareBody.length > 500) {
        shareBody = shareBody.substring(0, 497) + "...";
    }

    const text = `🔮 *INTARIUS: Моё предсказание*\n\n${shareBody}\n\n✨ Попробуй и ты!`;
    const fullUrl = `https://t.me/share/url?url=${encodeURIComponent(url)}&text=${encodeURIComponent(text)}`;
    tg.openTelegramLink ? tg.openTelegramLink(fullUrl) : window.open(fullUrl, '_blank');
}

// --- Utils ---
function resetApp() {
    localStorage.clear();
    location.reload();
}

function createParticles() {
    const pContainer = document.getElementById('particles');
    if (!pContainer) return;

    for (let i = 0; i < 30; i++) {
        const s = document.createElement('div');
        s.className = 'star';
        s.style.left = Math.random() * 100 + '%';
        s.style.top = Math.random() * 100 + '%';
        s.style.width = Math.random() * 3 + 'px';
        s.style.height = s.style.width;
        s.style.animationDelay = Math.random() * 5 + 's';
        pContainer.appendChild(s);
    }
}
