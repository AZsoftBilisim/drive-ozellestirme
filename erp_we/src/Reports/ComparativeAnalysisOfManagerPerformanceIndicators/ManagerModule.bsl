//@strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//
Procedure CustomizeReportOptions(Settings) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ComparativeAnalysisOfManagerPerformanceIndicators);
	DescriptionOfReport.DCSSettingsFormat = False;
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích tổng thể các chỉ tiêu thể hiện hiệu quả làm việc của người quản lý.';
									|ru = 'Комплексный анализ показателей, характеризующих эффективность работы менеджеров.';
									|en = 'Comprehensive analysis of sales person efficiency indicators.'; fa = 'Comprehensive analysis of sales person efficiency indicators.';
									|it = 'Комплексный анализ показателей, характеризующих эффективность работы менеджеров.';
									|pl = 'Analiza kompleksowa wskaźników, charakteryzujących  efektywność pracy mendeżerów.';
									|tr = 'Yöneticilerin etkinliğini karakterize eden göstergelerin kapsamlı analizi.'");
	OptionDetails.SearchSettings.FieldDescriptions = NStr("vi = 'Doanh thu
		|Lợi nhuận
		|Thu tiền
		|Doanh thu (thanh toán) trừ giá vốn (giao hàng)
		|Theo dõi các điều kiện giao hàng
		|Mất
		|Chiết khấu thủ công
		|Doanh thu trong một vụ việc
		|Doanh thu trong một lần giao tiếp
		|Các giai đoạn chính bị mất
		|Nguyên nhân thua vụ việc
		|Nguyên nhân không đáp ứng nhu cầu ban đầu
		|Biến động cơ sở khách hàng
		|Doanh thu từ khách hàng mới
		|Khiếu nại của khách hàng
		|Nguyên nhân phát sinh khiếu nại của khách hàng';
		|ru = 'Продажи
		|Прибыль
		|Поступление денежных средств
		|Выручка (по оплате) минус себестоимость (по отгрузке)
		|Соблюдение условий продаж
		|Потери
		|Ручные скидки
		|Продажи на одну сделку
		|Продажи на одно взаимодействие
		|Основные этапы потерь
		|Причины проигрыша сделок
		|Причины неудовлетворения первичного спроса
		|Динамика клиентской базы
		|Продажи новым клиентам
		|Претензии клиентов
		|Причины возникновения претензий клиентов';
		|en = 'Sales
		|Profit
		|Receipt
		|Revenue (by payment) minus cost (by shipment)
		|Compliance with sales terms and conditions
		|Losses
		|Discount adjustments
		|Sales per sales opportunity
		|Sales per interaction
		|Main stages of losses
		|Reasons for losing sales opportunities
		|Reasons for primary demand non-fulfillment
		|Customer base trends
		|Sales to new customers
		|Customer complaints
		|Reasons for customer complaints'; fa = 'Sales
		|Profit
		|Receipt
		|Revenue (by payment) minus cost (by shipment)
		|Compliance with sales terms and conditions
		|Losses
		|Discount adjustments
		|Sales per sales opportunity
		|Sales per interaction
		|Main stages of losses
		|Reasons for losing sales opportunities
		|Reasons for primary demand non-fulfillment
		|Customer base trends
		|Sales to new customers
		|Customer complaints
		|Reasons for customer complaints';
		|it = 'Продажи
		|Прибыль
		|Поступление денежных средств
		|Выручка (по оплате) минус себестоимость (по отгрузке)
		|Соблюдение условий продаж
		|Потери
		|Ручные скидки
		|Продажи на одну сделку
		|Продажи на одно взаимодействие
		|Основные этапы потерь
		|Причины проигрыша сделок
		|Причины неудовлетворения первичного спроса
		|Динамика клиентской базы
		|Продажи новым клиентам
		|Претензии клиентов
		|Причины возникновения претензий клиентов';
		|pl = 'Sprzedaż
		|Zysk
		|Wpłata środków pieniężnych
		|Utarg (według płatności) minus koszty własne (według wysyłki)
		|Przestrzeganie warunków sprzedaży
		|Straty
		|Ręczne rabaty
		|Sprzedaż na jedną umowę
		|Sprzedaż na jedną interakcję
		|Podstawowe etapy strat
		|Przyczyny niepowodzenia umowy
		|Przyczyny niezaspokojenia podstawowego popytu
		|Dynamika bazy klienckiej
		|Sprzedaż dla nowych klientów
		|Reklamacje klienta
		|Przyczyny powstania roszczeń klientów';
		|tr = 'Satışlar
		|Kâr
		|Nakit girişi
		|Gelir (ödemede) eksi maliyet (sevkiyata göre)
		|Satış koşullarına uyum
		|Kayıplar
		|İndirim düzeltmeleri
		|Anlaşma başına satış
		|Etkileşim başına satış
		|Kaybın ana aşamaları
		|Anlaşmaların kaybetme nedenleri
		|Birincil talebin memnuniyetsizlik nedenleri
		|Müşteri tabanının dinamikleri
		|Yeni müşterilere satış
		|Müşteri şikayetleri
		|Müşteri şikayetleri oluşma nedenleri'");
	OptionDetails.SearchSettings.FilterParameterDescriptions = NStr("vi = 'Kỳ phân tích
		|Kỳ để so sánh
		|Chỉ tiêu
		|Tỷ lệ hàng năm
		|Bộ phận
		|Người quản lý';
		|ru = 'Анализируемый период
		|Период для сравнения
		|Показатели
		|Годовая ставка
		|Подразделение
		|Менеджер';
		|en = 'Analyzed period
		|Period for comparison
		|Indicators
		|Annual rate
		|Business unit
		|Manager'; fa = 'Analyzed period
		|Period for comparison
		|Indicators
		|Annual rate
		|Business unit
		|Manager';
		|it = 'Анализируемый период
		|Период для сравнения
		|Показатели
		|Годовая ставка
		|Подразделение
		|Менеджер';
		|pl = 'Analizowany okres
		|Okres do porównania
		|Wskaźniki
		|Roczna stawka
		|Dział
		|Menedżer';
		|tr = 'Analiz edilen dönem
		|Karşılaştırma dönemi
		|Göstergeler
		|Yıllık oran
		|Departman
		|Yönetici'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "Main");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích tổng hợp các chỉ tiêu đặc trưng cho hiệu quả làm việc của người quản lý.
		|Đó là bán hàng, lợi nhuận, thu tiền, chiết khấu, v.v.';
		|ru = 'Комплексный анализ показателей, характеризующих эффективность работы менеджеров.
		|Таких, как продажи, прибыль, поступление ДС, скидки и другие.';
		|en = 'Comprehensive analysis of sales person efficiency indicators,
		|such as sales, income, cash receipt, discounts, and other.'; fa = 'Comprehensive analysis of sales person efficiency indicators,
		|such as sales, income, cash receipt, discounts, and other.';
		|it = 'Комплексный анализ показателей, характеризующих эффективность работы менеджеров.
		|Таких, как продажи, прибыль, поступление ДС, скидки и другие.';
		|pl = 'Analiza kompleksowa wskaźników, charakteryzujących  efektywność pracy mendeżerów.
		|Takich, jak sprzedaż, zysk, wpływ środków pieniężnych, rabaty i inne.';
		|tr = 'Yöneticilerin çalışmalarının etkinliğini karakterize eden göstergelerin kapsamlı analizi.
		|Satışlar, kârlar, Nakdin alınması, indirimler ve diğerleri gibi.'");
	OptionDetails.SearchSettings.FieldDescriptions = NStr("vi = 'Doanh thu
		|Lợi nhuận
		|Thu tiền
		|Doanh thu (thanh toán) trừ giá vốn (giao hàng)
		|Theo dõi các điều kiện giao hàng
		|Mất
		|Chiết khấu thủ công
		|Doanh thu trong một vụ việc
		|Doanh thu trong một lần giao tiếp
		|Các giai đoạn chính bị mất
		|Nguyên nhân thua vụ việc
		|Nguyên nhân không đáp ứng nhu cầu ban đầu
		|Biến động cơ sở khách hàng
		|Doanh thu từ khách hàng mới
		|Khiếu nại của khách hàng
		|Nguyên nhân phát sinh khiếu nại của khách hàng';
		|ru = 'Продажи
		|Прибыль
		|Поступление денежных средств
		|Выручка (по оплате) минус себестоимость (по отгрузке)
		|Соблюдение условий продаж
		|Потери
		|Ручные скидки
		|Продажи на одну сделку
		|Продажи на одно взаимодействие
		|Основные этапы потерь
		|Причины проигрыша сделок
		|Причины неудовлетворения первичного спроса
		|Динамика клиентской базы
		|Продажи новым клиентам
		|Претензии клиентов
		|Причины возникновения претензий клиентов';
		|en = 'Sales
		|Profit
		|Receipt
		|Revenue (by payment) minus cost (by shipment)
		|Compliance with sales terms and conditions
		|Losses
		|Discount adjustments
		|Sales per sales opportunity
		|Sales per interaction
		|Main stages of losses
		|Reasons for losing sales opportunities
		|Reasons for primary demand non-fulfillment
		|Customer base trends
		|Sales to new customers
		|Customer complaints
		|Reasons for customer complaints'; fa = 'Sales
		|Profit
		|Receipt
		|Revenue (by payment) minus cost (by shipment)
		|Compliance with sales terms and conditions
		|Losses
		|Discount adjustments
		|Sales per sales opportunity
		|Sales per interaction
		|Main stages of losses
		|Reasons for losing sales opportunities
		|Reasons for primary demand non-fulfillment
		|Customer base trends
		|Sales to new customers
		|Customer complaints
		|Reasons for customer complaints';
		|it = 'Продажи
		|Прибыль
		|Поступление денежных средств
		|Выручка (по оплате) минус себестоимость (по отгрузке)
		|Соблюдение условий продаж
		|Потери
		|Ручные скидки
		|Продажи на одну сделку
		|Продажи на одно взаимодействие
		|Основные этапы потерь
		|Причины проигрыша сделок
		|Причины неудовлетворения первичного спроса
		|Динамика клиентской базы
		|Продажи новым клиентам
		|Претензии клиентов
		|Причины возникновения претензий клиентов';
		|pl = 'Sprzedaż
		|Zysk
		|Wpłata środków pieniężnych
		|Utarg (według płatności) minus koszty własne (według wysyłki)
		|Przestrzeganie warunków sprzedaży
		|Straty
		|Ręczne rabaty
		|Sprzedaż na jedną umowę
		|Sprzedaż na jedną interakcję
		|Podstawowe etapy strat
		|Przyczyny niepowodzenia umowy
		|Przyczyny niezaspokojenia podstawowego popytu
		|Dynamika bazy klienckiej
		|Sprzedaż dla nowych klientów
		|Reklamacje klienta
		|Przyczyny powstania roszczeń klientów';
		|tr = 'Satışlar
		|Kâr
		|Nakit girişi
		|Gelir (ödemede) eksi maliyet (sevkiyata göre)
		|Satış koşullarına uyum
		|Kayıplar
		|İndirim düzeltmeleri
		|Anlaşma başına satış
		|Etkileşim başına satış
		|Kaybın ana aşamaları
		|Anlaşmaların kaybetme nedenleri
		|Birincil talebin memnuniyetsizlik nedenleri
		|Müşteri tabanının dinamikleri
		|Yeni müşterilere satış
		|Müşteri şikayetleri
		|Müşteri şikayetleri oluşma nedenleri'");
	OptionDetails.SearchSettings.FilterParameterDescriptions = NStr("vi = 'Kỳ phân tích
		|Kỳ để so sánh
		|Chỉ tiêu
		|Tỷ lệ hàng năm
		|Bộ phận
		|Người quản lý';
		|ru = 'Анализируемый период
		|Период для сравнения
		|Показатели
		|Годовая ставка
		|Подразделение
		|Менеджер';
		|en = 'Analyzed period
		|Period for comparison
		|Indicators
		|Annual rate
		|Business unit
		|Manager'; fa = 'Analyzed period
		|Period for comparison
		|Indicators
		|Annual rate
		|Business unit
		|Manager';
		|it = 'Анализируемый период
		|Период для сравнения
		|Показатели
		|Годовая ставка
		|Подразделение
		|Менеджер';
		|pl = 'Analizowany okres
		|Okres do porównania
		|Wskaźniki
		|Roczna stawka
		|Dział
		|Menedżer';
		|tr = 'Analiz edilen dönem
		|Karşılaştırma dönemi
		|Göstergeler
		|Yıllık oran
		|Departman
		|Yönetici'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
