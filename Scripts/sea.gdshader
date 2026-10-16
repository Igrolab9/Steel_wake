shader_type canvas_item;

// --- 1. Оригинальные настройки (ничего не меняем) ---
uniform float scroll_speed : hint_range(0.0, 500.0) = 80.0;

// --- 2. Настройки волн (искажение поверхности) ---
uniform float wave_amplitude : hint_range(0.0, 0.1) = 0.015; // Сила искажения (насколько волны "гнут" текстуру)
uniform float wave_frequency : hint_range(0.0, 50.0) = 15.0;  // Частота волн (сколько их на экране)
uniform float wave_speed : hint_range(0.0, 10.0) = 2.0;       // Скорость движения самих волн

// --- 3. Настройки бликов (солнечные зайчики) ---
uniform float glint_intensity : hint_range(0.0, 1.0) = 0.4;  // Общая яркость бликов
uniform float glint_scale : hint_range(0.0, 50.0) = 25.0;    // Размер бликов (чем больше число, тем они мельче)
uniform float glint_speed : hint_range(0.0, 10.0) = 1.5;     // Скорость переливания бликов

void fragment() {
    // Шаг 1: Базовое движение (твой оригинальный код)
    vec2 uv = UV;
    uv.y -= TIME * scroll_speed / 3000.0;
    
    // Шаг 2: Добавляем волновое искажение координат
    // Комбинируем две синусоиды для более естественного, "живого" движения воды
    float wave_offset = sin(uv.y * wave_frequency + TIME * wave_speed) * wave_amplitude;
    wave_offset += sin(uv.x * wave_frequency * 0.5 + TIME * wave_speed * 0.7) * (wave_amplitude * 0.5);
    uv.x += wave_offset;
    
    // Шаг 3: Получаем цвет текстуры с уже искажёнными координатами
    vec4 base_color = texture(TEXTURE, uv);
    
    // Шаг 4: Создаём маску для бликов
    // Комбинация синусов создаёт "острые" пики яркости, похожие на отражение света на воде
    float glint_wave = sin(uv.x * glint_scale + TIME * glint_speed) 
                     + sin(uv.y * glint_scale * 0.5 + TIME * glint_speed * 0.8);
    
    // Делаем пики резкими и яркими с помощью smoothstep (отсекаем плавные переходы, оставляем только вспышки)
    float highlight = smoothstep(0.8, 1.0, sin(glint_wave * 3.14159));
    
    // Шаг 5: Итоговый цвет
    // Беловато-голубой оттенок для бликов, чтобы они выглядели как солнечные отражения
    vec3 glint_color = vec3(0.9, 0.95, 1.0); 
    vec3 final_color = base_color.rgb + (glint_color * highlight * glint_intensity);
    
    // Записываем итоговый цвет, сохраняя оригинальную прозрачность (alpha)
    COLOR = vec4(final_color, base_color.a);
}