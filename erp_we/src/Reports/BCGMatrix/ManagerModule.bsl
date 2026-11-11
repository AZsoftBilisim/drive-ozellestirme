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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.BCGMatrix);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích tổng hợp dữ liệu khách hàng trên cơ sở phân loại ABC/XYZ khách hàng.
		|Đang làm việc với những khách hàng tiềm năng nào?';
		|ru = 'Комплексный анализ клиентской базы на основе АВС/XYZ-классификации клиентов.
		|С какими клиентам перспективно работать?';
		|en = 'Comprehensively analyze the customer base based on the ABC/XYZ classification of customers.
		|View which customers are promising to work with.'; fa = 'Comprehensively analyze the customer base based on the ABC/XYZ classification of customers.
		|View which customers are promising to work with.';
		|it = 'Комплексный анализ клиентской базы на основе АВС/XYZ-классификации клиентов.
		|С какими клиентам перспективно работать?';
		|pl = 'Analiza kompleksowa bazy klienckiej na podstawie АВС/XYZ-klasyfikacji klientów. 
		|Z jakimi klientami można perspektywnie pracować?';
		|tr = 'Müşterilerin ABC/XYZ sınıflandırmasına dayalı kapsamlı müşteri tabanı analizi.
		|Hangi müşterilerle çalışmak uzun vadelidir?'");
	OptionDetails.SearchSettings.FieldDescriptions = NStr("vi = 'Nhóm A
		|Nhóm B
		|Nhóm C
		|Nhóm X
		|Nhóm Y
		|Nhóm Z
		|Thường xuyên
		|Tiềm năng
		|Phân loại hiện tại
		|Phân loại trước
		|Phân loại ABC/XYZ
		|Thay đổi ABC
		|Thay đổi XYZ';
		|ru = 'A-класс
		|B-класс
		|C-класс
		|X-класс
		|Y-класс
		|Z-класс
		|Потерянные
		|Потенциальные
		|Текущая классификация
		|Предыдущая классификация
		|ABC/XYZ распределение
		|Изменения ABC
		|Изменения XYZ';
		|en = 'A class
		|B class
		|C class
		|X class
		|Y class
		|Z class
		|Lost
		|Potential
		|Current classification
		|Previous classification
		|ABC/XYZ classification
		|ABC changes
		|XYZ changes'; fa = 'A class
		|B class
		|C class
		|X class
		|Y class
		|Z class
		|Lost
		|Potential
		|Current classification
		|Previous classification
		|ABC/XYZ classification
		|ABC changes
		|XYZ changes';
		|it = 'A-класс
		|B-класс
		|C-класс
		|X-класс
		|Y-класс
		|Z-класс
		|Потерянные
		|Потенциальные
		|Текущая классификация
		|Предыдущая классификация
		|ABC/XYZ распределение
		|Изменения ABC
		|Изменения XYZ';
		|pl = 'klasa A
		|klasa B
		|klasa C
		|klasa X
		|klasa Y
		|klasa Z
		|Utracone
		|Potencjalne
		|Bieżąca klasyfikacja
		|Poprzednia klasyfikacja
		|ABC/XYZ podział
		|Zmiany ABC
		|Zmiany XYZ';
		|tr = 'A sınıfı
		|B sınıfı
		|C sınıfı
		|X sınıfı
		|Y sınıfı
		|Z sınıfı
		|Kaybedilen
		|Potansiyel
		|Mevcut sınıflandırma
		|Önceki sınıflandırma
		|ABC/XYZ dağılımı
		|ABC değişimi
		|XYZ değişimi'");
	OptionDetails.SearchSettings.FilterParameterDescriptions = NStr("vi = 'Phân tích tại ngày
		|Kiểu tham số phân loại
		|Ngày mặt cắt hiện tại
		|Ngày mặt cắt trước đó';
		|ru = 'Анализ на дату
		|Тип параметра классификации
		|Дата текущего среза
		|Дата предыдущего среза';
		|en = 'Analysis as of the date
		|Classification parameter type
		|Current slice date 
		|Previous slice date'; fa = 'Analysis as of the date
		|Classification parameter type
		|Current slice date 
		|Previous slice date';
		|it = 'Анализ на дату
		|Тип параметра классификации
		|Дата текущего среза
		|Дата предыдущего среза';
		|pl = 'Analiza na datę
		|Typ parametru klasyfikacji
		|Data bieżącego przekroju
		|Data poprzedniego przekroju';
		|tr = 'Tarih itibarıyla analiz
		|Sınıflandırma parametre türü
		|Mevcut kesit tarihi
		|Önceki kesit tarihi'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
