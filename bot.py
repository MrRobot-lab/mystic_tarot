import telebot
from telebot.types import InlineKeyboardMarkup, InlineKeyboardButton, WebAppInfo

# 1. Вставьте сюда токен, который дал @BotFather
BOT_TOKEN = 'ВАШ_ТОКЕН_ОТ_BOTFATHER'

# 2. Вставьте сюда HTTPS ссылку на ваш index.html (например, с GitHub Pages)
WEB_APP_URL = 'https://ваш-ник.github.io/mystic-tarot/'

bot = telebot.TeleBot(BOT_TOKEN)

@bot.message_handler(commands=['start'])
def send_welcome(message):
    markup = InlineKeyboardMarkup()
    
    # Кнопка, которая открывает Mini App внутри Телеграма
    btn_tarot = InlineKeyboardButton(
        text="✨ Раскинуть карты ✨", 
        web_app=WebAppInfo(url=WEB_APP_URL)
    )
    markup.add(btn_tarot)

    bot.send_message(
        message.chat.id, 
        "🌙 <b>Добро пожаловать в Mystic Tarot.</b>\n\n"
        "Звезды сошлись. Задай свой вопрос и открой карту дня.",
        parse_mode='HTML',
        reply_markup=markup
    )

print("Бот запущен...")
bot.infinity_polling()
