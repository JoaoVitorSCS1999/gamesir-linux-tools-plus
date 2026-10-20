pragma Singleton
import QtQuick

// Small runtime translation layer. English remains the source language; keys
// without a translation fall back to the original text so new UI strings remain
// usable while catalogs are expanded.
QtObject {
    id: i18n
    property string language: "en"

    readonly property var languages: [
        { code: "en", name: "English" },
        { code: "pt_BR", name: "Português (Brasil)" },
        { code: "ja", name: "日本語" },
        { code: "es", name: "Español" },
        { code: "ru", name: "Русский" },
        { code: "zh_CN", name: "简体中文" },
        { code: "ko", name: "한국어" },
        { code: "hi", name: "हिन्दी" },
        { code: "de", name: "Deutsch" },
        { code: "pl", name: "Polski" }
    ]

    // source text: [pt-BR, ja, es, ru, zh-CN, ko, hi, de, pl]
    readonly property var catalog: ({
        "Settings": ["Configurações", "設定", "Ajustes", "Настройки", "设置", "설정", "सेटिंग्स", "Einstellungen", "Ustawienia"],
        "Language": ["Idioma", "言語", "Idioma", "Язык", "语言", "언어", "भाषा", "Sprache", "Język"],
        "Appearance": ["Aparência", "外観", "Apariencia", "Внешний вид", "外观", "모양", "दिखावट", "Erscheinungsbild", "Wygląd"],
        "Density": ["Densidade", "密度", "Densidad", "Плотность", "密度", "밀도", "घनत्व", "Dichte", "Gęstość"],
        "Compact": ["Compacta", "コンパクト", "Compacta", "Компактная", "紧凑", "간결하게", "सघन", "Kompakt", "Kompaktowy"],
        "Comfortable": ["Confortável", "標準", "Cómoda", "Удобная", "舒适", "편안하게", "आरामदायक", "Komfortabel", "Wygodny"],
        "Cozy": ["Aconchegante", "ゆったり", "Acogedora", "Свободная", "宽松", "여유롭게", "आरामदायक", "Gemütlich", "Przytulny"],
        "Demo mode": ["Modo de demonstração", "デモモード", "Modo de demostración", "Демо-режим", "演示模式", "데모 모드", "डेमो मोड", "Demomodus", "Tryb demonstracyjny"],
        "Theme": ["Tema", "テーマ", "Tema", "Тема", "主题", "테마", "थीम", "Design", "Motyw"],
        "Reset colors": ["Redefinir cores", "色をリセット", "Restablecer colores", "Сбросить цвета", "重置颜色", "색상 초기화", "रंग रीसेट करें", "Farben zurücksetzen", "Resetuj kolory"],
        "Presets": ["Predefinições", "プリセット", "Preajustes", "Предустановки", "预设", "프리셋", "प्रीसेट", "Voreinstellungen", "Gotowe ustawienia"],
        "Custom colors": ["Cores personalizadas", "カスタムカラー", "Colores personalizados", "Свои цвета", "自定义颜色", "사용자 지정 색상", "कस्टम रंग", "Benutzerdefinierte Farben", "Kolory niestandardowe"],
        "Background": ["Plano de fundo", "背景", "Fondo", "Фон", "背景", "배경", "पृष्ठभूमि", "Hintergrund", "Tło"],
        "Choose…": ["Escolher…", "選択…", "Elegir…", "Выбрать…", "选择…", "선택…", "चुनें…", "Auswählen…", "Wybierz…"],
        "Clear": ["Limpar", "クリア", "Quitar", "Очистить", "清除", "지우기", "हटाएँ", "Entfernen", "Wyczyść"],
        "Fit": ["Ajustar", "フィット", "Ajustar", "По размеру", "适应", "맞춤", "फ़िट", "Einpassen", "Dopasuj"],
        "Dim": ["Escurecer", "暗さ", "Oscurecer", "Затемнение", "变暗", "어둡게", "मंद करें", "Abdunkeln", "Przyciemnienie"],
        "Controllers": ["Controles", "コントローラー", "Mandos", "Контроллеры", "控制器", "컨트롤러", "कंट्रोलर", "Controller", "Kontrolery"],
        "Nothing connected.": ["Nenhum dispositivo conectado.", "接続されていません。", "No hay ningún dispositivo conectado.", "Нет подключённых устройств.", "没有连接设备。", "연결된 장치가 없습니다.", "कोई डिवाइस कनेक्ट नहीं है।", "Kein Gerät verbunden.", "Brak podłączonych urządzeń."],
        "Backup & Restore": ["Backup e restauração", "バックアップと復元", "Copia de seguridad y restauración", "Резервное копирование и восстановление", "备份与恢复", "백업 및 복원", "बैकअप और पुनर्स्थापना", "Sicherung und Wiederherstellung", "Kopia zapasowa i przywracanie"],
        "Help & Diagnostics": ["Ajuda e diagnóstico", "ヘルプと診断", "Ayuda y diagnóstico", "Справка и диагностика", "帮助与诊断", "도움말 및 진단", "सहायता और निदान", "Hilfe und Diagnose", "Pomoc i diagnostyka"],
        "Diagnostics…": ["Diagnóstico…", "診断…", "Diagnóstico…", "Диагностика…", "诊断…", "진단…", "निदान…", "Diagnose…", "Diagnostyka…"],
        "🩺 Open diagnostics…": ["🩺 Abrir diagnóstico…", "🩺 診断を開く…", "🩺 Abrir diagnóstico…", "🩺 Открыть диагностику…", "🩺 打开诊断…", "🩺 진단 열기…", "🩺 निदान खोलें…", "🩺 Diagnose öffnen…", "🩺 Otwórz diagnostykę…"],
        "Check for updates": ["Verificar atualizações", "更新を確認", "Buscar actualizaciones", "Проверить обновления", "检查更新", "업데이트 확인", "अपडेट जाँचें", "Nach Updates suchen", "Sprawdź aktualizacje"],
        "Checking for updates…": ["Verificando atualizações…", "更新を確認中…", "Buscando actualizaciones…", "Проверка обновлений…", "正在检查更新…", "업데이트 확인 중…", "अपडेट जाँचे जा रहे हैं…", "Suche nach Updates…", "Sprawdzanie aktualizacji…"],
        "Buttons": ["Botões", "ボタン", "Botones", "Кнопки", "按键", "버튼", "बटन", "Tasten", "Przyciski"],
        "Rebinds": ["Remapeamento", "ボタン割り当て", "Asignación", "Переназначение", "按键映射", "버튼 재지정", "बटन रीमैप", "Tastenbelegung", "Przypisania"],
        "Sticks": ["Analógicos", "スティック", "Palancas", "Стики", "摇杆", "스틱", "स्टिक", "Sticks", "Drążki"],
        "Triggers": ["Gatilhos", "トリガー", "Gatillos", "Триггеры", "扳机", "트리거", "ट्रिगर", "Trigger", "Spusty"],
        "Vibration": ["Vibração", "振動", "Vibración", "Вибрация", "振动", "진동", "कंपन", "Vibration", "Wibracje"],
        "Motion": ["Movimento", "モーション", "Movimiento", "Движение", "动作", "모션", "मोशन", "Bewegung", "Ruch"],
        "Device": ["Dispositivo", "デバイス", "Dispositivo", "Устройство", "设备", "장치", "डिवाइस", "Gerät", "Urządzenie"],
        "Lights": ["Iluminação", "ライト", "Luces", "Подсветка", "灯光", "조명", "लाइट", "Beleuchtung", "Światła"],
        "Macros": ["Macros", "マクロ", "Macros", "Макросы", "宏", "매크로", "मैक्रो", "Makros", "Makra"],
        "DPI": ["DPI", "DPI", "DPI", "DPI", "DPI", "DPI", "DPI", "DPI", "DPI"],
        "Lighting": ["Iluminação", "ライティング", "Iluminación", "Подсветка", "灯光", "조명", "लाइटिंग", "Beleuchtung", "Oświetlenie"],
        "Lighting Profile": ["Perfil de iluminação", "ライティングプロファイル", "Perfil de iluminación", "Профиль подсветки", "灯光配置", "조명 프로필", "लाइटिंग प्रोफ़ाइल", "Beleuchtungsprofil", "Profil oświetlenia"],
        "Brightness & Speed": ["Brilho e velocidade", "明るさと速度", "Brillo y velocidad", "Яркость и скорость", "亮度和速度", "밝기 및 속도", "चमक और गति", "Helligkeit und Geschwindigkeit", "Jasność i szybkość"],
        "Select all": ["Selecionar tudo", "すべて選択", "Seleccionar todo", "Выбрать все", "全选", "모두 선택", "सभी चुनें", "Alle auswählen", "Zaznacz wszystko"],
        "Restore default lighting": ["Restaurar iluminação padrão", "標準のライトに戻す", "Restaurar iluminación predeterminada", "Восстановить подсветку по умолчанию", "恢复默认灯光", "기본 조명 복원", "डिफ़ॉल्ट लाइटिंग बहाल करें", "Standardbeleuchtung wiederherstellen", "Przywróć domyślne oświetlenie"],
        "Response Curve": ["Curva de resposta", "応答カーブ", "Curva de respuesta", "Кривая отклика", "响应曲线", "응답 곡선", "प्रतिक्रिया वक्र", "Antwortkurve", "Krzywa reakcji"],
        "Deadzone & Response": ["Zona morta e resposta", "デッドゾーンと応答", "Zona muerta y respuesta", "Мёртвая зона и отклик", "死区与响应", "데드존 및 응답", "डेडज़ोन और प्रतिक्रिया", "Totzone und Reaktion", "Martwa strefa i reakcja"],
        "Anti-Deadzone": ["Antizona morta", "アンチデッドゾーン", "Antizona muerta", "Антимёртвая зона", "反死区", "안티 데드존", "एंटी-डेडज़ोन", "Anti-Totzone", "Antymartwa strefa"],
        "Continuous Trigger": ["Gatilho contínuo", "連続トリガー", "Gatillo continuo", "Непрерывный триггер", "连续扳机", "연속 트리거", "निरंतर ट्रिगर", "Dauertrigger", "Ciągły spust"],
        "Tap to hold / release": ["Toque para manter/liberar", "タップで保持／解除", "Toca para mantener/soltar", "Нажмите, чтобы удерживать/отпустить", "轻触以按住/释放", "탭하여 유지/해제", "दबाकर रखें / छोड़ें", "Tippen zum Halten/Lösen", "Dotknij, aby przytrzymać/zwolnić"],
        "Save": ["Salvar", "保存", "Guardar", "Сохранить", "保存", "저장", "सहेजें", "Speichern", "Zapisz"],
        "Discard": ["Descartar", "破棄", "Descartar", "Отменить", "放弃", "취소", "रद्द करें", "Verwerfen", "Odrzuć"],
        "Cancel": ["Cancelar", "キャンセル", "Cancelar", "Отмена", "取消", "취소", "रद्द करें", "Abbrechen", "Anuluj"],
        "Apply": ["Aplicar", "適用", "Aplicar", "Применить", "应用", "적용", "लागू करें", "Anwenden", "Zastosuj"],
        "Working…": ["Processando…", "処理中…", "Procesando…", "Выполняется…", "处理中…", "처리 중…", "कार्य जारी है…", "Wird ausgeführt…", "Przetwarzanie…"],
        "Connected": ["Conectado", "接続済み", "Conectado", "Подключено", "已连接", "연결됨", "कनेक्टेड", "Verbunden", "Połączono"],
        "Not connected": ["Desconectado", "未接続", "Desconectado", "Не подключено", "未连接", "연결 안 됨", "कनेक्ट नहीं है", "Nicht verbunden", "Nie połączono"],
        "Wireless": ["Sem fio", "ワイヤレス", "Inalámbrico", "Беспроводной", "无线", "무선", "वायरलेस", "Kabellos", "Bezprzewodowy"],
        "Wired": ["Com fio", "有線", "Con cable", "Проводной", "有线", "유선", "वायर्ड", "Kabelgebunden", "Przewodowy"],
        "Poll rate": ["Taxa de polling", "ポーリングレート", "Frecuencia de sondeo", "Частота опроса", "轮询率", "폴링 속도", "पोलिंग दर", "Abfragerate", "Częstotliwość odpytywania"],
        "Report rate": ["Taxa de relatório", "レポートレート", "Frecuencia de informe", "Частота отчётов", "报告率", "보고율", "रिपोर्ट दर", "Berichtsrate", "Częstotliwość raportowania"],
        "Rename": ["Renomear", "名前を変更", "Renombrar", "Переименовать", "重命名", "이름 변경", "नाम बदलें", "Umbenennen", "Zmień nazwę"],
        "Reset profile": ["Redefinir perfil", "プロファイルをリセット", "Restablecer perfil", "Сбросить профиль", "重置配置", "프로필 초기화", "प्रोफ़ाइल रीसेट करें", "Profil zurücksetzen", "Resetuj profil"],
        "Choose a background image or video": ["Escolha uma imagem ou vídeo de fundo", "背景画像または動画を選択", "Elige una imagen o vídeo de fondo", "Выберите фоновое изображение или видео", "选择背景图片或视频", "배경 이미지 또는 동영상 선택", "पृष्ठभूमि छवि या वीडियो चुनें", "Hintergrundbild oder -video auswählen", "Wybierz obraz lub film w tle"],
        "Deadband update available": ["Atualização do Deadband disponível", "Deadbandの更新があります", "Hay una actualización de Deadband", "Доступно обновление Deadband", "Deadband 有可用更新", "Deadband 업데이트 사용 가능", "Deadband अपडेट उपलब्ध", "Deadband-Update verfügbar", "Dostępna aktualizacja Deadband"],
        "Later": ["Mais tarde", "後で", "Más tarde", "Позже", "稍后", "나중에", "बाद में", "Später", "Później"],
        "Update now": ["Atualizar agora", "今すぐ更新", "Actualizar ahora", "Обновить сейчас", "立即更新", "지금 업데이트", "अभी अपडेट करें", "Jetzt aktualisieren", "Aktualizuj teraz"],
        "Update installed": ["Atualização instalada", "更新をインストールしました", "Actualización instalada", "Обновление установлено", "更新已安装", "업데이트 설치됨", "अपडेट इंस्टॉल हो गया", "Update installiert", "Aktualizacja zainstalowana"],
        "This controller has no app-configurable lighting.": ["Este controle não tem iluminação configurável pelo app.", "このコントローラーのライトはアプリで設定できません。", "Este mando no tiene iluminación configurable desde la aplicación.", "Подсветка этого контроллера не настраивается в приложении.", "此控制器的灯光无法通过应用配置。", "이 컨트롤러의 조명은 앱에서 설정할 수 없습니다.", "इस कंट्रोलर की लाइटिंग ऐप से कॉन्फ़िगर नहीं की जा सकती।", "Die Beleuchtung dieses Controllers kann nicht in der App konfiguriert werden.", "Podświetlenia tego kontrolera nie można konfigurować w aplikacji."],
        "This controller has no app-configurable macros.": ["Este controle não tem macros configuráveis pelo app.", "このコントローラーのマクロはアプリで設定できません。", "Este mando no tiene macros configurables desde la aplicación.", "Макросы этого контроллера не настраиваются в приложении.", "此控制器的宏无法通过应用配置。", "이 컨트롤러의 매크로는 앱에서 설정할 수 없습니다.", "इस कंट्रोलर के मैक्रो ऐप से कॉन्फ़िगर नहीं किए जा सकते।", "Makros dieses Controllers können nicht in der App konfiguriert werden.", "Makra tego kontrolera nie można konfigurować w aplikacji."],
        "This controller has no app-configurable motion / gyro.": ["Este controle não tem movimento/giroscópio configurável pelo app.", "このコントローラーのモーション／ジャイロはアプリで設定できません。", "Este mando no tiene movimiento/giroscopio configurable desde la aplicación.", "Движение и гироскоп этого контроллера не настраиваются в приложении.", "此控制器的动作/陀螺仪无法通过应用配置。", "이 컨트롤러의 모션/자이로는 앱에서 설정할 수 없습니다.", "इस कंट्रोलर का मोशन/जायरो ऐप से कॉन्फ़िगर नहीं किया जा सकता।", "Bewegung und Gyroskop dieses Controllers können nicht in der App konfiguriert werden.", "Ruchu i żyroskopu tego kontrolera nie można konfigurować w aplikacji."],
        "Button Mapping": ["Mapeamento de botões", "ボタン割り当て", "Asignación de botones", "Назначение кнопок", "按键映射", "버튼 매핑", "बटन मैपिंग", "Tastenbelegung", "Mapowanie przycisków"],
        "Default": ["Padrão", "標準", "Predeterminado", "По умолчанию", "默认", "기본값", "डिफ़ॉल्ट", "Standard", "Domyślne"],
        "No profile selected": ["Nenhum perfil selecionado", "プロファイルが選択されていません", "Ningún perfil seleccionado", "Профиль не выбран", "未选择配置", "프로필이 선택되지 않음", "कोई प्रोफ़ाइल चयनित नहीं", "Kein Profil ausgewählt", "Nie wybrano profilu"],
        "Pick a profile (1–4) in the top bar to read and edit its settings.": ["Escolha um perfil (1–4) na barra superior para ler e editar suas configurações.", "上部バーでプロファイル（1～4）を選び、設定を読み込んで編集してください。", "Elige un perfil (1–4) en la barra superior para leer y editar sus ajustes.", "Выберите профиль (1–4) на верхней панели, чтобы просмотреть и изменить его настройки.", "在顶部栏选择配置（1–4）以读取和编辑设置。", "상단 표시줄에서 프로필(1–4)을 선택해 설정을 읽고 편집하세요.", "सेटिंग पढ़ने और संपादित करने के लिए ऊपर बार में प्रोफ़ाइल (1–4) चुनें।", "Wähle oben ein Profil (1–4), um dessen Einstellungen zu lesen und zu bearbeiten.", "Wybierz profil (1–4) na górnym pasku, aby odczytać i edytować jego ustawienia."],
        "Back up to file…": ["Fazer backup em arquivo…", "ファイルにバックアップ…", "Crear copia en un archivo…", "Сохранить резервную копию в файл…", "备份到文件…", "파일로 백업…", "फ़ाइल में बैकअप लें…", "In Datei sichern…", "Utwórz kopię zapasową do pliku…"],
        "Restore from file…": ["Restaurar de arquivo…", "ファイルから復元…", "Restaurar desde un archivo…", "Восстановить из файла…", "从文件恢复…", "파일에서 복원…", "फ़ाइल से पुनर्स्थापित करें…", "Aus Datei wiederherstellen…", "Przywróć z pliku…"],
        "Save controller backup": ["Salvar backup do controle", "コントローラーのバックアップを保存", "Guardar copia de seguridad del mando", "Сохранить резервную копию контроллера", "保存控制器备份", "컨트롤러 백업 저장", "कंट्रोलर बैकअप सहेजें", "Controller-Sicherung speichern", "Zapisz kopię zapasową kontrolera"],
        "Restore controller backup": ["Restaurar backup do controle", "コントローラーのバックアップを復元", "Restaurar copia de seguridad del mando", "Восстановить резервную копию контроллера", "恢复控制器备份", "컨트롤러 백업 복원", "कंट्रोलर बैकअप पुनर्स्थापित करें", "Controller-Sicherung wiederherstellen", "Przywróć kopię zapasową kontrolera"],
        "Reset all profiles to defaults": ["Redefinir todos os perfis", "すべてのプロファイルを初期化", "Restablecer todos los perfiles", "Сбросить все профили", "重置所有配置", "모든 프로필을 기본값으로 초기화", "सभी प्रोफ़ाइल डिफ़ॉल्ट पर रीसेट करें", "Alle Profile zurücksetzen", "Resetuj wszystkie profile"],
        "Reset to defaults": ["Redefinir para o padrão", "初期設定に戻す", "Restablecer valores predeterminados", "Сбросить настройки", "恢复默认设置", "기본값으로 초기화", "डिफ़ॉल्ट पर रीसेट करें", "Auf Standard zurücksetzen", "Przywróć ustawienia domyślne"],
        "Sequence": ["Sequência", "シーケンス", "Secuencia", "Последовательность", "序列", "시퀀스", "क्रम", "Sequenz", "Sekwencja"],
        "Live input": ["Entrada ao vivo", "ライブ入力", "Entrada en directo", "Входные данные", "实时输入", "실시간 입력", "लाइव इनपुट", "Live-Eingabe", "Dane wejściowe na żywo"],
        "Live Sensors": ["Sensores ao vivo", "ライブセンサー", "Sensores en directo", "Датчики в реальном времени", "实时传感器", "실시간 센서", "लाइव सेंसर", "Live-Sensoren", "Czujniki na żywo"],
        "DPI stages": ["Níveis de DPI", "DPI段階", "Niveles de DPI", "Уровни DPI", "DPI 档位", "DPI 단계", "DPI स्तर", "DPI-Stufen", "Poziomy DPI"],
        "How the DPI buttons work": ["Como funcionam os botões de DPI", "DPIボタンの仕組み", "Cómo funcionan los botones DPI", "Как работают кнопки DPI", "DPI 按键的工作方式", "DPI 버튼 작동 방식", "DPI बटन कैसे काम करते हैं", "Funktionsweise der DPI-Tasten", "Jak działają przyciski DPI"],
        "Charging dock": ["Base de carregamento", "充電ドック", "Base de carga", "Зарядная док-станция", "充电底座", "충전 도크", "चार्जिंग डॉक", "Ladestation", "Stacja ładująca"],
        "G7 Pro configuration session": ["Sessão de configuração do G7 Pro", "G7 Pro設定セッション", "Sesión de configuración del G7 Pro", "Сеанс настройки G7 Pro", "G7 Pro 配置会话", "G7 Pro 구성 세션", "G7 Pro कॉन्फ़िगरेशन सत्र", "G7-Pro-Konfigurationssitzung", "Sesja konfiguracji G7 Pro"],
        "+ Add event": ["+ Adicionar evento", "+ イベントを追加", "+ Añadir evento", "+ Добавить событие", "+ 添加事件", "+ 이벤트 추가", "+ इवेंट जोड़ें", "+ Ereignis hinzufügen", "+ Dodaj zdarzenie"],
        "Grant access (one-time)": ["Conceder acesso (uma vez)", "アクセスを許可（初回のみ）", "Conceder acceso (una vez)", "Предоставить доступ (один раз)", "授予访问权限（仅一次）", "접근 권한 허용(최초 1회)", "पहुँच दें (एक बार)", "Zugriff gewähren (einmalig)", "Przyznaj dostęp (jednorazowo)"],
        "Active": ["Ativo", "有効", "Activo", "Активно", "启用", "활성", "सक्रिय", "Aktiv", "Aktywne"],
        "Live": ["Ao vivo", "ライブ", "En directo", "В реальном времени", "实时", "실시간", "लाइव", "Live", "Na żywo"],
        "Output": ["Saída", "出力", "Salida", "Выход", "输出", "출력", "आउटपुट", "Ausgabe", "Wyjście"],
        "Activation": ["Ativação", "有効化", "Activación", "Активация", "激活", "활성화", "सक्रियण", "Aktivierung", "Aktywacja"],
        "Release to games": ["Liberar para os jogos", "ゲームに戻す", "Devolver a los juegos", "Вернуть играм", "释放给游戏", "게임에 다시 연결", "गेम के लिए छोड़ें", "Für Spiele freigeben", "Przekaż grom"],
        "Configure controller": ["Configurar controle", "コントローラーを設定", "Configurar mando", "Настроить контроллер", "配置控制器", "컨트롤러 구성", "कंट्रोलर कॉन्फ़िगर करें", "Controller konfigurieren", "Skonfiguruj kontroler"],
        "Retry": ["Tentar novamente", "再試行", "Reintentar", "Повторить", "重试", "다시 시도", "पुनः प्रयास करें", "Erneut versuchen", "Ponów próbę"],
        "Updating…": ["Atualizando…", "更新中…", "Actualizando…", "Обновление…", "正在更新…", "업데이트 중…", "अपडेट हो रहा है…", "Wird aktualisiert…", "Aktualizowanie…"],
        "Version %1 is available. Deadband will download and verify the update before installing it.": ["A versão %1 está disponível. O Deadband baixará e verificará a atualização antes de instalá-la.", "バージョン%1が利用可能です。Deadbandは更新をダウンロードして検証してからインストールします。", "La versión %1 está disponible. Deadband descargará y verificará la actualización antes de instalarla.", "Доступна версия %1. Deadband загрузит обновление и проверит его перед установкой.", "版本 %1 已发布。Deadband 将下载并验证更新后再安装。", "버전 %1을 사용할 수 있습니다. Deadband가 업데이트를 다운로드하고 검증한 후 설치합니다.", "संस्करण %1 उपलब्ध है। Deadband अपडेट डाउनलोड और सत्यापित करने के बाद इंस्टॉल करेगा।", "Version %1 ist verfügbar. Deadband lädt das Update herunter und prüft es vor der Installation.", "Wersja %1 jest dostępna. Deadband pobierze i zweryfikuje aktualizację przed instalacją."],
        "Version %1 is available, but no compatible package was found for this installation.": ["A versão %1 está disponível, mas não há pacote compatível com esta instalação.", "バージョン%1が利用可能ですが、このインストールに対応するパッケージがありません。", "La versión %1 está disponible, pero no hay un paquete compatible con esta instalación.", "Доступна версия %1, но совместимый пакет для этой установки не найден.", "版本 %1 已发布，但未找到适用于此安装方式的软件包。", "버전 %1을 사용할 수 있지만 현재 설치 방식과 호환되는 패키지가 없습니다.", "संस्करण %1 उपलब्ध है, लेकिन इस इंस्टॉलेशन के लिए संगत पैकेज नहीं मिला।", "Version %1 ist verfügbar, aber für diese Installation wurde kein passendes Paket gefunden.", "Wersja %1 jest dostępna, ale nie znaleziono pakietu zgodnego z tą instalacją."],
        "Click a zone to select it; Ctrl-click to add or remove zones": ["Clique em uma zona para selecioná-la; Ctrl+clique para adicionar ou remover zonas", "ゾーンをクリックして選択。Ctrl+クリックで追加または解除", "Haz clic en una zona para seleccionarla; Ctrl+clic para añadir o quitar zonas", "Нажмите на зону, чтобы выбрать её; Ctrl+нажатие добавляет или убирает зоны", "点击区域以选择；按住 Ctrl 点击可添加或移除区域", "영역을 클릭해 선택하고 Ctrl+클릭으로 추가하거나 제거하세요", "ज़ोन चुनने के लिए क्लिक करें; जोड़ने या हटाने के लिए Ctrl-क्लिक करें", "Klicke eine Zone zum Auswählen; Strg-Klick fügt Zonen hinzu oder entfernt sie", "Kliknij strefę, aby ją wybrać; Ctrl+kliknięcie dodaje lub usuwa strefy"],
        "Click wedges to select — pick several to edit together": ["Clique nas partes para selecionar; escolha várias para editar juntas", "パーツをクリックして選択。複数選ぶとまとめて編集できます", "Haz clic en las secciones para seleccionar varias y editarlas juntas", "Нажмите на сегменты — можно выбрать несколько для совместного редактирования", "点击扇区进行选择，可多选并一起编辑", "조각을 클릭해 선택하세요. 여러 개를 함께 편집할 수 있습니다", "हिस्सों को चुनने के लिए क्लिक करें — कई हिस्सों को साथ संपादित करें", "Klicke Segmente an; mehrere lassen sich gemeinsam bearbeiten", "Kliknij segmenty; możesz wybrać kilka i edytować je razem"],
        "Showing custom colours. Pick a preset to replace them.": ["Exibindo cores personalizadas. Escolha uma predefinição para substituí-las.", "カスタムカラーを表示中です。プリセットを選ぶと置き換わります。", "Se muestran colores personalizados. Elige un preajuste para reemplazarlos.", "Показаны свои цвета. Выберите предустановку, чтобы заменить их.", "正在显示自定义颜色。选择预设即可替换。", "사용자 지정 색상을 표시 중입니다. 프리셋을 선택하면 바뀝니다.", "कस्टम रंग दिख रहे हैं। बदलने के लिए प्रीसेट चुनें।", "Benutzerdefinierte Farben werden angezeigt. Wähle eine Voreinstellung zum Ersetzen.", "Wyświetlane są własne kolory. Wybierz gotowe ustawienie, aby je zastąpić."],
        "For a multi-step macro, use the Macros tab.": ["Para uma macro com várias etapas, use a aba Macros.", "複数ステップのマクロには「マクロ」タブを使ってください。", "Para una macro de varios pasos, usa la pestaña Macros.", "Для многошагового макроса откройте вкладку «Макросы».", "多步骤宏请使用“宏”选项卡。", "여러 단계 매크로는 매크로 탭을 사용하세요.", "बहु-चरण मैक्रो के लिए Macros टैब का उपयोग करें।", "Für mehrstufige Makros nutze den Tab Makros.", "Wieloetapowe makra utworzysz na karcie Makra."],
        "Device diagnostics": ["Diagnóstico do dispositivo", "デバイス診断", "Diagnóstico del dispositivo", "Диагностика устройства", "设备诊断", "장치 진단", "डिवाइस निदान", "Gerätediagnose", "Diagnostyka urządzenia"],
        "Copy command": ["Copiar comando", "コマンドをコピー", "Copiar comando", "Копировать команду", "复制命令", "명령 복사", "कमांड कॉपी करें", "Befehl kopieren", "Kopiuj polecenie"],
        "Button": ["Botão", "ボタン", "Botón", "Кнопка", "按键", "버튼", "बटन", "Taste", "Przycisk"],
        "Accent": ["Destaque", "アクセント", "Acento", "Акцент", "强调色", "강조 색상", "अक्सेंट", "Akzent", "Akcent"],
        "Anti-deadzone": ["Antizona morta", "アンチデッドゾーン", "Antizona muerta", "Антимёртвая зона", "反死区", "안티 데드존", "एंटी-डेडज़ोन", "Anti-Totzone", "Antymartwa strefa"],
        "Audio reactive": ["Reativo ao áudio", "オーディオ連動", "Reactivo al audio", "Реакция на звук", "音频响应", "오디오 반응", "ऑडियो प्रतिक्रिया", "Audioreaktiv", "Reakcja na dźwięk"],
        "Brightness": ["Brilho", "明るさ", "Brillo", "Яркость", "亮度", "밝기", "चमक", "Helligkeit", "Jasność"],
        "Color — ": ["Cor — ", "色 — ", "Color — ", "Цвет — ", "颜色 — ", "색상 — ", "रंग — ", "Farbe — ", "Kolor — "],
        "Controller Light": ["Luz do controle", "コントローラーのライト", "Luz del mando", "Подсветка контроллера", "控制器灯光", "컨트롤러 조명", "कंट्रोलर लाइट", "Controller-Beleuchtung", "Podświetlenie kontrolera"],
        "Curve Adjustment": ["Ajuste da curva", "カーブ調整", "Ajuste de curva", "Настройка кривой", "曲线调整", "곡선 조정", "वक्र समायोजन", "Kurvenanpassung", "Regulacja krzywej"],
        "Curve strength": ["Intensidade da curva", "カーブの強さ", "Intensidad de curva", "Сила кривой", "曲线强度", "곡선 강도", "वक्र तीव्रता", "Kurvenstärke", "Siła krzywej"],
        "Custom": ["Personalizado", "カスタム", "Personalizado", "Своя настройка", "自定义", "사용자 지정", "कस्टम", "Benutzerdefiniert", "Niestandardowe"],
        "Disabled": ["Desativado", "無効", "Desactivado", "Отключено", "禁用", "비활성화", "अक्षम", "Deaktiviert", "Wyłączone"],
        "Force": ["Forçar", "強制", "Forzar", "Принудительно", "强制", "강제", "बलपूर्वक", "Erzwingen", "Wymuś"],
        "G-Shift": ["G-Shift", "G-Shift", "G-Shift", "G-Shift", "G-Shift", "G-Shift", "G-Shift", "G-Shift", "G-Shift"],
        "Hold": ["Manter pressionado", "長押し", "Mantener", "Удержание", "按住", "누르고 있기", "दबाए रखें", "Gedrückt halten", "Przytrzymaj"],
        "Input": ["Entrada", "入力", "Entrada", "Вход", "输入", "입력", "इनपुट", "Eingabe", "Wejście"],
        "Intensity": ["Intensidade", "強度", "Intensidad", "Интенсивность", "强度", "강도", "तीव्रता", "Intensität", "Intensywność"],
        "Invert X": ["Inverter X", "X軸を反転", "Invertir X", "Инвертировать X", "反转 X", "X 반전", "X उलटें", "X umkehren", "Odwróć X"],
        "Invert Y": ["Inverter Y", "Y軸を反転", "Invertir Y", "Инвертировать Y", "反转 Y", "Y 반전", "Y उलटें", "Y umkehren", "Odwróć Y"],
        "Key": ["Tecla", "キー", "Tecla", "Клавиша", "按键", "키", "कुंजी", "Taste", "Klawisz"],
        "Keyboard": ["Teclado", "キーボード", "Teclado", "Клавиатура", "键盘", "키보드", "कीबोर्ड", "Tastatur", "Klawiatura"],
        "Keyboard & mouse": ["Teclado e mouse", "キーボードとマウス", "Teclado y ratón", "Клавиатура и мышь", "键盘和鼠标", "키보드 및 마우스", "कीबोर्ड और माउस", "Tastatur und Maus", "Klawiatura i mysz"],
        "Keyframes": ["Quadros-chave", "キーフレーム", "Fotogramas clave", "Ключевые кадры", "关键帧", "키프레임", "कीफ़्रेम", "Keyframes", "Klatki kluczowe"],
        "Left": ["Esquerda", "左", "Izquierda", "Слева", "左", "왼쪽", "बायाँ", "Links", "Lewo"],
        "Left trigger": ["Gatilho esquerdo", "左トリガー", "Gatillo izquierdo", "Левый триггер", "左扳机", "왼쪽 트리거", "बायाँ ट्रिगर", "Linker Trigger", "Lewy spust"],
        "Max": ["Máx.", "最大", "Máx.", "Макс.", "最大", "최대", "अधिकतम", "Max.", "Maks."],
        "Method": ["Método", "方式", "Método", "Метод", "方式", "방식", "विधि", "Methode", "Metoda"],
        "Min": ["Mín.", "最小", "Mín.", "Мин.", "最小", "최소", "न्यूनतम", "Min.", "Min."],
        "Off": ["Desligado", "オフ", "Apagado", "Выкл.", "关闭", "끔", "बंद", "Aus", "Wył."],
        "Pick-up to wake": ["Ativar ao pegar", "持ち上げて起動", "Activar al levantar", "Пробуждение при поднятии", "拿起唤醒", "들어 올려 깨우기", "उठाने पर जगाएँ", "Beim Anheben aufwecken", "Wybudzanie po podniesieniu"],
        "Power": ["Energia", "電源", "Energía", "Питание", "电源", "전원", "पावर", "Stromversorgung", "Zasilanie"],
        "Randomize": ["Aleatorizar", "ランダム", "Aleatorizar", "Случайно", "随机", "무작위", "यादृच्छिक", "Zufällig", "Losuj"],
        "Remove": ["Remover", "削除", "Quitar", "Удалить", "移除", "제거", "हटाएँ", "Entfernen", "Usuń"],
        "Repeat while held": ["Repetir enquanto pressionado", "押している間繰り返す", "Repetir mientras se mantiene", "Повторять при удержании", "按住时重复", "누르는 동안 반복", "दबाए रखने पर दोहराएँ", "Wiederholen, solange gedrückt", "Powtarzaj po przytrzymaniu"],
        "Resolution": ["Resolução", "解像度", "Resolución", "Разрешение", "分辨率", "해상도", "रिज़ॉल्यूशन", "Auflösung", "Rozdzielczość"],
        "Sensitivity": ["Sensibilidade", "感度", "Sensibilidad", "Чувствительность", "灵敏度", "감도", "संवेदनशीलता", "Empfindlichkeit", "Czułość"],
        "Sleep timer": ["Temporizador de suspensão", "スリープタイマー", "Temporizador de suspensión", "Таймер сна", "休眠计时器", "절전 타이머", "स्लीप टाइमर", "Ruhezustand-Timer", "Wyłącznik czasowy"],
        "Sniper": ["Precisão", "スナイパー", "Francotirador", "Снайпер", "狙击", "스나이퍼", "स्नाइपर", "Sniper", "Snajper"],
        "Sync": ["Sincronizar", "同期", "Sincronizar", "Синхронизация", "同步", "동기화", "सिंक", "Synchronisieren", "Synchronizuj"],
        "Text": ["Texto", "テキスト", "Texto", "Текст", "文本", "텍스트", "पाठ", "Text", "Tekst"],
        "Threshold": ["Limite", "しきい値", "Umbral", "Порог", "阈值", "임계값", "सीमा", "Schwellenwert", "Próg"],
        "Vertical": ["Vertical", "垂直", "Vertical", "Вертикально", "垂直", "세로", "लंबवत", "Vertikal", "Pionowo"],
        "Horizontal": ["Horizontal", "水平", "Horizontal", "Горизонтально", "水平", "가로", "क्षैतिज", "Horizontal", "Poziomo"],
        "Vibration strength": ["Intensidade da vibração", "振動の強さ", "Intensidad de vibración", "Сила вибрации", "振动强度", "진동 강도", "कंपन की तीव्रता", "Vibrationsstärke", "Siła wibracji"],
        "Deadband is up to date.": ["O Deadband está atualizado.", "Deadbandは最新です。", "Deadband está actualizado.", "Установлена последняя версия Deadband.", "Deadband 已是最新版本。", "Deadband가 최신 버전입니다.", "Deadband नवीनतम संस्करण है।", "Deadband ist auf dem neuesten Stand.", "Deadband jest aktualny."],
        "Waiting for system authorization…": ["Aguardando autorização do sistema…", "システムの認証を待っています…", "Esperando la autorización del sistema…", "Ожидание системного разрешения…", "正在等待系统授权…", "시스템 권한 승인 대기 중…", "सिस्टम अनुमति की प्रतीक्षा…", "Warte auf Systemberechtigung…", "Oczekiwanie na autoryzację systemu…"],
        "Installing update…": ["Instalando atualização…", "更新をインストール中…", "Instalando actualización…", "Установка обновления…", "正在安装更新…", "업데이트 설치 중…", "अपडेट इंस्टॉल हो रहा है…", "Update wird installiert…", "Instalowanie aktualizacji…"],
        "Update installed. Close and reopen Deadband to use it.": ["Atualização instalada. Feche e abra o Deadband novamente para usá-la.", "更新をインストールしました。Deadbandを再起動して適用してください。", "Actualización instalada. Cierra y vuelve a abrir Deadband para usarla.", "Обновление установлено. Перезапустите Deadband, чтобы применить его.", "更新已安装。请关闭并重新打开 Deadband 以使用新版本。", "업데이트가 설치되었습니다. Deadband를 닫았다가 다시 열어 적용하세요.", "अपडेट इंस्टॉल हो गया। इसे उपयोग करने के लिए Deadband बंद करके फिर खोलें।", "Update installiert. Schließe Deadband und öffne es erneut.", "Aktualizacja zainstalowana. Zamknij i uruchom ponownie Deadband."],
        "Downloading update…": ["Baixando atualização…", "更新をダウンロード中…", "Descargando actualización…", "Загрузка обновления…", "正在下载更新…", "업데이트 다운로드 중…", "अपडेट डाउनलोड हो रहा है…", "Update wird heruntergeladen…", "Pobieranie aktualizacji…"]
    })

    function t(source) {
        if (language === "en") return source
        var row = catalog[source]
        if (!row) return source
        var index = { pt_BR: 0, ja: 1, es: 2, ru: 3, zh_CN: 4,
                      ko: 5, hi: 6, de: 7, pl: 8 }[language]
        return index === undefined ? source : row[index]
    }

    function pending(count) {
        if (language === "en") return count + (count === 1 ? " unsaved change" : " unsaved changes")
        if (language === "zh_CN") return count + " 项未保存的更改"
        if (language === "ja") return "未保存の変更: " + count + " 件"
        if (language === "ko") return "저장하지 않은 변경 사항 " + count + "개"
        if (language === "hi") return count + " सहेजे नहीं गए बदलाव"
        if (language === "ru") {
            var lastTwo = count % 100
            var last = count % 10
            var ruNoun = last === 1 && lastTwo !== 11 ? " несохранённое изменение"
                       : (last >= 2 && last <= 4 && !(lastTwo >= 12 && lastTwo <= 14)
                          ? " несохранённых изменения" : " несохранённых изменений")
            return count + ruNoun
        }
        if (language === "pl") {
            var plNoun = count === 1 ? " niezapisana zmiana"
                       : (count % 10 >= 2 && count % 10 <= 4
                          && !(count % 100 >= 12 && count % 100 <= 14)
                          ? " niezapisane zmiany" : " niezapisanych zmian")
            return count + plNoun
        }
        var singular = count === 1
        var phrase = {
            pt_BR: singular ? " alteração não salva" : " alterações não salvas",
            es: singular ? " cambio sin guardar" : " cambios sin guardar",
            de: singular ? " ungespeicherte Änderung" : " ungespeicherte Änderungen"
        }[language]
        return phrase === undefined ? count + " unsaved changes" : count + phrase
    }
}
